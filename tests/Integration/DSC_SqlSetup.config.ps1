<#
    cSpell: ignore MSAS SNAC DREPLAY CTLR dbatools DSCSQLTEST DSCTABULAR DSCMULTI Hadr SQLAGENT SQLSERVERAGENT
#>
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

    <#
        The variable $script:sqlVersion is set in the integration script file,
        which is available once this script is dot-sourced.
    #>
    switch ($script:sqlVersion)
    {
        '160'
        {
            $versionSpecificData = @{
                SqlServerInstanceIdPrefix       = 'MSSQL16'
                AnalysisServiceInstanceIdPrefix = 'MSAS16'
                IsoImageName                    = 'SQL2022.iso'

                # Additional variables required as ISO is downloaded via additional EXE
                DownloadExeName                 = 'SQL2022_Download.exe'
                DownloadIsoName                 = 'SQLServer2022-x64-ENU-Dev.iso'

                # Features CONN, BC, SDK, SNAC_SDK, DREPLAY_CLT, DREPLAY_CTLR are no longer supported in 2022.
                SupportedFeatures               = 'SQLENGINE,REPLICATION'

                SqlServerModuleVersion          = '22.0.59'
                DbatoolsModuleVersion           = '2.0.1'
            }
        }

        '150'
        {
            $versionSpecificData = @{
                SqlServerInstanceIdPrefix       = 'MSSQL15'
                AnalysisServiceInstanceIdPrefix = 'MSAS15'
                IsoImageName                    = 'SQL2019.iso'

                # Additional variables required as ISO is downloaded via additional EXE
                DownloadExeName                 = 'SQL2019_Download.exe'
                DownloadIsoName                 = 'SQLServer2019-x64-ENU-Dev.iso'

                SupportedFeatures               = 'SQLENGINE,REPLICATION,CONN,BC,SDK'

                SqlServerModuleVersion          = '21.1.18256'
                DbatoolsModuleVersion           = '2.0.1'
            }
        }

        '140'
        {
            $versionSpecificData = @{
                SqlServerInstanceIdPrefix       = 'MSSQL14'
                AnalysisServiceInstanceIdPrefix = 'MSAS14'
                IsoImageName                    = 'SQL2017.iso'

                SupportedFeatures               = 'SQLENGINE,REPLICATION,CONN,BC,SDK'

                SqlServerModuleVersion          = '21.1.18256'
                DbatoolsModuleVersion           = '2.0.1'
            }
        }

        '130'
        {
            $versionSpecificData = @{
                SqlServerInstanceIdPrefix       = 'MSSQL13'
                AnalysisServiceInstanceIdPrefix = 'MSAS13'
                IsoImageName                    = 'SQL2016.iso'

                SupportedFeatures               = 'SQLENGINE,REPLICATION,CONN,BC,SDK'

                SqlServerModuleVersion          = '21.1.18256'
                DbatoolsModuleVersion           = '2.0.1'
            }
        }
    }

    # Set environment variables so other integration tests can reuse the downloaded ISO.
    $env:IsoDriveLetter = $mockIsoMediaDriveLetter
    $env:IsoImagePath = Join-Path -Path $env:TEMP -ChildPath $versionSpecificData.IsoImageName

    if ($env:SMODefaultModuleName -and $env:SMODefaultModuleName -eq 'SqlServer')
    {
        $SMOModuleName = $env:SMODefaultModuleName
        $SMOModuleVersion = $versionSpecificData.SqlServerModuleVersion
    }
    elseif ($env:SMODefaultModuleName -and $env:SMODefaultModuleName -eq 'dbatools')
    {
        $SMOModuleName = $env:SMODefaultModuleName
        $SMOModuleVersion = $versionSpecificData.DbatoolsModuleVersion
    }
    else
    {
        $SMOModuleName = 'SqlServer'
        $SMOModuleVersion = $versionSpecificData.SqlServerModuleVersion
    }

    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                                = 'localhost'

                SMOModuleName                           = $SMOModuleName

                SMOModuleVersion                        = $SMOModuleVersion
                SMOModuleVersionIsPrerelease            = $true

                SqlServerInstanceIdPrefix               = $versionSpecificData.SqlServerInstanceIdPrefix
                AnalysisServiceInstanceIdPrefix         = $versionSpecificData.AnalysisServiceInstanceIdPrefix

                # Database Engine properties.
                DatabaseEngineNamedInstanceName         = 'DSCSQLTEST'
                DatabaseEngineNamedInstanceFeatures     = $versionSpecificData.SupportedFeatures

                <#
                    Analysis Services Multi-dimensional properties.
                #>
                AnalysisServicesMultiInstanceName       = 'DSCMULTI'
                AnalysisServicesMultiFeatures           = 'AS'
                AnalysisServicesMultiServerMode         = 'MULTIDIMENSIONAL'

                <#
                    Analysis Services Tabular properties.
                #>
                AnalysisServicesTabularInstanceName     = 'DSCTABULAR'
                AnalysisServicesTabularFeatures         = 'AS'
                AnalysisServicesTabularServerMode       = 'TABULAR'

                <#
                    Database Engine default instance properties.
                #>
                DatabaseEngineDefaultInstanceName       = 'MSSQLSERVER'
                DatabaseEngineDefaultInstanceFeatures   = $versionSpecificData.SupportedFeatures

                # General SqlSetup properties
                Collation                               = 'Finnish_Swedish_CI_AS'
                InstanceDir                             = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedDir                        = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir                     = 'C:\Program Files (x86)\Microsoft SQL Server'
                InstallSQLDataDir                       = "C:\Db\$($script:sqlVersion)\System"
                SQLUserDBDir                            = "C:\Db\$($script:sqlVersion)\Data\"
                SQLUserDBLogDir                         = "C:\Db\$($script:sqlVersion)\Log\"
                SQLBackupDir                            = "C:\Db\$($script:sqlVersion)\Backup"
                UpdateEnabled                           = 'False'
                SuppressReboot                          = $true # Make sure we don't reboot during testing.
                ForceReboot                             = $false

                # Properties for downloading media
                DownloadExePath                         = $(if ($versionSpecificData.DownloadExeName)
                    {
                        Join-Path -Path $env:TEMP -ChildPath $versionSpecificData.DownloadExeName
                    })
                DownloadIsoPath                         = $(if ($versionSpecificData.DownloadIsoName)
                    {
                        Join-Path -Path $env:TEMP -ChildPath $versionSpecificData.DownloadIsoName
                    })

                # Properties for mounting media
                ImagePath                               = $env:IsoImagePath
                DriveLetter                             = $env:IsoDriveLetter

                # Parameters to configure TempDb
                SqlTempDbFileCount                      = '2'
                SqlTempDbFileSize                       = '128'
                SqlTempDbFileGrowth                     = '128'
                SqlTempDbLogFileSize                    = '128'
                SqlTempDbLogFileGrowth                  = '128'

                SqlInstallAccountUserName               = "$env:COMPUTERNAME\SqlInstall"
                SqlInstallAccountPassword               = 'P@ssw0rd1'
                SqlAdministratorAccountUserName         = "$env:COMPUTERNAME\SqlAdmin"
                SqlAdministratorAccountPassword         = 'P@ssw0rd1'
                SqlServicePrimaryAccountUserName        = "$env:COMPUTERNAME\svc-SqlPrimary"
                SqlServicePrimaryAccountPassword        = 'yig-C^Equ3'
                SqlAgentServicePrimaryAccountUserName   = "$env:COMPUTERNAME\svc-SqlAgentPri"
                SqlAgentServicePrimaryAccountPassword   = 'yig-C^Equ3'
                SqlServiceSecondaryAccountUserName      = "$env:COMPUTERNAME\svc-SqlSecondary"
                SqlServiceSecondaryAccountPassword      = 'yig-C^Equ3'
                SqlAgentServiceSecondaryAccountUserName = "$env:COMPUTERNAME\svc-SqlAgentSec"
                SqlAgentServiceSecondaryAccountPassword = 'yig-C^Equ3'

                CertificateFile                         = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    Creating all the credential objects to save some repeating code.
#>

$SqlInstallCredential = New-Object `
    -TypeName System.Management.Automation.PSCredential `
    -ArgumentList @($ConfigurationData.AllNodes.SqlInstallAccountUserName,
        (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlInstallAccountPassword -AsPlainText -Force))

$SqlAdministratorCredential = New-Object `
    -TypeName System.Management.Automation.PSCredential `
    -ArgumentList @($ConfigurationData.AllNodes.SqlAdministratorAccountUserName,
        (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlAdministratorAccountPassword -AsPlainText -Force))

$SqlServicePrimaryCredential = New-Object `
    -TypeName System.Management.Automation.PSCredential `
    -ArgumentList @($ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName,
        (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlServicePrimaryAccountPassword -AsPlainText -Force))

$SqlAgentServicePrimaryCredential = New-Object `
    -TypeName System.Management.Automation.PSCredential `
    -ArgumentList @($ConfigurationData.AllNodes.SqlAgentServicePrimaryAccountUserName,
        (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlAgentServicePrimaryAccountPassword -AsPlainText -Force))

$SqlServiceSecondaryCredential = New-Object `
    -TypeName System.Management.Automation.PSCredential `
    -ArgumentList @(
        $ConfigurationData.AllNodes.SqlServiceSecondaryAccountUserName,
                (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlServiceSecondaryAccountPassword -AsPlainText -Force))

$SqlAgentServiceSecondaryCredential = New-Object `
    -TypeName System.Management.Automation.PSCredential `
    -ArgumentList @($ConfigurationData.AllNodes.SqlAgentServiceSecondaryAccountUserName,
        (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlAgentServiceSecondaryAccountPassword -AsPlainText -Force))

<#
    .SYNOPSIS
        Setting up the dependencies to test installing SQL Server instances.
#>
Configuration DSC_SqlSetup_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'
    Import-DscResource -ModuleName 'StorageDsc' -ModuleVersion '5.1.0'

    node $AllNodes.NodeName
    {
        MountImage 'MountIsoMedia'
        {
            ImagePath   = $Node.ImagePath
            DriveLetter = $Node.DriveLetter
            Ensure      = 'Present'
        }

        WaitForVolume WaitForMountOfIsoMedia
        {
            DriveLetter      = $Node.DriveLetter
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        xUser 'CreateSqlServicePrimaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlServicePrimaryCredential.UserName -Leaf
            Password = $SqlServicePrimaryCredential
        }

        xUser 'CreateSqlAgentServicePrimaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAgentServicePrimaryCredential.UserName -Leaf
            Password = $SqlAgentServicePrimaryCredential
        }

        xUser 'CreateSqlServiceSecondaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlServiceSecondaryCredential.UserName -Leaf
            Password = $SqlServicePrimaryCredential
        }

        xUser 'CreateSqlAgentServiceSecondaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAgentServiceSecondaryCredential.UserName -Leaf
            Password = $SqlAgentServicePrimaryCredential
        }

        xUser 'CreateSqlInstallAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlInstallCredential.UserName -Leaf
            Password = $SqlInstallCredential
        }

        xGroup 'AddSqlInstallAsAdministrator'
        {
            Ensure           = 'Present'
            GroupName        = 'Administrators'
            MembersToInclude = Split-Path -Path $SqlInstallCredential.UserName -Leaf
        }

        xUser 'CreateSqlAdminAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
            Password = $SqlAdministratorCredential
        }

        xWindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
    }
}

<#
    .SYNOPSIS
        Installing the specific SqlServer module from PowerShell Gallery.

    .NOTES
        This module might already be installed on the build worker. This is needed
        to install SQL Server Analysis Services instances.

        The SqlServer module is purposely not added to 'RequiredModule.psd1' so
        that it does not conflict with the SqlServerStubs module that is used by
        unit tests.
#>
Configuration DSC_SqlSetup_InstallSMOModule_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'

    node $AllNodes.NodeName
    {
        # Only set the environment variable for the LCM user only if the pipeline has it configured.
        if ($env:SMODefaultModuleName)
        {
            xEnvironment 'SetSMODefaultModuleName'
            {
                Name = 'SMODefaultModuleName'
                Value = $env:SMODefaultModuleName
                Ensure = 'Present'
                Path = $false
                Target = @('Process', 'Machine')
            }
        }

        xScript 'InstallSMOModule'
        {
              SetScript  = {
                # Uninstall any existing SMO module, to make sure there is only one at the end.
                Get-Module -Name $using:Node.SMOModuleName -ListAvailable | Uninstall-PSResource -ErrorAction 'Stop'

                # Make sure we use TLS 1.2.
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

                $installModuleParameters = @{
                    Name            = $using:Node.SMOModuleName
                    Scope           = 'AllUsers'
                    Version         = $Using:Node.SMOModuleVersion
                    Prerelease      = $Using:Node.SMOModuleVersionIsPrerelease
                    PassThru        = $true
                    Quiet           = $true
                    AcceptLicense   = $true
                    TrustRepository = $true
                }

                # Install the required SqlServer module version.
                $installedModule = Install-PSResource @installModuleParameters |
                    Where-Object -FilterScript {
                        <#
                            Need to filter out the right module since if dependencies are
                            also installed they will also be in the returned array.
                        #>
                        $_.Name -eq $using:Node.SMOModuleName
                    }

                Write-Verbose -Message ('Installed {0} module version {1}' -f $using:Node.SMOModuleName, $installedModule.Version)

                Write-Verbose -Message ('Current set preferred module name (SMODefaultModuleName): {0}' -f ($env:SMODefaultModuleName | Out-String))

                if ($using:Node.SMOModuleName -eq 'dbatools')
                {
                    Set-DbatoolsConfig -Name Import.EncryptionMessageCheck -Value $false -PassThru |
                        Register-DbatoolsConfig -Verbose

                    Write-Verbose -Message 'Disabled dbatools setting Import.EncryptionMessageCheck'
                }
            }

            TestScript = {
                <#
                    This takes the string of the $GetScript parameter and creates
                    a new script block (during runtime in the resource) and then
                    runs that script block.
                #>
                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                if ($getScriptResult.Result -eq $Using:Node.SMOModuleVersion)
                {
                    Write-Verbose -Message ('The node already contain the module {0} with version {1}.' -f $using:Node.SMOModuleName, $Using:Node.SMOModuleVersion)

                    return $true
                }

                Write-Verbose -Message ('The module {0} with version {1} is not installed.' -f $using:Node.SMOModuleName, $Using:Node.SMOModuleVersion)

                return $false
            }

            GetScript  = {
                $moduleVersion = $null
                $smoModule = $null

                $smoModule = Get-Module -Name $using:Node.SMOModuleName -ListAvailable |
                    Sort-Object -Property Version -Descending |
                    Select-Object -First 1

                if ($smoModule)
                {
                    $moduleVersion = $smoModule.Version.ToString()

                    if ($smoModule.PrivateData.PSData.Keys -contains 'Prerelease')
                    {
                        if (-not [System.String]::IsNullOrEmpty($smoModule.PrivateData.PSData.Prerelease))
                        {
                            $moduleVersion = '{0}-{1}' -f $moduleVersion, $smoModule.PrivateData.PSData.Prerelease
                        }
                    }

                    Write-Verbose -Message ('Found {0} module v{1}.' -f $using:Node.SMOModuleName, $moduleVersion) -Verbose
                }

                return @{
                    Result = $moduleVersion
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Installs a named instance of Database Engine and Analysis Services.

    .NOTES
        This is the instance that is used for many of the other integration tests.
#>
Configuration DSC_SqlSetup_InstallDatabaseEngineNamedInstanceAsSystem_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlSetup 'Integration_Test'
        {
            FeatureFlag            = @()

            InstanceName           = $Node.DatabaseEngineNamedInstanceName
            Features               = $Node.DatabaseEngineNamedInstanceFeatures
            SourcePath             = "$($Node.DriveLetter):\"
            SqlSvcStartupType      = 'Automatic'
            AgtSvcStartupType      = 'Automatic'
            BrowserSvcStartupType  = 'Automatic'
            SecurityMode           = 'SQL'
            SAPwd                  = $SqlAdministratorCredential
            SQLCollation           = $Node.Collation
            SQLSvcAccount          = $SqlServicePrimaryCredential
            AgtSvcAccount          = $SqlAgentServicePrimaryCredential
            InstanceDir            = $Node.InstanceDir
            InstallSharedDir       = $Node.InstallSharedDir
            InstallSharedWOWDir    = $Node.InstallSharedWOWDir
            InstallSQLDataDir      = $Node.InstallSQLDataDir
            SQLUserDBDir           = $Node.SQLUserDBDir
            SQLUserDBLogDir        = $Node.SQLUserDBLogDir
            SQLBackupDir           = $Node.SQLBackupDir
            UpdateEnabled          = $Node.UpdateEnabled
            SuppressReboot         = $Node.SuppressReboot
            ForceReboot            = $Node.ForceReboot
            SqlTempDbFileCount     = $Node.SqlTempDbFileCount
            SqlTempDbFileSize      = $Node.SqlTempDbFileSize
            SqlTempDbFileGrowth    = $Node.SqlTempDbFileGrowth
            SqlTempDbLogFileSize   = $Node.SqlTempDbLogFileSize
            SqlTempDbLogFileGrowth = $Node.SqlTempDbLogFileGrowth
            NpEnabled              = $true
            TcpEnabled             = $true
            UseEnglish             = $true
            SkipRule               = 'ServerCoreBlockUnsupportedSxSCheck'

            # This must be set if using SYSTEM account to install.
            SQLSysAdminAccounts    = @(
                Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
                <#
                    Must have permission to properties IsClustered and
                    IsHadrEnable for SqlAlwaysOnService.
                #>
                Split-Path -Path $SqlInstallCredential.UserName -Leaf
            )
        }
    }
}

<#
    .SYNOPSIS
        Stopping the named instance to save memory on the build worker.

    .NOTES
        The named instance is restarted at the end of the tests.
#>
Configuration DSC_SqlSetup_StopServicesInstance_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'

    node $AllNodes.NodeName
    {
        <#
            Stopping the SQL Server Agent service for the named instance.
            It will be restarted at the end of the tests.
        #>
        xService ('StopSqlServerAgentForInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name  = ('SQLAGENT${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Stopped'
        }

        <#
            Stopping the Database Engine named instance. It will be restarted
            at the end of the tests.
        #>
        xService ('StopSqlServerInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name  = ('MSSQL${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Stopped'
        }
    }
}

<#
    .SYNOPSIS
        Installs a default instance of Database Engine.
#>
Configuration DSC_SqlSetup_InstallDatabaseEngineDefaultInstanceAsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlSetup 'Integration_Test'
        {
            FeatureFlag          = @()

            InstanceName         = $Node.DatabaseEngineDefaultInstanceName
            Features             = $Node.DatabaseEngineDefaultInstanceFeatures
            SourcePath           = "$($Node.DriveLetter):\"
            SQLCollation         = $Node.Collation
            SQLSvcAccount        = $SqlServicePrimaryCredential
            AgtSvcAccount        = $SqlAgentServicePrimaryCredential
            InstallSharedDir     = $Node.InstallSharedDir
            InstallSharedWOWDir  = $Node.InstallSharedWOWDir
            UpdateEnabled        = $Node.UpdateEnabled
            SuppressReboot       = $Node.SuppressReboot
            ForceReboot          = $Node.ForceReboot
            SQLSysAdminAccounts  = @(
                Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
            )

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}

<#
    .SYNOPSIS
        Stopping the default instance to save memory on the build worker.
#>
Configuration DSC_SqlSetup_StopSqlServerDefaultInstance_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'

    node $AllNodes.NodeName
    {
        xService ('StopSqlServerAgentForInstance{0}' -f $Node.DatabaseEngineDefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Stopped'
        }


        xService ('StopSqlServerInstance{0}' -f $Node.DatabaseEngineDefaultInstanceName)
        {
            Name  = $Node.DatabaseEngineDefaultInstanceName
            State = 'Stopped'
        }
    }
}

<#
    .SYNOPSIS
        Installs a named instance of Analysis Services in multi-dimensional mode.
#>
Configuration DSC_SqlSetup_InstallMultiDimensionalAnalysisServicesAsSystem_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlSetup 'Integration_Test'
        {
            FeatureFlag         = @('AnalysisServicesConnection')

            InstanceName        = $Node.AnalysisServicesMultiInstanceName
            Features            = $Node.AnalysisServicesMultiFeatures
            SourcePath          = "$($Node.DriveLetter):\"
            ASServerMode        = $Node.AnalysisServicesMultiServerMode
            ASCollation         = $Node.Collation
            ASSvcAccount        = $SqlServicePrimaryCredential
            InstallSharedDir    = $Node.InstallSharedDir
            InstallSharedWOWDir = $Node.InstallSharedWOWDir
            UpdateEnabled       = $Node.UpdateEnabled
            SuppressReboot      = $Node.SuppressReboot
            ForceReboot         = $Node.ForceReboot

            # This must be set if using SYSTEM account to install.
            ASSysAdminAccounts  = @(
                Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
            )
        }
    }
}

<#
    .SYNOPSIS
        Stopping the Analysis Services multi-dimensional named instance to save
        memory on the build worker.
#>
Configuration DSC_SqlSetup_StopMultiDimensionalAnalysisServices_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'

    node $AllNodes.NodeName
    {
        xService ('StopMultiDimensionalAnalysisServicesInstance{0}' -f $Node.AnalysisServicesMultiInstanceName)
        {
            Name  = ('MSOLAP${0}' -f $Node.AnalysisServicesMultiInstanceName)
            State = 'Stopped'
        }
    }
}


<#
    .SYNOPSIS
        Installs a named instance of Analysis Services in tabular mode.
#>
Configuration DSC_SqlSetup_InstallTabularAnalysisServicesAsSystem_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlSetup 'Integration_Test'
        {
            FeatureFlag         = @('AnalysisServicesConnection')

            InstanceName        = $Node.AnalysisServicesTabularInstanceName
            Features            = $Node.AnalysisServicesTabularFeatures
            SourcePath          = "$($Node.DriveLetter):\"
            ASServerMode        = $Node.AnalysisServicesTabularServerMode
            ASCollation         = $Node.Collation
            ASSvcAccount        = $SqlServicePrimaryCredential
            InstallSharedDir    = $Node.InstallSharedDir
            InstallSharedWOWDir = $Node.InstallSharedWOWDir
            UpdateEnabled       = $Node.UpdateEnabled
            SuppressReboot      = $Node.SuppressReboot
            ForceReboot         = $Node.ForceReboot

            # This must be set if using SYSTEM account to install.
            ASSysAdminAccounts  = @(
                Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
            )
        }
    }
}

<#
    .SYNOPSIS
        Stopping the Analysis Services tabular named instance to save memory on
        the build worker.
#>
Configuration DSC_SqlSetup_StopTabularAnalysisServices_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'

    node $AllNodes.NodeName
    {
        xService ('StopTabularAnalysisServicesInstance{0}' -f $Node.AnalysisServicesTabularInstanceName)
        {
            Name  = ('MSOLAP${0}' -f $Node.AnalysisServicesTabularInstanceName)
            State = 'Stopped'
        }
    }
}

<#
    .SYNOPSIS
        Restarting the Database Engine named instance.

    .NOTES
        This is so that other integration tests are dependent on this
        named instance.
#>
Configuration DSC_SqlSetup_StartServicesInstance_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'

    node $AllNodes.NodeName
    {
        # Start the Database Engine named instance.
        xService ('StartSqlServerInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name  = ('MSSQL${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Running'
        }

        # Starting the SQL Server Agent service for the named instance.
        xService ('StartSqlServerAgentForInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name  = ('SQLAGENT${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Running'
        }
    }
}
