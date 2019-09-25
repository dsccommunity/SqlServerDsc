<#
    .EXAMPLE
        This example shows how to ensure that the windows security eventlog
        audit destination is present on the instance sqltest.company.local\DSC.
        The server should shutdown when logging is not posible.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlServerAudit SecuritylogAudit_Server
        {
            Ensure               = 'Present'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            Name                 = 'SecLogAudit'
            DestinationType      = 'SecurityLog'
            OnFailure            = 'SHUTDOWN'
            Enabled              = $true
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

