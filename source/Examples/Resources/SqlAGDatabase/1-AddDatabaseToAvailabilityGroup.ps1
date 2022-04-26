<#
    .DESCRIPTION
        This example shows how to ensure that the databases 'DB*' and 'AdventureWorks'
        are members of the Availability Group 'TestAG'.

        In the event this is applied to a Failover Cluster Instance (FCI), the
        ProcessOnlyOnActiveNode property will tell the Test-TargetResource function
        to evaluate if any changes are needed if the node is actively hosting the
        SQL Server Instance.
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

    Node $AllNodes.NodeName
    {
        SqlAGDatabase 'AddAGDatabaseMemberships'
        {
            AvailabilityGroupName   = 'TestAG'
            BackupPath              = '\\SQL1\AgInitialize'
            DatabaseName            = 'DB*', 'AdventureWorks'
            InstanceName            = 'MSSQLSERVER'
            ServerName              = $Node.NodeName
            Ensure                  = 'Present'
            ProcessOnlyOnActiveNode = $true

            PsDscRunAsCredential    = $SqlAdministratorCredential
        }
    }
}
