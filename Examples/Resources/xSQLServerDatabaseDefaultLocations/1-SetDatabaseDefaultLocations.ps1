<#
.EXAMPLE
    This example shows how to manage database default locations for Data, Logs, and Backups for SQL Server.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    node localhost
    {
        xSQLServerDatabaseDefaultLocations Set_SqlDatabaseDefaultDirectory_Data
        {
            DefaultLocationPath  = 'C:\Program Files\Microsoft SQL Server'
            DefaultLocationType  = 'Data'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerDatabaseDefaultLocations Set_SqlDatabaseDefaultDirectory_Log
        {
            DefaultLocationPath  = 'C:\Program Files\Microsoft SQL Server'
            DefaultLocationType  = 'Log'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerDatabaseDefaultLocations Set_SqlDatabaseDefaultDirectory_Backup
        {
            DefaultLocationPath  = 'C:\Program Files\Microsoft SQL Server'
            DefaultLocationType  = 'Backup'
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
