<#
    .DESCRIPTION
        This example shows how to ensure that the Availability Group 'TestAG' exists.

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

        SqlAlwaysOnService 'EnableHADR'
        {
            Ensure               = 'Present'
            InstanceName         = 'MSSQLSERVER'
            ServerName           = $Node.NodeName
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlAG 'AddTestAG'
        {
            Ensure                        = 'Present'
            Name                          = 'TestAG'
            InstanceName                  = 'MSSQLSERVER'
            ServerName                    = $Node.NodeName
            ProcessOnlyOnActiveNode       = $true

            AutomatedBackupPreference     = 'Primary'
            AvailabilityMode              = 'SynchronousCommit'
            BackupPriority                = 50
            ConnectionModeInPrimaryRole   = 'AllowAllConnections'
            ConnectionModeInSecondaryRole = 'AllowNoConnections'
            FailoverMode                  = 'Automatic'
            HealthCheckTimeout            = 15000

            # SQl Server 2016 or later only
            BasicAvailabilityGroup        = $false
            DatabaseHealthTrigger         = $true
            DtcSupportEnabled             = $true

            DependsOn                     = '[SqlAlwaysOnService]EnableHADR', '[SqlEndpoint]HADREndpoint', '[SqlPermission]AddNTServiceClusSvcPermissions'

            PsDscRunAsCredential          = $SqlAdministratorCredential
        }
    }
}
