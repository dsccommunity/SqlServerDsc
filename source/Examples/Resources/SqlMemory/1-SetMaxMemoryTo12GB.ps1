<#
    .DESCRIPTION
        This example shows how to set the minimum and maximum memory
        configuration option with the value equal to 1024 and 12288.
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
        SqlMemory 'Set_SQLServerMaxMemory_To12GB'
        {
            Ensure               = 'Present'
            DynamicAlloc         = $false
            MinMemory            = 1024
            MaxMemory            = 12288
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
