<#
    .DESCRIPTION
        This example shows how to do the following:

        1. Ensure that the login and user for CONTOSO\Clare exists in the AdventureWorks database.

        2. Ensure that db_datareader and db_datawriter will be the only roles for user CONTOSO\Clare in the AdventureWorks database.

        3. Ensure that the login and user for group CONTOSO\ReadOnlyUsers exists in the AdventureWorks database.

        4. Ensure that db_datareader will be the only role for the group CONTOSO\ReadOnlyUsers in the AdventureWorks database.
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

    # Make sure the user has the roles to be enforced

        SqlDatabaseUserRole 'UserRoles_AdventureWorks_Clare_MacIntyre-Ross_Enforce'
        {
            ServerName              = 'sqltest.company.local'
            InstanceName            = 'DSC'
            DatabaseName            = 'AdventureWorks'
            UserName                = 'Clare MacIntyre-Ross'
            RoleNamesToEnforce      = 'db_datareader', 'db_datawriter'
            OnAllReplicas           = $false
            PsDscRunAsCredential    = $SqlAdministratorCredential
        }

    # Make sure the login exists

        SqlServerLogin 'Login_CONTOSO_Clare' {
            ServerName      = 'sqltest.company.local'
            InstanceName    = 'DSC'
            Name            = 'CONTOSO\ReadOnlyUsers'
            Ensure          = 'Present'
            LoginType       = 'WindowsGroup'
            Disabled        = $false
        }

    # Make sure the user exists

        SqlDatabaseUser 'User_AdventureWorks_CONTOSO_Read-Only_Users' {
            ServerName      = 'sqltest.company.local'
            InstanceName    = 'DSC'
            DatabaseName    = 'AdventureWorks'
            Name            = 'CONTOSO Read-Only Users'
            LoginName       = 'CONTOSO\ReadOnlyUsers'
            UserType        = 'Login'
            Ensure          = 'Present'
#            OnAllReplicas   = $false
            Force           = $false
        }

    # Make sure the user has the roles to be enforced

        SqlDatabaseUserRole 'UserRoles_AdventureWorks_CONTOSO_Read-Only_Users_Enforce'
        {
            ServerName              = 'sqltest.company.local'
            InstanceName            = 'DSC'
            DatabaseName            = 'AdventureWorks'
            UserName                = 'CONTOSO Read-Only Users'
            RoleNamesToEnforce      = , 'db_datareader'
            OnAllReplicas           = $false
            PsDscRunAsCredential    = $SqlAdministratorCredential
        }

    }

}
