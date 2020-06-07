<#
    .DESCRIPTION
        This example will remove the server permissions AlterAnyAvailabilityGroup and ViewServerState
        from the login 'NT AUTHORITY\SYSTEM'.
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
        # Add permission
        SqlPermission 'SQLConfigureServerPermission'
        {
            Ensure               = 'Absent'
            ServerName           = 'SQLNODE01.company.local'
            InstanceName         = 'MSSQLSERVER'
            Principal            = 'NT AUTHORITY\SYSTEM'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
