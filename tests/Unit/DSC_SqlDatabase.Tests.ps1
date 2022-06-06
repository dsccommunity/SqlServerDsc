<#
    .SYNOPSIS
        Automated unit test for DSC_SqlDatabase DSC resource.

#>
return
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlDatabase'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockInstanceVersionMajor = 13
        $mockSqlDatabaseName = 'AdventureWorks'
        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod = $false
        $mockInvalidOperationForAlterMethod = $false
        $mockExpectedDatabaseNameToCreate = 'Contoso'
        $mockExpectedDatabaseNameToDrop = 'Sales'
        $mockSqlDatabaseCollation = 'SQL_Latin1_General_CP1_CI_AS'
        $mockSqlDatabaseCompatibilityLevel = 'Version130'
        $mockSqlDatabaseRecoveryModel = 'Full'
        $mockSqlDatabaseOwner = 'sa'

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
                        Add-Member -MemberType NoteProperty -Name VersionMajor -Value $mockInstanceVersionMajor -PassThru |
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
                                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockSqlDatabaseName -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name 'Collation' -Value $mockSqlDatabaseCollation -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name 'CompatibilityLevel' -Value $mockSqlDatabaseCompatibilityLevel -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name 'RecoveryModel' -Value $mockSqlDatabaseRecoveryModel -PassThru |
                                                    Add-Member -MemberType NoteProperty -Name 'Owner' -Value $mockSqlDatabaseOwner -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
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
                                                    Add-Member -MemberType ScriptMethod -Name 'SetOwner' -Value {
                                                        $script:methodSetOwnerWasCalled += 1
                                                    } -PassThru |
                                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
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
                        Add-Member -MemberType NoteProperty -Name CompatibilityLevel -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name RecoveryModel -Value '' -PassThru |
                        Add-Member -MemberType NoteProperty -Name Owner -Value '' -PassThru |
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
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name 'SetOwner' -Value {
                            $script:methodSetOwnerWasCalled += 1
                        } -PassThru -Force
                )
            )
        }
        #endregion

        Describe 'DSC_SqlDatabase\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $testParameters = $mockDefaultParameters.Clone()
                $testParameters['Name'] = 'UnknownDatabase'

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
                    $result.CompatibilityLevel | Should -BeNullOrEmpty
                    $result.RecoveryModel | Should -BeNullOrEmpty
                    $result.Owner | Should -BeNullOrEmpty
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Context 'When the system is in the desired state for a database' {
                $testParameters = $mockDefaultParameters.Clone()
                $testParameters['Name'] = 'AdventureWorks'

                It 'Should return the state as present' {
                    $result = Get-TargetResource @testParameters

                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters

                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                    $result.Collation | Should -Be $mockSqlDatabaseCollation
                    $result.CompatibilityLevel | Should -Be $mockSqlDatabaseCompatibilityLevel
                    $result.RecoveryModel | Should -Be $mockSqlDatabaseRecoveryModel
                    $result.OwnerName | Should -Be $mockSqlDatabaseOwner
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DSC_SqlDatabase\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when desired database does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name               = 'UnknownDatabase'
                        Ensure             = 'Present'
                        Collation          = 'SQL_Latin1_General_CP1_CS_AS'
                        CompatibilityLevel = 'Version130'
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

                It 'Should return the state as false when desired database exists but has the incorrect compatibility level' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name               = 'AdventureWorks'
                        Ensure             = 'Present'
                        CompatibilityLevel = 'Version120'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should return the state as false when desired database exists but has the incorrect recovery model' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        Ensure        = 'Present'
                        RecoveryModel = 'Simple'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should return the state as false when desired database exists but has the incorrect owner' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'AdventureWorks'
                        Ensure    = 'Present'
                        OwnerName = 'NewLoginName'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }


                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 5 -Scope Context
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
                        Name               = 'AdventureWorks'
                        Ensure             = 'Present'
                        Collation          = 'SQL_Latin1_General_CP1_CI_AS'
                        CompatibilityLevel = 'Version130'
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

                It 'Should return the state as true when desired database exists and has the correct compatibility level' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name               = 'AdventureWorks'
                        Ensure             = 'Present'
                        CompatibilityLevel = 'Version130'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should return the state as true when desired database exists and has the correct recovery model' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'AdventureWorks'
                        Ensure        = 'Present'
                        RecoveryModel = 'Full'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 4 -Scope Context
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

        Describe 'DSC_SqlDatabase\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectDatabase -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                } -Verifiable
            }

            $mockSqlDatabaseName = 'Contoso'
            $mockExpectedDatabaseNameToCreate = 'Contoso'

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                BeforeEach {
                    $script:methodSetOwnerWasCalled = 0
                }

                Context 'When creating a new database with just mandatory parameters' {
                    It 'Should not throw when creating the database' {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Name   = 'NewDatabase'
                            Ensure = 'Present'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }

                    It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Database' {
                        Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -ParameterFilter {
                            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Database'
                        } -Scope Context
                    }
                }

                Context 'When creating a new database and specifying recovery model' {
                    It 'Should not throw when creating the database' {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Name          = 'NewDatabase'
                            Ensure        = 'Present'
                            RecoveryModel = 'Full'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }
                }

                Context 'When creating a new database and specifying owner' {
                    It 'Should not throw when creating the database' {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Name      = 'NewDatabase'
                            Ensure    = 'Present'
                            OwnerName = 'LoginName'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw

                        $script:methodSetOwnerWasCalled | Should -Be 1
                    }
                }

                Context 'When creating a new database and specifying collation' {
                    It 'Should not throw when creating the database' {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Name      = 'NewDatabase'
                            Ensure    = 'Present'
                            Collation = 'SQL_Latin1_General_CP1_CI_AS'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }
                }

                Context 'When creating a new database and specifying compatibility level' {
                    It 'Should not throw when creating the database' {
                        $testParameters = $mockDefaultParameters
                        $testParameters += @{
                            Name               = 'NewDatabase'
                            Ensure             = 'Present'
                            CompatibilityLevel = 'Version130'
                        }

                        { Set-TargetResource @testParameters } | Should -Not -Throw
                    }
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

                It 'Should not throw when changing the database compatibility level' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name               = 'Contoso'
                        Ensure             = 'Present'
                        CompatibilityLevel = 'Version130'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should not throw when changing the database recovery model' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name          = 'Contoso'
                        Ensure        = 'Present'
                        RecoveryModel = 'Simple'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should not throw when changing the owner' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'Contoso'
                        Ensure    = 'Present'
                        OwnerName = 'NewLoginName'
                    }

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    $script:methodSetOwnerWasCalled | Should -Be 1
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 4 -Scope Context
                }

                It 'Should throw when trying to use an unsupported compatibility level' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name               = 'Contoso'
                        Ensure             = 'Present'
                        CompatibilityLevel = 'Version140'
                    }

                    $mockErrorMessage = $script:localizedData.InvalidCompatibilityLevel -f $testParameters.CompatibilityLevel, $mockInstanceName

                    { Set-TargetResource @testParameters } | Should -Throw $mockErrorMessage
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
                        Name      = $mockSqlDatabaseName
                        Ensure    = 'Present'
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
    }
}
finally
{
    Invoke-TestCleanup
}
