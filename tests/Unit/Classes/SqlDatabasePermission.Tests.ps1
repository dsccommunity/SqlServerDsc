<#
    .SYNOPSIS
        Unit test for DSC_SqlDatabasePermission DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../TestHelpers/CommonTestHelper.psm1')

    # # Loading mocked classes
    # Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlDatabasePermission' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { [SqlDatabasePermission]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $instance = [SqlDatabasePermission]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                $instance = [SqlDatabasePermission]::new()
                $instance.GetType().Name | Should -Be 'SqlDatabasePermission'
            }
        }
    }
}

Describe 'SqlDatabasePermission\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        Context 'When the desired permission should exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Name         = 'MockUserName'
                        DatabaseName = 'MockDatabaseName'
                        InstanceName = 'NamedInstance'
                        Permission   = [DatabasePermission[]] @(
                            [DatabasePermission] @{
                                State      = 'Grant'
                                Permission = @('Connect')
                            }
                        )
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockSqlDatabasePermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                InstanceName = 'NamedInstance'
                                DatabaseName = 'MockDatabaseName'
                                Name         = 'MockUserName'
                                ServerName   = 'localhost'
                                Permission   = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @('Connect')
                                    }
                                )
                            }
                        }
                }
            }

            It 'Should return the state as present' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabasePermissionInstance.Get()

                    $currentState.Ensure | Should -Be 'Present'
                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.DatabaseName | Should -Be 'MockDatabaseName'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be 'localhost'
                    $currentState.Credential | Should -BeNullOrEmpty
                    $currentState.Reasons | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'

                    $currentState.Permission[0].State | Should -Be 'Grant'
                    $currentState.Permission[0].Permission | Should -Be 'Connect'
                }
            }
        }

        Context 'When the desired permission should not exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Ensure       = 'Absent'
                        Name         = 'MockUserName'
                        DatabaseName = 'MockDatabaseName'
                        InstanceName = 'NamedInstance'
                        Permission   = [DatabasePermission[]] @()
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockSqlDatabasePermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                InstanceName = 'NamedInstance'
                                DatabaseName = 'MockDatabaseName'
                                Name         = 'MockUserName'
                                ServerName   = 'localhost'
                                Permission   = [DatabasePermission[]] @()
                            }
                        }
                }
            }

            It 'Should return the state as absent' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabasePermissionInstance.Get()

                    $currentState.Ensure | Should -Be 'Absent'
                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.DatabaseName | Should -Be 'MockDatabaseName'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be 'localhost'
                    $currentState.Credential | Should -BeNullOrEmpty
                    $currentState.Reasons | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'

                    $currentState.Permission | Should -BeNullOrEmpty
                }
            }
        }
    }
}
