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

                MailServerName  = 'mail.company.local'
                AccountName     = 'MyMail'
                ProfileName     = 'MyMailProfile'
                EmailAddress    = 'NoReply@company.local'
                Description     = 'Default mail account and profile.'
                LoggingLevel    = 'Normal'
                TcpPort         = 25

                CertificateFile = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Configures database mail.

    .NOTES
        This also enables the option 'Database Mail XPs'.
#>
Configuration DSC_SqlDatabaseMail_Add_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlConfiguration 'EnableDatabaseMailXPs'
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.InstanceName
            OptionName     = 'Database Mail XPs'
            OptionValue    = 1
            RestartService = $false
        }

        SqlDatabaseMail 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = $Node.AccountName
            ProfileName          = $Node.ProfileName
            EmailAddress         = $Node.EmailAddress
            ReplyToAddress       = $Node.EmailAddress
            DisplayName          = $Node.MailServerName
            MailServerName       = $Node.MailServerName
            Description          = $Node.Description
            LoggingLevel         = $Node.LoggingLevel
            TcpPort              = $Node.TcpPort

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

Configuration DSC_SqlDatabaseMail_AddMultiple_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabaseMail 'CreateAlertsProfile'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = 'Company SQL Alerts'
            ProfileName          = 'Company SQL Alerts'
            EmailAddress         = 'sqlalerts@company.local'
            ReplyToAddress       = 'noreply@company.local'
            DisplayName          = ('Company SQL Alerts {0}' -f $node.InstanceName)
            MailServerName       = $Node.MailServerName
            Description          = 'This profile will be used to alert Company SQL Personnel.'
            LoggingLevel         = 'Extended'
            TcpPort              = 25

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlDatabaseMail 'CreateMaintenanceNotifyProfile'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = 'Company SQL Maintenance Notify'
            ProfileName          = 'Company SQL Maintenance Notify'
            EmailAddress         = 'sqlmaintnotify@company.local'
            ReplyToAddress       = 'noreply@company.local'
            DisplayName          = ('Company Maintenance Alerts {0}' -f $node.InstanceName)
            MailServerName       = $Node.MailServerName
            Description          = 'This profile will be used to alert Company Maintenance Personnel.'
            LoggingLevel         = 'Extended'
            TcpPort              = 25

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes database mail.

    .NOTES
        This also disables the option 'Database Mail XPs'.
#>
Configuration DSC_SqlDatabaseMail_Remove_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabaseMail 'Integration_Test'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            AccountName          = $Node.AccountName
            ProfileName          = $Node.ProfileName
            EmailAddress         = $Node.EmailAddress
            MailServerName       = $Node.MailServerName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }

        SqlConfiguration 'DisableDatabaseMailXPs'
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.InstanceName
            OptionName     = 'Database Mail XPs'
            OptionValue    = 0
            RestartService = $false
        }
    }
}
