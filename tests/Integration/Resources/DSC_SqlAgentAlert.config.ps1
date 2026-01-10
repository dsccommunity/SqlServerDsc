#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName        = 'localhost'

                UserName        = "$env:COMPUTERNAME\SqlInstall"
                Password        = 'P@ssw0rd1'

                ServerName      = $env:COMPUTERNAME
                InstanceName    = 'DSCSQLTEST'

                Name            = 'MockAlert'
                Severity        = '17'
                MessageId       = '50001'

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Adds a SQL Agent alert.
#>
Configuration DSC_SqlAgentAlert_Add_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAgentAlert 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Name                 = $Node.Name
            Severity             = $Node.Severity

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Changes a SQL Agent alert to use MessageId instead of Severity.
#>
Configuration DSC_SqlAgentAlert_ChangeToMessageId_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        # First, create the custom system message
        SqlScriptQuery 'CreateCustomMessage'
        {
            Id                   = 'CreateCustomMessage'
            InstanceName         = $Node.InstanceName
            ServerName           = $Node.ServerName
            Encrypt              = 'Optional'
            # cSpell: ignore addmessage msgnum msgtext
            SetQuery             = "
                IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = $($Node.MessageId) AND language_id = 1033)
                BEGIN
                    EXEC sp_addmessage
                        @msgnum = $($Node.MessageId),
                        @severity = 16,
                        @msgtext = N'Custom test message for SqlAgentAlert integration test',
                        @lang = 'us_english'
                END
            "
            TestQuery            = "
                IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = $($Node.MessageId) AND language_id = 1033)
                BEGIN
                    RAISERROR ('Did not found message id [$($Node.MessageId)]', 16, 1)
                END
                ELSE
                BEGIN
                    PRINT 'Found a message id [$($Node.MessageId)]'
                END
            "
            GetQuery             = "SELECT message_id, text FROM sys.messages WHERE message_id = $($Node.MessageId) AND language_id = 1033 FOR JSON AUTO"

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlAgentAlert 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Name                 = $Node.Name
            MessageId            = $Node.MessageId

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            DependsOn            = '[SqlScriptQuery]CreateCustomMessage'
        }
    }
}

<#
    .SYNOPSIS
        Removes a SQL Agent alert.
#>
Configuration DSC_SqlAgentAlert_Remove_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAgentAlert 'Integration_Test'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Name                 = $Node.Name

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        # Clean up the custom system message
        SqlScriptQuery 'RemoveCustomMessage'
        {
            Id                   = 'RemoveCustomMessage'
            InstanceName         = $Node.InstanceName
            ServerName           = $Node.ServerName
            Encrypt              = 'Optional'
            # cSpell: ignore dropmessage
            SetQuery             = "
                IF EXISTS (SELECT 1 FROM sys.messages WHERE message_id = $($Node.MessageId) AND language_id = 1033)
                BEGIN
                    EXEC sp_dropmessage
                        @msgnum = $($Node.MessageId),
                        @lang = 'us_english'
                END
            "
            TestQuery            = "
                IF EXISTS (SELECT 1 FROM sys.messages WHERE message_id = $($Node.MessageId) AND language_id = 1033)
                BEGIN
                    RAISERROR ('Found message id [$($Node.MessageId)]', 16, 1)
                END
                ELSE
                BEGIN
                    PRINT 'Did not found a message id [$($Node.MessageId)]'
                END
            "
            GetQuery             = "SELECT message_id, text FROM sys.messages WHERE message_id = $($Node.MessageId) AND language_id = 1033 FOR JSON AUTO"

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))

            DependsOn            = '[SqlAgentAlert]Integration_Test'
        }
    }
}
