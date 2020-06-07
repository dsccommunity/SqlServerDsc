<#
    .DESCRIPTION
        This example will set the TCP/IP address group IPAll to use static ports.

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
        SqlProtocol 'DisableListenAllIPAddresses'
        {
            InstanceName           = 'MSSQLSERVER'
            ProtocolName           = 'TcpIp'
            Enabled                = $true
            ListenOnAllIpAddresses = $false

            PsDscRunAsCredential   = $SystemAdministratorAccount
        }

        SqlProtocolTcpIP 'ChangeIP1'
        {
            InstanceName         = 'MSSQLSERVER'
            IpAddressGroup       = 'IP1'
            Enabled              = $true
            IpAddress            = 'fe80::7894:a6b6:59dd:c8fe%9'
            TcpPort              = '1433,1500,1501'

            PsDscRunAsCredential = $SystemAdministratorAccount
        }
    }
}
