<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlDatabase DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

#region HEADER
$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlDatabase'

# Unit Test Template Version: 1.2.4
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
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

    InModuleScope $script:dscResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockSqlDatabaseName = 'AdventureWorks'
        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod = $false
        $mockInvalidOperationForAlterMethod = $false
        $mockExpectedDatabaseNameToCreate = 'Contoso'
        $mockExpectedDatabaseNameToDrop = 'Sales'
        $mockSqlDatabaseCollation = 'SQL_Latin1_General_CP1_CI_AS'

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
        }

        #region Function mocks

        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name Collation -Value $mockSqlDatabaseCollation -PassThru |
                        Add-Member -MemberType ScriptMethod -Name EnumCollations -Value {
                        return @(
                            ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty Name -Value $mockSqlDatabaseCollation -PassThru
                            ),
                            ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty Name -Value 'SQL_Latin1_General_CP1_CS_AS' -PassThru
                            ),
                            ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty Name -Value 'SQL_Latin1_General_Pref_CP850_CI_AS' -PassThru
                            )
                        )
                    } -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name Databases -Value {
                        return @{
                            $mockSqlDatabaseName = ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                                    Add-Member -MemberType NoteProperty -Name Collation -Value $mockSqlDatabaseCollation -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                    if ($mockInvalidOperationForDropMethod)
                                    {
                                        throw 'Mock Drop Method was called with invalid operation.'
                                    }

                                    if ( $this.Name -ne $mockExpectedDatabaseNameToDrop )
                                    {
                                        throw "Called mocked Drop() method without dropping the right database. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedDatabaseNameToDrop, $this.Name
                                    }
                                } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                    if ($mockInvalidOperationForAlterMethod)
                                    {
                                        throw 'Mock Alter Method was called with invalid operation.'
                                    }
                                } -PassThru
                            )
                        }
                    } -PassThru -Force
                )
            )
        }

        $mockNewObjectDatabase = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlDatabaseName -PassThru |
                        Add-Member -MemberType NoteProperty -Name Collation -Value '' -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Create -Value {
                        if ($mockInvalidOperationForCreateMethod)
                        {
                            throw 'Mock Create Method was called with invalid operation.'
                        }

                        if ( $this.Name -ne $mockExpectedDatabaseNameToCreate )
                        {
                            throw "Called mocked Create() method without adding the right database. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedDatabaseNameToCreate, $this.Name
                        }
                    } -PassThru -Force
                )
            )
        }
        #endregion

        Describe 'MSFT_SqlDatabase\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name      = 'UnknownDatabase'
                    Collation = 'SQL_Latin1_General_CP1_CI_AS'
                }

                It 'Should return the state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.Collation | Should -BeNullOrEmpty
                }


                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is in the desired state for a database' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name      = 'AdventureWorks'
                    Collation = 'SQL_Latin1_General_CP1_CI_AS'
                }

                It 'Should return the state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.Collation | Should -Be $testParameters.Collation
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlDatabase\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when desired database does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'UnknownDatabase'
                        Ensure    = 'Present'
                        Collation = 'SQL_Latin1_General_CP1_CS_AS'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should return the state as false when desired database exists but has the incorrect collation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'AdventureWorks'
                        Ensure    = 'Present'
                        Collation = 'SQL_Latin1_General_CP1_CS_AS'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should return the state as false when non-desired database exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'AdventureWorks'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Present' {
                It 'Should return the state as true when desired database exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'AdventureWorks'
                        Ensure    = 'Present'
                        Collation = 'SQL_Latin1_General_CP1_CI_AS'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should return the state as true when desired database exists and has the correct collation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'AdventureWorks'
                        Ensure    = 'Present'
                        Collation = 'SQL_Latin1_General_CP1_CI_AS'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                It 'Should return the state as true when desired database does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'UnknownDatabase'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe 'MSFT_SqlDatabase\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectDatabase -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                } -Verifiable
            }

            $mockSqlDatabaseName = 'Contoso'
            $mockExpectedDatabaseNameToCreate = 'Contoso'

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should not throw when creating the database' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'NewDatabase'
                        Ensure = 'Present'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should not throw when changing the database collation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'Contoso'
                        Ensure    = 'Present'
                        Collation = 'SQL_Latin1_General_CP1_CS_AS'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Database' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                    } -Scope Context
                }
            }

            $mockExpectedDatabaseNameToDrop = 'Sales'
            $mockSqlDatabaseName = 'Sales'

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should not throw when dropping the database' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Sales'
                        Ensure = 'Absent'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockInvalidOperationForCreateMethod = $true
            $mockInvalidOperationForAlterMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should throw the correct error when Create() method was called with invalid operation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'NewDatabase'
                        Ensure = 'Present'
                    }

                    $errorMessage = $script:localizedData.FailedToCreateDatabase -f $testParameters.Name

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                    } -Scope It
                }

                It 'Should throw the correct error when Alter() method was called with invalid operation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = $mockSqlDatabaseName
                        Ensure = 'Present'
                        Collation = 'SQL_Latin1_General_Pref_CP850_CI_AS'
                    }

                    $errorMessage = $script:localizedData.FailedToUpdateDatabase -f $testParameters.Name

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should throw the correct error when invalid collation is specified' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'Sales'
                        Ensure    = 'Present'
                        Collation = 'InvalidCollation'
                    }

                    $errorMessage = $script:localizedData.InvalidCollation -f $testParameters.Collation, $testParameters.InstanceName

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            $mockSqlDatabaseName = 'AdventureWorks'
            $mockInvalidOperationForDropMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name      = 'AdventureWorks'
                    Ensure    = 'Absent'
                    Collation = 'SQL_Latin1_General_CP1_CS_AS'
                }

                It 'Should throw the correct error when Drop() method was called with invalid operation' {

                    $errorMessage = $script:localizedData.FailedToDropDatabase -f $testParameters.Name

                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe 'SqlDatabase\Export-TargetResource' {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

            # Mocking for protocol TCP
            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
                return $null
            } -Verifiable

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'Extract the existing configuration' {
                $result = Export-TargetResource


                It 'Should return content from the extraction' {
                    $result | Should -Not -Be $null
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
