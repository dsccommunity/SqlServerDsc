<#
    .DESCRIPTION
        This example shows how to enforce that if the user account CONTOSO\SQLAdmin
        in the databases DB01 would be granted the permission "Delete" outside of
        DSC, it is revoked.
        Any other existing permissions in the states Grant, Deny, and GrantWithGrant
        will not be changed.
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
            ServerName            = 'sql01.company.local'
            InstanceName          = 'DSC'
            DatabaseName          = 'DB01'
            Name                  = 'CONTOSO\SQLAdmin'
            Credential            = $SqlAdministratorCredential
            PermissionToExclude   = @(
                DatabasePermission
                {
                    State      = 'Grant'
                    Permission = @('Delete')
                }
            )
        }
    }
}
