<#
.EXAMPLE
    This example performs a custom SQL Server Reporting Services configuration.
    It will initialize SQL Server Reporting Services and register the below
    custom Report Server Web Service and Report Manager URLs and enable SSL.

    Report Server Web Service: https://localhost:443/MyReportServer ()
    Report Manager: https://localhost:443/MyReports

    Note: this resource does not currently handle SSL bindings for HTTPS endpoints.
#>
Configuration Example
{
    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlRS DefaultConfiguration
        {
            InstanceName                 = 'MSSQLSERVER'
            DatabaseServerName           = 'localhost'
            DatabaseInstanceName         = 'MSSQLSERVER'
            ReportServerVirtualDirectory = 'MyReportServer'
            ReportsVirtualDirectory      = 'MyReports'
            ReportServerReservedUrl      = @('https://+:443')
            ReportsReservedUrl           = @('https://+:443')
            UseSsl                       = $true
        }
    }
}
