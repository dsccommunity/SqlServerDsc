<#
.EXAMPLE
    This example shows how to ensure that the database users ReportAdmin, CONTOSO\ReportEditors, CONTOSO\ReportViewers,
    and are present in the AdventureWorks database on instance sqltest.company.local\DSC.
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
        SqlDatabaseUser ReportAdmin_AddUser
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Database             = 'AdventureWorks'
            LoginName            = 'ReportAdmin'
            Name                 = 'ReportAdmin'
            Ensure               = 'Present'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabaseUser ContosoReportEditor_AddUser
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Database             = 'AdventureWorks'
            LoginName            = 'CONTOSO\ReportEditor'
            Name                 = 'CONTOSO\ReportEditor'
            Ensure               = 'Present'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlDatabaseUser ContosoReportViewer_AddUser
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Database             = 'AdventureWorks'
            LoginName            = 'CONTOSO\ReportViewer'
            Name                 = 'CONTOSO\ReportViewer'
            Ensure               = 'Present'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
