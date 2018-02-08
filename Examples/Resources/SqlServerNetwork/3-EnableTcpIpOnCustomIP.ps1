<#
.EXAMPLE
    This example will enable TCP/IP protocol and set the custom static port to 1433
    on the IP address 192.168.1.10.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SystemAdministratorAccount
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerNetwork 'ChangeTcpIpOnDefaultInstance'
        {
            InstanceName         = 'MSSQLSERVER'
            ProtocolName         = 'Tcp'
            IPAddress            = '192.168.1.10'
            IsEnabled            = $true
            TCPDynamicPort       = $false
            TCPPort              = 1433
            PsDscRunAsCredential = $SystemAdministratorAccount
        }
    }
}
