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
    # Get a spare drive letter
    $mockLastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
    $mockIsoMediaDriveLetter = [char](([int][char]$mockLastDrive) + 1)

    if ($script:sqlVersion -eq '160')
    {
        # SQL2022
        $instanceName = 'SSRS'
    }
    elseif ($script:sqlVersion -eq '150')
    {
        # SQL2019
        $instanceName = 'SSRS'
    }
    elseif ($script:sqlVersion -eq '140')
    {
        # SQL2017
        $instanceName = 'SSRS'
    }
    else
    {
        # SQL2016
        $instanceName = 'DSCRS2016'
    }

    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName             = 'localhost'

                RunAs_UserName       = "$env:COMPUTERNAME\SqlInstall"
                RunAs_Password       = 'P@ssw0rd1'
                Service_UserName     = "$env:COMPUTERNAME\svc-Reporting"
                Service_Password     = 'yig-C^Equ3'

                InstanceName         = $instanceName
                Features             = 'RS'
                InstallSharedDir     = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir  = 'C:\Program Files (x86)\Microsoft SQL Server'
                UpdateEnabled        = 'False'
                SuppressReboot       = $true # Make sure we don't reboot during testing.
                ForceReboot          = $false

                ImagePath            = "$env:TEMP\SQL2016.iso"
                DriveLetter          = $mockIsoMediaDriveLetter

                DatabaseServerName   = $env:COMPUTERNAME
                DatabaseInstanceName = 'DSCSQLTEST'

                CertificateFile      = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Add dependencies for configuring Reporting Services. Mounts the ISO,
        create the service account, make sure .NET Framework 4.5 is installed,
        and installs the Reporting Services,
#>
Configuration DSC_SqlRS_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'
    Import-DscResource -ModuleName 'StorageDsc' -ModuleVersion '5.1.0'
    Import-DscResource -ModuleName 'WSManDsc' -ModuleVersion '3.1.1'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        WSManConfig Config
        {
            IsSingleInstance  = 'Yes'
            MaxEnvelopeSizeKb = 600
        }

        xUser 'CreateReportingServicesServiceAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $Node.Service_UserName -Leaf
            Password = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Service_UserName, (ConvertTo-SecureString -String $Node.Service_Password -AsPlainText -Force))
        }

        xWindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        if ($script:sqlVersion -eq '130')
        {
            MountImage 'MountIsoMedia'
            {
                ImagePath   = $Node.ImagePath
                DriveLetter = $Node.DriveLetter
                Ensure      = 'Present'
            }

            WaitForVolume 'WaitForMountOfIsoMedia'
            {
                DriveLetter      = $Node.DriveLetter
                RetryIntervalSec = 5
                RetryCount       = 10
            }

            SqlSetup 'InstallReportingServicesInstance'
            {
                InstanceName          = $Node.InstanceName
                Features              = $Node.Features
                SourcePath            = "$($Node.DriveLetter):\"
                BrowserSvcStartupType = 'Automatic'
                InstallSharedDir      = $Node.InstallSharedDir
                InstallSharedWOWDir   = $Node.InstallSharedWOWDir
                UpdateEnabled         = $Node.UpdateEnabled
                SuppressReboot        = $Node.SuppressReboot
                ForceReboot           = $Node.ForceReboot
                RSSvcAccount          = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @($Node.Service_UserName, (ConvertTo-SecureString -String $Node.Service_Password -AsPlainText -Force))

                DependsOn             = @(
                    '[WaitForVolume]WaitForMountOfIsoMedia'
                    '[xUser]CreateReportingServicesServiceAccount'
                    '[xWindowsFeature]NetFramework45'
                )

                PsDscRunAsCredential = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @(
                        $Node.RunAs_UserName, (ConvertTo-SecureString -String $Node.RunAs_Password -AsPlainText -Force))
            }
        }
        <#
            DSC_SqlRSSetup.Integration.Tests.ps1 will have installed SSRS 2017 or 2019.
            We just need to start SSRS.
        #>
        elseif ($script:sqlVersion -in @('140', '150', '160'))
        {
            xService 'StartReportingServicesInstance'
            {
                Name  = 'SQLServerReportingServices'
                State = 'Running'
            }
        }
    }
}

<#
    .SYNOPSIS
        Configures the Reporting Services.
#>
Configuration DSC_SqlRS_ConfigureReportingServices_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRS 'Integration_Test'
        {
            # Instance name for the Reporting Services.
            InstanceName         = $Node.InstanceName

            <#
                Instance for Reporting Services databases.
                Note: This instance is created in a prior integration test.
            #>
            DatabaseServerName   = $Node.DatabaseServerName
            DatabaseInstanceName = $Node.DatabaseInstanceName
            Encrypt              = 'Optional'

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.RunAs_UserName, (ConvertTo-SecureString -String $Node.RunAs_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Enables SSL on the Reporting Services.
#>
Configuration DSC_SqlRS_ConfigureSsl_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRS 'Integration_Test'
        {
            # Instance name for the Reporting Services.
            InstanceName         = $Node.InstanceName
            UseSsl               = $true
            Encrypt              = 'Optional'

            <#
                Instance for Reporting Services databases.
                Note: This instance is created in a prior integration test.
            #>
            DatabaseServerName   = $Node.DatabaseServerName
            DatabaseInstanceName = $Node.DatabaseInstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.RunAs_UserName, (ConvertTo-SecureString -String $Node.RunAs_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Disables SSL on the Reporting Services.
#>
Configuration DSC_SqlRS_RestoreToNoSsl_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlRS 'Integration_Test'
        {
            # Instance name for the Reporting Services.
            InstanceName         = $Node.InstanceName
            UseSsl               = $false
            Encrypt              = 'Optional'

            <#
                Instance for Reporting Services databases.
                Note: This instance is created in a prior integration test.
            #>
            DatabaseServerName   = $Node.DatabaseServerName
            DatabaseInstanceName = $Node.DatabaseInstanceName

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $Node.RunAs_UserName, (ConvertTo-SecureString -String $Node.RunAs_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Stops the Reporting Services instance to save resource on the build worker.
#>
Configuration DSC_SqlRS_StopReportingServicesInstance_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'

    node $AllNodes.NodeName
    {
        if ($script:sqlVersion -eq '130')
        {
            xService ('StopReportingServicesInstance{0}' -f $Node.InstanceName)
            {
                Name  = ('ReportServer${0}' -f $Node.InstanceName)
                State = 'Stopped'
            }
        }
        elseif ($script:sqlVersion -in @('140', '150', '160'))
        {
            xService 'StopReportingServicesInstance'
            {
                Name  = 'SQLServerReportingServices'
                State = 'Stopped'
            }
        }
    }
}
