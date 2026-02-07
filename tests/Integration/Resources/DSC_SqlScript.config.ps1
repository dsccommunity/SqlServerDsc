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
                Database4Name     = 'ScriptDatabase4'

                GetSqlScriptPath  = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
                SetSqlScriptPath  = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
                TestSqlScriptPath = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())

                GetSqlScriptPath2  = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
                SetSqlScriptPath2  = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())
                TestSqlScriptPath2 = Join-Path -Path $env:SystemDrive -ChildPath ([System.IO.Path]::GetRandomFileName())

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
                Write-Verbose -Message ('Creating Get SQL script file at path: {0}' -f $Using:Node.GetSqlScriptPath) -Verbose

                $Using:Node.GetSqlScript | Out-File -FilePath $Using:Node.GetSqlScriptPath -Encoding ascii -NoClobber -Force

                Write-Verbose -Message 'Get SQL script file created successfully' -Verbose
            }

            TestScript = {
                Write-Verbose -Message 'Testing if Get SQL script file exists and matches expected content' -Verbose

                <#
                    This takes the string of the $GetScript parameter and creates
                    a new script block (during runtime in the resource) and then
                    runs that script block.
                #>
                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                $testResult = $getScriptResult.Result -eq $Using:Node.GetSqlScript

                Write-Verbose -Message ('Completed testing Get SQL script file. Returning: {0}' -f $testResult) -Verbose

                return $testResult
            }

            GetScript  = {
                Write-Verbose -Message ('Reading Get SQL script file content from path: {0}' -f $Using:Node.GetSqlScriptPath) -Verbose

                $fileContent = $null

                if (Test-Path -Path $Using:Node.GetSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.GetSqlScriptPath -Raw
                }

                $returnValue = @{
                    Result = $fileContent
                }

                Write-Verbose -Message ('Completed reading Get SQL script file content. Returning: {0}' -f ($returnValue | Out-String)) -Verbose

                return $returnValue
            }
        }

        xScript 'CreateFile_TestSqlScript'
        {
            SetScript  = {
                Write-Verbose -Message ('Creating Test SQL script file at path: {0}' -f $Using:Node.TestSqlScriptPath) -Verbose

                $Using:Node.TestSqlScript | Out-File -FilePath $Using:Node.TestSqlScriptPath -Encoding ascii -NoClobber -Force

                Write-Verbose -Message 'Test SQL script file created successfully' -Verbose
            }

            TestScript = {
                Write-Verbose -Message 'Testing if Test SQL script file exists and matches expected content' -Verbose

                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                $testResult = $getScriptResult.Result -eq $Using:Node.TestSqlScript

                Write-Verbose -Message ('Completed testing Test SQL script file. Returning: {0}' -f $testResult) -Verbose

                return $testResult
            }

            GetScript  = {
                Write-Verbose -Message ('Reading Test SQL script file content from path: {0}' -f $Using:Node.TestSqlScriptPath) -Verbose

                $fileContent = $null

                if (Test-Path -Path $Using:Node.TestSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.TestSqlScriptPath -Raw
                }

                $returnValue = @{
                    Result = $fileContent
                }

                Write-Verbose -Message ('Completed reading Test SQL script file content. Returning: {0}' -f ($returnValue | Out-String)) -Verbose

                return $returnValue
            }
        }

        xScript 'CreateFile_SetSqlScript'
        {
            SetScript  = {
                Write-Verbose -Message ('Creating Set SQL script file at path: {0}' -f $Using:Node.SetSqlScriptPath) -Verbose

                $Using:Node.SetSqlScript | Out-File -FilePath $Using:Node.SetSqlScriptPath -Encoding ascii -NoClobber -Force

                Write-Verbose -Message 'Set SQL script file created successfully' -Verbose
            }

            TestScript = {
                Write-Verbose -Message 'Testing if Set SQL script file exists and matches expected content' -Verbose

                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                $testResult = $getScriptResult.Result -eq $Using:Node.SetSqlScript

                Write-Verbose -Message ('Completed testing Set SQL script file. Returning: {0}' -f $testResult) -Verbose

                return $testResult
            }

            GetScript  = {
                Write-Verbose -Message ('Reading Set SQL script file content from path: {0}' -f $Using:Node.SetSqlScriptPath) -Verbose

                $fileContent = $null

                if (Test-Path -Path $Using:Node.SetSqlScriptPath)
                {
                    $fileContent = Get-Content -Path $Using:Node.SetSqlScriptPath -Raw
                }

                $returnValue = @{
                    Result = $fileContent
                }

                Write-Verbose -Message ('Completed reading Set SQL script file content. Returning: {0}' -f ($returnValue | Out-String)) -Verbose

                return $returnValue
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
            Id                   = 'Integration_Test'
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
            Id             = 'Integration_Test'
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
            Id             = 'Integration_Test'
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
        Creates the script files and runs the SQL script as a Windows User
        in the same configuration using DependsOn.
#>
Configuration DSC_SqlScript_RunSqlScriptAsWindowsUserWithDependencies_Config
{
    Import-DscResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '9.1.0'
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        xScript 'CreateFile_GetSqlScript'
        {
            SetScript  = {
                Write-Verbose -Message ('Creating Get SQL script file at path: {0}' -f $Using:Node.GetSqlScriptPath2) -Verbose

                $Using:Node.GetSqlScript | Out-File -FilePath $Using:Node.GetSqlScriptPath2 -Encoding ascii -NoClobber -Force

                Write-Verbose -Message 'Get SQL script file created successfully' -Verbose
            }

            TestScript = {
                Write-Verbose -Message 'Testing if Get SQL script file exists and matches expected content' -Verbose

                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                $testResult = $getScriptResult.Result -eq $Using:Node.GetSqlScript

                Write-Verbose -Message ('Completed testing Get SQL script file. Returning: {0}' -f $testResult) -Verbose

                return $testResult
            }

            GetScript  = {
                Write-Verbose -Message ('Reading Get SQL script file content from path: {0}' -f $Using:Node.GetSqlScriptPath2) -Verbose

                $fileContent = $null

                if (Test-Path -Path $Using:Node.GetSqlScriptPath2)
                {
                    $fileContent = Get-Content -Path $Using:Node.GetSqlScriptPath2 -Raw
                }

                $returnValue = @{
                    Result = $fileContent
                }

                Write-Verbose -Message ('Completed reading Get SQL script file content. Returning: {0}' -f ($returnValue | Out-String)) -Verbose

                return $returnValue
            }
        }

        xScript 'CreateFile_TestSqlScript'
        {
            SetScript  = {
                Write-Verbose -Message ('Creating Test SQL script file at path: {0}' -f $Using:Node.TestSqlScriptPath2) -Verbose

                $Using:Node.TestSqlScript | Out-File -FilePath $Using:Node.TestSqlScriptPath2 -Encoding ascii -NoClobber -Force

                Write-Verbose -Message 'Test SQL script file created successfully' -Verbose
            }

            TestScript = {
                Write-Verbose -Message 'Testing if Test SQL script file exists and matches expected content' -Verbose

                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                $testResult = $getScriptResult.Result -eq $Using:Node.TestSqlScript

                Write-Verbose -Message ('Completed testing Test SQL script file. Returning: {0}' -f $testResult) -Verbose

                return $testResult
            }

            GetScript  = {
                Write-Verbose -Message ('Reading Test SQL script file content from path: {0}' -f $Using:Node.TestSqlScriptPath2) -Verbose

                $fileContent = $null

                if (Test-Path -Path $Using:Node.TestSqlScriptPath2)
                {
                    $fileContent = Get-Content -Path $Using:Node.TestSqlScriptPath2 -Raw
                }

                $returnValue = @{
                    Result = $fileContent
                }

                Write-Verbose -Message ('Completed reading Test SQL script file content. Returning: {0}' -f ($returnValue | Out-String)) -Verbose

                return $returnValue
            }
        }

        xScript 'CreateFile_SetSqlScript'
        {
            SetScript  = {
                Write-Verbose -Message ('Creating Set SQL script file at path: {0}' -f $Using:Node.SetSqlScriptPath2) -Verbose

                $Using:Node.SetSqlScript | Out-File -FilePath $Using:Node.SetSqlScriptPath2 -Encoding ascii -NoClobber -Force

                Write-Verbose -Message 'Set SQL script file created successfully' -Verbose
            }

            TestScript = {
                Write-Verbose -Message 'Testing if Set SQL script file exists and matches expected content' -Verbose

                $getScriptResult = & ([ScriptBlock]::Create($GetScript))

                $testResult = $getScriptResult.Result -eq $Using:Node.SetSqlScript

                Write-Verbose -Message ('Completed testing Set SQL script file. Returning: {0}' -f $testResult) -Verbose

                return $testResult
            }

            GetScript  = {
                Write-Verbose -Message ('Reading Set SQL script file content from path: {0}' -f $Using:Node.SetSqlScriptPath2) -Verbose

                $fileContent = $null

                if (Test-Path -Path $Using:Node.SetSqlScriptPath2)
                {
                    $fileContent = Get-Content -Path $Using:Node.SetSqlScriptPath2 -Raw
                }

                $returnValue = @{
                    Result = $fileContent
                }

                Write-Verbose -Message ('Completed reading Set SQL script file content. Returning: {0}' -f ($returnValue | Out-String)) -Verbose

                return $returnValue
            }
        }

        SqlScript 'Integration_Test'
        {
            Id                   = 'Integration_Test'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName

            GetFilePath          = $Node.GetSqlScriptPath2
            TestFilePath         = $Node.TestSqlScriptPath2
            SetFilePath          = $Node.SetSqlScriptPath2
            Variable             = @(
                ('DatabaseName={0}' -f $Node.Database4Name)
            )
            QueryTimeout         = 30
            Encrypt              = 'Optional'

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))

            DependsOn            = @(
                '[xScript]CreateFile_GetSqlScript'
                '[xScript]CreateFile_TestSqlScript'
                '[xScript]CreateFile_SetSqlScript'
            )
        }
    }
}

<#
    .SYNOPSIS
        Remove the database created from the combined configuration test.
#>
Configuration DSC_SqlScript_RemoveDatabase4_Config
{
    Import-DscResource -ModuleName 'SqlServerDsc'

    node $AllNodes.NodeName
    {
        SqlDatabase 'RemoveDatabase4'
        {
            Ensure               = 'Absent'
            ServerName           = $Node.ServerName
            InstanceName         = $Node.InstanceName
            Name                 = $Node.Database4Name

            PsDscRunAsCredential = New-Object `
                -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @($Node.Admin_UserName, (ConvertTo-SecureString -String $Node.Admin_Password -AsPlainText -Force))
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
