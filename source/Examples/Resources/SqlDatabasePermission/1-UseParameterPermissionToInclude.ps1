<#
    .DESCRIPTION
        This example shows how to ensure that the user account CONTOSO\SQLAdmin
        is granted "Connect" and "Update" permissions for the databases DB01.
        Any existing permissions in the states Grant, Deny, and GrantWithGrant will
        not be changed (unless the contradict with the desired state).
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
            PermissionToInclude   = @(
                DatabasePermission
                {
                    State      = 'Grant'
                    Permission = @('Connect', 'Update')
                }
            )
        }
    }
}
