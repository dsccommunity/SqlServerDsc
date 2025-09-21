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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-SqlDscServerPermission' -Tag 'Public' {
    Context 'When the principal does not exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $false
            }

            Mock -CommandName Test-SqlDscIsRole -MockWith {
                return $false
            }
        }

        Context 'When specifying to throw on error' {
            BeforeAll {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.ServerPermission_MissingPrincipal
                }
            }

            It 'Should throw the correct error' {
                { Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'UnknownUser' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'UnknownUser', 'MockInstance')
            }
        }

        Context 'When ignoring the error' {
            It 'Should not throw an exception and return $null' {
                Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'UnknownUser' -ErrorAction 'SilentlyContinue' |
                    Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the principal is a login' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptMethod' -Name 'EnumServerPermissions' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $SqlServerLogin
                    )

                    $mockEnumServerPermissions = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                    $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                        PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                            ConnectSql = $true
                        }
                        PermissionState = 'Grant'
                    }

                    $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                        PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                            AlterAnyAvailabilityGroup = $true
                        }
                        PermissionState = 'Grant'
                    }

                    return $mockEnumServerPermissions
                } -PassThru -Force

            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $true
            }

            Mock -CommandName Test-SqlDscIsRole -MockWith {
                return $false
            }
        }

        It 'Should return the correct values' {
            $mockResult = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'Zebes\SamusAran' -ErrorAction 'Stop'

            $mockResult | Should -HaveCount 2

            $mockResult[0].PermissionState | Should -Be 'Grant'
            $mockResult[0].PermissionType.ConnectSql | Should -BeTrue
            $mockResult[0].PermissionType.AlterAnyAvailabilityGroup | Should -BeFalse

            $mockResult[1].PermissionState | Should -Be 'Grant'
            $mockResult[1].PermissionType.ConnectSql | Should -BeFalse
            $mockResult[1].PermissionType.AlterAnyAvailabilityGroup | Should -BeTrue
        }

        Context 'When passing ServerObject over the pipeline' {
            It 'Should return the correct values' {
                $mockResult = $mockServerObject | Get-SqlDscServerPermission -Name 'Zebes\SamusAran' -ErrorAction 'Stop'

                $mockResult | Should -HaveCount 2

                $mockResult[0].PermissionState | Should -Be 'Grant'
                $mockResult[0].PermissionType.ConnectSql | Should -BeTrue
                $mockResult[0].PermissionType.AlterAnyAvailabilityGroup | Should -BeFalse

                $mockResult[1].PermissionState | Should -Be 'Grant'
                $mockResult[1].PermissionType.ConnectSql | Should -BeFalse
                $mockResult[1].PermissionType.AlterAnyAvailabilityGroup | Should -BeTrue
            }
        }
    }

    Context 'When the principal is a server role' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptMethod' -Name 'EnumServerPermissions' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $SqlServerRole
                    )

                    $mockEnumServerPermissions = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                    $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                        PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                            ViewServerState = $true
                        }
                        PermissionState = 'Grant'
                    }

                    $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                        PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                            ControlServer = $true
                        }
                        PermissionState = 'Grant'
                    }

                    return $mockEnumServerPermissions
                } -PassThru -Force

            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $false
            }

            Mock -CommandName Test-SqlDscIsRole -MockWith {
                return $true
            }
        }

        It 'Should return the correct values for a server role' {
            $mockResult = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'MyCustomRole' -ErrorAction 'Stop'

            $mockResult | Should -HaveCount 2

            $mockResult[0].PermissionState | Should -Be 'Grant'
            $mockResult[0].PermissionType.ViewServerState | Should -BeTrue
            $mockResult[0].PermissionType.ControlServer | Should -BeFalse

            $mockResult[1].PermissionState | Should -Be 'Grant'
            $mockResult[1].PermissionType.ViewServerState | Should -BeFalse
            $mockResult[1].PermissionType.ControlServer | Should -BeTrue
        }

        Context 'When passing ServerObject over the pipeline' {
            It 'Should return the correct values for a server role' {
                $mockResult = $mockServerObject | Get-SqlDscServerPermission -Name 'MyCustomRole' -ErrorAction 'Stop'

                $mockResult | Should -HaveCount 2

                $mockResult[0].PermissionState | Should -Be 'Grant'
                $mockResult[0].PermissionType.ViewServerState | Should -BeTrue
                $mockResult[0].PermissionType.ControlServer | Should -BeFalse

                $mockResult[1].PermissionState | Should -Be 'Grant'
                $mockResult[1].PermissionType.ViewServerState | Should -BeFalse
                $mockResult[1].PermissionType.ControlServer | Should -BeTrue
            }
        }
    }

    Context 'When verifying function calls' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptMethod' -Name 'EnumServerPermissions' -Value {
                    return @()
                } -PassThru -Force
        }

        Context 'When no PrincipalType is specified' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Test-SqlDscIsRole -MockWith {
                    return $false
                }
            }

            It 'Should call both Test-SqlDscIsLogin and Test-SqlDscIsRole' {
                $null = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestPrincipal' -ErrorAction 'SilentlyContinue'

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter {
                    $ServerObject.Equals($mockServerObject) -and $Name -eq 'TestPrincipal'
                } -Exactly -Times 1

                Should -Invoke -CommandName Test-SqlDscIsRole -ParameterFilter {
                    $ServerObject.Equals($mockServerObject) -and $Name -eq 'TestPrincipal'
                } -Exactly -Times 1
            }
        }

        Context 'When no PrincipalType is specified and login is not found' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $false
                }

                Mock -CommandName Test-SqlDscIsRole -MockWith {
                    return $true
                }
            }

            It 'Should call both Test-SqlDscIsLogin and Test-SqlDscIsRole' {
                $null = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestPrincipal' -ErrorAction 'SilentlyContinue'

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter {
                    $ServerObject.Equals($mockServerObject) -and $Name -eq 'TestPrincipal'
                } -Exactly -Times 1

                Should -Invoke -CommandName Test-SqlDscIsRole -ParameterFilter {
                    $ServerObject.Equals($mockServerObject) -and $Name -eq 'TestPrincipal'
                } -Exactly -Times 1
            }
        }

        Context 'When PrincipalType is Login' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Test-SqlDscIsRole -MockWith {
                    return $false
                }
            }

            It 'Should only call Test-SqlDscIsLogin' {
                $null = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestPrincipal' -PrincipalType 'Login' -ErrorAction 'SilentlyContinue'

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter {
                    $ServerObject.Equals($mockServerObject) -and $Name -eq 'TestPrincipal'
                } -Exactly -Times 1

                Should -Invoke -CommandName Test-SqlDscIsRole -Exactly -Times 0
            }
        }

        Context 'When PrincipalType is Role' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $false
                }

                Mock -CommandName Test-SqlDscIsRole -MockWith {
                    return $true
                }
            }

            It 'Should only call Test-SqlDscIsRole' {
                $null = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestPrincipal' -PrincipalType 'Role' -ErrorAction 'SilentlyContinue'

                Should -Invoke -CommandName Test-SqlDscIsLogin -Exactly -Times 0

                Should -Invoke -CommandName Test-SqlDscIsRole -ParameterFilter {
                    $ServerObject.Equals($mockServerObject) -and $Name -eq 'TestPrincipal'
                } -Exactly -Times 1
            }
        }

        Context 'When PrincipalType is both Login and Role' {
            BeforeAll {
                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Test-SqlDscIsRole -MockWith {
                    return $false
                }
            }

            It 'Should call both Test-SqlDscIsLogin and Test-SqlDscIsRole when both types are specified' {
                $null = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestPrincipal' -PrincipalType 'Login', 'Role' -ErrorAction 'SilentlyContinue'

                Should -Invoke -CommandName Test-SqlDscIsLogin -ParameterFilter {
                    $ServerObject.Equals($mockServerObject) -and $Name -eq 'TestPrincipal'
                } -Exactly -Times 1

                Should -Invoke -CommandName Test-SqlDscIsRole -ParameterFilter {
                    $ServerObject.Equals($mockServerObject) -and $Name -eq 'TestPrincipal'
                } -Exactly -Times 1
            }
        }
    }

    Context 'When using PrincipalType parameter' {
        Context 'When PrincipalType is Login and principal is a login' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'EnumServerPermissions' -Value {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $SqlServerLogin
                        )

                        $mockEnumServerPermissions = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                        $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                            PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                                ConnectSql = $true
                            }
                            PermissionState = 'Grant'
                        }

                        return $mockEnumServerPermissions
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                Mock -CommandName Test-SqlDscIsRole -MockWith {
                    return $false
                }
            }

            It 'Should return the correct values when specifying PrincipalType as Login' {
                $mockResult = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestLogin' -PrincipalType 'Login' -ErrorAction 'Stop'

                $mockResult | Should -HaveCount 1
                $mockResult[0].PermissionState | Should -Be 'Grant'
                $mockResult[0].PermissionType.ConnectSql | Should -BeTrue
            }
        }

        Context 'When PrincipalType is Role and principal is a role' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'EnumServerPermissions' -Value {
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $SqlServerRole
                        )

                        $mockEnumServerPermissions = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                        $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                            PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                                ViewServerState = $true
                            }
                            PermissionState = 'Grant'
                        }

                        return $mockEnumServerPermissions
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $false
                }

                Mock -CommandName Test-SqlDscIsRole -MockWith {
                    return $true
                }
            }

            It 'Should return the correct values when specifying PrincipalType as Role' {
                $mockResult = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestRole' -PrincipalType 'Role' -ErrorAction 'Stop'

                $mockResult | Should -HaveCount 1
                $mockResult[0].PermissionState | Should -Be 'Grant'
                $mockResult[0].PermissionType.ViewServerState | Should -BeTrue
            }
        }

        Context 'When PrincipalType is Login but principal is not a login' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $false
                }

                Mock -CommandName Test-SqlDscIsRole -MockWith {
                    return $false
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.ServerPermission_MissingPrincipal
                }
            }

            It 'Should throw an error when principal is not found as login' {
                { Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'NotALogin' -PrincipalType 'Login' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'NotALogin', 'MockInstance')
            }
        }
    }

    Context 'When using Login parameter set' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptMethod' -Name 'EnumServerPermissions' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $SqlServerLogin
                    )

                    $mockEnumServerPermissions = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                    $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                        PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                            ConnectSql = $true
                        }
                        PermissionState = 'Grant'
                    }

                    return $mockEnumServerPermissions
                } -PassThru -Force

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestLogin'
        }

        It 'Should return the correct values when using Login object' {
            $mockResult = Get-SqlDscServerPermission -Login $mockLoginObject -ErrorAction 'Stop'

            $mockResult | Should -HaveCount 1
            $mockResult[0].PermissionState | Should -Be 'Grant'
            $mockResult[0].PermissionType.ConnectSql | Should -BeTrue
        }

        It 'Should accept Login from pipeline' {
            $mockResult = $mockLoginObject | Get-SqlDscServerPermission -ErrorAction 'Stop'

            $mockResult | Should -HaveCount 1
            $mockResult[0].PermissionState | Should -Be 'Grant'
            $mockResult[0].PermissionType.ConnectSql | Should -BeTrue
        }
    }

    Context 'When using ServerRole parameter set' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptMethod' -Name 'EnumServerPermissions' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $SqlServerRole
                    )

                    $mockEnumServerPermissions = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                    $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                        PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                            ViewServerState = $true
                        }
                        PermissionState = 'Grant'
                    }

                    return $mockEnumServerPermissions
                } -PassThru -Force

            $mockServerRoleObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList $mockServerObject, 'TestRole'
        }

        It 'Should return the correct values when using ServerRole object' {
            $mockResult = Get-SqlDscServerPermission -ServerRole $mockServerRoleObject -ErrorAction 'Stop'

            $mockResult | Should -HaveCount 1
            $mockResult[0].PermissionState | Should -Be 'Grant'
            $mockResult[0].PermissionType.ViewServerState | Should -BeTrue
        }

        It 'Should accept ServerRole from pipeline' {
            $mockResult = $mockServerRoleObject | Get-SqlDscServerPermission -ErrorAction 'Stop'

            $mockResult | Should -HaveCount 1
            $mockResult[0].PermissionState | Should -Be 'Grant'
            $mockResult[0].PermissionType.ViewServerState | Should -BeTrue
        }
    }

    Context 'When validating parameters' {
        It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
            @{
                MockParameterSetName = 'ByName'
                MockExpectedParameters = '-ServerObject <Server> -Name <string> [-PrincipalType <string[]>] [<CommonParameters>]'
            }
            @{
                MockParameterSetName = 'Login'
                MockExpectedParameters = '-Login <Login> [<CommonParameters>]'
            }
            @{
                MockParameterSetName = 'ServerRole'
                MockExpectedParameters = '-ServerRole <ServerRole> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscServerPermission').ParameterSets |
                Where-Object -FilterScript {
                    $_.Name -eq $mockParameterSetName
                } |
                Select-Object -Property @(
                    @{
                        Name = 'ParameterSetName'
                        Expression = { $_.Name }
                    },
                    @{
                        Name = 'ParameterListAsString'
                        Expression = { $_.ToString() }
                    }
                )

            $result.ParameterSetName | Should -Be $MockParameterSetName
            $result.ParameterListAsString | Should -Be $MockExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter in ByName parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept ServerObject from pipeline in ByName parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have Name as a mandatory parameter in ByName parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have PrincipalType as an optional parameter in ByName parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['PrincipalType']
            $parameterInfo.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should have PrincipalType with correct ValidateSet values' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['PrincipalType']
            $validateSetAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSetAttribute.ValidValues | Should -Contain 'Login'
            $validateSetAttribute.ValidValues | Should -Contain 'Role'
            $validateSetAttribute.ValidValues | Should -HaveCount 2
        }

        It 'Should have Login as a mandatory parameter in Login parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['Login']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept Login from pipeline in Login parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['Login']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have ServerRole as a mandatory parameter in ServerRole parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['ServerRole']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept ServerRole from pipeline in ServerRole parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerPermission').Parameters['ServerRole']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }
    }
}
