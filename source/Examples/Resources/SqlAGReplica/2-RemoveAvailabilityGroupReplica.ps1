<#
    .DESCRIPTION
        This example shows how to ensure that the Availability Group Replica 'SQL2'
        does not exist in the Availability Group 'TestAG'.
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
        # Add the availability group replica to the availability group
        SqlAGReplica 'RemoveReplica'
        {
            Ensure                     = 'Absent'
            Name                       = $Node.NodeName
            AvailabilityGroupName      = 'TestAG'
            ServerName                 = $Node.NodeName
            InstanceName               = 'MSSQLSERVER'
            PrimaryReplicaServerName   = 'SQL1'
            PrimaryReplicaInstanceName = 'MSSQLSERVER'

            PsDscRunAsCredential       = $SqlAdministratorCredential
        }
    }
}
