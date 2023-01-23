#region HEADER
# Integration Test Config Template Version: 1.2.0
#endregion

$configFile = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'json')
if (Test-Path -Path $configFile)
{
    <#
        Allows reading the configuration data from a JSON file,
        for real testing scenarios outside of the CI.
    #>
    $ConfigurationData = Get-Content -Path $configFile | ConvertFrom-Json
}
else
{
    $ConfigurationData = @{
        AllNodes = @(
            @{
                NodeName          = 'localhost'

                Admin_UserName    = "$env:COMPUTERNAME\SqlAdmin"
                Admin_Password    = 'P@ssw0rd1'
                SqlLogin_UserName = 'DscAdmin1'
                SqlLogin_Password = 'P@ssw0rd1'

                ServerName        = $env:COMPUTERNAME
                InstanceName      = 'DSCSQLTEST'
                Database1Name     = 'ScriptDatabase3'
                Database2Name     = 'ScriptDatabase4'
                Database3Name     = '$(DatabaseName)'

                GetQuery          = @'
SELECT Name FROM sys.databases WHERE Name = '$(DatabaseName)' FOR JSON AUTO
'@

                TestQuery         = @'
if (select count(name) from sys.databases where name = '$(DatabaseName)') = 0
BEGIN
    RAISERROR ('Did not find database [$(DatabaseName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [$(DatabaseName)]'
END
'@

                SetQuery          = @'
CREATE DATABASE [$(DatabaseName)]
'@

                CertificateFile   = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Runs the SQL query as a Windows User.
#>
Configuration DSC_SqlScriptQuery_RunSqlScriptQueryAsWindowsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScriptQuery 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            GetQuery             = $Node.GetQuery
            TestQuery            = $Node.TestQuery
            SetQuery             = $Node.SetQuery
            QueryTimeout         = 30
            Variable             = @(
                ('DatabaseName={0}' -f $Node.Database1Name)
            )
            Encrypt              = 'Optional'

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_Username, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Runs the SQL query as a SQL login.
#>
Configuration DSC_SqlScriptQuery_RunSqlScriptQueryAsSqlUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScriptQuery 'Integration_Test'
        {
            ServerName   = $Node.ServerName
            InstanceName = $Node.InstanceName

            GetQuery     = $Node.GetQuery
            TestQuery    = $Node.TestQuery
            SetQuery     = $Node.SetQuery
            QueryTimeout = 30
            Variable     = @(
                ('DatabaseName={0}' -f $Node.Database2Name)
            )
            Encrypt      = 'Optional'
            Credential   = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlLogin_Username, (ConvertTo-SecureString -String $Node.SqlLogin_Password -AsPlainText -Force))
        }
    }
}


<#
    .SYNOPSIS
        Runs the SQL query with variables disabled.

    .NOTES
        When the test is run with the DisableVariables parameter the ConfigData variable as it apears in the query will be used as the database name.
        For example if the ConfigData database name is written as $(DatabaseName) in the T-SQL then the name of the database created will be $(DatabaseName).
        It might appear odd but it is a valid database name.

        The SqlScript resource has a similar test for DisableVariables.  The integration test run order has SqlScriptQuery running after SqlScript.
        The SqlScript test is written to remove the database because if the database already existed the SqlScriptQuery test would be invalid as
        the TestQuery would see an existing database and therefore not run the SetQuery.
#>
Configuration DSC_SqlScriptQuery_RunSqlScriptQueryWithVariablesDisabled_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScriptQuery 'Integration_Test'
        {
            ServerName       = $Node.ServerName
            InstanceName     = $Node.InstanceName

            GetQuery         = $Node.GetQuery
            TestQuery        = $Node.TestQuery
            SetQuery         = $Node.SetQuery
            DisableVariables = $true
            QueryTimeout     = 30
            Encrypt          = 'Optional'
            Credential       = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlLogin_Username, (ConvertTo-SecureString -String $Node.SqlLogin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Remove the database created from the DisabledVariables test.

    .NOTES
        At this point the database is no longer needed by any other resources or tests so it will be removed.
#>
Configuration DSC_SqlScriptQuery_RemoveDatabase3_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabase 'RemoveDatabase3'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Name                 = $Node.Database3Name

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}
