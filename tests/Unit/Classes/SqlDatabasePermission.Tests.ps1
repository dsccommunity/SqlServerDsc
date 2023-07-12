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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
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
        Context 'When the desired permission exist' {
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

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabasePermissionInstance.Get()

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

        Context 'When the desired permission exist and using parameter Credential' {
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

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabasePermissionInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.DatabaseName | Should -Be 'MockDatabaseName'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)

                    $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]

                    $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'

                    $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'

                    $currentState.Permission[0].State | Should -Be 'Grant'
                    $currentState.Permission[0].Permission | Should -Be 'Connect'

                    $currentState.Reasons | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the desired permission exist' {
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
                                        Permission = @('Connect', 'Update')
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

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlDatabasePermissionInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.DatabaseName | Should -Be 'MockDatabaseName'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'DatabasePermission[]'

                    $currentState.Permission[0].State | Should -Be 'Grant'
                    $currentState.Permission[0].Permission | Should -Contain 'Connect'
                    $currentState.Permission[0].Permission | Should -Contain 'Update'

                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'SqlDatabasePermission:SqlDatabasePermission:Permission'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property Permission should be [{"State":"Grant","Permission":["Connect"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}], but was [{"State":"Grant","Permission":["Connect","Update"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}]'
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
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'Grant'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Update = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'Grant'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2

                return $mockDatabasePermissionInfoCollection
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
                $grantState.Permission | Should -HaveCount 2
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
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true
                $mockDatabasePermissionSet1.Update = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'Grant'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Select = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'Deny'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2

                return $mockDatabasePermissionInfoCollection
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

    Context 'When using parameter PermissionToInclude' {
        Context 'When the system is in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Name                = 'MockUserName'
                        DatabaseName        = 'MockDatabaseName'
                        InstanceName        = 'NamedInstance'
                        PermissionToInclude = [DatabasePermission] @{
                            State      = 'Grant'
                            Permission = 'update'
                        }
                    }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Get-SqlDscDatabasePermission -MockWith {
                    [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                    $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                    $mockDatabasePermissionSet1.Connect = $true
                    $mockDatabasePermissionSet1.Update = $true

                    $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                    $mockDatabasePermissionInfo1.PermissionState = 'Grant'
                    $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                    $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                    $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                    $mockDatabasePermissionSet2.Select = $true

                    $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                    $mockDatabasePermissionInfo2.PermissionState = 'Deny'
                    $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                    $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2

                    return $mockDatabasePermissionInfoCollection
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

                    $currentState.PermissionToInclude | Should -HaveCount 1
                    $currentState.PermissionToInclude[0].State | Should -Be 'Grant'
                    $currentState.PermissionToInclude[0].Permission | Should -Be 'Update'
                }
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Name                = 'MockUserName'
                        DatabaseName        = 'MockDatabaseName'
                        InstanceName        = 'NamedInstance'
                        PermissionToInclude = [DatabasePermission] @{
                            State      = 'Grant'
                            Permission = 'alter'
                        }
                    }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Get-SqlDscDatabasePermission -MockWith {
                    [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                    $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                    $mockDatabasePermissionSet1.Connect = $true
                    $mockDatabasePermissionSet1.Update = $true

                    $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                    $mockDatabasePermissionInfo1.PermissionState = 'Grant'
                    $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                    $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                    $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                    $mockDatabasePermissionSet2.Select = $true

                    $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                    $mockDatabasePermissionInfo2.PermissionState = 'Deny'
                    $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                    $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2

                    return $mockDatabasePermissionInfoCollection
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

                    $currentState.PermissionToInclude | Should -HaveCount 1
                    $currentState.PermissionToInclude[0].State | Should -Be 'Grant'
                    $currentState.PermissionToInclude[0].Permission | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When using parameter PermissionToExclude' {
        Context 'When the system is in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Name                = 'MockUserName'
                        DatabaseName        = 'MockDatabaseName'
                        InstanceName        = 'NamedInstance'
                        PermissionToExclude = [DatabasePermission] @{
                            State      = 'Grant'
                            Permission = 'alter'
                        }
                    }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Get-SqlDscDatabasePermission -MockWith {
                    [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                    $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                    $mockDatabasePermissionSet1.Connect = $true
                    $mockDatabasePermissionSet1.Update = $true

                    $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                    $mockDatabasePermissionInfo1.PermissionState = 'Grant'
                    $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                    $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                    $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                    $mockDatabasePermissionSet2.Select = $true

                    $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                    $mockDatabasePermissionInfo2.PermissionState = 'Deny'
                    $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                    $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2

                    return $mockDatabasePermissionInfoCollection
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

                    $currentState.PermissionToExclude | Should -HaveCount 1
                    $currentState.PermissionToExclude[0].State | Should -Be 'Grant'
                    $currentState.PermissionToExclude[0].Permission | Should -Be 'Alter'
                }
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Name                = 'MockUserName'
                        DatabaseName        = 'MockDatabaseName'
                        InstanceName        = 'NamedInstance'
                        PermissionToExclude = [DatabasePermission] @{
                            State      = 'Grant'
                            Permission = 'update'
                        }
                    }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Get-SqlDscDatabasePermission -MockWith {
                    [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                    $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                    $mockDatabasePermissionSet1.Connect = $true
                    $mockDatabasePermissionSet1.Update = $true

                    $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                    $mockDatabasePermissionInfo1.PermissionState = 'Grant'
                    $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                    $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                    $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                    $mockDatabasePermissionSet2.Select = $true

                    $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                    $mockDatabasePermissionInfo2.PermissionState = 'Deny'
                    $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                    $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2

                    return $mockDatabasePermissionInfoCollection
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

                    $currentState.PermissionToExclude | Should -HaveCount 1
                    $currentState.PermissionToExclude[0].State | Should -Be 'Grant'
                    $currentState.PermissionToExclude[0].Permission | Should -BeNullOrEmpty
                }
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
                            Property      = 'Permission'
                            ExpectedValue = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State      = 'Grant'
                                    Permission = @('Connect', 'Update')
                                }
                            )
                            ActualValue   = [DatabasePermission[]] @(
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
                            Property      = 'Permission'
                            ExpectedValue = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State      = 'Grant'
                                    Permission = @('Connect', 'Update')
                                }
                            )
                            ActualValue   = [DatabasePermission[]] @(
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

Describe 'SqlDatabasePermission\Modify()' -Tag 'Modify' {
    Context 'When the database principal does not exist' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # This test does not set a desired state as it is not necessary for this test.
                $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                    Name         = 'MockUserName'
                    DatabaseName = 'MockDatabaseName'
                    InstanceName = 'NamedInstance'
                    # Credential is set to increase code coverage.
                    Credential   = [System.Management.Automation.PSCredential]::new(
                        'MyCredentialUserName',
                        [SecureString]::new()
                    )
                }
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }

            Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $mockSqlDatabasePermissionInstance.localizedData.NameIsMissing
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockErrorMessage -f @(
                    'MockUserName'
                    'MockDatabaseName'
                    'NamedInstance'
                )
            )

            InModuleScope -ScriptBlock {
                {
                    # This test does not pass any properties to set as it is not necessary for this test.
                    $mockSqlDatabasePermissionInstance.Modify(@{
                            Permission = [DatabasePermission[]] @()
                        })
                } | Should -Throw -ExpectedMessage $mockErrorRecord
            }
        }
    }

    Context 'When property Permission is not in desired state' {
        Context 'When a desired permissions is missing from the current state' {
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
                                Permission = @('Update')
                            }
                            [DatabasePermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
                    $script:mockSqlDatabasePermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @()
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

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscDatabasePermission
            }

            It 'Should call the correct mock with the correct parameter values' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlDatabasePermissionInstance.Modify(@{
                                Permission = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @('Connect')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('Update')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            })
                    } | Should -Not -Throw
                }

                # Grants
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.Connect -eq $true
                } -Exactly -Times 1 -Scope It

                # GrantWithGrants
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.Update -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When a desired permission is missing from the current state and there are four permissions that should not exist in the current state' {
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

                    # This mocks the method GetCurrentState().
                    $script:mockSqlDatabasePermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @('Alter', 'Select')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('Delete')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'Deny'
                                        Permission = @('CreateDatabase')
                                    }
                                )
                            }
                        }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscDatabasePermission
            }

            It 'Should call the correct mock with the correct parameter values' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlDatabasePermissionInstance.Modify(@{
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
                            })
                    } | Should -Not -Throw
                }

                # Revoking Grants
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.Alter -eq $true -and $Permission.Select -eq $true
                } -Exactly -Times 1 -Scope It

                # Revoking GrantWithGrants
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.Delete -eq $true
                } -Exactly -Times 1 -Scope It

                # Revoking Denies
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.CreateDatabase -eq $true
                } -Exactly -Times 1 -Scope It

                # Adding new Grant
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.Connect -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When property PermissionToInclude is not in desired state' {
        Context 'When a desired permissions is missing from the current state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Name                = 'MockUserName'
                        DatabaseName        = 'MockDatabaseName'
                        InstanceName        = 'NamedInstance'
                        PermissionToInclude = [DatabasePermission[]] @(
                            [DatabasePermission] @{
                                State      = 'Grant'
                                Permission = @('Connect')
                            }
                            [DatabasePermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @('Update')
                            }
                            [DatabasePermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
                    $script:mockSqlDatabasePermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @()
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

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscDatabasePermission
            }

            It 'Should call the correct mock with the correct parameter values' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlDatabasePermissionInstance.Modify(@{
                                PermissionToInclude = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @('Connect')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('Update')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            })
                    } | Should -Not -Throw
                }

                # Grants
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.Connect -eq $true
                } -Exactly -Times 1 -Scope It

                # GrantWithGrants
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.Update -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When property PermissionToExclude is not in desired state' {
        Context 'When a desired permissions is missing from the current state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{
                        Name                = 'MockUserName'
                        DatabaseName        = 'MockDatabaseName'
                        InstanceName        = 'NamedInstance'
                        PermissionToExclude = [DatabasePermission[]] @(
                            [DatabasePermission] @{
                                State      = 'Grant'
                                Permission = @('Connect')
                            }
                            [DatabasePermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @('Update')
                            }
                            [DatabasePermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
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
                                        Permission = @('Update')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            }
                        }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscDatabasePermission
            }

            It 'Should call the correct mock with the correct parameter values' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlDatabasePermissionInstance.Modify(@{
                                PermissionToExclude = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @('Connect')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('Update')
                                    }
                                    [DatabasePermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            })
                    } | Should -Not -Throw
                }

                # Revoking Grants
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.Connect -eq $true
                } -Exactly -Times 1 -Scope It

                # Revoking GrantWithGrants
                Should -Invoke -CommandName Set-SqlDscDatabasePermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.Update -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When Set-SqlDscDatabasePermission fails to change permission' {
        Context 'When granting permissions' {
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

                    # This mocks the method GetCurrentState().
                    $script:mockSqlDatabasePermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @()
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

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscDatabasePermission -MockWith {
                    throw 'Mocked error'
                }
            }

            It 'Should throw the correct error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $mockSqlDatabasePermissionInstance.localizedData.FailedToSetPermission
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockErrorMessage -f @(
                        'MockUserName'
                        'MockDatabaseName'
                    )
                )

                InModuleScope -ScriptBlock {
                    {
                        $mockSqlDatabasePermissionInstance.Modify(@{
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
                            })
                    } | Should -Throw -ExpectedMessage $mockErrorRecord
                }
            }
        }

        Context 'When revoking permissions' {
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

                    # This mocks the method GetCurrentState().
                    $script:mockSqlDatabasePermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [DatabasePermission[]] @(
                                    [DatabasePermission] @{
                                        State      = 'Grant'
                                        Permission = @('Update')
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

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Test-SqlDscIsDatabasePrincipal -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscDatabasePermission -MockWith {
                    throw 'Mocked error'
                }
            }

            It 'Should throw the correct error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $mockSqlDatabasePermissionInstance.localizedData.FailedToRevokePermissionFromCurrentState
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockErrorMessage -f @(
                        'MockUserName'
                        'MockDatabaseName'
                    )
                )

                InModuleScope -ScriptBlock {
                    {
                        $mockSqlDatabasePermissionInstance.Modify(@{
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
                            })
                    } | Should -Throw -ExpectedMessage $mockErrorRecord
                }
            }
        }
    }
}

Describe 'SqlDatabasePermission\AssertProperties()' -Tag 'AssertProperties' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlDatabasePermissionInstance = [SqlDatabasePermission] @{}
        }
    }

    <#
        These tests just check for the string localized ID. Since the error is part
        of a command outside of SqlServerDsc, a small changes to the localized
        string should not fail these tests.
    #>
    Context 'When passing mutually exclusive parameters' {
        Context 'When passing Permission and PermissionToInclude' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlDatabasePermissionInstance.AssertProperties(@{
                                Permission          = [DatabasePermission[]] @([DatabasePermission] @{})
                                PermissionToInclude = [DatabasePermission[]] @([DatabasePermission] @{})
                            })
                    } | Should -Throw -ExpectedMessage '*DRC0010*'
                }
            }
        }

        Context 'When passing Permission and PermissionToExclude' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlDatabasePermissionInstance.AssertProperties(@{
                                Permission          = [DatabasePermission[]] @([DatabasePermission] @{})
                                PermissionToExclude = [DatabasePermission[]] @([DatabasePermission] @{})
                            })
                    } | Should -Throw -ExpectedMessage '*DRC0010*'
                }
            }
        }
    }

    Context 'When not passing any permission property' {
        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $mockSqlDatabasePermissionInstance.localizedData.MustAssignOnePermissionProperty
            }

            InModuleScope -ScriptBlock {
                {
                    $mockSqlDatabasePermissionInstance.AssertProperties(@{})
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When a permission Property contain the same State twice' {
        It 'Should throw the correct error for property <MockPropertyName>' -ForEach @(
            @{
                MockPropertyName = 'Permission'
            }
            @{
                MockPropertyName = 'PermissionToInclude'
            }
            @{
                MockPropertyName = 'PermissionToExclude'
            }
        ) {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $mockSqlDatabasePermissionInstance.localizedData.DuplicatePermissionState
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $mockSqlDatabasePermissionInstance.AssertProperties(@{
                            $MockPropertyName = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State = 'Grant'
                                }
                                [DatabasePermission] @{
                                    State = 'Grant'
                                }
                            )
                        })
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When the property Permission is missing a state' {
        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $mockSqlDatabasePermissionInstance.localizedData.MissingPermissionState
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $mockSqlDatabasePermissionInstance.AssertProperties(@{
                            Permission = [DatabasePermission[]] @(
                                # Missing state Deny.
                                [DatabasePermission] @{
                                    State = 'Grant'
                                }
                                [DatabasePermission] @{
                                    State = 'GrantWithGrant'
                                }
                            )
                        })
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When a permission Property contain the same permission name twice' {
        It 'Should throw the correct error for property <MockPropertyName>' -ForEach @(
            @{
                MockPropertyName = 'Permission'
            }
            @{
                MockPropertyName = 'PermissionToInclude'
            }
            @{
                MockPropertyName = 'PermissionToExclude'
            }
        ) {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $mockSqlDatabasePermissionInstance.localizedData.DuplicatePermissionBetweenState
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $mockSqlDatabasePermissionInstance.AssertProperties(@{
                            $MockPropertyName = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State      = 'Grant'
                                    Permission = 'Select'
                                }
                                [DatabasePermission] @{
                                    State      = 'Deny'
                                    Permission = 'Select'
                                }
                            )
                        })
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When a permission Property does not specify any permission name' {
        It 'Should throw the correct error for property <MockPropertyName>' -ForEach @(
            @{
                MockPropertyName = 'PermissionToInclude'
            }
            @{
                MockPropertyName = 'PermissionToExclude'
            }
        ) {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $mockSqlDatabasePermissionInstance.localizedData.MustHaveMinimumOnePermissionInState
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $mockSqlDatabasePermissionInstance.AssertProperties(@{
                            $MockPropertyName = [DatabasePermission[]] @(
                                [DatabasePermission] @{
                                    State      = 'Grant'
                                    <#
                                    This should not be able to be $null since the property
                                    is mandatory but do allow empty collection. So no need
                                    to test using $null value.
                                #>
                                    Permission = @()
                                }
                                [DatabasePermission] @{
                                    State      = 'Deny'
                                    Permission = 'Select'
                                }
                            )
                        })
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }
}
