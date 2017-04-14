<#
    .EXAMPLE
        This example will add a Database Mirror endpoint with specifc listener port and listener IP address.
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
        xSQLServerEndpoint SQLConfigureEndpoint
        {
            Ensure = 'Present'

            EndpointName = 'HADR'
            Port = 9001
            IpAddress = '192.168.0.20'

            SQLServer = 'server1.company.local'
            SQLInstanceName = 'INST1'

            PsDscRunAsCredential = $SysAdminAccount
        }
   }
}
