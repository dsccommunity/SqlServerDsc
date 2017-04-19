<#
    .EXAMPLE
        This example will add the server permissions AlterAnyAvailabilityGroup and ViewServerState
        to the login 'NT AUTHORITY\SYSTEM'.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSQLServer

    node localhost
    {
        # Add permission
        xSQLServerPermission SQLConfigureServerPermission
        {
            Ensure = 'Present'
            NodeName = 'SQLNODE01.company.local'
            InstanceName = 'MSSQLSERVER'
            Principal = 'NT AUTHORITY\SYSTEM'
            Permission = 'AlterAnyAvailabilityGroup','ViewServerState'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
