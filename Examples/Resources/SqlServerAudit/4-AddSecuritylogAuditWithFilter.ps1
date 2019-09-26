<#
    .EXAMPLE
        This example shows how to ensure that the windows security eventlog
        audit destination is present on the instance sqltest.company.local\DSC.
        and adds a filter so only users with a name lie administrator are audited
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
            Enabled              = $true
            Filter               = '([server_principal_name] like ''%ADMINISTRATOR'')'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}

