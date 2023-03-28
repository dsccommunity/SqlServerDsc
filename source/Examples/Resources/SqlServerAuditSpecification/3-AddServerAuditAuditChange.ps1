<#
    .EXAMPLE
        This example shows how to ensure that an audit destination
        is absent on the instance sqltest.company.local\DSC.
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
        SqlAudit SecurityLogAudit_Server
        {
            Ensure                    = 'Present'
            ServerName                = 'sqltest.company.local'
            InstanceName              = 'DSC'
            Name                      = 'SecLogAudit'
            LogType                   = 'SecurityLog'
            Enabled                   = $true
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }

        SqlServerAuditSpecification 'ServerAuditSpecification_AuditAudit'
        {
            Ensure                    = 'Present'
            ServerName                = 'sqltest.company.local'
            InstanceName              = 'DSC'
            Name                      = 'AuditAudit'
            AuditName                 = 'SecLogAudit'
            Enabled                   = $true
            AuditChangeGroup          = $true
            TraceChangeGroup          = $true
            DependsOn                 = "[SqlAudit]SecurityLogAudit_Server"
            PsDscRunAsCredential      = $SqlAdministratorCredential
        }
    }
}
