<#
    .DESCRIPTION
        This example shows how to run SQL script using SQL Authentication.
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
        SqlScriptQuery 'RunAsSqlCredential'
        {
            ServerName   = 'localhost'
            InstanceName = 'SQL2016'

            Credential   = $SqlCredential

            SetQuery     = 'Set query'
            TestQuery    = 'Test query'
            GetQuery     = 'Get query'
            Variable     = @('FilePath=C:\temp\log\AuditFiles')
        }
    }
}
