<#
    .DESCRIPTION
        This example shows how to enforce that if the login CONTOSO\SQLAdmin would
        be granted the permission "CreateEndpoint" outside of DSC, it is revoked.
        Any other existing permissions in the states Grant, Deny, and GrantWithGrant
        will not be changed (unless the contradict with the desired state).
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
        SqlPermission 'Set_Permissions_SQLAdmin'
        {
            ServerName            = 'sql01.company.local'
            InstanceName          = 'DSC'
            Name                  = 'CONTOSO\SQLAdmin'
            Credential            = $SqlAdministratorCredential
            PermissionToExclude   = @(
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @('CreateEndpoint')
                }
            )
        }
    }
}
