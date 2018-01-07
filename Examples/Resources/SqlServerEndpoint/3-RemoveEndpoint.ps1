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
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerEndpoint SQLConfigureEndpoint-Instance1
        {
            Ensure               = 'Absent'

            EndpointName         = 'HADR'
            InstanceName      = 'INST1'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlServerEndpoint SQLConfigureEndpoint-Instance2
        {
            Ensure               = 'Absent'

            EndpointName         = 'HADR'
            InstanceName      = 'INST2'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
