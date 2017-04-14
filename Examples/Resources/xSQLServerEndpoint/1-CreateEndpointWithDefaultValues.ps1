<#
    .EXAMPLE
        This example will add a Database Mirror endpoint using the default values to two instances.

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
        xSQLServerEndpoint SQLConfigureEndpoint-Instance1
        {
            EndpointName = 'HADR'
            SQLInstanceName = 'INST1'

            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerEndpoint SQLConfigureEndpoint-Instances2
        {
            EndpointName = 'HADR'
            SQLInstanceName = 'INST2'

            PsDscRunAsCredential = $SysAdminAccount
        }
   }
}
