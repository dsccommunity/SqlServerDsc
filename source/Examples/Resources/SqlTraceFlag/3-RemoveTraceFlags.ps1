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
        SqlTraceFlag 'Set_SqlTraceFlagsRemove'
        {
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            RestartService       = $true
            Ensure               = 'Absent'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
