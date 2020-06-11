<#
    .DESCRIPTION
        This example shows how to ensure that the server role named
        AdminSqlforBI is present on instance sqltest.company.local\DSC and logins
        CONTOSO\Mark and CONTOSO\Lucy are not members of this role.
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
        SqlRole 'Drop_ServerRole_AdminSqlforBI'
        {
            Ensure               = 'Present'
            ServerRoleName       = 'AdminSqlforBI'
            MembersToExclude     = 'CONTOSO\Mark', 'CONTOSO\Lucy'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
