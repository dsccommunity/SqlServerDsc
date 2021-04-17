<#
    .DESCRIPTION
        This example shows how to set the minimum and maximum memory
        configuration option, to a percentage of total server memory.
        In this case a value equal to 25 and 75 percent of total memory.
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
            DynamicAlloc         = $false
            MinMemoryPercent     = 25
            MaxMemoryPercent     = 75
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
