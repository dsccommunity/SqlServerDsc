<#
    .DESCRIPTION
        This example shows how to ensure that the SQL Agent
        Failsafe Operator 'FailsafeOp' exists with the correct Notification.
#>

Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlAgentFailsafe 'Add_FailsafeOp'
        {
            Ensure             = 'Present'
            Name               = 'FailsafeOp'
            ServerName         = 'TestServer'
            InstanceName       = 'MSSQLServer'
            NotificationMethod = 'NotifyEmail'
        }
    }
}
