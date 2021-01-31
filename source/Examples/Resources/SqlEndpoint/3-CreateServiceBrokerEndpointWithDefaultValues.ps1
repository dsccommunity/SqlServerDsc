<#
    .DESCRIPTION
        This example will add a Service Broker endpoint, to a instance, complete with MessageForwarding

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
        SqlEndpoint 'ServiceBroker'
        {
            Ensure                     = 'Present'

            EndpointName               = 'SSBR'
            EndpointType               = 'ServiceBroker'
            Port                       = 5023
            IpAddress                  = '192.168.0.20'
            Owner                      = 'sa'
            State                      = 'Started'

            ServerName                 = 'server1.company.local'
            InstanceName               = 'INST1'

            IsMessageForwardingEnabled = $true
            MessageForwardingSize      = 2

            PsDscRunAsCredential       = $SqlAdministratorCredential
        }
    }
}
