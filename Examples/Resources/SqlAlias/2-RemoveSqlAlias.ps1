<#
.EXAMPLE
    This example shows how to ensure that the SQL Alias
    SQLDSC* does not exist with Named Pipes or TCP.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlAlias Remove_SqlAlias_TCP
        {
            Ensure               = 'Absent'
            Name                 = 'SQLDSC-TCP'
            ServerName           = 'sqltest.company.local\DSC'
            Protocol             = 'TCP'
            TcpPort              = 1777
            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlAlias Remove_SqlAlias_NP
        {
            Ensure               = 'Absent'
            Name                 = 'SQLDSC-NP'
            ServerName           = '\\sqlnode\PIPE\sql\query'
            Protocol             = 'NP'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
