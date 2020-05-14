<#
    .DESCRIPTION
        These two example shows how to run SQL script using Windows Authentication.
        First example shows how the resource is run as account SYSTEM. And the second
        example shows how the resource is run with a user account.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $WindowsCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    Node localhost
    {
        SqlScriptQuery 'RunAsSYSTEM'
        {
            ServerName   = 'localhost'
            InstanceName = 'SQL2016'

            SetQuery     = 'Set Query as System'
            TestQuery    = 'Test query as System'
            GetQuery     = 'Get query as System'
            Variable     = @('FilePath=C:\temp\log\AuditFiles')
        }

        SqlScriptQuery 'RunAsUser'
        {
            ServerName           = 'localhost'
            InstanceName         = 'SQL2016'

            SetQuery             = 'Set query as User'
            TestQuery            = 'Test query as User'
            GetQuery             = 'Get query as User'
            Variable             = @('FilePath=C:\temp\log\AuditFiles')

            PsDscRunAsCredential = $WindowsCredential
        }

        SqlScriptQuery 'RunAsUser-With30SecondTimeout'
        {
            ServerName           = 'localhost'
            InstanceName         = 'SQL2016'

            SetQuery             = 'Set query with query timeout'
            TestQuery            = 'Test query with query timeout'
            GetQuery             = 'Get query with query timeout'
            QueryTimeout         = 30
            Variable             = @('FilePath=C:\temp\log\AuditFiles')

            PsDscRunAsCredential = $WindowsCredential
        }
    }
}
