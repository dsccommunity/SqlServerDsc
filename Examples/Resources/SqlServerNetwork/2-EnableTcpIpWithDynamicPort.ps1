<#
.EXAMPLE
    This example will enable TCP/IP protocol and set the custom static port to 4509.
    When RestartService is set to $true the resource will also restart the SQL service.
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

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerNetwork 'ChangeTcpIpOnDefaultInstance'
        {
            InstanceName         = 'MSSQLSERVER'
            ProtocolName         = 'Tcp'
            IsEnabled            = $true
            TCPDynamicPort       = $true
            RestartService       = $true
            PsDscRunAsCredential = $SystemAdministratorAccount
        }
    }
}
