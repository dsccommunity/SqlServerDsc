<#
    .DESCRIPTION
        This example shows how to ensure that the SQL Agent Alert
        Sev17 exists with the correct severity level, and SQL
        Agent Alert Msg825 with the correct message id.
#>

Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlAgentAlert 'Add_Sev17'
        {
            Ensure       = 'Present'
            Name         = 'Sev17'
            ServerName   = 'TestServer'
            InstanceName = 'MSSQLServer'
            Severity     = '17'
        }

        SqlAgentAlert 'Add_Msg825'
        {
            Ensure       = 'Present'
            Name         = 'Msg825'
            ServerName   = 'TestServer'
            InstanceName = 'MSSQLServer'
            MessageId    = '825'
        }
    }
}
