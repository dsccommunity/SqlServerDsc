<#
    .DESCRIPTION
        This example shows how to ensure the SQL Server service
        on TestServer is running under a user account.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ServiceAccountCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    Node localhost
    {
        SqlServiceAccount 'SetServiceAccount_User'
        {
            ServerName     = 'TestServer'
            InstanceName   = 'MSSQLSERVER'
            ServiceType    = 'DatabaseEngine'
            ServiceAccount = $ServiceAccountCredential
            RestartService = $true
        }
    }
}
