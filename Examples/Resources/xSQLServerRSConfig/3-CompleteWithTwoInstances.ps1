<#
.EXAMPLE
    This example installs to instances where the first named instance is used for
    the Reporting Services databases, and the second named instance is used for
    Reporting Services. After installing the two instances, the configuration
    performs a default SSRS configuration. It will initialize SSRS
    and register default Report Server Web Service and Report Manager URLs:
    http://localhost:80/ReportServer (Report Server Web Service)
    http://localhost:80/Reports (Report Manager)
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost'

            # This is values used for the Reporting Services instance.
            InstanceName                = 'RS'
            Features                    = 'RS'

            # This is values used for the Database Engine instance.
            RSServer                 = $env:COMPUTERNAME
            RSInstanceName           = 'RSDB'
            RSFeatures               = 'SQLENGINE'
            RSCollation              = 'Finnish_Swedish_CI_AS'

            # This is values used for both instances.
            MediaPath                   = 'Z:\Sql2016Media'
            InstallSharedDir            = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir         = 'C:\Program Files (x86)\Microsoft SQL Server'
            UpdateEnabled               = 'False'
            BrowserSvcStartupType       = 'Automatic'

            PSDscAllowPlainTextPassword = $true
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
    Import-DscResource -ModuleName xSqlServer

    node localhost {
        WindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        xSQLServerSetup 'InstallDatabaseEngine'
        {
            InstanceName          = $Node.RSInstanceName
            Features              = $Node.RSFeatures
            SourcePath            = $Node.MediaPath
            BrowserSvcStartupType = $Node.BrowserSvcStartupType
            SQLCollation          = $Node.RSCollation
            SQLSvcAccount         = $SqlServiceCredential
            AgtSvcAccount         = $SqlAgentServiceCredential
            InstallSharedDir      = $Node.InstallSharedDir
            InstallSharedWOWDir   = $Node.InstallSharedWOWDir
            UpdateEnabled         = $Node.UpdateEnabled

            SQLSysAdminAccounts   = @(
                $SqlAdministratorCredential.UserName
            )

            DependsOn             = @(
                '[WindowsFeature]NetFramework45'
            )

            PsDscRunAsCredential  = $SqlInstallCredential
        }

        xSQLServerSetup 'InstallReportingServicesInstance'
        {
            InstanceName          = $Node.InstanceName
            Features              = $Node.Features
            SourcePath            = $Node.MediaPath
            BrowserSvcStartupType = $Node.BrowserSvcStartupType
            RSSvcAccount          = $ReportingServicesServiceCredential
            InstallSharedDir      = $Node.InstallSharedDir
            InstallSharedWOWDir   = $Node.InstallSharedWOWDir
            UpdateEnabled         = $Node.UpdateEnabled

            SQLSysAdminAccounts   = @(
                $SqlAdministratorCredential.UserName
            )

            DependsOn             = @(
                '[WindowsFeature]NetFramework45'
                '[xSQLServerSetup]InstallDatabaseEngine'
            )

            PsDscRunAsCredential  = $SqlInstallCredential
        }

        xSQLServerRSConfig 'ConfigureReportingServiceInstance'
        {
            # Instance name for the Reporting Services.
            InstanceName         = $Node.InstanceName

            # Instance for Reporting Services databases.
            RSSQLServer          = $Node.RSServer
            RSSQLInstanceName    = $Node.RSInstanceName

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn            = @(
                '[xSQLServerSetup]InstallReportingServicesInstance'
            )
        }
    }
}
