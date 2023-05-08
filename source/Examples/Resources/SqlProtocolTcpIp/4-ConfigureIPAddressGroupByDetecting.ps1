<#
    .DESCRIPTION
        This example will set the TCP/IP address group by detecting the group name. Not required to specify the group name.

        The resource will be run as the account provided in $SystemAdministratorAccount.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SystemAdministratorAccount
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlProtocolTcpIP 'ChangeIP'
        {
            InstanceName         = 'MSSQLSERVER'
            IpAddressGroup       = 'fe80::7894:a6b6:59dd:c8fe%9'
            Enabled              = $true
            IpAddress            = 'fe80::7894:a6b6:59dd:c8fe%9'
            TcpPort              = '1433,1500,1501'

            PsDscRunAsCredential = $SystemAdministratorAccount
        }
    }
}
