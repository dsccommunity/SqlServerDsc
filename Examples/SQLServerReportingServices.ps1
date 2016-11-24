
Configuration SQLServerReportingServices
{
    param
    (
        # Credentials for the setup.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SetupCredential,

        # Credentials for the SQL Server reporting account.
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $ReportingCredential
    )

    Import-DscResource -ModuleName xSQLServer
    Import-DscResource -ModuleName xCredSSP

    Node $AllNodes.NodeName
    {
        # Install the .NET Framework 3.5 feature
        WindowsFeature 'NETFrameworkCoreFeature'
        {
            Ensure = 'Present'
            Name   = 'NET-Framework-Core'
        }

        # The xSQLServerRSConfig resource depends on te SQLPS module. Download
        # the required tools from the Microsoft Download Center, e.g. SQL 2016:
        # https://www.microsoft.com/en-us/download/details.aspx?id=52676
        Package SQLSysClrTypesPackage
        {
            Ensure    = 'Present'
            Path      = 'C:\Setup\Tools\SQLSysClrTypes.msi'
            Name      = 'Microsoft System CLR Types for SQL Server 2016'
            ProductId = '96EB5054-C775-4BEF-B7B9-AA96A295EDCD'
        }
        Package SharedManagementObjectsPackage
        {
            Ensure    = 'Present'
            Path      = 'C:\Setup\Tools\SharedManagementObjects.msi'
            Name      = 'Microsoft SQL Server 2016 Management Objects  (x64)'
            ProductId = '20EA85AA-2A1D-4F11-B09F-4BA2BF3C8989'

            DependsOn = @(
                '[Package]SQLSysClrTypesPackage'
            )
        }
        Package PowerShellToolsPackage
        {
            Ensure    = 'Present'
            Path      = 'C:\Setup\Tools\PowerShellTools.msi'
            Name      = 'PowerShell Extensions for SQL Server 2016 '
            ProductId = '1E19C524-DADE-4587-BE64-D57B1C0BA3C0'

            DependsOn = @(
                '[Package]SharedManagementObjectsPackage'
            )
        }

        # The CredSSP client and server needs to be enabled, so that the
        # xSQLServerRSConfig resoruce can execute remote SQL scripts with the
        # SQL admin credentals.
        xCredSSP CredSSPServer
        {
            Ensure            = 'Present'
            Role              = 'Server'
        }
        xCredSSP CredSSPClient
        {
            Ensure            = 'Present'
            Role              = 'Client'
            DelegateComputers = '*'
        }

        # Now invoke the SQL Server setup to just install the RS feature.
        xSQLServerSetup SQLServerSetup
        {
            InstanceName        = 'MSSQLSERVER'
            Features            = 'RS'

            InstallSharedDir    = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir         = 'C:\Program Files\Microsoft SQL Server'

            SetupCredential     = $SetupCredential
            RSSvcAccount        = $ReportingCredential

            SourcePath          = 'C:\Setup\Source'
            SourceFolder        = ''
            UpdateSource        = 'C:\Setup\Update'

            DependsOn           = @(
                '[WindowsFeature]NETFrameworkCoreFeature'
            )
        }

        # Create firewall rules for the SQL Server Reporting Services ports.
        xSQLServerFirewall SQLServerFirewall
        {
            InstanceName = 'MSSQLSERVER'
            Features     = 'RS'

            SourcePath   = 'C:\Setup\SQL\Source'
            SourceFolder = ''

            DependsOn = @(
                '[xSQLServerSetup]SQLServerSetup'
            )
        }

        # Finally, configure the SQL Server Reporting Services virtual
        # directories and create the ReportServer[TempDB] databases on a remote
        # SQL Server.
        xSQLServerRSConfig SQLServerRSConfig
        {
            InstanceName       = 'MSSQLSERVER'
            RSSQLServer        = 'SQLSERVER01'
            RSSQLInstanceName  = 'MSSQLSERVER'
            SQLAdminCredential = $SetupCredential

            DependsOn = @(
                '[xSQLServerSetup]SQLServerSetup'
            )
        }
    }
}
