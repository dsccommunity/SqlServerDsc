<#
.EXAMPLE
    This example shows one way to create the SQL script files and how to run
    those files.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName          = 'localhost'

            ServerName        = $env:COMPUTERNAME
            InstanceName      = 'DSCTEST'

            DatabaseName      = 'ScriptDatabase1'

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
        Script 'CreateFile_GetSqlScript'
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

        Script 'CreateFile_TestSqlScript'
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

        Script 'CreateFile_SetSqlScript'
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

        SqlScript 'Integration_Test'
        {
            ServerInstance       = Join-Path -Path $Node.ServerName -ChildPath $Node.InstanceName

            GetFilePath          = $Node.GetSqlScriptPath
            TestFilePath         = $Node.TestSqlScriptPath
            SetFilePath          = $Node.SetSqlScriptPath
            Variable             = @(
                ('DatabaseName={0}' -f $Node.DatabaseName)
            )
            QueryTimeout         = 30

            PsDscRunAsCredential = $SqlAdministratorCredential
        }
    }
}
