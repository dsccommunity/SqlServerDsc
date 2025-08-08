<#
    .SYNOPSIS
        The possible states for the commands and DSC resources that handles
        SQL Server Reporting Services or Power BI Report Server and uses the
        parameter Edition.
#>
enum ReportServerEdition
{
    Developer = 1
    Evaluation
    ExpressAdvanced
}