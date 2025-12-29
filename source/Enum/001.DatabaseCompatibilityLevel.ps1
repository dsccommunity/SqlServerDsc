<#
    .SYNOPSIS
        Enum for database compatibility levels.

    .DESCRIPTION
        This enum represents the SQL Server database compatibility levels.
        Each value corresponds to a specific SQL Server version.
#>
enum DatabaseCompatibilityLevel
{
    Version80  = 80
    Version90  = 90
    Version100 = 100
    Version110 = 110
    Version120 = 120
    Version130 = 130
    Version140 = 140
    Version150 = 150
    Version160 = 160
}
