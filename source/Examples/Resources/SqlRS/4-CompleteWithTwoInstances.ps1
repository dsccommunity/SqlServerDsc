<#
    .DESCRIPTION
        This example installs to instances where the first named instance is used for
        the Reporting Services databases, and the second named instance is used for
        Reporting Services. After installing the two instances, the configuration
        performs a default SQL Server Reporting Services configuration. It will
        initialize SQL Server Reporting Services and register the default
        Report Server Web Service and Report Manager URLs:

        Report Manager: http://localhost:80/Reports_RS
        Report Server Web Service: http://localhost:80/ReportServer_RS
#>

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

    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'
    Import-DscResource -ModuleName 'SqlServerDsc'

    Node localhost
    {
        xWindowsFeature 'NetFramework45'
        {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        SqlSetup 'InstallDatabaseEngine'
        {
            InstanceName          = 'RSDB'
            Features              = 'SQLENGINE'
            SourcePath            = 'Z:\Sql2016Media'
            BrowserSvcStartupType = 'Automatic'
            SQLCollation          = 'Finnish_Swedish_CI_AS'
            SQLSvcAccount         = $SqlServiceCredential
            AgtSvcAccount         = $SqlAgentServiceCredential
            InstallSharedDir      = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
            UpdateEnabled         = 'False'

            SQLSysAdminAccounts   = @(
                $SqlAdministratorCredential.UserName
            )

            PsDscRunAsCredential  = $SqlInstallCredential

            DependsOn             = @(
                '[xWindowsFeature]NetFramework45'
            )
        }

        SqlSetup 'InstallReportingServicesInstance'
        {
            InstanceName          = 'RS'
            Features              = 'RS'
            SourcePath            = 'Z:\Sql2016Media'
            BrowserSvcStartupType = 'Automatic'
            RSSvcAccount          = $ReportingServicesServiceCredential
            InstallSharedDir      = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
            UpdateEnabled         = 'False'

            PsDscRunAsCredential  = $SqlInstallCredential

            DependsOn             = @(
                '[xWindowsFeature]NetFramework45'
                '[SqlSetup]InstallDatabaseEngine'
            )
        }

        SqlRS 'ConfigureReportingServiceInstance'
        {
            # Instance name for the Reporting Services.
            InstanceName         = 'RS'

            <#
                Instance for Reporting Services databases.
                Tge value $env:COMPUTERNAME can only be used if the configuration
                is compiled on the node that should contain the instance 'RSDB'.
                If not, set to the node name.
            #>
            DatabaseServerName   = $env:COMPUTERNAME
            DatabaseInstanceName = 'RSDB'

            PsDscRunAsCredential = $SqlInstallCredential

            DependsOn            = @(
                '[SqlSetup]InstallReportingServicesInstance'
            )
        }
    }
}
