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

                UserName              = "$env:COMPUTERNAME\SqlAdmin"
                Password              = 'P@ssw0rd1'

                ServerName            = $env:COMPUTERNAME
                InstanceName          = 'DSCSQLTEST'

                AuditName1            = 'FileAudit'
                Path1                 = 'C:\Temp\audit'
                MaximumFileSize1      = 10
                MaximumFileSizeUnit1  = 'MB'
                MaximumRolloverFiles1 = 11

                AuditName2            = 'SecLogAudit'
                LogType2              = 'SecurityLog'
                Filter2               = '([server_principal_name] like ''%ADMINISTRATOR'')'
            }
        )
    }

    # TODO: This leaves the SecLogAudit, if so it should be documented.

    # TODO: This folder should be created with DSC.
    New-Item -Path 'C:\Temp\audit' -ItemType 'Directory' -Force | Out-Null
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
            Filter          = $Node.Filter2

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
            Filter          = ''

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
