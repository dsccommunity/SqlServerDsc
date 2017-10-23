<#
.EXAMPLE
    This example shows how to manage database default locations for Data, Logs, and Backups for SQL Server.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    node localhost
    {
        xSQLServerDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Data
        {
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            Type                 = 'Data'
            Path                 = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Log
        {
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            Type                 = 'Log'
            Path                 = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerDatabaseDefaultLocation Set_SqlDatabaseDefaultDirectory_Backup
        {
            SQLServer            = 'SQLServer'
            SQLInstanceName      = 'DSC'
            Type                 = 'Backup'
            Path                 = 'C:\Program Files\Microsoft SQL Server'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
