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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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
                            [DatabasePermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [DatabasePermission] @{
                                State      = 'Deny'
                                Permission = @()
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
                                Permission = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @('Connect')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [DatabasePermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            }
                        }
                }
            }

            It 'Should return the state as present' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabasePermissionInstance.Get()

                    #$currentState.Ensure | Should -Be ([Ensure]::Present)
                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.DatabaseName | Should -Be 'MockDatabaseName'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty
                    $currentState.Reasons | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'

                    $currentState.Permission[0].State | Should -Be 'Grant'
                    $currentState.Permission[0].Permission | Should -Be 'Connect'
                }
            }
        }

        Context 'When the desired permission should exist and using parameter Credential' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Name         = 'MockUserName'
                        DatabaseName = 'MockDatabaseName'
                        InstanceName = 'NamedInstance'
                        Credential   = [System.Management.Automation.PSCredential]::new(
                            'MyCredentialUserName',
                            [SecureString]::new()
                        )
                        Permission   = [DatabasePermission[]] @(
                            [DatabasePermission] @{
                                State      = 'Grant'
                                Permission = @('Connect')
                            }
                            [DatabasePermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [DatabasePermission] @{
                                State      = 'Deny'
                                Permission = @()
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
                                Credential = $this.Credential
                                Permission = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @('Connect')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [DatabasePermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            }
                        }
                }
            }

            It 'Should return the state as present' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabasePermissionInstance.Get()

                    #$currentState.Ensure | Should -Be ([Ensure]::Present)
                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.DatabaseName | Should -Be 'MockDatabaseName'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Reasons | Should -BeNullOrEmpty

                    $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]

                    $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'

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
                        #Ensure       = [Ensure]::Absent
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
                                Permission   = [DatabasePermission[]] @()
                            }
                        }
                }
            }

            It 'Should return the state as absent' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabasePermissionInstance.Get()

                    #$currentState.Ensure | Should -Be ([Ensure]::Absent)
                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.DatabaseName | Should -Be 'MockDatabaseName'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty
                    $currentState.Reasons | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'

                    $currentState.Permission | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'SqlDatabasePermission\GetCurrentState()' -Tag 'GetCurrentState' {
    Context 'When there are no permission in the current state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                    Name         = 'MockUserName'
                    DatabaseName = 'MockDatabaseName'
                    InstanceName = 'NamedInstance'
                }
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }

            Mock -CommandName Get-SqlDscDatabasePermission
        }

        It 'Should return empty collections for each state' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlDatabasePermissionInstance.GetCurrentState(@{
                    Name         = 'MockUserName'
                    DatabaseName = 'MockDatabaseName'
                    InstanceName = 'NamedInstance'
                })

                $currentState.Credential | Should -BeNullOrEmpty

                $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'
                $currentState.Permission | Should -HaveCount 3

                $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                $grantState | Should -Not -BeNullOrEmpty
                $grantState.State | Should -Be 'Grant'
                $grantState.Permission | Should -BeNullOrEmpty

                $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                $grantWithGrantState | Should -Not -BeNullOrEmpty
                $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                $grantWithGrantState.Permission | Should -BeNullOrEmpty

                $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                $denyState | Should -Not -BeNullOrEmpty
                $denyState.State | Should -Be 'Deny'
                $denyState.Permission | Should -BeNullOrEmpty
            }
        }

        Context 'When using property Credential' {
            It 'Should return empty collections for each state' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance.Credential = [System.Management.Automation.PSCredential]::new(
                        'MyCredentialUserName',
                        [SecureString]::new()
                    )

                    $currentState = $script:mockSqlDatabasePermissionInstance.GetCurrentState(@{
                        Name         = 'MockUserName'
                        DatabaseName = 'MockDatabaseName'
                        InstanceName = 'NamedInstance'
                    })

                    $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]

                    $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'

                    $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'
                    $currentState.Permission | Should -HaveCount 3

                    $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                    $grantState | Should -Not -BeNullOrEmpty
                    $grantState.State | Should -Be 'Grant'
                    $grantState.Permission | Should -BeNullOrEmpty

                    $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                    $grantWithGrantState | Should -Not -BeNullOrEmpty
                    $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                    $grantWithGrantState.Permission | Should -BeNullOrEmpty

                    $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                    $denyState | Should -Not -BeNullOrEmpty
                    $denyState.State | Should -Be 'Deny'
                    $denyState.Permission | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When there are permissions for only state Grant' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                    Name         = 'MockUserName'
                    DatabaseName = 'MockDatabaseName'
                    InstanceName = 'NamedInstance'
                }
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }

            Mock -CommandName Get-SqlDscDatabasePermission -MockWith {
                $mockDatabasePermissionInfo = @()

                $mockDatabasePermissionInfo += New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name PermissionType -Value (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($true, $false, $false, $false)) -PassThru |
                    Add-Member -MemberType NoteProperty -Name PermissionState -Value 'Grant' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Grantee -Value 'MockUserName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru

                $mockDatabasePermissionInfo += New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name PermissionType -Value $(New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($false, $true, $false, $false)) -PassThru |
                    Add-Member -MemberType NoteProperty -Name PermissionState -Value 'Grant' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Grantee -Value 'MockUserName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru

                return $mockDatabasePermissionInfo
            }
        }

        It 'Should return correct values for state Grant and empty collections for the two other states' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlDatabasePermissionInstance.GetCurrentState(@{
                    Name         = 'MockUserName'
                    DatabaseName = 'MockDatabaseName'
                    InstanceName = 'NamedInstance'
                })

                $currentState.Credential | Should -BeNullOrEmpty

                $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'
                $currentState.Permission | Should -HaveCount 3

                $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                $grantState | Should -Not -BeNullOrEmpty
                $grantState.State | Should -Be 'Grant'
                $grantState.Permission | Should -Contain 'Connect'
                $grantState.Permission | Should -Contain 'Update'

                $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                $grantWithGrantState | Should -Not -BeNullOrEmpty
                $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                $grantWithGrantState.Permission | Should -BeNullOrEmpty

                $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                $denyState | Should -Not -BeNullOrEmpty
                $denyState.State | Should -Be 'Deny'
                $denyState.Permission | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When there are permissions for both state Grant and Deny' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                    Name         = 'MockUserName'
                    DatabaseName = 'MockDatabaseName'
                    InstanceName = 'NamedInstance'
                }
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }

            Mock -CommandName Get-SqlDscDatabasePermission -MockWith {
                $mockDatabasePermissionInfo = @()

                $mockDatabasePermissionInfo += New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name PermissionType -Value (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($true, $false, $false, $false)) -PassThru |
                    Add-Member -MemberType NoteProperty -Name PermissionState -Value 'Grant' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Grantee -Value 'MockUserName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru

                $mockDatabasePermissionInfo += New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name PermissionType -Value $(New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($false, $true, $false, $false)) -PassThru |
                    Add-Member -MemberType NoteProperty -Name PermissionState -Value 'Grant' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Grantee -Value 'MockUserName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru

                $mockDatabasePermissionInfo += New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name PermissionType -Value $(New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet' -ArgumentList @($false, $false, $true, $false)) -PassThru |
                    Add-Member -MemberType NoteProperty -Name PermissionState -Value 'Deny' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Grantee -Value 'MockUserName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name GrantorType -Value 'User' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectClass -Value 'DatabaseName' -PassThru |
                    Add-Member -MemberType NoteProperty -Name ObjectName -Value 'AdventureWorks' -PassThru

                return $mockDatabasePermissionInfo
            }
        }

        It 'Should return correct values for the states Grant and Deny and empty collections for the state GrantWithGrant' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlDatabasePermissionInstance.GetCurrentState(@{
                    Name         = 'MockUserName'
                    DatabaseName = 'MockDatabaseName'
                    InstanceName = 'NamedInstance'
                })

                $currentState.Credential | Should -BeNullOrEmpty

                $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'
                $currentState.Permission | Should -HaveCount 3

                $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                $grantState | Should -Not -BeNullOrEmpty
                $grantState.State | Should -Be 'Grant'
                $grantState.Permission | Should -Contain 'Connect'
                $grantState.Permission | Should -Contain 'Update'

                $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                $grantWithGrantState | Should -Not -BeNullOrEmpty
                $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                $grantWithGrantState.Permission | Should -BeNullOrEmpty

                $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                $denyState | Should -Not -BeNullOrEmpty
                $denyState.State | Should -Be 'Deny'
                $denyState.Permission | Should -Contain 'Select'
            }
        }
    }
}

Describe 'SqlDatabasePermission\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                Name         = 'MockUserName'
                DatabaseName = 'MockDatabaseName'
                InstanceName = 'NamedInstance'
            } |
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
                $script:mockSqlDatabasePermissionInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 0
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property = 'Permission'
                            ExpectedValue = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State      = 'Grant'
                                    Permission = @('Connect', 'Update')
                                }
                            )
                            ActualValue = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State      = 'Grant'
                                    Permission = @('Connect')
                                }
                            )
                        }
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'SqlDatabasePermission\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                Name         = 'MockUserName'
                DatabaseName = 'MockDatabaseName'
                InstanceName = 'NamedInstance'
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance.Test() | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property = 'Permission'
                            ExpectedValue = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State      = 'Grant'
                                    Permission = @('Connect', 'Update')
                                }
                            )
                            ActualValue = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State      = 'Grant'
                                    Permission = @('Connect')
                                }
                            )
                        }
                    }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $script:mockSqlDatabasePermissionInstance.Test() | Should -BeFalse
            }
        }
    }
}
