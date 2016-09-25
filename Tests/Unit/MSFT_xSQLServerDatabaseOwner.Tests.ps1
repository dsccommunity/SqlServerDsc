$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerDatabaseOwner'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

# Begin Testing
try
{
    #region Pester Test Initialization

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')

    $nodeName = 'localhost'
    $instanceName = 'MSSQLSERVER'

    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName) - $($script:DSCModuleName)" {
        InModuleScope $script:DSCResourceName {
            $defaultParameters = @{
                SQLInstanceName = $instanceName
                SQLServer = $nodeName
                Name = 'SQLAdmin'
            }

            Mock -CommandName Connect-SQL -MockWith {
                return New-Object Object | 
                    Add-Member ScriptProperty Databases {
                        return @{
                            'AdventureWorks' = @( ( New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, 'AdventureWorks') ) )
                        }
                    } -PassThru -Force 
            } -ModuleName $script:DSCResourceName -Verifiable

            Context 'When the specified database does not exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Database = 'UnknownDatabase'
                }

                Mock -CommandName Get-SqlDatabaseOwner -MockWith { return $null }
                Mock -CommandName Set-SqlDatabaseOwner -MockWith { return exception }

                $result = Get-TargetResource @testParameters

                It 'Should return the name as null from the get method' {
                    $result.Name | Should Be $null
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should throw when the set method is called" {
                    { Set-TargetResource @testParameters } | Should Throw
                }
            }

            Context 'When the specified login does not exist' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Database = 'UnknownDatabase'
                }

                Mock -CommandName Get-SqlDatabaseOwner -MockWith { return $null }
                Mock -CommandName Set-SqlDatabaseOwner -MockWith { return exception }

                $result = Get-TargetResource @testParameters

                It 'Should return the name as null from the get method' {
                    $result.Name | Should Be $null
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Should throw when the set method is called" {
                    { Set-TargetResource @testParameters } | Should Throw
                }
            }

            Context 'When the specified name is not the owner of the database and should be' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Database = 'AdventureWorks'
                }

                Mock -CommandName Get-SqlDatabaseOwner -MockWith { return $null }
                Mock -CommandName Set-SqlDatabaseOwner -MockWith { }

                $result = Get-TargetResource @testParameters

                It 'Should return the name as null from the get method' {
                    $result.Name | Should Be $null
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParameters | Should Be $false
                }

                It "Calls the mock function Set-SqlDatabaseOwner from the set method" {
                    Set-TargetResource @testParameters
                    Assert-MockCalled Set-SqlDatabaseOwner
                }
            }
    
            Context 'When the specified name is the owner of the database and should be' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    Database = 'AdventureWorks'
                }

                Mock -CommandName Get-SqlDatabaseOwner -MockWith { return $testParameters.Name }
    
                $result = Get-TargetResource @testParameters

                It 'Should return the name of the owner from the get method' {
                    $result.Name | Should Be $testParameters.Name
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParameters | Should Be $true
                }
            }

            Assert-VerifiableMocks
        }
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment 

    #endregion
}
