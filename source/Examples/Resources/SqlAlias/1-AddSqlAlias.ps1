<#
    .DESCRIPTION
        This example shows how to ensure that the SQL Alias
        SQLDSC* exists with Named Pipes or TCP.
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
        SqlAlias 'Add_SqlAlias_TCP'
        {
            Ensure               = 'Present'
            Name                 = 'SQLDSC-TCP'
            ServerName           = 'sqltest.company.local\DSC'
            Protocol             = 'TCP'
            TcpPort              = 1777

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlAlias 'Add_SqlAlias_TCPUseDynamicTcpPort'
        {
            Ensure               = 'Present'
            Name                 = 'SQLDSC-DYN'
            ServerName           = 'sqltest.company.local\DSC'
            Protocol             = 'TCP'
            UseDynamicTcpPort    = $true

            PsDscRunAsCredential = $SqlAdministratorCredential
        }

        SqlAlias 'Add_SqlAlias_NP'
        {
            Ensure               = 'Present'
            Name                 = 'SQLDSC-NP'
            ServerName           = '\\sqlnode\PIPE\sql\query'
            Protocol             = 'NP'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
