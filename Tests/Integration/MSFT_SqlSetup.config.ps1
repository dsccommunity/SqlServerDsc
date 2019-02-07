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
                NodeName                              = 'localhost'

                # Database Engine properties.
                DatabaseEngineNamedInstanceName       = 'DSCSQL2016'
                DatabaseEngineNamedInstanceFeatures   = 'SQLENGINE,AS,CONN,BC,SDK'
                AnalysisServicesMultiServerMode       = 'MULTIDIMENSIONAL'

                <#
                    Analysis Services Tabular properties.
                    The features CONN,BC,SDK is installed with the DSCSQL2016 so those
                    features will found for DSCTABULAR instance as well.
                    The features is added here so the same property can be used to
                    evaluate the result in the test.
                #>
                AnalysisServicesTabularInstanceName   = 'DSCTABULAR'
                AnalysisServicesTabularFeatures       = 'AS,CONN,BC,SDK'
                AnalysisServicesTabularServerMode     = 'TABULAR'

                <#
                    Database Engine default instance properties.
                    The features CONN,BC,SDK is installed with the DSCSQL2016 so those
                    features will found for DSCTABULAR instance as well.
                    The features is added here so the same property can be used to
                    evaluate the result in the test.
                #>
                DatabaseEngineDefaultInstanceName     = 'MSSQLSERVER'
                DatabaseEngineDefaultInstanceFeatures = 'SQLENGINE,CONN,BC,SDK'

                # General SqlSetup properties
                Collation                             = 'Finnish_Swedish_CI_AS'
                InstallSharedDir                      = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir                   = 'C:\Program Files (x86)\Microsoft SQL Server'
                UpdateEnabled                         = 'False'
                SuppressReboot                        = $true # Make sure we don't reboot during testing.
                ForceReboot                           = $false

                # Properties for mounting media
                ImagePath                             = "$env:TEMP\SQL2016.iso"
                DriveLetter                           = $mockIsoMediaDriveLetter

                # Parameters to configure Tempdb
                SqlTempdbFileCount                    = '2'
                SqlTempdbFileSize                     = '128'
                SqlTempdbFileGrowth                   = '128'
                SqlTempdbLogFileSize                  = '128'
                SqlTempdbLogFileGrowth                = '128'

                # Creating all the credential objects to save some repeating code.
                SqlInstallAccountUserName             = "$env:COMPUTERNAME\SqlInstall"
                SqlInstallAccountPassword             = 'P@ssw0rd1'
                SqlInstallCredential                  = New-Object `
                    -TypeName System.Management.Automation.PSCredential `
                    -ArgumentList @(
                        $ConfigurationData.AllNodes.SqlInstallAccountUserName,
                        (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlInstallAccountPassword -AsPlainText -Force)
                        )

                SqlAdministratorAccountUserName = "$env:COMPUTERNAME\SqlAdmin"
                SqlAdministratorAccountPassword = 'P@ssw0rd1'
                SqlAdministratorCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $ConfigurationData.AllNodes.SqlAdminAccountUserName,
                    (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlAdminAccountPassword -AsPlainText -Force)
                    )

                SqlServicePrimaryAccountUserName = "$env:COMPUTERNAME\svc-SqlPrimary"
                SqlServicePrimaryAccountPassword = 'yig-C^Equ3'
                SqlServicePrimaryCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName,
                    (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlServicePrimaryAccountPassword -AsPlainText -Force)
                    )

                SqlAgentServicePrimaryAccountUserName = "$env:COMPUTERNAME\svc-SqlAgentPri"
                SqlAgentServicePrimaryAccountPassword = 'yig-C^Equ3'
                SqlAgentServicePrimaryCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $ConfigurationData.AllNodes.SqlAgentServicePrimaryAccountUserName,
                    (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlAgentServicePrimaryAccountPassword -AsPlainText -Force)
                    )

                SqlServiceSecondaryAccountUserName = "$env:COMPUTERNAME\svc-SqlSecondary"
                SqlServiceSecondaryAccountPassword = 'yig-C^Equ3'
                SqlServiceSecondaryCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $ConfigurationData.AllNodes.SqlServiceSecondaryAccountUserName,
                    (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlServiceSecondaryAccountPassword -AsPlainText -Force)
                    )

                SqlAgentServiceSecondaryAccountUserName = "$env:COMPUTERNAME\svc-SqlAgentSec"
                SqlAgentServiceSecondaryAccountPassword = 'yig-C^Equ3'
                SqlAgentServiceSecondaryCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(
                    $ConfigurationData.AllNodes.SqlAgentServiceSecondaryAccountUserName,
                    (ConvertTo-SecureString -String $ConfigurationData.AllNodes.SqlAgentServiceSecondaryAccountPassword -AsPlainText -Force)
                    )

                CertificateFile                       = $env:DscPublicCertificatePath
            }
        )
    }
}

Configuration MSFT_SqlSetup_CreateDependencies_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceSecondaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceSecondaryCredential
    )

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
            UserName = $Node.SqlInstallAccountUserName
            Password = $Node.SqlInstallCredential
        }

        Group 'AddSqlInstallAsAdministrator'
        {
            Ensure           = 'Present'
            GroupName        = 'Administrators'
            MembersToInclude = $Node.SqlInstallAccountUserName
        }

        User 'CreateSqlAdminAccount'
        {
            Ensure   = 'Present'
            UserName = $Node.SqlAdministratorAccountUserName
            Password = $Node.SqlAdministratorCredential
        }

        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }
    }
}

Configuration MSFT_SqlSetup_InstallDatabaseEngineNamedInstanceAsSystem_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential
    )

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
            SAPwd                  = $Node.SqlAdministratorCredential
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
                $Node.SqlAdministratorAccountUserName
                <#
                    Must have permission to properties IsClustered and
                    IsHadrEnable for SqlAlwaysOnService.
                #>
                $Node.SqlInstallAccountUserName
            )

            # This must be set if using SYSTEM account to install.
            ASSysAdminAccounts    = @(
                $Node.SqlAdministratorAccountUserName
            )
        }
    }
}

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

Configuration MSFT_SqlSetup_InstallDatabaseEngineDefaultInstanceAsUser_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServicePrimaryCredential
    )

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
                $Node.SqlAdministratorAccountUserName
            )

            PsDscRunAsCredential = $Node.SqlInstallCredential
        }
    }
}

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

Configuration MSFT_SqlSetup_InstallTabularAnalysisServicesAsSystem_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServicePrimaryCredential

    )

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
                $Node.SqlAdministratorAccountUserName
            )
        }
    }
}

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
