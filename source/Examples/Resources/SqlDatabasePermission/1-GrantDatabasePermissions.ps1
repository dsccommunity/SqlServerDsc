<#
    .DESCRIPTION
        This example shows how to ensure that the user account CONTOSO\SQLAdmin
        has "Connect" and "Update" SQL Permissions for database "AdventureWorks".
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
        SqlDatabasePermission 'Grant_SqlDatabasePermissions_SQLAdmin_Db01'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            DatabaseName         = 'AdventureWorks'
            PermissionState      = 'Grant'
            Permissions          = @('Connect', 'Update')
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabasePermission 'Grant_SqlDatabasePermissions_SQLUser_Db01'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLUser'
            DatabaseName         = 'AdventureWorks'
            PermissionState      = 'Grant'
            Permissions          = @('Connect', 'Update')
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabasePermission 'Grant_SqlDatabasePermissions_SQLAdmin_Db02'
        {
            Ensure               = 'Present'
            Name                 = 'CONTOSO\SQLAdmin'
            DatabaseName         = 'AdventureWorksLT'
            PermissionState      = 'Grant'
            Permissions          = @('Connect', 'Update')
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
