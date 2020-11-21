<#
    .DESCRIPTION
        This example shows how to set TraceFlags where all existing
        TraceFlags are overwriten by these
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
        SqlDatabaseEngineTraceFlag 'Set_SqlDatabaseEngineTraceFlagsIncludeExclude'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            TraceFlagsToInclude  = 834, 1117, 1118, 2371, 3226
            TraceFlagsToExclude  = 1112
            RestartService       = $true
            Ensure               = 'Present'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
