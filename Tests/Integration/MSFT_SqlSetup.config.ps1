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

    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName                                = 'localhost'

                # Database Engine properties.
                DatabaseEngineNamedInstanceName         = 'DSCSQLTEST'

                <#
                    CONN feature:
                    Due to issue #1105 the feature CONN was removed.
                    It cannot be used here if CONN is already installed
                    in the AppVeyor build worker.
                #>
                DatabaseEngineNamedInstanceFeatures     = 'SQLENGINE,AS,BC,SDK'
                AnalysisServicesMultiServerMode         = 'MULTIDIMENSIONAL'

                <#
                    Analysis Services Tabular properties.
                    The features CONN,BC,SDK is installed with the DSCSQL2016 so those
                    features will found for DSCTABULAR instance as well.
                    The features is added here so the same property can be used to
                    evaluate the result in the test.
                #>
                AnalysisServicesTabularInstanceName     = 'DSCTABULAR'

                <#
                    CONN feature:
                    Due to issue #1105 the feature CONN was removed.
                    It cannot be used here if CONN is already installed
                    in the AppVeyor build worker.
                #>
                AnalysisServicesTabularFeatures         = 'AS,BC,SDK'
                AnalysisServicesTabularServerMode       = 'TABULAR'

                <#
                    Database Engine default instance properties.
                    The features CONN,BC,SDK is installed with the DSCSQL2016 so those
                    features will found for DSCTABULAR instance as well.
                    The features is added here so the same property can be used to
                    evaluate the result in the test.
                #>
                DatabaseEngineDefaultInstanceName       = 'MSSQLSERVER'

                <#
                    CONN feature:
                    Due to issue #1105 the feature CONN was removed.
                    It cannot be used here if CONN is already installed
                    in the AppVeyor build worker.
                #>
                DatabaseEngineDefaultInstanceFeatures   = 'SQLENGINE,BC,SDK'

                # General SqlSetup properties
                Collation                               = 'Finnish_Swedish_CI_AS'
                InstallSharedDir                        = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir                     = 'C:\Program Files (x86)\Microsoft SQL Server'
                UpdateEnabled                           = 'False'
                SuppressReboot                          = $true # Make sure we don't reboot during testing.
                ForceReboot                             = $false

                # Properties for mounting media
                ImagePath                               = "$env:TEMP\SQL2017.iso"
                DriveLetter                             = $mockIsoMediaDriveLetter

                # Parameters to configure Tempdb
                SqlTempdbFileCount                      = '2'
                SqlTempdbFileSize                       = '128'
                SqlTempdbFileGrowth                     = '128'
                SqlTempdbLogFileSize                    = '128'
                SqlTempdbLogFileGrowth                  = '128'

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
Configuration MSFT_SqlSetup_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'StorageDsc'

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

        User 'CreateSqlServicePrimaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlServicePrimaryCredential.UserName -Leaf
            Password = $SqlServicePrimaryCredential
        }

        User 'CreateSqlAgentServicePrimaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAgentServicePrimaryCredential.UserName -Leaf
            Password = $SqlAgentServicePrimaryCredential
        }

        User 'CreateSqlServiceSecondaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlServiceSecondaryCredential.UserName -Leaf
            Password = $SqlServicePrimaryCredential
        }

        User 'CreateSqlAgentServiceSecondaryAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAgentServiceSecondaryCredential.UserName -Leaf
            Password = $SqlAgentServicePrimaryCredential
        }

        User 'CreateSqlInstallAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlInstallCredential.UserName -Leaf
            Password = $SqlInstallCredential
        }

        Group 'AddSqlInstallAsAdministrator'
        {
            Ensure           = 'Present'
            GroupName        = 'Administrators'
            MembersToInclude = Split-Path -Path $SqlInstallCredential.UserName -Leaf
        }

        User 'CreateSqlAdminAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
            Password = $SqlAdministratorCredential
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
    }
}

<#
    .SYNOPSIS
        Installs a named instance of Database Engine and Analysis Services.

    .NOTES
        This is the instance that is used for many of the other integration tests.
#>
Configuration MSFT_SqlSetup_InstallDatabaseEngineNamedInstanceAsSystem_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlSetup 'Integration_Test'
        {
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
            ASServerMode           = $Node.AnalysisServicesMultiServerMode
            AsSvcStartupType       = 'Automatic'
            ASCollation            = $Node.Collation
            ASSvcAccount           = $SqlServicePrimaryCredential
            InstallSharedDir       = $Node.InstallSharedDir
            InstallSharedWOWDir    = $Node.InstallSharedWOWDir
            UpdateEnabled          = $Node.UpdateEnabled
            SuppressReboot         = $Node.SuppressReboot
            ForceReboot            = $Node.ForceReboot
            SqlTempdbFileCount     = $Node.SqlTempdbFileCount
            SqlTempdbFileSize      = $Node.SqlTempdbFileSize
            SqlTempdbFileGrowth    = $Node.SqlTempdbFileGrowth
            SqlTempdbLogFileSize   = $Node.SqlTempdbLogFileSize
            SqlTempdbLogFileGrowth = $Node.SqlTempdbLogFileGrowth

            # This must be set if using SYSTEM account to install.
            SQLSysAdminAccounts   = @(
                Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
                <#
                    Must have permission to properties IsClustered and
                    IsHadrEnable for SqlAlwaysOnService.
                #>
                Split-Path -Path $SqlInstallCredential.UserName -Leaf
            )

            # This must be set if using SYSTEM account to install.
            ASSysAdminAccounts    = @(
                Split-Path -Path $SqlAdministratorCredential.UserName -Leaf
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
Configuration MSFT_SqlSetup_StopServicesInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node $AllNodes.NodeName
    {
        <#
            Stopping the SQL Server Agent service for the named instance.
            It will be restarted at the end of the tests.
        #>
        Service ('StopSqlServerAgentForInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name  = ('SQLAGENT${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Stopped'
        }

        <#
            Stopping the Database Engine named instance. It will be restarted
            at the end of the tests.
        #>
        Service ('StopSqlServerInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name   = ('MSSQL${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State  = 'Stopped'
        }

        Service ('StopMultiAnalysisServicesInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name  = ('MSOLAP${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Stopped'
        }
    }
}

<#
    .SYNOPSIS
        Installs a default instance of Database Engine.
#>
Configuration MSFT_SqlSetup_InstallDatabaseEngineDefaultInstanceAsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlSetup 'Integration_Test'
        {
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
Configuration MSFT_SqlSetup_StopSqlServerDefaultInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node $AllNodes.NodeName
    {
        Service ('StopSqlServerAgentForInstance{0}' -f $Node.DatabaseEngineDefaultInstanceName)
        {
            Name  = 'SQLSERVERAGENT'
            State = 'Stopped'
        }


        Service ('StopSqlServerInstance{0}' -f $Node.DatabaseEngineDefaultInstanceName)
        {
            Name  = $Node.DatabaseEngineDefaultInstanceName
            State = 'Stopped'
        }
    }
}

<#
    .SYNOPSIS
        Installs a named instance of Analysis Services in tabular mode.
#>
Configuration MSFT_SqlSetup_InstallTabularAnalysisServicesAsSystem_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlSetup 'Integration_Test'
        {
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
Configuration MSFT_SqlSetup_StopTabularAnalysisServices_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node $AllNodes.NodeName
    {
        Service ('StopTabularAnalysisServicesInstance{0}' -f $Node.AnalysisServicesTabularInstanceName)
        {
            Name  = ('MSOLAP${0}' -f $Node.DatabaseEngineNamedInstanceName)
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
Configuration MSFT_SqlSetup_StartServicesInstance_Config
{
    Import-DscResource -ModuleName 'PSDscResources'

    node $AllNodes.NodeName
    {
        # Start the Database Engine named instance.
        Service ('StartSqlServerInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name   = ('MSSQL${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State  = 'Running'
        }

        # Starting the SQL Server Agent service for the named instance.
        Service ('StartSqlServerAgentForInstance{0}' -f $Node.DatabaseEngineNamedInstanceName)
        {
            Name  = ('SQLAGENT${0}' -f $Node.DatabaseEngineNamedInstanceName)
            State = 'Running'
        }
    }
}
