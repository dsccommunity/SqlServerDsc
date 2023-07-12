<#
    .SYNOPSIS
        Unit test for DSC_SqlPermission DSC resource.
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

Describe 'SqlPermission' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { [SqlPermission]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $instance = [SqlPermission]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                $instance = [SqlPermission]::new()
                $instance.GetType().Name | Should -Be 'SqlPermission'
            }
        }
    }
}

Describe 'SqlPermission\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        Context 'When the desired permission exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                        Permission   = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission] @{
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
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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
                    $currentState = $script:mockSqlPermissionInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty
                    $currentState.Reasons | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'

                    $currentState.Permission[0].State | Should -Be 'Grant'
                    $currentState.Permission[0].Permission | Should -Be 'ConnectSql'
                }
            }
        }

        Context 'When the desired permission exist and using parameter Credential' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                        Credential   = [System.Management.Automation.PSCredential]::new(
                            'MyCredentialUserName',
                            [SecureString]::new()
                        )
                        Permission   = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission] @{
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
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Credential = $this.Credential
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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
                    $currentState = $script:mockSqlPermissionInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)

                    $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]

                    $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'

                    $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'

                    $currentState.Permission[0].State | Should -Be 'Grant'
                    $currentState.Permission[0].Permission | Should -Be 'ConnectSql'

                    $currentState.Reasons | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the desired permission exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                        Permission   = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission] @{
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
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql', 'AlterAnyEndpoint')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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
                    $currentState = $script:mockSqlPermissionInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.Name | Should -Be 'MockUserName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'

                    $currentState.Permission[0].State | Should -Be 'Grant'
                    $currentState.Permission[0].Permission | Should -Contain 'ConnectSql'
                    $currentState.Permission[0].Permission | Should -Contain 'AlterAnyEndpoint'

                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'SqlPermission:SqlPermission:Permission'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property Permission should be [{"State":"Grant","Permission":["ConnectSql"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}], but was [{"State":"Grant","Permission":["ConnectSql","AlterAnyEndpoint"]},{"State":"GrantWithGrant","Permission":[]},{"State":"Deny","Permission":[]}]'
                }
            }
        }
    }
}

Describe 'SqlPermission\GetCurrentState()' -Tag 'GetCurrentState' {
    Context 'When there are no permission in the current state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlPermissionInstance = [SqlPermission] @{
                    Name         = 'MockUserName'
                    InstanceName = 'NamedInstance'
                }
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }

            Mock -CommandName Get-SqlDscServerPermission
        }

        It 'Should return empty collections for each state' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlPermissionInstance.GetCurrentState(@{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                    })

                $currentState.Credential | Should -BeNullOrEmpty

                $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'
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
                    $script:mockSqlPermissionInstance.Credential = [System.Management.Automation.PSCredential]::new(
                        'MyCredentialUserName',
                        [SecureString]::new()
                    )

                    $currentState = $script:mockSqlPermissionInstance.GetCurrentState(@{
                            Name         = 'MockUserName'
                            InstanceName = 'NamedInstance'
                        })

                    $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]

                    $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'

                    $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'
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
                $script:mockSqlPermissionInstance = [SqlPermission] @{
                    Name         = 'MockUserName'
                    InstanceName = 'NamedInstance'
                }
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'Grant'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.AlterAnyEndpoint = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'Grant'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2

                return $mockServerPermissionInfoCollection
            }
        }

        It 'Should return correct values for state Grant and empty collections for the two other states' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlPermissionInstance.GetCurrentState(@{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                    })

                $currentState.Credential | Should -BeNullOrEmpty

                $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'
                $currentState.Permission | Should -HaveCount 3

                $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                $grantState | Should -Not -BeNullOrEmpty
                $grantState.State | Should -Be 'Grant'
                $grantState.Permission | Should -HaveCount 2
                $grantState.Permission | Should -Contain 'ConnectSql'
                $grantState.Permission | Should -Contain 'AlterAnyEndpoint'

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
                $script:mockSqlPermissionInstance = [SqlPermission] @{
                    Name         = 'MockUserName'
                    InstanceName = 'NamedInstance'
                }
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true
                $mockServerPermissionSet1.AlterAnyEndpoint = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'Grant'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.ViewServerState = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'Deny'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2

                return $mockServerPermissionInfoCollection
            }
        }

        It 'Should return correct values for the states Grant and Deny and empty collections for the state GrantWithGrant' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlPermissionInstance.GetCurrentState(@{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                    })

                $currentState.Credential | Should -BeNullOrEmpty

                $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'
                $currentState.Permission | Should -HaveCount 3

                $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                $grantState | Should -Not -BeNullOrEmpty
                $grantState.State | Should -Be 'Grant'
                $grantState.Permission | Should -Contain 'ConnectSql'
                $grantState.Permission | Should -Contain 'AlterAnyEndpoint'

                $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                $grantWithGrantState | Should -Not -BeNullOrEmpty
                $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                $grantWithGrantState.Permission | Should -BeNullOrEmpty

                $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                $denyState | Should -Not -BeNullOrEmpty
                $denyState.State | Should -Be 'Deny'
                $denyState.Permission | Should -Contain 'ViewServerState'
            }
        }
    }

    Context 'When using parameter PermissionToInclude' {
        Context 'When the system is in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name                = 'MockUserName'
                        InstanceName        = 'NamedInstance'
                        PermissionToInclude = [ServerPermission] @{
                            State      = 'Grant'
                            Permission = 'AlterAnyEndpoint'
                        }
                    }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                    $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockServerPermissionSet1.ConnectSql = $true
                    $mockServerPermissionSet1.AlterAnyEndpoint = $true

                    $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockServerPermissionInfo1.PermissionState = 'Grant'
                    $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                    $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                    $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockServerPermissionSet2.ViewServerState = $true

                    $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockServerPermissionInfo2.PermissionState = 'Deny'
                    $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                    $mockServerPermissionInfoCollection += $mockServerPermissionInfo2

                    return $mockServerPermissionInfoCollection
                }
            }

            It 'Should return correct values for the states Grant and Deny and empty collections for the state GrantWithGrant' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlPermissionInstance.GetCurrentState(@{
                            Name         = 'MockUserName'
                            InstanceName = 'NamedInstance'
                        })

                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'
                    $currentState.Permission | Should -HaveCount 3

                    $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                    $grantState | Should -Not -BeNullOrEmpty
                    $grantState.State | Should -Be 'Grant'
                    $grantState.Permission | Should -Contain 'ConnectSql'
                    $grantState.Permission | Should -Contain 'AlterAnyEndpoint'

                    $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                    $grantWithGrantState | Should -Not -BeNullOrEmpty
                    $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                    $grantWithGrantState.Permission | Should -BeNullOrEmpty

                    $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                    $denyState | Should -Not -BeNullOrEmpty
                    $denyState.State | Should -Be 'Deny'
                    $denyState.Permission | Should -Contain 'ViewServerState'

                    $currentState.PermissionToInclude | Should -HaveCount 1
                    $currentState.PermissionToInclude[0].State | Should -Be 'Grant'
                    $currentState.PermissionToInclude[0].Permission | Should -Be 'AlterAnyEndpoint'
                }
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name                = 'MockUserName'
                        InstanceName        = 'NamedInstance'
                        PermissionToInclude = [ServerPermission] @{
                            State      = 'Grant'
                            Permission = 'AlterAnyAvailabilityGroup'
                        }
                    }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                    $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockServerPermissionSet1.ConnectSql = $true
                    $mockServerPermissionSet1.AlterAnyEndpoint = $true

                    $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockServerPermissionInfo1.PermissionState = 'Grant'
                    $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                    $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                    $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockServerPermissionSet2.ViewServerState = $true

                    $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockServerPermissionInfo2.PermissionState = 'Deny'
                    $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                    $mockServerPermissionInfoCollection += $mockServerPermissionInfo2

                    return $mockServerPermissionInfoCollection
                }
            }

            It 'Should return correct values for the states Grant and Deny and empty collections for the state GrantWithGrant' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlPermissionInstance.GetCurrentState(@{
                            Name         = 'MockUserName'
                            InstanceName = 'NamedInstance'
                        })

                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'
                    $currentState.Permission | Should -HaveCount 3

                    $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                    $grantState | Should -Not -BeNullOrEmpty
                    $grantState.State | Should -Be 'Grant'
                    $grantState.Permission | Should -Contain 'ConnectSql'
                    $grantState.Permission | Should -Contain 'AlterAnyEndpoint'

                    $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                    $grantWithGrantState | Should -Not -BeNullOrEmpty
                    $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                    $grantWithGrantState.Permission | Should -BeNullOrEmpty

                    $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                    $denyState | Should -Not -BeNullOrEmpty
                    $denyState.State | Should -Be 'Deny'
                    $denyState.Permission | Should -Contain 'ViewServerState'

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
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name                = 'MockUserName'
                        InstanceName        = 'NamedInstance'
                        PermissionToExclude = [ServerPermission] @{
                            State      = 'Grant'
                            Permission = 'AlterAnyAvailabilityGroup'
                        }
                    }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                    $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockServerPermissionSet1.ConnectSql = $true
                    $mockServerPermissionSet1.AlterAnyEndpoint = $true

                    $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockServerPermissionInfo1.PermissionState = 'Grant'
                    $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                    $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                    $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockServerPermissionSet2.ViewServerState = $true

                    $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockServerPermissionInfo2.PermissionState = 'Deny'
                    $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                    $mockServerPermissionInfoCollection += $mockServerPermissionInfo2

                    return $mockServerPermissionInfoCollection
                }
            }

            It 'Should return correct values for the states Grant and Deny and empty collections for the state GrantWithGrant' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlPermissionInstance.GetCurrentState(@{
                            Name         = 'MockUserName'
                            InstanceName = 'NamedInstance'
                        })

                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'
                    $currentState.Permission | Should -HaveCount 3

                    $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                    $grantState | Should -Not -BeNullOrEmpty
                    $grantState.State | Should -Be 'Grant'
                    $grantState.Permission | Should -Contain 'ConnectSql'
                    $grantState.Permission | Should -Contain 'AlterAnyEndpoint'

                    $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                    $grantWithGrantState | Should -Not -BeNullOrEmpty
                    $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                    $grantWithGrantState.Permission | Should -BeNullOrEmpty

                    $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                    $denyState | Should -Not -BeNullOrEmpty
                    $denyState.State | Should -Be 'Deny'
                    $denyState.Permission | Should -Contain 'ViewServerState'

                    $currentState.PermissionToExclude | Should -HaveCount 1
                    $currentState.PermissionToExclude[0].State | Should -Be 'Grant'
                    $currentState.PermissionToExclude[0].Permission | Should -Be 'AlterAnyAvailabilityGroup'
                }
            }
        }

        Context 'When the system is not in the desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name                = 'MockUserName'
                        InstanceName        = 'NamedInstance'
                        PermissionToExclude = [ServerPermission] @{
                            State      = 'Grant'
                            Permission = 'AlterAnyEndpoint'
                        }
                    }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                    $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockServerPermissionSet1.ConnectSql = $true
                    $mockServerPermissionSet1.AlterAnyEndpoint = $true

                    $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockServerPermissionInfo1.PermissionState = 'Grant'
                    $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                    $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                    $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                    $mockServerPermissionSet2.ViewServerState = $true

                    $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                    $mockServerPermissionInfo2.PermissionState = 'Deny'
                    $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                    $mockServerPermissionInfoCollection += $mockServerPermissionInfo2

                    return $mockServerPermissionInfoCollection
                }
            }

            It 'Should return correct values for the states Grant and Deny and empty collections for the state GrantWithGrant' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlPermissionInstance.GetCurrentState(@{
                            Name         = 'MockUserName'
                            InstanceName = 'NamedInstance'
                        })

                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.Permission.GetType().FullName | Should -Be 'ServerPermission[]'
                    $currentState.Permission | Should -HaveCount 3

                    $grantState = $currentState.Permission.Where({ $_.State -eq 'Grant' })

                    $grantState | Should -Not -BeNullOrEmpty
                    $grantState.State | Should -Be 'Grant'
                    $grantState.Permission | Should -Contain 'ConnectSql'
                    $grantState.Permission | Should -Contain 'AlterAnyEndpoint'

                    $grantWithGrantState = $currentState.Permission.Where({ $_.State -eq 'GrantWithGrant' })

                    $grantWithGrantState | Should -Not -BeNullOrEmpty
                    $grantWithGrantState.State | Should -Be 'GrantWithGrant'
                    $grantWithGrantState.Permission | Should -BeNullOrEmpty

                    $denyState = $currentState.Permission.Where({ $_.State -eq 'Deny' })

                    $denyState | Should -Not -BeNullOrEmpty
                    $denyState.State | Should -Be 'Deny'
                    $denyState.Permission | Should -Contain 'ViewServerState'

                    $currentState.PermissionToExclude | Should -HaveCount 1
                    $currentState.PermissionToExclude[0].State | Should -Be 'Grant'
                    $currentState.PermissionToExclude[0].Permission | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'SqlPermission\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlPermissionInstance = [SqlPermission] @{
                Name         = 'MockUserName'
                InstanceName = 'NamedInstance'
                Permission   = [ServerPermission[]] @(
                    [ServerPermission] @{
                        State      = 'Grant'
                        Permission = @('ConnectSql')
                    }
                    [ServerPermission] @{
                        State      = 'GrantWithGrant'
                        Permission = @()
                    }
                    [ServerPermission] @{
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
                $script:mockSqlPermissionInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockSqlPermissionInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 0
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlPermissionInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property      = 'Permission'
                            ExpectedValue = [ServerPermission[]] @(
                                [ServerPermission] @{
                                    State      = 'Grant'
                                    Permission = @('ConnectSql', 'AlterAnyEndpoint')
                                }
                            )
                            ActualValue   = [ServerPermission[]] @(
                                [ServerPermission] @{
                                    State      = 'Grant'
                                    Permission = @('ConnectSql')
                                }
                            )
                        }
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockSqlPermissionInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'SqlPermission\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlPermissionInstance = [SqlPermission] @{
                Name         = 'MockUserName'
                InstanceName = 'NamedInstance'
                Permission   = [ServerPermission[]] @(
                    [ServerPermission] @{
                        State      = 'Grant'
                        Permission = @('ConnectSql')
                    }
                    [ServerPermission] @{
                        State      = 'GrantWithGrant'
                        Permission = @()
                    }
                    [ServerPermission] @{
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
                $script:mockSqlPermissionInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $script:mockSqlPermissionInstance.Test() | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlPermissionInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property      = 'Permission'
                            ExpectedValue = [ServerPermission[]] @(
                                [ServerPermission] @{
                                    State      = 'Grant'
                                    Permission = @('ConnectSql', 'AlterAnyEndpoint')
                                }
                            )
                            ActualValue   = [ServerPermission[]] @(
                                [ServerPermission] @{
                                    State      = 'Grant'
                                    Permission = @('ConnectSql')
                                }
                            )
                        }
                    }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $script:mockSqlPermissionInstance.Test() | Should -BeFalse
            }
        }
    }
}

Describe 'SqlPermission\Modify()' -Tag 'Modify' {
    Context 'When the principal does not exist' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # This test does not set a desired state as it is not necessary for this test.
                $script:mockSqlPermissionInstance = [SqlPermission] @{
                    Name         = 'MockUserName'
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

            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $mockSqlPermissionInstance.localizedData.NameIsMissing
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockErrorMessage -f @(
                    'MockUserName'
                    'NamedInstance'
                )
            )

            InModuleScope -ScriptBlock {
                {
                    # This test does not pass any properties to set as it is not necessary for this test.
                    $mockSqlPermissionInstance.Modify(@{
                            Permission = [ServerPermission[]] @()
                        })
                } | Should -Throw -ExpectedMessage $mockErrorRecord
            }
        }
    }

    Context 'When property Permission is not in desired state' {
        Context 'When a desired permissions is missing from the current state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                        Permission   = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @('AlterAnyEndpoint')
                            }
                            [ServerPermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscServerPermission
            }

            It 'Should call the correct mock with the correct parameter values' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlPermissionInstance.Modify(@{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('AlterAnyEndpoint')
                                    }
                                    [ServerPermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            })
                    } | Should -Not -Throw
                }

                # Grants
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.ConnectSql -eq $true
                } -Exactly -Times 1 -Scope It

                # GrantWithGrants
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.AlterAnyEndpoint -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When a desired permission is missing from the current state and there are four permissions that should not exist in the current state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                        Permission   = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('AlterAnyAvailabilityGroup', 'ViewServerState')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('ControlServer')
                                    }
                                    [ServerPermission] @{
                                        State      = 'Deny'
                                        Permission = @('CreateEndpoint')
                                    }
                                )
                            }
                        }
                }

                Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscServerPermission
            }

            It 'Should call the correct mock with the correct parameter values' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlPermissionInstance.Modify(@{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            })
                    } | Should -Not -Throw
                }

                # Revoking Grants
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.AlterAnyAvailabilityGroup -eq $true -and $Permission.ViewServerState -eq $true
                } -Exactly -Times 1 -Scope It

                # Revoking GrantWithGrants
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.ControlServer -eq $true
                } -Exactly -Times 1 -Scope It

                # Revoking Denies
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.CreateEndpoint -eq $true
                } -Exactly -Times 1 -Scope It

                # Adding new Grant
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.ConnectSql -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When property PermissionToInclude is not in desired state' {
        Context 'When a desired permissions is missing from the current state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name                = 'MockUserName'
                        InstanceName        = 'NamedInstance'
                        PermissionToInclude = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @('AlterAnyEndpoint')
                            }
                            [ServerPermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscServerPermission
            }

            It 'Should call the correct mock with the correct parameter values' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlPermissionInstance.Modify(@{
                                PermissionToInclude = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('AlterAnyEndpoint')
                                    }
                                    [ServerPermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            })
                    } | Should -Not -Throw
                }

                # Grants
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.ConnectSql -eq $true
                } -Exactly -Times 1 -Scope It

                # GrantWithGrants
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Grant' -and $Permission.AlterAnyEndpoint -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When property PermissionToExclude is not in desired state' {
        Context 'When a desired permissions is missing from the current state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name                = 'MockUserName'
                        InstanceName        = 'NamedInstance'
                        PermissionToExclude = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @('AlterAnyEndpoint')
                            }
                            [ServerPermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('AlterAnyEndpoint')
                                    }
                                    [ServerPermission] @{
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

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscServerPermission
            }

            It 'Should call the correct mock with the correct parameter values' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlPermissionInstance.Modify(@{
                                PermissionToExclude = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @('AlterAnyEndpoint')
                                    }
                                    [ServerPermission] @{
                                        State      = 'Deny'
                                        Permission = @()
                                    }
                                )
                            })
                    } | Should -Not -Throw
                }

                # Revoking Grants
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.ConnectSql -eq $true
                } -Exactly -Times 1 -Scope It

                # Revoking GrantWithGrants
                Should -Invoke -CommandName Set-SqlDscServerPermission -ParameterFilter {
                    $State -eq 'Revoke' -and $Permission.AlterAnyEndpoint -eq $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When Set-SqlDscServerPermission fails to change permission' {
        Context 'When granting permissions' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                        Permission   = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscServerPermission -MockWith {
                    throw 'Mocked error'
                }
            }

            It 'Should throw the correct error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $mockSqlPermissionInstance.localizedData.FailedToSetPermission
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockErrorMessage -f @(
                        'MockUserName'
                    )
                )

                InModuleScope -ScriptBlock {
                    {
                        $mockSqlPermissionInstance.Modify(@{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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
                    $script:mockSqlPermissionInstance = [SqlPermission] @{
                        Name         = 'MockUserName'
                        InstanceName = 'NamedInstance'
                        Permission   = [ServerPermission[]] @(
                            [ServerPermission] @{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission] @{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission] @{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }

                    # This mocks the method GetCurrentState().
                    $script:mockSqlPermissionInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('AlterAnyEndpoint')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Set-SqlDscServerPermission -MockWith {
                    throw 'Mocked error'
                }
            }

            It 'Should throw the correct error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $mockSqlPermissionInstance.localizedData.FailedToRevokePermissionFromCurrentState
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockErrorMessage -f @(
                        'MockUserName'
                    )
                )

                InModuleScope -ScriptBlock {
                    {
                        $mockSqlPermissionInstance.Modify(@{
                                Permission = [ServerPermission[]] @(
                                    [ServerPermission] @{
                                        State      = 'Grant'
                                        Permission = @('ConnectSql')
                                    }
                                    [ServerPermission] @{
                                        State      = 'GrantWithGrant'
                                        Permission = @()
                                    }
                                    [ServerPermission] @{
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

Describe 'SqlPermission\AssertProperties()' -Tag 'AssertProperties' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlPermissionInstance = [SqlPermission] @{}
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
                        $mockSqlPermissionInstance.AssertProperties(@{
                                Permission          = [ServerPermission[]] @([ServerPermission] @{})
                                PermissionToInclude = [ServerPermission[]] @([ServerPermission] @{})
                            })
                    } | Should -Throw -ExpectedMessage '*DRC0010*'
                }
            }
        }

        Context 'When passing Permission and PermissionToExclude' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlPermissionInstance.AssertProperties(@{
                                Permission          = [ServerPermission[]] @([ServerPermission] @{})
                                PermissionToExclude = [ServerPermission[]] @([ServerPermission] @{})
                            })
                    } | Should -Throw -ExpectedMessage '*DRC0010*'
                }
            }
        }
    }

    Context 'When not passing any permission property' {
        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $mockSqlPermissionInstance.localizedData.MustAssignOnePermissionProperty
            }

            InModuleScope -ScriptBlock {
                {
                    $mockSqlPermissionInstance.AssertProperties(@{})
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
                $mockSqlPermissionInstance.localizedData.DuplicatePermissionState
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $mockSqlPermissionInstance.AssertProperties(@{
                            $MockPropertyName = [ServerPermission[]] @(
                                [ServerPermission] @{
                                    State = 'Grant'
                                }
                                [ServerPermission] @{
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
                $mockSqlPermissionInstance.localizedData.MissingPermissionState
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $mockSqlPermissionInstance.AssertProperties(@{
                            Permission = [ServerPermission[]] @(
                                # Missing state Deny.
                                [ServerPermission] @{
                                    State = 'Grant'
                                }
                                [ServerPermission] @{
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
                $mockSqlPermissionInstance.localizedData.DuplicatePermissionBetweenState
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $mockSqlPermissionInstance.AssertProperties(@{
                            $MockPropertyName = [ServerPermission[]] @(
                                [ServerPermission] @{
                                    State      = 'Grant'
                                    Permission = 'ViewServerState'
                                }
                                [ServerPermission] @{
                                    State      = 'Deny'
                                    Permission = 'ViewServerState'
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
                $mockSqlPermissionInstance.localizedData.MustHaveMinimumOnePermissionInState
            }

            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $mockSqlPermissionInstance.AssertProperties(@{
                            $MockPropertyName = [ServerPermission[]] @(
                                [ServerPermission] @{
                                    State      = 'Grant'
                                    <#
                                    This should not be able to be $null since the property
                                    is mandatory but do allow empty collection. So no need
                                    to test using $null value.
                                #>
                                    Permission = @()
                                }
                                [ServerPermission] @{
                                    State      = 'Deny'
                                    Permission = 'ViewServerState'
                                }
                            )
                        })
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }
}
