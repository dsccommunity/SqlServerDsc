<#
    .DESCRIPTION
        This example shows how to ensure that the user account CONTOSO\SQLAdmin
        is granted "Connect" and "Update" permissions for the databases DB01 and
        DB02. It also shows that the user account CONTOSO\SQLUser has is granted
        "Connect" and "Update" permissions, but also how it is denied the permission
        "Delete" for the database DB01.
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
        SqlDatabasePermission 'Set_Database_Permissions_SQLAdmin_DB01'
        {
            ServerName   = 'sql01.company.local'
            InstanceName = 'DSC'
            DatabaseName = 'DB01'
            Name         = 'CONTOSO\SQLAdmin'
            Credential   = $SqlAdministratorCredential
            Permission   = @(
                DatabasePermission
                {
                    State      = 'Grant'
                    Permission = @('Connect', 'Update')
                }
                DatabasePermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                DatabasePermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
            )
        }

        SqlDatabasePermission 'Set_Database_Permissions_SQLAdmin_DB02'
        {
            ServerName   = 'sql01.company.local'
            InstanceName = 'DSC'
            DatabaseName = 'DB02'
            Name         = 'CONTOSO\SQLAdmin'
            Credential   = $SqlAdministratorCredential
            Permission   = @(
                DatabasePermission
                {
                    State      = 'Grant'
                    Permission = @('Connect', 'Update')
                }
                DatabasePermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                DatabasePermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
            )
        }

        SqlDatabasePermission 'Set_Database_Permissions_SQLUser_DB01'
        {
            ServerName   = 'sql01.company.local'
            InstanceName = 'DSC'
            DatabaseName = 'DB01'
            Name         = 'CONTOSO\SQLUser'
            Credential   = $SqlAdministratorCredential
            Permission   = @(
                DatabasePermission
                {
                    State      = 'Grant'
                    Permission = @('Connect', 'Update')
                }
                DatabasePermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                DatabasePermission
                {
                    State      = 'Deny'
                    Permission = @('Delete')
                }
            )
        }
    }
}
