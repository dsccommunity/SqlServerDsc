<#
    .DESCRIPTION
        This example will add an Availability Group listener with the same name
        as the cluster role VCO.

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
        SqlAGListener 'AvailabilityGroupListenerWithSameNameAsVCO'
        {
            Ensure                  = 'Present'
            ServerName              = 'SQLNODE01.company.local'
            InstanceName            = 'MSSQLSERVER'
            AvailabilityGroup       = 'AG-01'
            Name                    = 'AG-01'
            IpAddress               = '192.168.0.73/255.255.255.0'
            Port                    = 5301
            ProcessOnlyOnActiveNode = $true

            PsDscRunAsCredential    = $SqlAdministratorCredential
        }
    }
}
