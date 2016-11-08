<#
    .SYNOPSIS
        Automated unit test for MSFT_xSQLServerScript DSC Resource
#>

# Suppression of this PSSA rule allowed in tests.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
Param()

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName 'xSQLServer' `
    -DSCResourceName 'MSFT_xSQLServerScript' `
    -TestType Unit 

#endregion HEADER

function Invoke-TestSetup {
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SqlPowerShellSqlExecutionException.cs')
    Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SQLPSStub.psm1') -Force
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope 'MSFT_xSQLServerScript' { 

        $testParameters = @{
            ServerInstance = $env:COMPUTERNAME
            SetFilePath = "set.sql" 
            GetFilePath = "get.sql" 
            TestFilePath = "test.sql"
        }

        $dscResourceName = 'MSFT_xSQLServerScript'
        $sqlServerHelperModuleName = 'xSQLServerHelper'

        Describe "$dscResourceName\Get-TargetResource" {         

            Context 'Get-TargetResource fails to import SQLPS module' {
                $throwMessage = "Failed to import SQLPS module."

                Mock -CommandName Import-SQLPSModule -MockWith { throw $throwMessage } -ModuleName $sqlServerHelperModuleName

                It 'Should throw an error' {
                    { Get-TargetResource @testParameters } | Should Throw $throwMessage
                }
            }

            Context 'Get-TargetResource returns script results successfully' {
                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith { "" } -ModuleName $dscResourceName

                $result = Get-TargetResource @testParameters

                It 'Should return the expected results' {
                    $result.ServerInstance | Should Be $testParameters.ServerInstance
                    $result.SetFilePath | Should Be $testParameters.SetFilePath
                    $result.GetFilePath | Should Be $testParameters.GetFilePath
                    $result.TestFilePath | Should Be $testParameters.TestFilePath
                    $result.GetType() | Should Be "hashtable"
                }
            }

            Context 'Get SQl script throws an error' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith { Throw $errorMessage } -ModuleName $script:DSCResourceName

                It 'Should throw an error' {
                    { Get-TargetResource @testParameters } | Should Throw $errorMessage
                }
            } 
        }

        Describe "$dscResourceName\Set-TargetResource" {

            Context 'Set-TargetResource fails to import SQLPS module' {
                $throwMessage = "Failed to import SQLPS module."

                Mock -CommandName Import-SQLPSModule -MockWith { throw $throwMessage } -ModuleName $sqlServerHelperModuleName

                It 'Should throw an error' {
                    { Set-TargetResource @testParameters } | Should Throw $throwMessage
                }
            }

            Context 'Set-TargetResource runs script without issue' {
                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith { "" } -ModuleName $dscResourceName

                $result = Set-TargetResource @testParameters

                It 'Should return the expected results' {
                    $result | should be ""
                }
            }

            Context 'Set SQL script trhows an error' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith { Throw $errorMessage } -ModuleName $script:DSCResourceName

                It 'Should throw an error' {
                    { Set-TargetResource @testParameters } | Should Throw $errorMessage
                }
            }
        }
        
        Describe "$dscResourceName\Test-TargetResource" {
            Context 'Test-TargetResource fails to import SQLPS module' {
                $throwMessage = "Failed to import SQLPS module."

                Mock -CommandName Import-SQLPSModule -MockWith { throw $throwMessage } -ModuleName $sqlServerHelperModuleName

                It 'Should throw an error' {
                    { Set-TargetResource @testParameters } | Should Throw $throwMessage
                }
            }

            Context 'Test-TargetResource runs script without issue' {
                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {} -ModuleName $dscResourceName

                $result = Test-TargetResource @testParameters

                It 'Should return true' {
                    $result | should be $true
                }
            }

            Context 'Test SQL script throws SQL execution error' {
                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith { throw New-Object Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException} -ModuleName $dscResourceName

                $result = Test-TargetResource @testParameters

                It 'Should return false' {
                    $result | should be $false
                }
            }

            Context 'Test SQL script throws a different error' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith { Throw $errorMessage } -ModuleName $script:DSCResourceName

                It 'Should throw an error' {
                    { Test-TargetResource @testParameters } | Should Throw $errorMessage
                }            
            }
        }

        Describe "$dscResourceName\Invoke-SqlScript" {
            $invokeScriptParameters = @{
                ServerInstance = $env:COMPUTERNAME 
                SqlScriptPath = "set.sql" 
            }

            Context 'Invoke-SqlScript fails to import SQLPS module' {
                $throwMessage = "Failed to import SQLPS module."

                Mock -CommandName Import-SQLPSModule -MockWith { throw $throwMessage } -ModuleName $sqlServerHelperModuleName

                It 'Should throw an error' {
                    { Invoke-SqlScript @invokeScriptParameters } | Should Throw $throwMessage
                }
            }

            Context 'Invoke-SQlScript is called with credentials' {
                $passwordPlain = "password"
                $user = "User"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith {} -ParameterFilter { ($Username -eq $user) -and ($Password -eq $passwordPlain) } -ModuleName $dscResourceName

                $password = ConvertTo-SecureString -String $passwordPlain -AsPlainText -Force
                $cred = New-Object pscredential -ArgumentList $user, $password

                $invokeScriptParameters.Add("Credential", $cred)

                $null = Invoke-SqlScript @invokeScriptParameters

                It 'Should call Invoke-Sqlcmd with correct parameters' {
                    Assert-MockCalled -CommandName Invoke-Sqlcmd -Times 1 -Exactly -ParameterFilter { ($Username -eq $user) -and ($Password -eq $passwordPlain) }
                }
            }

            Context 'Invoke-SqlScript fails to execute the SQL scripts' {
                $errorMessage = "Failed to run SQL Script"

                Mock -CommandName Import-Module -MockWith {} -ModuleName $sqlServerHelperModuleName
                Mock -CommandName Invoke-Sqlcmd -MockWith { Throw $errorMessage } -ModuleName $script:DSCResourceName

                It 'Should throw an error' {
                    { Invoke-SqlScript @invokeScriptParameters } | Should Throw $errorMessage
                } 
            }
        }  
    }
}
finally
{
    Invoke-TestCleanup
}
