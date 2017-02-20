$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerDatabase'

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
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockSQLServerName                   = 'localhost'
        $mockSQLServerInstanceName           = 'MSSQLSERVER'
        $mockSQLDatabaseName                 = 'AdventureWorks'
        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod   = $false
        $mockExpectedCreateForAlterMethod    = 'AdventureWorks'
        $mockExpectedDropForAlterMethod      = 'Sales'

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            SQLInstanceName = $mockSQLServerInstanceName
            SQLServer       = $mockSQLServerName
        }
        
        #region Function mocks
        #$mockSQLDatabaseName = @( ( New-Object Microsoft.SqlServer.Management.Smo.Database -ArgumentList @( $null, $mockSQLDatabaseName) ) )
        $mockConnectSQL = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockSQLServerInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockSQLServerName -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Databases -Value {
                            return @{
                                $mockSQLDatabaseName = ( New-Object Object | 
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockSQLDatabaseName -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Create -Value {
                                        if ( $this.Databases[$mockSQLDatabaseName] -ne $mockExpectedCreateForAlterMethod )
                                        {
                                            throw "Called mocked Create() method without adding the right database. Expected '{0}'. But was '{1}'." `
                                                  -f $mockExpectedCreateForAlterMethod, $this.Databases[$mockSQLDatabaseName]
                                        }
                                        if ($mockInvalidOperationForCreateMethod)
                                        {
                                            throw 'Mock Create Method was called with invalid operation.'
                                        }
                                    } -PassThru -Force |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                        if ( $this.Databases[$mockSQLDatabaseName] -ne $mockExpectedDropForAlterMethod )
                                        {
                                            throw "Called mocked Create() method without dropping the right database. Expected '{0}'. But was '{1}'." `
                                                  -f $mockExpectedDropForAlterMethod, $this.Databases[$mockSQLDatabaseName]
                                        }
                                        if ($mockInvalidOperationForDropMethod)
                                        {
                                            throw 'Mock Drop Method was called with invalid operation.'
                                        }
                                    } -PassThru -Force
                                    ) 
                                }
                            } -PassThru -Force                                        
                )
            )
        }
        #endregion

        Describe "MSFT_xSQLServerDatabase\Get-TargetResource" -Tag 'Get'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'UnknownDatabase'
                }

                $result = Get-TargetResource @testParameters

                It 'Should return the state as absent' {
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }
        
            Context 'When the system is in the desired state for a database' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                }
        
                $result = Get-TargetResource @testParameters

                It 'Should return the state as present' {
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.Name | Should Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMocks
        }
        
        Describe "MSFT_xSQLServerDatabase\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when desired database does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name = 'UnknownDatabase'
                        Ensure = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should return the state as false when non-desired database exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name = 'AdventureWorks'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Present' {
                It 'Should return the state as present when desired database exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name = 'AdventureWorks'
                        Ensure = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                It 'Should return the state as absent when desired database does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name = 'UnknownDatabase'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMocks
        }
        
        Describe "MSFT_xSQLServerDatabase\Set-TargetResource" -Tag 'Set'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'NewDatabase'
                    Ensure = 'Present'
                }

                It 'Should Not Throw when Ensure parameter is set to Present' {
                    { Set-TargetResource @testParameters } | Should Not Throw
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    Ensure = 'Absent'
                }             

                It 'Should Not Throw when Ensure parameter is set to Present' {
                    { Set-TargetResource @testParameters } | Should Not Throw
                }
                
                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockInvalidOperationForCreateMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'NewDatabase'
                    Ensure = 'Present'
                }

                It 'Shoud throw the correct error when Create() method was called with invalid operation' {
                    $throwInvalidOperation = ('Unexpected result when trying to configure the max degree of parallelism ' + `
                                              'server configuration option. InnerException: Exception calling "Create" ' + `
                                              'with "0" argument(s): "Mock Create Method was called with invalid operation."')
                    
                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation 
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockInvalidOperationForDropMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name = 'AdventureWorks'
                    Ensure = 'Absent'
                }
                
                It 'Shoud throw the correct error when Drop() method was called with invalid operation' {
                    $throwInvalidOperation = ('Unexpected result when trying to configure the max degree of parallelism ' + `
                                              'server configuration option. InnerException: Exception calling "Drop" ' + `
                                              'with "0" argument(s): "Mock Drop Method was called with invalid operation."')
                    
                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation 
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }
            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}
