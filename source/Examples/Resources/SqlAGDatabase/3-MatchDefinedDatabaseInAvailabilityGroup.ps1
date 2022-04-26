<#
    .DESCRIPTION
        This example shows how to ensure that the databases 'DB*' and 'AdventureWorks'
        are the only members of the Availability Group 'TestAG'.
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
        SqlAGDatabase 'TestAGDatabaseMemberships'
        {
            AvailabilityGroupName = 'TestAG'
            BackupPath            = '\\SQL1\AgInitialize'
            DatabaseName          = 'DB*', 'AdventureWorks'
            InstanceName          = 'MSSQLSERVER'
            ServerName            = $Node.NodeName
            Ensure                = 'Present'
            Force                 = $true

            PsDscRunAsCredential  = $SqlAdministratorCredential
        }
    }
}
