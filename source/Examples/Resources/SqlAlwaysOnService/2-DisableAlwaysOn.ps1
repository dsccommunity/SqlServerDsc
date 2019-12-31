<#
    .DESCRIPTION
        This example shows how to disable SQL Server Always On high availability and
        disaster recovery (HADR).
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
        SqlAlwaysOnService 'DisableAlwaysOn'
        {
            Ensure               = 'Absent'
            ServerName           = 'SP23-VM-SQL1'
            InstanceName         = 'MSSQLSERVER'
            RestartTimeout       = 120

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
