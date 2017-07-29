<#
    .EXAMPLE
        This example will remove connect permission to both an Always On primary replica and an
        Always On secondary replica, and where each replica has a different SQL service account.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName        = '*'
            SqlInstanceName = 'MSSQLSERVER'
        },

        @{
            NodeName = 'SQLNODE01.company.local'
            Role     = 'PrimaryReplica'
        },

        @{
            NodeName = 'SQLNODE02.company.local'
            Role     = 'SecondaryReplica'
        }
    )
}

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SysAdminAccount,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlServiceNode1Credential,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlServiceNode2Credential
    )

    Import-DscResource -ModuleName xSQLServer

    node $AllNodes.Where{$_.Role -eq 'PrimaryReplica' }.NodeName
    {
        xSQLServerEndpointPermission RemoveSQLConfigureEndpointPermissionPrimary
        {
            Ensure               = 'Absent'
            NodeName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceCredentialNode2.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[xSQLServerEndpointPermission]SQLConfigureEndpointPermissionPrimary'
        }

        xSQLServerEndpointPermission RemoveSQLConfigureEndpointPermissionSecondary
        {
            Ensure               = 'Absent'
            NodeName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceCredentialNode2.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[xSQLServerEndpointPermission]SQLConfigureEndpointPermissionSecondary'
        }
    }

    Node $AllNodes.Where{ $_.Role -eq 'SecondaryReplica' }.NodeName
    {
        xSQLServerEndpointPermission RemoveSQLConfigureEndpointPermissionPrimary
        {
            Ensure               = 'Absent'
            NodeName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceCredentialNode2.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[xSQLServerEndpointPermission]SQLConfigureEndpointPermissionPrimary'
        }

        xSQLServerEndpointPermission RemoveSQLConfigureEndpointPermissionSecondary
        {
            Ensure               = 'Absent'
            NodeName             = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceCredentialNode2.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[xSQLServerEndpointPermission]SQLConfigureEndpointPermissionSecondary'
        }
    }
}
