<#
    .EXAMPLE
        This example will make sure that the endpoint DefaultMirrorEndpoint is in started state, if not it will start the endpoint.
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
        # Start the endpoint
        xSQLServerEndpointState StartEndpoint
        {
            NodeName = 'SQLNODE01.company.local'
            InstanceName = 'MSSQLSERVER'
            Name = 'DefaultMirrorEndpoint'
            State = 'Started'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
