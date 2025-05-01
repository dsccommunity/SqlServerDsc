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
                NodeName             = 'localhost'
                InstanceName         = if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_PowerBI')
                {
                    'PBIRS'
                }
                else
                {
                    'SSRS'
                }
                Action               = 'Install'
                AcceptLicensingTerms = $true
                MediaPath            = Join-Path -Path $env:TEMP -ChildPath 'SQLServerReportingServices.exe'
                Edition              = 'Developer'
                InstallFolder        = 'C:\Program Files\SSRS'
                LogPath              = Join-Path -Path $env:TEMP -ChildPath 'SSRS_Install.log'

                UserName             = "$env:COMPUTERNAME\SqlInstall"
                Password             = 'P@ssw0rd1'

                CertificateFile      = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Installs a Microsoft SQL Server Reporting Services instance.

    .NOTES
        When this test was written the build worker already contained a
        Microsoft SQL Server Reporting Services instance.
        If it exist, it will be upgraded.

        Uninstall is not tested, because when upgrading the existing Microsoft
        SQL Server 2017 or SQL Server 2019 Reporting Services instance it requires
        a restart which prevents uninstall until the node is rebooted.
#>
Configuration DSC_SqlRSSetup_InstallReportingServicesAsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRSSetup 'Integration_Test'
        {
            InstanceName         = $Node.InstanceName
            Action               = $Node.Action
            AcceptLicensingTerms = $Node.AcceptLicensingTerms
            MediaPath            = $Node.MediaPath
            Edition              = $Node.Edition
            InstallFolder        = $Node.InstallFolder
            LogPath              = $Node.LogPath

            <#
                The build worker contains already an instance, make sure to upgrade it.
                It does not work for Microsoft SQL Server 2017 Reporting Services,
                see .NOTES section in the resource.
            #>
            VersionUpgrade       = if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2017')
            {
                $false
            }
            else
            {
                $true
            }

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
        Stopping the Microsoft SQL Server Reporting Services instance to
        save memory on the build worker.
#>
Configuration DSC_SqlRSSetup_StopReportingServicesInstance_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'

    $serviceConfigName = if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_PowerBI')
    {
        'StopPowerBIReportServerInstance'
    }
    else
    {
        'StopReportingServicesInstance'
    }

    node $AllNodes.NodeName
    {
        xService $serviceConfigName
        {
            Name  = if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_PowerBI')
            {
                'PowerBIReportServer'
            }
            else
            {
                'SQLServerReportingServices'
            }
            State = 'Stopped'
        }
    }
}
