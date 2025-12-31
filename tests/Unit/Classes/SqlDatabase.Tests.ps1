<#
    .SYNOPSIS
        Unit test for SqlDatabase DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../TestHelpers/CommonTestHelper.psm1')

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlDatabase' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                $null = [SqlDatabase]::new()
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $instance = [SqlDatabase]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                $instance = [SqlDatabase]::new()
                $instance.GetType().Name | Should -Be 'SqlDatabase'
            }
        }
    }
}

Describe 'SqlDatabase\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        Context 'When the database exists with default values' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockSqlDatabaseInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name          = 'TestDatabase'
                                InstanceName  = 'NamedInstance'
                                ServerName    = Get-ComputerName
                                Collation     = 'SQL_Latin1_General_CP1_CI_AS'
                                RecoveryModel = 'Full'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabaseInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.Name | Should -Be 'TestDatabase'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty
                    $currentState.Reasons | Should -BeNullOrEmpty
                    $currentState.Collation | Should -Be 'SQL_Latin1_General_CP1_CI_AS'
                    $currentState.RecoveryModel | Should -Be 'Full'
                }
            }

            Context 'When using parameter Credential' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlDatabaseInstance.Credential = [System.Management.Automation.PSCredential]::new(
                            'MyCredentialUserName',
                            [SecureString]::new()
                        )

                        <#
                            This mocks the method GetCurrentState().

                            Method Get() will call the base method Get() which will
                            call back to the derived class method GetCurrentState()
                            to get the result to return from the derived method Get().
                        #>
                        $script:mockSqlDatabaseInstance |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                                return [System.Collections.Hashtable] @{
                                    Name         = 'TestDatabase'
                                    InstanceName = 'NamedInstance'
                                    ServerName   = Get-ComputerName
                                    Credential   = $this.Credential
                                }
                            } -PassThru |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                                return
                            }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        $currentState = $script:mockSqlDatabaseInstance.Get()

                        $currentState.InstanceName | Should -Be 'NamedInstance'
                        $currentState.Name | Should -Be 'TestDatabase'
                        $currentState.ServerName | Should -Be (Get-ComputerName)
                        $currentState.Reasons | Should -BeNullOrEmpty

                        $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]
                        $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'
                    }
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When property Collation has the wrong value' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                        Collation    = 'Finnish_Swedish_CI_AS'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockSqlDatabaseInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name         = 'TestDatabase'
                                InstanceName = 'NamedInstance'
                                ServerName   = Get-ComputerName
                                Collation    = 'SQL_Latin1_General_CP1_CI_AS'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabaseInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.Name | Should -Be 'TestDatabase'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.Collation | Should -Be 'SQL_Latin1_General_CP1_CI_AS'

                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'SqlDatabase:SqlDatabase:Collation'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property Collation should be "Finnish_Swedish_CI_AS", but was "SQL_Latin1_General_CP1_CI_AS"'
                }
            }
        }
    }
}

Describe 'SqlDatabase\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                Name         = 'TestDatabase'
                InstanceName = 'NamedInstance'
            } |
                # Mock method GetCurrentState() which is called by the base method Get()
                Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                    return [System.Collections.Hashtable] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                        ServerName   = Get-ComputerName
                    }
                } -PassThru |
                # Mock method Modify which is called by the base method Set().
                Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                    $script:mockMethodModifyCallCount += 1
                } -PassThru
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockMethodModifyCallCount = 0
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 0
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property      = 'Collation'
                            ExpectedValue = 'Finnish_Swedish_CI_AS'
                            ActualValue   = 'SQL_Latin1_General_CP1_CI_AS'
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'SqlDatabase\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                Name         = 'TestDatabase'
                InstanceName = 'NamedInstance'
            } |
                # Mock method GetCurrentState() which is called by the base method Get()
                Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                    return [System.Collections.Hashtable] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                        ServerName   = Get-ComputerName
                    }
                } -PassThru
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance |
                    # Mock method Compare() which is called by the base method Test()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance.Test() | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance |
                    # Mock method Compare() which is called by the base method Test()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        <#
                            Compare() method shall only return the properties NOT in
                            desired state, in the format of the command Compare-DscParameterState.
                        #>
                        return @(
                            @{
                                Property      = 'Collation'
                                ExpectedValue = 'Finnish_Swedish_CI_AS'
                                ActualValue   = 'SQL_Latin1_General_CP1_CI_AS'
                            }
                        )
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance.Test() | Should -BeFalse
            }
        }
    }
}

Describe 'SqlDatabase\GetCurrentState()' -Tag 'GetCurrentState' {
    Context 'When database is missing in the current state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                    Name         = 'TestDatabase'
                    InstanceName = 'NamedInstance'
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    } -PassThru
            }

            Mock -CommandName Get-SqlDscDatabase
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlDatabaseInstance.GetCurrentState(
                    @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                    }
                )

                $currentState.InstanceName | Should -Be 'NamedInstance'
                $currentState.ServerName | Should -Be (Get-ComputerName)
                $currentState.Credential | Should -BeNullOrEmpty

                # Database doesn't exist, so Name should not be in current state
                $currentState.Keys | Should -Not -Contain 'Name'
            }
        }

        Context 'When using property Credential' {
            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Credential = [System.Management.Automation.PSCredential]::new(
                        'MyCredentialUserName',
                        [SecureString]::new()
                    )

                    $currentState = $script:mockSqlDatabaseInstance.GetCurrentState(
                        @{
                            Name         = 'TestDatabase'
                            InstanceName = 'NamedInstance'
                        }
                    )

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.ServerName | Should -Be (Get-ComputerName)

                    $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]
                    $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'
                }
            }
        }
    }

    Context 'When the database is present in the current state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                    Name         = 'TestDatabase'
                    InstanceName = 'NamedInstance'
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    } -PassThru
            }

            Mock -CommandName Get-SqlDscDatabase -MockWith {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                    (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                    'TestDatabase'
                )

                $mockDatabaseObject.Collation = 'SQL_Latin1_General_CP1_CI_AS'
                $mockDatabaseObject.CompatibilityLevel = [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]::Version150
                $mockDatabaseObject.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full
                $mockDatabaseObject.Owner = 'sa'
                $mockDatabaseObject.SnapshotIsolationState = [Microsoft.SqlServer.Management.Smo.SnapshotIsolationState]::Disabled
                $mockDatabaseObject.AutoClose = $false
                $mockDatabaseObject.AutoShrink = $false
                $mockDatabaseObject.ReadOnly = $false

                return $mockDatabaseObject
            }
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlDatabaseInstance.GetCurrentState(
                    @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                    }
                )

                $currentState.InstanceName | Should -Be 'NamedInstance'
                $currentState.ServerName | Should -Be (Get-ComputerName)
                $currentState.Credential | Should -BeNullOrEmpty
                $currentState.Name | Should -Be 'TestDatabase'
                $currentState.Collation | Should -Be 'SQL_Latin1_General_CP1_CI_AS'
                $currentState.CompatibilityLevel | Should -Be 'Version150'
                $currentState.RecoveryModel | Should -Be 'Full'
                $currentState.OwnerName | Should -Be 'sa'
                $currentState.SnapshotIsolation | Should -BeFalse
                $currentState.AutoClose | Should -BeFalse
                $currentState.AutoShrink | Should -BeFalse
                $currentState.ReadOnly | Should -BeFalse
            }
        }
    }
}

Describe 'SqlDatabase\Modify()' -Tag 'Modify' {
    Context 'When the system is not in the desired state' {
        Context 'When database is present but should be absent' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                        Ensure       = 'Absent'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Remove-SqlDscDatabase
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Ensure = 'Absent'
                        }
                    )

                    Should -Invoke -CommandName Remove-SqlDscDatabase -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When database is absent but should be present' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName New-SqlDscDatabase
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Ensure = 'Present'
                        }
                    )

                    Should -Invoke -CommandName New-SqlDscDatabase -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the database should also have an owner' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                            Name         = 'TestDatabase'
                            InstanceName = 'NamedInstance'
                            OwnerName    = 'DOMAIN\User'
                        } |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                            }  -PassThru |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                                return
                            } -PassThru
                    }

                    Mock -CommandName New-SqlDscDatabase
                }

                It 'Should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlDatabaseInstance.Modify(
                            # This is the properties not in desired state.
                            @{
                                Ensure    = 'Present'
                                OwnerName = 'DOMAIN\User'
                            }
                        )

                        # New-SqlDscDatabase handles OwnerName directly, so Get-SqlDscDatabase is not called.
                        Should -Invoke -CommandName New-SqlDscDatabase -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the database should also have snapshot isolation enabled' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                            Name              = 'TestDatabase'
                            InstanceName      = 'NamedInstance'
                            SnapshotIsolation = $true
                        } |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                            }  -PassThru |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                                return
                            } -PassThru
                    }

                    Mock -CommandName New-SqlDscDatabase

                    Mock -CommandName Get-SqlDscDatabase -MockWith {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                            (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                            'TestDatabase'
                        )
                    }

                    Mock -CommandName Enable-SqlDscDatabaseSnapshotIsolation
                }

                It 'Should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlDatabaseInstance.Modify(
                            # This is the properties not in desired state.
                            @{
                                Ensure            = 'Present'
                                SnapshotIsolation = $true
                            }
                        )

                        Should -Invoke -CommandName New-SqlDscDatabase -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Enable-SqlDscDatabaseSnapshotIsolation -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When property Collation is not in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                        Collation    = 'Finnish_Swedish_CI_AS'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscDatabase -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'TestDatabase'
                    )
                }

                Mock -CommandName Set-SqlDscDatabaseProperty
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Collation = 'Finnish_Swedish_CI_AS'
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscDatabase -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Set-SqlDscDatabaseProperty -ParameterFilter {
                        $Collation -eq 'Finnish_Swedish_CI_AS'
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When property RecoveryModel is not in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name          = 'TestDatabase'
                        InstanceName  = 'NamedInstance'
                        RecoveryModel = 'Simple'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscDatabase -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'TestDatabase'
                    )
                }

                Mock -CommandName Set-SqlDscDatabaseProperty
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            RecoveryModel = 'Simple'
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscDatabase -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Set-SqlDscDatabaseProperty -ParameterFilter {
                        $RecoveryModel -eq [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When property OwnerName is not in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                        OwnerName    = 'DOMAIN\NewOwner'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscDatabase -MockWith {
                    $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'TestDatabase'
                    )

                    $mockDatabaseObject |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'SetOwner' -Value {
                            # SetOwner method will be called - we verify through Get-SqlDscDatabase being called
                        }

                    return $mockDatabaseObject
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            OwnerName = 'DOMAIN\NewOwner'
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscDatabase -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When property SnapshotIsolation should be enabled' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name              = 'TestDatabase'
                        InstanceName      = 'NamedInstance'
                        SnapshotIsolation = $true
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscDatabase -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'TestDatabase'
                    )
                }

                Mock -CommandName Enable-SqlDscDatabaseSnapshotIsolation
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            SnapshotIsolation = $true
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscDatabase -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Enable-SqlDscDatabaseSnapshotIsolation -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When property SnapshotIsolation should be disabled' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name              = 'TestDatabase'
                        InstanceName      = 'NamedInstance'
                        SnapshotIsolation = $false
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscDatabase -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'TestDatabase'
                    )
                }

                Mock -CommandName Disable-SqlDscDatabaseSnapshotIsolation
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            SnapshotIsolation = $false
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscDatabase -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Disable-SqlDscDatabaseSnapshotIsolation -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When property AutoClose is not in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                        Name         = 'TestDatabase'
                        InstanceName = 'NamedInstance'
                        AutoClose    = $true
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscDatabase -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'TestDatabase'
                    )
                }

                Mock -CommandName Set-SqlDscDatabaseProperty
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabaseInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            AutoClose = $true
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscDatabase -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Set-SqlDscDatabaseProperty -ParameterFilter {
                        $AutoClose -eq $true
                    } -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}

Describe 'SqlDatabase\AssertProperties()' -Tag 'AssertProperties' {
    Context 'When trying to change CatalogCollation on existing database' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                    Name             = 'TestDatabase'
                    InstanceName     = 'NamedInstance'
                    CatalogCollation = 'SqlLatin1GeneralCp1CiAs'
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    } -PassThru
            }

            Mock -CommandName Get-SqlDscDatabase -MockWith {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                    (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                    'TestDatabase'
                )

                $mockDatabaseObject.CatalogCollation = [Microsoft.SqlServer.Management.Smo.CatalogCollationType]::DatabaseDefault

                return $mockDatabaseObject
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = Get-InvalidOperationRecord -Message (
                    $mockSqlDatabaseInstance.localizedData.CatalogCollationCannotBeChanged
                )

                {
                    $script:mockSqlDatabaseInstance.AssertProperties(
                        @{
                            CatalogCollation = 'SqlLatin1GeneralCp1CiAs'
                        }
                    )
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When trying to change IsLedger on existing database' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                    Name         = 'TestDatabase'
                    InstanceName = 'NamedInstance'
                    IsLedger     = $true
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    } -PassThru
            }

            Mock -CommandName Get-SqlDscDatabase -MockWith {
                $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database' -ArgumentList @(
                    (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                    'TestDatabase'
                )

                $mockDatabaseObject.IsLedger = $false

                return $mockDatabaseObject
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = Get-InvalidOperationRecord -Message (
                    $mockSqlDatabaseInstance.localizedData.IsLedgerCannotBeChanged
                )

                {
                    $script:mockSqlDatabaseInstance.AssertProperties(
                        @{
                            IsLedger = $true
                        }
                    )
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When specifying an invalid collation' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                    Name         = 'TestDatabase'
                    InstanceName = 'NamedInstance'
                    Collation    = 'Invalid_Collation'
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        $serverObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'

                        $serverObject |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'EnumCollations' -Value {
                                return @(
                                    [PSCustomObject] @{ Name = 'SQL_Latin1_General_CP1_CI_AS' }
                                    [PSCustomObject] @{ Name = 'Finnish_Swedish_CI_AS' }
                                )
                            }

                        return $serverObject
                    } -PassThru
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = Get-InvalidArgumentRecord -ArgumentName 'Collation' -Message (
                    $mockSqlDatabaseInstance.localizedData.InvalidCollation -f 'Invalid_Collation', 'NamedInstance'
                )

                {
                    $script:mockSqlDatabaseInstance.AssertProperties(
                        @{
                            Collation = 'Invalid_Collation'
                        }
                    )
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When specifying an invalid compatibility level' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabaseInstance = [SqlDatabase] @{
                    Name               = 'TestDatabase'
                    InstanceName       = 'NamedInstance'
                    CompatibilityLevel = 'Version80'
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    } -PassThru
            }

            Mock -CommandName Get-SqlDscCompatibilityLevel -MockWith {
                return @(
                    [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]::Version150
                    [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]::Version140
                )
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = Get-InvalidArgumentRecord -ArgumentName 'CompatibilityLevel' -Message (
                    $mockSqlDatabaseInstance.localizedData.InvalidCompatibilityLevel -f 'Version80', 'NamedInstance'
                )

                {
                    $script:mockSqlDatabaseInstance.AssertProperties(
                        @{
                            CompatibilityLevel = 'Version80'
                        }
                    )
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }
}
