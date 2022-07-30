<#
    .DESCRIPTION
        This example shows how to ensure that the login CONTOSO\SQLAdmin is granted
        the "AlterAnyAvailabilityGroup" and "ViewServerState" permissions.
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
        SqlPermission 'Set_Database_Permissions_SQLAdmin'
        {
            ServerName            = 'sql01.company.local'
            InstanceName          = 'DSC'
            Name                  = 'CONTOSO\SQLAdmin'
            Credential            = $SqlAdministratorCredential
            PermissionToInclude   = @(
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @('AlterAnyAvailabilityGroup', 'ViewServerState')
                }
            )
        }
    }
}
