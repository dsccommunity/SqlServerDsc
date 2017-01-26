<#
.EXAMPLE
    This example shows how to ensure that the user account CONTOSO\SQLAdmin
    has "dbcreator" and "securityadmin" SQL server roles.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    node localhost {
        xSQLServerLogin Add_LoginForSQLAdmin
        {
            Ensure = 'Present'
            Name = 'CONTOSO\SQLAdmin'
            LoginType = 'WindowsUser'
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerRole Add_ServerRoleToLogin
        {
            DependsOn = '[xSQLServerLogin]Add_LoginForSQLAdmin'
            Ensure = 'Present'
            Name = 'CONTOSO\SQLAdmin'
            ServerRole = "dbcreator","securityadmin"
            SQLServer = 'SQLServer'
            SQLInstanceName = 'DSC'
            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
