<#
    .DESCRIPTION
        This example uses the Configuration Data to pass the Query Strings fo SqlScriptQuery Resource.
#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlScriptQuery 'CreateDatabase_ScriptDatabase1'
        {
            ServerName           = $env:COMPUTERNAME
            InstanceName         = 'DSCTEST'

            GetQuery             = @'
SELECT Name FROM sys.databases WHERE Name = '$(DatabaseName)' FOR JSON AUTO
'@

            TestQuery            = @'
if (select count(name) from sys.databases where name = '$(DatabaseName)') = 0
BEGIN
    RAISERROR ('Did not find database [$(DatabaseName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [$(DatabaseName)]'
END
'@

            SetQuery             = @'
CREATE DATABASE [$(DatabaseName)]
'@

            Variable             = @(
                ('DatabaseName={0}' -f 'ScriptDatabase1')
            )

            QueryTimeout         = 30

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
