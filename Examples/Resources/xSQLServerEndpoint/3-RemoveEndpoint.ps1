<#
    .EXAMPLE
        This example will remove an Database Mirror endpoint from two instances.

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
            Ensure = 'Absent'

            EndpointName = 'HADR'
            SQLInstanceName = 'INST1'

            PsDscRunAsCredential = $SysAdminAccount
        }

        xSQLServerEndpoint SQLConfigureEndpoint
        {
            Ensure = 'Absent'

            EndpointName = 'HADR'
            SQLInstanceName = 'INST2'

            PsDscRunAsCredential = $SysAdminAccount
        }
   }
