<#
.EXAMPLE
    This example installs to instances where the first named instance is used for
    the Reporting Services databases, and the second named instance is used for
    Reporting Services. After installing the two instances, the configuration
    performs a default SQL Server Reporting Services configuration. It will
    initialize SQL Server Reporting Services and register the default
    Report Server Web Service and Report Manager URLs:

    Report Manager: http://localhost:80/Reports_RS
    Report Server Web Service: http://localhost:80/ReportServer_RS
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                   = 'localhost'

            # This is values used for the Reporting Services instance.
            InstanceName               = 'RS'
            Features                   = 'RS'

            # This is values used for the Database Engine instance.
            DatabaseServerName         = $env:COMPUTERNAME
            DatabaseServerInstanceName = 'RSDB'
            DatabaseServerFeatures     = 'SQLENGINE'
            DatabaseServerCollation    = 'Finnish_Swedish_CI_AS'

            # This is values used for both instances.
            MediaPath                  = 'Z:\Sql2016Media'
            InstallSharedDir           = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir        = 'C:\Program Files (x86)\Microsoft SQL Server'
            UpdateEnabled              = 'False'
            BrowserSvcStartupType      = 'Automatic'
        }
    )
}

Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential,

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
        $SqlAgentServiceCredential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $ReportingServicesServiceCredential
    )

    Import-DscResource -ModuleName PSDscResources
    Import-DscResource -ModuleName SqlServerDsc

    Node localhost {
        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        SqlSetup 'InstallDatabaseEngine'
        {
            InstanceName          = $Node.DatabaseServerInstanceName
            Features              = $Node.DatabaseServerFeatures
            SourcePath            = $Node.MediaPath
            BrowserSvcStartupType = $Node.BrowserSvcStartupType
            SQLCollation          = $Node.DatabaseServerCollation
            SQLSvcAccount         = $SqlServiceCredential
            AgtSvcAccount         = $SqlAgentServiceCredential
            InstallSharedDir      = $Node.InstallSharedDir
            InstallSharedWOWDir   = $Node.InstallSharedWOWDir
            UpdateEnabled         = $Node.UpdateEnabled

            SQLSysAdminAccounts   = @(
                $SqlAdministratorCredential.UserName
            )

            PsDscRunAsCredential  = $SqlInstallCredential

            DependsOn             = @(
                '[WindowsFeature]NetFramework45'
            )
        }

        SqlSetup 'InstallReportingServicesInstance'
        {
            InstanceName          = $Node.InstanceName
            Features              = $Node.Features
            SourcePath            = $Node.MediaPath
            BrowserSvcStartupType = $Node.BrowserSvcStartupType
            RSSvcAccount          = $ReportingServicesServiceCredential
            InstallSharedDir      = $Node.InstallSharedDir
            InstallSharedWOWDir   = $Node.InstallSharedWOWDir
            UpdateEnabled         = $Node.UpdateEnabled

            PsDscRunAsCredential  = $SqlInstallCredential

            DependsOn             = @(
                '[WindowsFeature]NetFramework45'
                '[SqlSetup]InstallDatabaseEngine'
            )
        }

        SqlRS 'ConfigureReportingServiceInstance'
        {
            # Instance name for the Reporting Services.
            InstanceName         = $Node.InstanceName

            # Instance for Reporting Services databases.
            DatabaseServerName   = $Node.DatabaseServerName
            DatabaseInstanceName = $Node.DatabaseServerInstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn            = @(
                '[SqlSetup]InstallReportingServicesInstance'
            )
        }
    }
}
