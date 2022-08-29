<#
    .DESCRIPTION
        This example will add an Availability Group listener with a different
        than the cluster role VCO.

        In the event this is applied to a Failover Cluster Instance (FCI), the
        ProcessOnlyOnActiveNode property will tell the Test-TargetResource function
        to evaluate if any changes are needed if the node is actively hosting the
        SQL Server instance.
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
        SqlAGListener 'AvailabilityGroupListenerWithDifferentNameAsVCO'
        {
            Ensure                  = 'Present'
            ServerName              = 'SQLNODE01.company.local'
            InstanceName            = 'MSSQLSERVER'
            AvailabilityGroup       = 'AvailabilityGroup-01'
            Name                    = 'AG-01'
            IpAddress               = '192.168.0.74/255.255.255.0'
            Port                    = 5302
            ProcessOnlyOnActiveNode = $true

            PsDscRunAsCredential    = $SqlAdministratorCredential
        }
    }
}
