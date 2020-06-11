<#
    .DESCRIPTION
        This example will set the TCP/IP address group IPAll to use dynamic port.

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
            UseTcpDynamicPort      = $true

            PsDscRunAsCredential   = $SystemAdministratorAccount
        }
    }
}
