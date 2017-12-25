# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 1)]
param()

# Get a spare drive letter
$mockLastDrive = ((Get-Volume).DriveLetter | Sort-Object | Select-Object -Last 1)
$mockIsoMediaDriveLetter = [char](([int][char]$mockLastDrive) + 1)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                            = 'localhost'

            # SQL Engine properties
            SqlEngineInstanceName               = 'DSCSQL2016'
            SqlEngineFeatures                   = 'SQLENGINE,AS,CONN,BC,SDK'
            AnalysisServicesMultiServerMode     = 'MULTIDIMENSIONAL'

            # Analysis Services Tabular properties
            AnalysisServicesTabularInstanceName = 'DSCTABULAR'
            <#
                CONN,BC,SDK is installed with the DSCSQL2016 so those feature
                will found for DSCTABULAR instance as well.
            #>
            AnalysisServicesTabularFeatures     = 'AS,CONN,BC,SDK'
            AnalysisServicesTabularServerMode   = 'TABULAR'

            # General SqlSetup properties
            Collation                           = 'Finnish_Swedish_CI_AS'
            InstallSharedDir                    = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir                 = 'C:\Program Files (x86)\Microsoft SQL Server'
            UpdateEnabled                       = 'False'
            SuppressReboot                      = $true # Make sure we don't reboot during testing.
            ForceReboot                         = $false

            # Properties for mounting media
            ImagePath                           = "$env:TEMP\SQL2016.iso"
            DriveLetter                         = $mockIsoMediaDriveLetter

            <#
                We must compile the configuration using plain text since the
                common integration test framework does not use certificates.
                This should not be used in production.
            #>
            PSDscAllowPlainTextPassword         = $true
        }
    )
}

Configuration MSFT_SqlSetup_InstallSqlEngineAsSystem_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAgentServiceCredential
    )

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'xStorage'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        xMountImage 'MountIsoMedia'
        {
            ImagePath   = $Node.ImagePath
            DriveLetter = $Node.DriveLetter
            Ensure      = 'Present'
        }

        xWaitForVolume WaitForMountOfIsoMedia
        {
            DriveLetter      = $Node.DriveLetter
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        User 'CreateSqlServiceAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlServiceCredential.UserName -Leaf
            Password = $SqlServiceCredential
        }

        User 'CreateSqlAgentServiceAccount'
        {
            Ensure   = 'Present'
            UserName = Split-Path -Path $SqlAgentServiceCredential.UserName -Leaf
            Password = $SqlAgentServiceCredential
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
            MembersToInclude = $SqlInstallCredential.UserName
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

        SqlSetup 'Integration_Test'
        {
            InstanceName          = $Node.SqlEngineInstanceName
            Features              = $Node.SqlEngineFeatures
            SourcePath            = "$($Node.DriveLetter):\"
            BrowserSvcStartupType = 'Automatic'
            SQLCollation          = $Node.Collation
            SQLSvcAccount         = $SqlServiceCredential
            AgtSvcAccount         = $SqlAgentServiceCredential
            ASServerMode          = $Node.AnalysisServicesMultiServerMode
            ASCollation           = $Node.Collation
            ASSvcAccount          = $SqlServiceCredential
            InstallSharedDir      = $Node.InstallSharedDir
            InstallSharedWOWDir   = $Node.InstallSharedWOWDir
            UpdateEnabled         = $Node.UpdateEnabled
            SuppressReboot        = $Node.SuppressReboot
            ForceReboot           = $Node.ForceReboot

            # This must be set if using SYSTEM account to install.
            SQLSysAdminAccounts   = @(
                $SqlAdministratorCredential.UserName
                <#
                    Must have permission to properties IsClustered and
                    IsHadrEnable for SqlAlwaysOnService.
                #>
                $SqlInstallCredential.UserName
            )

            # This must be set if using SYSTEM account to install.
            ASSysAdminAccounts  = @(
                $SqlAdministratorCredential.UserName
                $SqlInstallCredential.UserName
            )

            DependsOn             = @(
                '[xMountImage]MountIsoMedia'
                '[User]CreateSqlServiceAccount'
                '[User]CreateSqlAgentServiceAccount'
                '[User]CreateSqlInstallAccount'
                '[Group]AddSqlInstallAsAdministrator'
                '[User]CreateSqlAdminAccount'
                '[WindowsFeature]NetFramework45'
            )
        }
    }
}

Configuration MSFT_SqlSetup_InstallAnalysisServicesAsSystem_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlServiceCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {
        SqlSetup 'Integration_Test'
        {
            InstanceName        = $Node.AnalysisServicesTabularInstanceName
            Features            = $Node.AnalysisServicesTabularFeatures
            SourcePath          = "$($Node.DriveLetter):\"
            ASServerMode        = $Node.AnalysisServicesTabularServerMode
            ASCollation         = $Node.Collation
            ASSvcAccount        = $SqlServiceCredential
            InstallSharedDir    = $Node.InstallSharedDir
            InstallSharedWOWDir = $Node.InstallSharedWOWDir
            UpdateEnabled       = $Node.UpdateEnabled
            SuppressReboot      = $Node.SuppressReboot
            ForceReboot         = $Node.ForceReboot

            # This must be set if using SYSTEM account to install.
            ASSysAdminAccounts  = @(
                $SqlAdministratorCredential.UserName
                $SqlInstallCredential.UserName
            )
        }
    }
}

