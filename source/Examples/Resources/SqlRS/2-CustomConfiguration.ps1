<#
    .DESCRIPTION
        This example performs a custom SQL Server Reporting Services configuration.
        It will initialize SQL Server Reporting Services and register the below
        custom Report Server Web Service and Report Manager URLs.

        Report Server Web Service:
        http://localhost:80/MyReportServer
        https://localhost:443/MyReportServer

        Report Manager:
        http://localhost:80/MyReports
        https://localhost:443/MyReports

        > [!NOTE]
        > This resource does not currently handle SSL bindings for HTTPS endpoints.
#>
Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlRS 'DefaultConfiguration'
        {
            InstanceName                 = 'MSSQLSERVER'
            DatabaseServerName           = 'localhost'
            DatabaseInstanceName         = 'MSSQLSERVER'
            ReportServerVirtualDirectory = 'MyReportServer'
            ReportsVirtualDirectory      = 'MyReports'
            ReportServerReservedUrl      = @('http://+:80', 'https://+:443')
            ReportsReservedUrl           = @('http://+:80', 'https://+:443')
        }
    }
}
