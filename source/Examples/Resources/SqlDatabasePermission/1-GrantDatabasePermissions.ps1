<#
    .DESCRIPTION
        This example shows how to ensure that the user account CONTOSO\SQLAdmin
        has "Connect" and "Update" SQL Permissions for database "AdventureWorks".
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
        SqlDatabasePermission 'Grant_SqlDatabasePermissions_SQLAdmin_Db01'
        {
            Ensure       = 'Present'
            Name         = 'CONTOSO\SQLAdmin'
            DatabaseName = 'AdventureWorks'
            Permission   = [CimInstance[]] @(
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName DatabasePermission -Property @{
                        State      = 'Grant'
                        Permission = @('Connect', 'Update')
                    }
                )
            )
            ServerName      = 'sqltest.company.local'
            InstanceName    = 'DSC'
            Credential      = $SqlAdministratorCredential
        }

        SqlDatabasePermission 'Grant_SqlDatabasePermissions_SQLUser_Db01'
        {
            Ensure          = 'Present'
            Name            = 'CONTOSO\SQLUser'
            DatabaseName    = 'AdventureWorks'
            Permission   = [CimInstance[]] @(
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName DatabasePermission -Property @{
                        State      = 'Grant'
                        Permission = @('Connect', 'Update')
                    }
                )
            )
            ServerName      = 'sqltest.company.local'
            InstanceName    = 'DSC'
            Credential      = $SqlAdministratorCredential
        }

        SqlDatabasePermission 'Grant_SqlDatabasePermissions_SQLAdmin_Db02'
        {
            Ensure          = 'Present'
            Name            = 'CONTOSO\SQLAdmin'
            DatabaseName    = 'AdventureWorksLT'
            Permission   = [CimInstance[]] @(
                (
                    New-CimInstance -ClientOnly -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName DatabasePermission -Property @{
                        State      = 'Grant'
                        Permission = @('Connect', 'Update')
                    }
                )
            )
            ServerName      = 'sqltest.company.local'
            InstanceName    = 'DSC'
            Credential      = $SqlAdministratorCredential
        }
    }
}
