<#
    .DESCRIPTION
        This example shows how to ensure that the Availability Group Replica 'SQL2'
        exists in the Availability Group 'TestAG'.

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
        # Adding the required service account to allow the cluster to log into SQL
        SqlLogin 'AddNTServiceClusSvc'
        {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            ServerName           = $Node.NodeName
            InstanceName         = 'MSSQLSERVER'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        # Add the required permissions to the cluster service login
        SqlPermission 'AddNTServiceClusSvcPermissions'
        {
            DependsOn    = '[SqlLogin]AddNTServiceClusSvc'
            ServerName   = $Node.NodeName
            InstanceName = 'MSSQLSERVER'
            Name         = 'NT SERVICE\ClusSvc'
            Credential   = $SqlAdministratorCredential
            Permission   = @(
                ServerPermission
                {
                    State      = 'Grant'
                    Permission = @('AlterAnyAvailabilityGroup', 'ViewServerState')
                }
                ServerPermission
                {
                    State      = 'GrantWithGrant'
                    Permission = @()
                }
                ServerPermission
                {
                    State      = 'Deny'
                    Permission = @()
                }
            )
        }

        # Create a DatabaseMirroring endpoint
        SqlEndpoint 'HADREndpoint'
        {
            EndPointName         = 'HADR'
            EndpointType         = 'DatabaseMirroring'
            Ensure               = 'Present'
            Port                 = 5022
            ServerName           = $Node.NodeName
            InstanceName         = 'MSSQLSERVER'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlAlwaysOnService EnableHADR
        {
            Ensure               = 'Present'
            InstanceName         = 'MSSQLSERVER'
            ServerName           = $Node.NodeName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        # Add the availability group replica to the availability group
        SqlAGReplica 'AddReplica'
        {
            Ensure                     = 'Present'
            Name                       = $Node.NodeName
            AvailabilityGroupName      = 'TestAG'
            ServerName                 = $Node.NodeName
            InstanceName               = 'MSSQLSERVER'
            PrimaryReplicaServerName   = 'SQL1'
            PrimaryReplicaInstanceName = 'MSSQLSERVER'
            ProcessOnlyOnActiveNode    = $true

            DependsOn                  = '[SqlAlwaysOnService]EnableHADR'

            PsDscRunAsCredential       = $SqlAdministratorCredential
        }
    }
}
