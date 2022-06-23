<#
    .DESCRIPTION
        This example performs a default Power BI Report Server configuration.
        It will initialize Power BI Report Server and register default Report
        Server Web Service and Report Manager URLs.

        Report Server Web Service: http://localhost:80/ReportServer
        Report Manager: http://localhost:80/Reports
#>
Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlRS 'PowerBIReportServerDefaultConfiguration'
        {
            InstanceName         = 'PBIRS'
            DatabaseServerName   = 'localhost'
            DatabaseInstanceName = 'MSSQLSERVER'
        }
    }
}
