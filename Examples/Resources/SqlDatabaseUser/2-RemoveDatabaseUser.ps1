<#
.EXAMPLE
    This example shows how to ensure that the database user CONTOSO\ReportViewers is not present in the AdventureWorks
    database on instance sqltest.company.local\DSC.
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
        SqlDatabaseUser ContosoReportViewer_RemoveUser
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Database             = 'AdventureWorks'
            LoginName            = 'CONTOSO\ReportViewer'
            Name                 = 'CONTOSO\ReportViewer'
            Ensure               = 'Absent'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
