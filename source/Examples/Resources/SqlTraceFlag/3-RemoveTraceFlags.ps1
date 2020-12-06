<#
    .DESCRIPTION
        This example shows how to clear all TraceFlags.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlTraceFlag 'Remove_SqlTraceFlags'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            RestartService       = $true
            TraceFlags           = @()

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
