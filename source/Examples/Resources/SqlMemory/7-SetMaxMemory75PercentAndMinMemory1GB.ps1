<#
    .DESCRIPTION
        This example shows how to set the maximum memory to 75 percent of total server memory and the minimum memory
        to a fixed value of 1024.
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
            MaxMemoryPercent     = 75
            MinMemory            = 1024
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
