<#
    .DESCRIPTION
        This example shows how to do the following:

        1. Ensure that user CONTOSO\Barbara will have the db_datareader role and will not have the db_denydatareader and db_denydatawriter roles.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {

    # Make sure the login exists

        SqlServerLogin 'Login_CONTOSO_Clare' {
            ServerName      = 'sqltest.company.local'
            InstanceName    = 'DSC'
            Name            = 'CONTOSO\Clare'
            Ensure          = 'Present'
            LoginType       = 'WindowsGroup'
            Disabled        = $false
        }

    # Make sure the user exists

        SqlDatabaseUser 'User_AdventureWorks_Clare_MacIntyre-Ross' {
            ServerName      = 'sqltest.company.local'
            InstanceName    = 'DSC'
            DatabaseName    = 'AdventureWorks'
            Name            = 'Clare MacIntyre-Ross'
            LoginName       = 'CONTOSO\Clare'
            UserType        = 'Login'
            Ensure          = 'Present'
#            OnAllReplicas   = $false
            Force           = $false
        }

    # Make sure the user has at least read access to the database and is not denied write access if granted by other roles

        SqlDatabaseRole 'ReportViewer_IncludeAndExcludeRoleMembers'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            DatabaseName         = 'AdventureWorks'
            UserName             = 'Clare MacIntyre-Ross'
            RoleNamesToInclude   = , 'db_datareader'
            RoleNamesToExclude   = 'db_denydatareader', 'db_denydatawriter'
            OnAllReplicas        = $false
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

    }
}
