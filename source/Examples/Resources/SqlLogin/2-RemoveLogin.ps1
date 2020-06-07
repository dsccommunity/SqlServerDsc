<#
    .DESCRIPTION
        This example shows how to remove the Windows user 'CONTOSO\WindowsUser',
        Windows group 'CONTOSO\WindowsGroup', and the SQL Login 'SqlLogin'.
#>

Configuration Example
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlLogin 'Remove_WindowsUser'
        {
            Ensure       = 'Absent'
            Name         = 'CONTOSO\WindowsUser'
            LoginType    = 'WindowsUser'
            ServerName   = 'TestServer.company.local'
            InstanceName = 'DSC'
        }

        SqlLogin 'Remove_WindowsGroup'
        {
            Ensure       = 'Absent'
            Name         = 'CONTOSO\WindowsGroup'
            LoginType    = 'WindowsGroup'
            ServerName   = 'TestServer.company.local'
            InstanceName = 'DSC'
        }

        SqlLogin 'Remove_SqlLogin'
        {
            Ensure       = 'Absent'
            Name         = 'SqlLogin'
            LoginType    = 'SqlLogin'
            ServerName   = 'TestServer.company.local'
            InstanceName = 'DSC'
        }
    }
}
