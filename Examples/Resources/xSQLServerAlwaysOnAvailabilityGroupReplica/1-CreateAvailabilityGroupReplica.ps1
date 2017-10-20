<#
.EXAMPLE
    This example shows how to ensure that the Availability Group Replica 'SQL2' exists in the Availability Group 'TestAG'.

    In the event this is applied to a Failover Cluster Instance (FCI), the
    ProcessOnlyOnActiveNode property will tell the Test-TargetResource function
    to evaluate if any changes are needed if the node is actively hosting the
    SQL Server Instance.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                = '*'
            SQLInstanceName         = 'MSSQLSERVER'
            AvailabilityGroupName   = 'TestAG'
            ProcessOnlyOnActiveNode = $true

        },

        @{
            NodeName = 'SQL1'
            Role     = 'PrimaryReplica'
        },

        @{
            NodeName = 'SQL2'
            Role     = 'SecondaryReplica'
        }
    )
}

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    Node $AllNodes.NodeName {
        # Adding the required service account to allow the cluster to log into SQL
        xSQLServerLogin AddNTServiceClusSvc
        {
            Ensure               = 'Present'
            Name                 = 'NT SERVICE\ClusSvc'
            LoginType            = 'WindowsUser'
            SQLServer            = $Node.NodeName
            SQLInstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Add the required permissions to the cluster service login
        xSQLServerPermission AddNTServiceClusSvcPermissions
        {
            DependsOn            = '[xSQLServerLogin]AddNTServiceClusSvc'
            Ensure               = 'Present'
            NodeName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Principal            = 'NT SERVICE\ClusSvc'
            Permission           = 'AlterAnyAvailabilityGroup', 'ViewServerState'
            PsDscRunAsCredential = $SysAdminAccount
        }

        # Create a DatabaseMirroring endpoint
        xSQLServerEndpoint HADREndpoint
        {
            EndPointName         = 'HADR'
            Ensure               = 'Present'
            Port                 = 5022
            SQLServer            = $Node.NodeName
            SQLInstanceName      = $Node.SQLInstanceName
            PsDscRunAsCredential = $SysAdminAccount
        }

        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            xSQLServerAlwaysOnAvailabilityGroup AddTestAG
            {
                Ensure               = 'Present'
                Name                 = $Node.AvailabilityGroupName
                SQLInstanceName      = $Node.SQLInstanceName
                SQLServer            = $Node.NodeName
                DependsOn            = '[xSQLServerEndpoint]HADREndpoint', '[xSQLServerPermission]AddNTServiceClusSvcPermissions'
                PsDscRunAsCredential = $SysAdminAccount
            }
        }

        if ( $Node.Role -eq 'SecondaryReplica' )
        {
            # Add the availability group replica to the availability group
            xSQLServerAlwaysOnAvailabilityGroupReplica AddReplica
            {
                Ensure                        = 'Present'
                Name                          = $Node.NodeName
                AvailabilityGroupName         = $Node.AvailabilityGroupName
                SQLServer                     = $Node.NodeName
                SQLInstanceName               = $Node.SQLInstanceName
                PrimaryReplicaSQLServer       = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).NodeName
                PrimaryReplicaSQLInstanceName = ( $AllNodes | Where-Object { $_.Role -eq 'PrimaryReplica' } ).SQLInstanceName
                ProcessOnlyOnActiveNode       = $Node.ProcessOnlyOnActiveNode
            }
        }
    }
}
