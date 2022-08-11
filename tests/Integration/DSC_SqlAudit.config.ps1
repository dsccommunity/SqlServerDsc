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
                NodeName              = 'localhost'
                CertificateFile       = $env:DscPublicCertificatePath

                <#
                    This must be either the UPN username (e.g. username@domain.local)
                    or the user name without the NetBIOS name (e.g. username). Using
                    the NetBIOS name (e.g. DOMAIN\username) will not work.
                #>
                UserName              = "SqlAdmin"
                Password              = 'P@ssw0rd1'

                ServerName            = $env:COMPUTERNAME
                InstanceName          = 'DSCSQLTEST'

                AuditName1            = 'FileAudit'
                Path1                 = 'C:\Temp\audit'
                MaximumFileSize1      = 10
                MaximumFileSizeUnit1  = 'Megabyte'
                MaximumRolloverFiles1 = 11

                AuditName2            = 'SecLogAudit'
                LogType2              = 'SecurityLog'
                AuditFilter2          = '([server_principal_name] like ''%ADMINISTRATOR'')'
            }
        )
    }
}

<#
    .SYNOPSIS
        Creates a folder that is needed for creating a File audit.
#>
Configuration DSC_SqlAudit_Prerequisites_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        File 'Integration_Test'
        {
            Ensure          = 'Present'
            DestinationPath = $Node.Path1
            Type            = 'Directory'
            Force           = $true
        }
    }
}

<#
    .SYNOPSIS
        Creates a Server Audit with File destination.
#>
Configuration DSC_SqlAudit_AddFileAudit_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAudit 'Integration_Test'
        {
            Ensure               = 'Present'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Name                 = $Node.AuditName1
            Path                 = $Node.Path1
            MaximumFileSize      = $Node.MaximumFileSize1
            MaximumFileSizeUnit  = $Node.MaximumFileSizeUnit1
            MaximumRolloverFiles = $Node.MaximumRolloverFiles1

            Credential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Creates a audit to the security log, with a filter.
#>
Configuration DSC_SqlAudit_AddSecLogAudit_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAudit 'Integration_Test'
        {
            Ensure          = 'Present'
            ServerName      = $Node.ServerName
            InstanceName    = $Node.InstanceName
            Name            = $Node.AuditName2
            LogType         = $Node.LogType2
            AuditFilter     = $Node.AuditFilter2

            Credential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Should remove the filter
#>
Configuration DSC_SqlAudit_AddSecLogAuditNoFilter_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAudit 'Integration_Test'
        {
            Ensure          = 'Present'
            ServerName      = $Node.ServerName
            InstanceName    = $Node.InstanceName
            Name            = $Node.AuditName2
            AuditFilter     = ''

            Credential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the file audit.
#>
Configuration DSC_SqlAudit_RemoveAudit1_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAudit 'Integration_Test'
        {
            Ensure       = 'Absent'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.AuditName1

            Credential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Removes the log audit.
#>
Configuration DSC_SqlAudit_RemoveSecLogAudit_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlAudit 'Integration_Test'
        {
            Ensure       = 'Absent'
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName
            Name         = $Node.AuditName2

            Credential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
