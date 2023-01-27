<#
    .DESCRIPTION
        This example shows how to set TraceFlags while keeping all existing
        traceflags. Also one existing traceflag is removed.
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
        SqlTraceFlag 'Set_SqlTraceFlagsIncludeExclude'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            TraceFlagsToInclude  = @(834, 1117, 1118, 2371, 3226)
            TraceFlagsToExclude  = @(1112)
            RestartService      = $true

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
