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
                NodeName           = 'localhost'
                InstanceName       = 'SSRS'
                IAcceptLicensTerms = 'Yes'
                SourcePath         = Join-Path -Path $env:TEMP -ChildPath 'SQLServerReportingServices.exe'
                Edition            = 'Development'

                UserName           = "$env:COMPUTERNAME\SqlInstall"
                Password           = 'P@ssw0rd1'

                CertificateFile    = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Installs a Microsoft SQL Server 2017 Reporting Services.

    .NOTES
        When this test was written the build worker already contained a
        Microsoft SQL Server 2017 Reporting Services instance.
        If it exist, it will be upgraded.
#>
Configuration MSFT_SqlRSSetup_InstallReportingServicesAsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRSSetup 'Integration_Test'
        {
            InstanceName         = $Node.InstanceName
            IAcceptLicensTerms   = $Node.IAcceptLicensTerms
            SourcePath           = $Node.SourcePath
            Edition              = $Node.Edition

            # The build worker contains already an instance, make sure to upgrade it.
            VersionUpgrade       = $true

            # Suppressing restart because the build worker are not allowed to be restarted.
            SuppressRestart      = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Uninstalls the Microsoft SQL Server 2017 Reporting Services instance.
#>
Configuration MSFT_SqlRSSetup_UninstallReportingServicesAsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRSSetup 'Integration_Test'
        {
            InstanceName         = $Node.InstanceName
            IAcceptLicensTerms   = $Node.IAcceptLicensTerms
            SourcePath           = $Node.SourcePath
            Action               = 'Uninstall'

            SuppressRestart      = $true

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Username, (ConvertTo-SecureString -String $Node.Password -AsPlainText -Force))
        }
    }
}
