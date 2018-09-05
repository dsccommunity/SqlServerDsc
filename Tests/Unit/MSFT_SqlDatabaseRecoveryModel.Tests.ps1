$script:DSCModuleName = 'SqlServerDsc'
$script:DSCResourceName = 'MSFT_SqlDatabaseRecoveryModel'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup
    InModuleScope $script:DSCResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockSqlDatabaseName = 'AdventureWorks'
        $mockSqlDatabaseRecoveryModel = 'Simple'
        $mockSqlDatabaseName2 = 'AdventureWorks2'
        $mockSqlDatabaseRecoveryModel2 = 'Full'

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
        }

        #region Function mocks
        Class Database
        {
            [string]$Name
            [string]$RecoveryModel
            [bool] $mockInvalidOperationForAlterMethod = $false
            [string] $mockExpectedRecoveryModel = 'Simple'

            Database($Name, $RecoveryModel)
            {
                $this.Name = $Name
                $this.RecoveryModel = $RecoveryModel
            }

            Alter()
            {
                if ($this.mockInvalidOperationForAlterMethod)
                {
                    throw 'Mock Alter Method was called with invalid operation.'
                }

                if ( $this.RecoveryModel -ne $this.mockExpectedRecoveryModel )
                {
                    throw "Called Alter Drop() method without setting the right recovery model. Expected '{0}'. But was '{1}'." `
                        -f $this.mockExpectedRecoveryModel, $this.RecoveryModel
                }
            }
        }

        Class ConnectSQL
        {
            [string] $InstanceName
            [string] $ComputerNamePhysicalNetBIOS
            [Database[]] $Databases

            ConnectSQL($InstanceName, $ComputerNamePhysicalNetBIOS, $Databases)
            {
                $this.InstanceName = $InstanceName
                $this.ComputerNamePhysicalNetBIOS = $ComputerNamePhysicalNetBIOS
                $this.Databases = $Databases
            }
        }

        $databases = @(
            ([Database]::new($mockSqlDatabaseName, $mockSqlDatabaseRecoveryModel))
            ([Database]::new($mockSqlDatabaseName2, $mockSqlDatabaseRecoveryModel2))
        )
        $mockConnectSQL = [ConnectSQL]::new($mockInstanceName, $mockServerName, $databases)
        #endregion

        Describe "MSFT_SqlDatabaseRecoveryModel\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith { return $mockConnectSQL } -Verifiable
            }

            Context 'When passing values to parameters and database does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'UnknownDatabase'
                        RecoveryModel = 'Full'
                    }

                    $throwInvalidOperation = ("Database 'UnknownDatabase' does not exist " + `
                        "on SQL server 'localhost\MSSQLSERVER'.")

                    Mock -CommandName Connect-SQL -MockWith { throw $throwInvalidOperation }

                    { Get-TargetResource @testParameters } | Should Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should return wrong RecoveryModel' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Full'
                    }

                    $result = Get-TargetResource @testParameters
                    $result.RecoveryModel | Should -Not -Be $testParameters.RecoveryModel
                }

                It 'Should return the same values as passed as parameters' {
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state for a database' {
                It 'Should return the correct RecoveryModel' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Simple'
                    }

                    $result = Get-TargetResource @testParameters
                    $result.RecoveryModel | Should -Be $testParameters.RecoveryModel
                }

                It 'Should return the same values as passed as parameters' {
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlDatabaseRecoveryModel\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith { return $mockConnectSQL } -Verifiable
            }

            Context 'When the system is not in the desired state' {
                It 'Should return the state as false when desired recovery model is not correct' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Full'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state' {
                It 'Should return the state as true when desired recovery model is correct' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Simple'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlDatabaseRecoveryModel\Set-TargetResource" -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith { return $mockConnectSQL } -Verifiable
            }

            Context 'When the system is not in the desired state, and database does not exist' {
                It 'Should throw the correct error' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'UnknownDatabase'
                        RecoveryModel = 'Full'
                    }

                    $throwInvalidOperation = ("Database 'UnknownDatabase' does not exist " + `
                            "on SQL server 'localhost\MSSQLSERVER'.")

                    { Set-TargetResource @testParameters } | Should -Throw $throwInvalidOperation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should not throw when calling the alter method when desired recovery model should be set' {
                    $mockConnectSQL.Databases.Where{$_.Name -eq 'AdventureWorks'}[0].mockExpectedRecoveryModel = 'Full'
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        RecoveryModel = 'Full'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}
