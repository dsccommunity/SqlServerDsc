<#
    .DESCRIPTION
        This example shows how to set the minimum memory, to 25 percent of total server memory and the maximum memory
        configuration option with the automatic configuration.
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
        SqlMemory 'Set_SQLServerMemoryByPercent'
        {
            Ensure               = 'Present'
            DynamicAlloc         = $true
            MinMemoryPercent     = 25
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
