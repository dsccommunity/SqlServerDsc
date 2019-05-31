<#
    .EXAMPLE
        This example shows how to ensure that the SQL Agent Alert
        Sev17 exists with the correct severity level.
#>

Configuration Example
{

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlAgentOperator Add_Sev17 {
            Ensure               = 'Present'
            Name                 = 'Sev17'
            ServerName           = 'TestServer'
            InstanceName         = 'MSSQLServer'
            Severity             = '17'
        }
    }
}
