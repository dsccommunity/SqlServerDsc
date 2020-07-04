<#
    .DESCRIPTION
        This example shows how to run SQL script with disabled variables.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SqlCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    Node localhost
    {
        SqlScript 'RunWithDisabledVariables'
        {
            ServerName       = 'localhost'
            InstanceName     = 'SQL2016'
            Credential       = $SqlCredential

            SetFilePath      = 'C:\DSCTemp\SQLScripts\Set-RunSQLScript.sql'
            TestFilePath     = 'C:\DSCTemp\SQLScripts\Test-RunSQLScript.sql'
            GetFilePath      = 'C:\DSCTemp\SQLScripts\Get-RunSQLScript.sql'
            DisableVariables = $true
        }
    }
}
