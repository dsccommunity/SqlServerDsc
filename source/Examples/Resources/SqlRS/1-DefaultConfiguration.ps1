<#
    .DESCRIPTION
        This example performs a default SQL Server Reporting Services configuration.
        It will initialize SQL Server Reporting Services and register default
        Report Server Web Service and Report Manager URLs.

        Report Server Web Service: http://localhost:80/ReportServer
        Report Manager: http://localhost:80/Reports
#>
Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlRS 'DefaultConfiguration'
        {
            InstanceName         = 'MSSQLSERVER'
            DatabaseServerName   = 'localhost'
            DatabaseInstanceName = 'MSSQLSERVER'
        }
    }
}
