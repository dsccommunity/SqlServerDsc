<#
    .DESCRIPTION
        This example shows how to ensure that the Availability Group 'TestAG' exists.
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

        # Ensure the HADR option is enabled for the instance
        SqlAlwaysOnService 'EnableHADR'
        {
            Ensure               = 'Present'
            InstanceName         = 'MSSQLSERVER'
            ServerName           = $Node.NodeName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        # Create the availability group on the instance tagged as the primary replica
        SqlAG 'AddTestAG'
        {
            Ensure               = 'Present'
            Name                 = 'TestAG'
            InstanceName         = 'MSSQLSERVER'
            ServerName           = $Node.NodeName

            DependsOn            = '[SqlAlwaysOnService]EnableHADR', '[SqlEndpoint]HADREndpoint', '[SqlPermission]AddNTServiceClusSvcPermissions'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
