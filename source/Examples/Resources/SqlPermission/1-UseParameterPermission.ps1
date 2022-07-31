<#
    .DESCRIPTION
        This example shows how to ensure that the login "NT AUTHORITY\SYSTEM" and
        "NT SERVICE\ClusSvc" is granted "AlterAnyAvailabilityGroup" and "ViewServerState"
        permissions.
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
        SqlPermission 'SQLConfigureServerPermission-SYSTEM'
        {
            ServerName   = 'sql01.company.local'
            InstanceName = 'DSC'
            Name         = 'NT AUTHORITY\SYSTEM'
            Credential   = $SqlAdministratorCredential
            Permission   = @(
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @('AlterAnyAvailabilityGroup', 'ViewServerState')
                }
                ServerPermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                ServerPermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
            )
        }

        SqlPermission 'SQLConfigureServerPermission-ClusterSvc'
        {
            ServerName   = 'sql01.company.local'
            InstanceName = 'DSC'
            Name         = 'NT SERVICE\ClusSvc'
            Credential   = $SqlAdministratorCredential
            Permission   = @(
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @('AlterAnyAvailabilityGroup', 'ViewServerState')
                }
                ServerPermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                ServerPermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
            )
        }
    }
}
