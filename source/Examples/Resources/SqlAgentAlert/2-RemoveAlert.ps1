<#
    .DESCRIPTION
        This example shows how to ensure that the SQL Agent Alert
        Sev17 does not exist, or that the SQL Agent Alert
        Msg825 does not exist.
#>
Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlAgentAlert 'Remove_Sev17'
        {
            Ensure       = 'Absent'
            Name         = 'Sev17'
            ServerName   = 'TestServer'
            InstanceName = 'MSSQLServer'
        }

        SqlAgentAlert 'Remove_Msg825'
        {
            Ensure       = 'Absent'
            Name         = 'Msg825'
            ServerName   = 'TestServer'
            InstanceName = 'MSSQLServer'
        }
    }
}
