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
        SqlProtocolTcpIP 'ChangeIPAll'
        {
            InstanceName           = 'MSSQLSERVER'
            IpAddressGroup         = 'IPAll'
            TcpPort                = '1433,1500,1501'

            PsDscRunAsCredential   = $SystemAdministratorAccount
        }
    }
}
