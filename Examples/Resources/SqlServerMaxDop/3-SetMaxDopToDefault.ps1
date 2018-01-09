<#
.EXAMPLE
    This example shows how to set max degree of parallelism server
    configuration option with the default configuration.
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
        SqlServerMaxDop Set_SQLServerMaxDop_ToDefault
        {
            Ensure               = 'Absent'
            ServerName           = 'sqltest.company.local'
            InstanceName         = 'DSC'
            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
