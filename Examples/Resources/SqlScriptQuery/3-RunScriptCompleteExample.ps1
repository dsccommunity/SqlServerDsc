<#
.EXAMPLE
    This example uses the Configuration Data to pass the Query Strings fo SqlScriptQuery Resource.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName     = 'localhost'
            ServerName   = $env:COMPUTERNAME
            InstanceName = 'DSCTEST'
            DatabaseName = 'ScriptDatabase1'

            GetSqlQuery  = @'
SELECT Name FROM sys.databases WHERE Name = '$(DatabaseName)' FOR JSON AUTO
'@

            TestSqlQuery = @'
if (select count(name) from sys.databases where name = '$(DatabaseName)') = 0
BEGIN
    RAISERROR ('Did not find database [$(DatabaseName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [$(DatabaseName)]'
END
'@

            SetSqlQuery = @'
CREATE DATABASE [$(DatabaseName)]
'@

            <#
                NOTE! THIS IS NOT RECOMMENDED IN PRODUCTION.
                This is added so that AppVeyor automatic tests can pass, otherwise
                the tests will fail on passwords being in plain text and not being
                encrypted. Because it is not possible to have a certificate in
                AppVeyor to encrypt the passwords we need to add the parameter
                'PSDscAllowPlainTextPassword'.
                NOTE! THIS IS NOT RECOMMENDED IN PRODUCTION.
            #>
            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlAdministratorCredential
    )

    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost {

        SqlScriptQuery 'Integration_Test'
        {
            ServerInstance       = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName

            GetQuery          = $Node.GetSqlScriptQuery
            TestQuery         = $Node.TestSqlScriptQuery
            SetQuery          = $Node.SetSqlScriptQuery
            Variable             = @(
                ('DatabaseName={0}' -f $Node.DatabaseName)
            )
            QueryTimeout         = 30

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
