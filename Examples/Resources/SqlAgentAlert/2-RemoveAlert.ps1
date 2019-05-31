<#
    .EXAMPLE
        This example shows how to ensure that the SQL Agent Alert
        Sev17 does not exist.
#>

Configuration Example
{

    Import-DscResource -ModuleName SqlServerDsc

    node localhost {
        SqlAgentAlert Remove_Sev17 {
            Ensure               = 'Absent'
            Name                 = 'Sev17'
            ServerName           = 'TestServer'
            InstanceName         = 'MSSQLServer'
        }
    }
}
