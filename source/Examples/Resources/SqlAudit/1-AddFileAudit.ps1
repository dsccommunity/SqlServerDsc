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
        SqlAudit FileAudit_Server
        {
            Ensure               = 'Present'
            ServerName           = 'SQL2019-01'
            InstanceName         = 'INST01'
            Name                 = 'FileAudit'
            Path                 = 'C:\Temp\audit'
            MaximumFileSize      = 10
            MaximumFileSizeUnit  = 'Megabyte'
            MaximumRolloverFiles = 11
            Enabled              = $true
            Credential           = $SqlAdministratorCredential
        }
    }
}
