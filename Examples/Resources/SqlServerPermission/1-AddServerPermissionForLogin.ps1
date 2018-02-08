<#
    .EXAMPLE
        This example will add the server permissions AlterAnyAvailabilityGroup and ViewServerState
        to the login 'NT AUTHORITY\SYSTEM' and 'NT SERVICE\ClusSvc' to the default instance.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDSC

    node localhost
    {
        # Add permission
        SqlServerPermission 'SQLConfigureServerPermission-SYSTEM'
        {
            Ensure               = 'Present'
            ServerName           = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            Principal            = 'NT AUTHORITY\SYSTEM'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlServerPermission 'SQLConfigureServerPermission-ClusSvc'
        {
            Ensure               = 'Present'
            ServerName           = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
