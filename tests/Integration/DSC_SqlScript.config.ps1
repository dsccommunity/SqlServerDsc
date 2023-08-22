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
                SqlLogin_UserName = "DscAdmin1"
                SqlLogin_Password = 'P@ssw0rd1'

                ServerName        = $env:COMPUTERNAME
                InstanceName      = 'DSCSQLTEST'

                Database1Name     = 'ScriptDatabase1'
                Database2Name     = 'ScriptDatabase2'
                Database3Name     = '$(DatabaseName)'

                GetSqlScriptPath  = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
                SetSqlScriptPath  = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
                TestSqlScriptPath = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())

                GetSqlScript      = @'
SELECT Name FROM sys.databases WHERE Name = '$(DatabaseName)' FOR JSON AUTO
'@

                TestSqlScript     = @'
if (select count(name) from sys.databases where name = '$(DatabaseName)') = 0
BEGIN
    RAISERROR ('Did not find database [$(DatabaseName)]', 16, 1)
END
ELSE
BEGIN
    PRINT 'Found database [$(DatabaseName)]'
END
'@

                SetSqlScript      = @'
CREATE DATABASE [$(DatabaseName)]
'@

                CertificateFile   = $env:DscPublicCertificatePath
            }
        )
    }
}

<#
    .SYNOPSIS
        Dependencies for testing the SqlScript resource.
        - Creates the script files, Get, Test, and Set.
        - Creates the SqlLogin and adds it to db_creator role.
#>
Configuration DSC_SqlScript_CreateDependencies_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        xScript 'CreateFile_GetSqlScript'
        {
            SetScript  = {
                $Using:Node.GetSqlScript | Out-File -FilePath $Using:Node.GetSqlScriptPath -Encoding ascii -NoClobber -Force
            }

            TestScript = {
                <#
                    This takes the string of the $GetScript parameter and creates
                    a new script block (during runtime in the resource) and then
                    runs that script block.
                #>
                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                return $getScriptResult.Result -eq $Using:Node.GetSqlScript
            }

            GetScript  = {
                $fileContent = $null

                if (Test-Path -Path $Using:Node.GetSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.GetSqlScriptPath -Raw
                }

                return @{
                    Result = $fileContent
                }
            }
        }

        xScript 'CreateFile_TestSqlScript'
        {
            SetScript  = {
                $Using:Node.TestSqlScript | Out-File -FilePath $Using:Node.TestSqlScriptPath -Encoding ascii -NoClobber -Force
            }

            TestScript = {
                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                return $getScriptResult.Result -eq $Using:Node.TestSqlScript
            }

            GetScript  = {
                $fileContent = $null

                if (Test-Path -Path $Using:Node.TestSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.TestSqlScriptPath -Raw
                }

                return @{
                    Result = $fileContent
                }
            }
        }

        xScript 'CreateFile_SetSqlScript'
        {
            SetScript  = {
                $Using:Node.SetSqlScript | Out-File -FilePath $Using:Node.SetSqlScriptPath -Encoding ascii -NoClobber -Force
            }

            TestScript = {
                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                return $getScriptResult.Result -eq $Using:Node.SetSqlScript
            }

            GetScript  = {
                $fileContent = $null

                if (Test-Path -Path $Using:Node.SetSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.SetSqlScriptPath -Raw
                }

                return @{
                    Result = $fileContent
                }
            }
        }

        SqlLogin ('Create{0}' -f $Node.SqlLogin_UserName)
        {
            Ensure                         = 'Present'
            Name                           = $Node.SqlLogin_UserName
            LoginType                      = 'SqlLogin'
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $true
            LoginPasswordPolicyEnforced    = $true

            LoginCredential                = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlLogin_UserName, (ConvertTo-SecureString -String $Node.SqlLogin_Password -AsPlainText -Force))

            ServerName                     = $Node.ServerName
            InstanceName                   = $Node.InstanceName

            PsDscRunAsCredential           = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }

        SqlRole ('Add{0}ToDbCreator' -f $Node.SqlLogin_UserName)
        {
            Ensure               = 'Present'
            ServerRoleName       = 'dbcreator'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Members              = @(
                $Node.SqlLogin_UserName
            )

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))

            DependsOn            = @(
                ('[SqlLogin]Create{0}' -f $Node.SqlLogin_UserName)
            )
        }
    }
}

<#
    .SYNOPSIS
        Runs the SQL script as a Windows User.
#>
Configuration DSC_SqlScript_RunSqlScriptAsWindowsUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScript 'Integration_Test'
        {
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            GetFilePath          = $Node.GetSqlScriptPath
            TestFilePath         = $Node.TestSqlScriptPath
            SetFilePath          = $Node.SetSqlScriptPath
            Variable             = @(
                ('DatabaseName={0}' -f $Node.Database1Name)
            )
            QueryTimeout         = 30
            Encrypt              = 'Optional'

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Runs the SQL script as a SQL login.
#>
Configuration DSC_SqlScript_RunSqlScriptAsSqlUser_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScript 'Integration_Test'
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.InstanceName

            GetFilePath    = $Node.GetSqlScriptPath
            TestFilePath   = $Node.TestSqlScriptPath
            SetFilePath    = $Node.SetSqlScriptPath
            Variable       = @(
                ('DatabaseName={0}' -f $Node.Database2Name)
            )
            QueryTimeout   = 30
            Encrypt        = 'Optional'
            Credential     = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlLogin_UserName, (ConvertTo-SecureString -String $Node.SqlLogin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Runs the SQL script with variables disabled.

    .NOTES
        When the test is run with the DisableVariables parameter the ConfigData variable as it apears in the query will be used as the database name.
        For example if the ConfigData database name is written as $(DatabaseName) in the T-SQL then the name of the database created will be $(DatabaseName).
        It might appear odd but it is a valid name.
#>
Configuration DSC_SqlScript_RunSqlScriptWithVariablesDisabled_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlScript 'Integration_Test'
        {
            ServerName     = $Node.ServerName
            InstanceName   = $Node.InstanceName

            GetFilePath       = $Node.GetSqlScriptPath
            TestFilePath      = $Node.TestSqlScriptPath
            SetFilePath       = $Node.SetSqlScriptPath
            DisableVariables  = $true
            QueryTimeout      = 30
            Encrypt           = 'Optional'
            Credential        = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.SqlLogin_UserName, (ConvertTo-SecureString -String $Node.SqlLogin_Password -AsPlainText -Force))
        }
    }
}

<#
    .SYNOPSIS
        Remove the database created from the DisabledVariables test.

    .NOTES
        The current integration test run order has SqlScriptQuery running after SqlScript. Since both the SqlScript and SqlScriptQuery
        resources use the same database name variable in their ConfigData queries it is imperative this database is absent when
        the SqlScriptQuery resource runs its DisableVariables integration test.
#>
Configuration DSC_SqlScript_RemoveDatabase3_Config
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
