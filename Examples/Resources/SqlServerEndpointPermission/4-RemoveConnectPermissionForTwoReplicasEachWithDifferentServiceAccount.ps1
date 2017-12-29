<#
    .EXAMPLE
        This example will remove connect permission to both an Always On primary replica and an
        Always On secondary replica, and where each replica has a different SQL service account.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = '*'
            SqlInstanceName             = 'MSSQLSERVER'

            <#
                NOTE! THIS IS NOT RECOMMENDED IN PRODUCTION.
                This is added so that AppVeyor automatic tests can pass, otherwise
                the tests will fail on passwords being in plain text and not being
                encrypted. Because it is not possible to have a certificate in
                AppVeyor to encrypt the passwords we need to add parameter
                'PSDscAllowPlainTextPassword'.
                NOTE! THIS IS NOT RECOMMENDED IN PRODUCTION.
            #>
            PSDscAllowPlainTextPassword = $true
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
        $SqlAdministratorCredential,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlServiceNode1Credential,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SqlServiceNode2Credential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node $AllNodes.Where{$_.Role -eq 'PrimaryReplica' }.NodeName
    {
        SqlServerEndpointPermission RemoveSQLConfigureEndpointPermissionPrimary
        {
            Ensure               = 'Absent'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceNode1Credential.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[SqlServerEndpointPermission]SQLConfigureEndpointPermissionPrimary'
        }

        SqlServerEndpointPermission RemoveSQLConfigureEndpointPermissionSecondary
        {
            Ensure               = 'Absent'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceNode2Credential.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[SqlServerEndpointPermission]SQLConfigureEndpointPermissionSecondary'
        }
    }

    Node $AllNodes.Where{ $_.Role -eq 'SecondaryReplica' }.NodeName
    {
        SqlServerEndpointPermission RemoveSQLConfigureEndpointPermissionPrimary
        {
            Ensure               = 'Absent'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceNode1Credential.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[SqlServerEndpointPermission]SQLConfigureEndpointPermissionPrimary'
        }

        SqlServerEndpointPermission RemoveSQLConfigureEndpointPermissionSecondary
        {
            Ensure               = 'Absent'
            ServerName           = $Node.NodeName
            InstanceName         = $Node.SqlInstanceName
            Name                 = 'DefaultMirrorEndpoint'
            Principal            = $SqlServiceNode2Credential.UserName
            Permission           = 'CONNECT'

            PsDscRunAsCredential = $SqlAdministratorCredential

            DependsOn            = '[SqlServerEndpointPermission]SQLConfigureEndpointPermissionSecondary'
        }
    }
}
