<#
    .DESCRIPTION
        This example shows how to ensure that the Availability Group 'TestAG' does not exist.
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
        # Create the availability group on the instance tagged as the primary replica
        SqlAG 'RemoveTestAG'
        {
            Ensure               = 'Absent'
            Name                 = 'TestAG'
            InstanceName         = 'MSSQLSERVER'
            ServerName           = $Node.NodeName

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
