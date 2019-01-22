<#
.EXAMPLE
    This example shows how to configure a SQL Server instance as the publisher.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerReplication publisher
        {
            Ensure               = 'Present'
            InstanceName         = 'PUBLISHER'
            AdminLinkCredentials = $SqlAdministratorCredential
            DistributorMode      = 'Remote'
            RemoteDistributor    = 'distsqlsrv.company.local'
            WorkingDirectory     = 'C:\Temp'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
