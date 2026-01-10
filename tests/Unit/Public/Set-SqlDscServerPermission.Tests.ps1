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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Set-SqlDscServerPermission' -Tag 'Public' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Login'
                ExpectedParameters = '-Login <Login> [-Grant <SqlServerPermission[]>] [-GrantWithGrant <SqlServerPermission[]>] [-Deny <SqlServerPermission[]>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ServerRole'
                ExpectedParameters = '-ServerRole <ServerRole> [-Grant <SqlServerPermission[]>] [-GrantWithGrant <SqlServerPermission[]>] [-Deny <SqlServerPermission[]>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscServerPermission').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When validating parameter properties' {
        It 'Should have Login as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscServerPermission').Parameters['Login']

            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerRole as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscServerPermission').Parameters['ServerRole']

            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Grant parameter not accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscServerPermission').Parameters['Grant']

            $parameterInfo.Attributes.ValueFromPipeline | Should -BeFalse
        }

        It 'Should have GrantWithGrant parameter not accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscServerPermission').Parameters['GrantWithGrant']

            $parameterInfo.Attributes.ValueFromPipeline | Should -BeFalse
        }

        It 'Should have Deny parameter not accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscServerPermission').Parameters['Deny']

            $parameterInfo.Attributes.ValueFromPipeline | Should -BeFalse
        }
    }

    Context 'When using parameter WhatIf' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

            Mock -CommandName Get-SqlDscServerPermission
            Mock -CommandName Grant-SqlDscServerPermission
            Mock -CommandName Deny-SqlDscServerPermission
            Mock -CommandName Revoke-SqlDscServerPermission
            Mock -CommandName ConvertTo-SqlDscServerPermission
        }

        It 'Should not call any permission commands' {
            Set-SqlDscServerPermission -Login $mockLoginObject -Grant 'ConnectSql' -WhatIf

            Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Deny-SqlDscServerPermission -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Revoke-SqlDscServerPermission -Exactly -Times 0 -Scope It
        }
    }

    Context 'When setting permissions for a login' {
        Context 'When no current permissions exist' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $null
                }

                Mock -CommandName Grant-SqlDscServerPermission
                Mock -CommandName Deny-SqlDscServerPermission
                Mock -CommandName Revoke-SqlDscServerPermission
            }

            It 'Should grant the specified permissions' {
                Set-SqlDscServerPermission -Login $mockLoginObject -Grant 'ConnectSql', 'ViewServerState' -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ConnectSql' -and $Permission -contains 'ViewServerState'
                } -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Deny-SqlDscServerPermission -Exactly -Times 0 -Scope It
            }

            It 'Should deny the specified permissions' {
                Set-SqlDscServerPermission -Login $mockLoginObject -Deny 'ViewAnyDatabase' -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Deny-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewAnyDatabase'
                } -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -Exactly -Times 0 -Scope It
            }

            It 'Should grant with grant option the specified permissions' {
                Set-SqlDscServerPermission -Login $mockLoginObject -GrantWithGrant 'AlterAnyDatabase' -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'AlterAnyDatabase' -and $WithGrant -eq $true
                } -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Deny-SqlDscServerPermission -Exactly -Times 0 -Scope It
            }
        }

        Context 'When current permissions exist and need to be revoked' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

                # Create mock ServerPermissionInfo objects
                $mockServerPermissionInfo = @(
                    New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                )

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $mockServerPermissionInfo
                }

                # Mock ConvertTo-SqlDscServerPermission to return the permissions we want
                Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                    return InModuleScope -ScriptBlock {
                        @(
                            [ServerPermission]@{
                                State      = 'Grant'
                                Permission = @('ConnectSql', 'ViewServerState')
                            }
                            [ServerPermission]@{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission]@{
                                State      = 'Deny'
                                Permission = @('ViewAnyDatabase')
                            }
                        )
                    }
                }

                Mock -CommandName Grant-SqlDscServerPermission
                Mock -CommandName Deny-SqlDscServerPermission
                Mock -CommandName Revoke-SqlDscServerPermission
            }

            It 'Should revoke unwanted permissions and grant new ones' {
                # Desired: Grant only ConnectSql (ViewServerState should be revoked)
                Set-SqlDscServerPermission -Login $mockLoginObject -Grant 'ConnectSql' -Deny @() -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It

                # Should revoke ViewServerState (was granted, no longer desired)
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewServerState'
                } -Exactly -Times 1 -Scope It

                # Should revoke ViewAnyDatabase (was denied, no longer desired)
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewAnyDatabase'
                } -Exactly -Times 1 -Scope It

                # ConnectSql is already granted, so no Grant call needed
                Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 0 -Scope It
            }

            It 'Should add new permissions while keeping existing ones' {
                # Desired: Grant ConnectSql, ViewServerState, AlterAnyDatabase
                Set-SqlDscServerPermission -Login $mockLoginObject -Grant 'ConnectSql', 'ViewServerState', 'AlterAnyDatabase' -Deny @() -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It

                # Should grant AlterAnyDatabase (new)
                Should -Invoke -CommandName Grant-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'AlterAnyDatabase'
                } -Exactly -Times 1 -Scope It

                # Should revoke ViewAnyDatabase (was denied, no longer desired)
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewAnyDatabase'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using pipeline input' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $null
                }

                Mock -CommandName Grant-SqlDscServerPermission
                Mock -CommandName Deny-SqlDscServerPermission
                Mock -CommandName Revoke-SqlDscServerPermission
            }

            It 'Should accept Login object from pipeline' {
                $mockLoginObject | Set-SqlDscServerPermission -Grant 'ConnectSql' -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 1 -Scope It
            }
        }

        Context 'When revoking all permissions using empty arrays' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

                # Create mock ServerPermissionInfo objects
                $mockServerPermissionInfo = @(
                    New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                )

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $mockServerPermissionInfo
                }

                Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                    return InModuleScope -ScriptBlock {
                        @(
                            [ServerPermission]@{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission]@{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission]@{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }
                }

                Mock -CommandName Grant-SqlDscServerPermission
                Mock -CommandName Deny-SqlDscServerPermission
                Mock -CommandName Revoke-SqlDscServerPermission
            }

            It 'Should revoke all permissions when empty Grant array is specified' {
                Set-SqlDscServerPermission -Login $mockLoginObject -Grant @() -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It

                # Should revoke ConnectSql
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ConnectSql'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 0 -Scope It
            }
        }

        Context 'When revoking only specific permission categories while preserving others' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

                # Create mock ServerPermissionInfo objects
                $mockServerPermissionInfo = @(
                    New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                )

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $mockServerPermissionInfo
                }

                Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                    return InModuleScope -ScriptBlock {
                        @(
                            [ServerPermission]@{
                                State      = 'Grant'
                                Permission = @('ViewServerState')
                            }
                            [ServerPermission]@{
                                State      = 'GrantWithGrant'
                                Permission = @('CreateAnyDatabase')
                            }
                            [ServerPermission]@{
                                State      = 'Deny'
                                Permission = @('ViewAnyDefinition')
                            }
                        )
                    }
                }

                Mock -CommandName Grant-SqlDscServerPermission
                Mock -CommandName Deny-SqlDscServerPermission
                Mock -CommandName Revoke-SqlDscServerPermission
            }

            It 'Should revoke only Grant permissions when only Grant parameter is specified' {
                # Specify only Grant parameter with empty array - should revoke Grant permissions only
                Set-SqlDscServerPermission -Login $mockLoginObject -Grant @() -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It

                # Should revoke ViewServerState (Grant permission)
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewServerState' -and -not $WithGrant
                } -Exactly -Times 1 -Scope It

                # Should NOT revoke GrantWithGrant or Deny permissions
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'CreateAnyDatabase'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewAnyDefinition'
                } -Exactly -Times 0 -Scope It
            }

            It 'Should revoke only GrantWithGrant permissions when only GrantWithGrant parameter is specified' {
                # Specify only GrantWithGrant parameter with empty array
                Set-SqlDscServerPermission -Login $mockLoginObject -GrantWithGrant @() -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It

                # Should revoke CreateAnyDatabase (GrantWithGrant permission)
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'CreateAnyDatabase' -and $WithGrant -eq $true
                } -Exactly -Times 1 -Scope It

                # Should NOT revoke Grant or Deny permissions
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewServerState'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewAnyDefinition'
                } -Exactly -Times 0 -Scope It
            }

            It 'Should revoke only Deny permissions when only Deny parameter is specified' {
                # Specify only Deny parameter with empty array
                Set-SqlDscServerPermission -Login $mockLoginObject -Deny @() -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It

                # Should revoke ViewAnyDefinition (Deny permission)
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewAnyDefinition' -and -not $WithGrant
                } -Exactly -Times 1 -Scope It

                # Should NOT revoke Grant or GrantWithGrant permissions
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ViewServerState'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'CreateAnyDatabase'
                } -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When setting permissions for a server role' {
        Context 'When no current permissions exist' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                $mockServerRoleObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($mockServerObject, 'MyServerRole')

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $null
                }

                Mock -CommandName Grant-SqlDscServerPermission
                Mock -CommandName Deny-SqlDscServerPermission
                Mock -CommandName Revoke-SqlDscServerPermission
            }

            It 'Should grant the specified permissions to the role' {
                Set-SqlDscServerPermission -ServerRole $mockServerRoleObject -Grant 'AlterAnyDatabase' -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'AlterAnyDatabase'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using pipeline input' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                $mockServerRoleObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($mockServerObject, 'MyServerRole')

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $null
                }

                Mock -CommandName Grant-SqlDscServerPermission
                Mock -CommandName Deny-SqlDscServerPermission
                Mock -CommandName Revoke-SqlDscServerPermission
            }

            It 'Should accept ServerRole object from pipeline' {
                $mockServerRoleObject | Set-SqlDscServerPermission -Grant 'AlterAnyDatabase' -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 1 -Scope It
            }
        }

        Context 'When revoking permissions' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $mockServerObject.InstanceName = 'MockInstance'

                $mockServerRoleObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($mockServerObject, 'MyServerRole')

                # Create mock ServerPermissionInfo objects
                $mockServerPermissionInfo = @(
                    New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                )

                Mock -CommandName Get-SqlDscServerPermission -MockWith {
                    return $mockServerPermissionInfo
                }

                Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
                    return InModuleScope -ScriptBlock {
                        @(
                            [ServerPermission]@{
                                State      = 'Grant'
                                Permission = @('ConnectSql')
                            }
                            [ServerPermission]@{
                                State      = 'GrantWithGrant'
                                Permission = @()
                            }
                            [ServerPermission]@{
                                State      = 'Deny'
                                Permission = @()
                            }
                        )
                    }
                }

                Mock -CommandName Grant-SqlDscServerPermission
                Mock -CommandName Deny-SqlDscServerPermission
                Mock -CommandName Revoke-SqlDscServerPermission
            }

            It 'Should revoke all permissions when empty Grant array is specified' {
                Set-SqlDscServerPermission -ServerRole $mockServerRoleObject -Grant @() -Force

                Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It

                # Should revoke ConnectSql
                Should -Invoke -CommandName Revoke-SqlDscServerPermission -ParameterFilter {
                    $Permission -contains 'ConnectSql'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When setting multiple permission states at once' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                return $null
            }

            Mock -CommandName Grant-SqlDscServerPermission
            Mock -CommandName Deny-SqlDscServerPermission
            Mock -CommandName Revoke-SqlDscServerPermission
        }

        It 'Should grant, grant with grant, and deny the specified permissions' {
            Set-SqlDscServerPermission -Login $mockLoginObject `
                -Grant 'ConnectSql' `
                -GrantWithGrant 'AlterAnyDatabase' `
                -Deny 'ViewAnyDatabase' `
                -Force

            Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It

            # Should grant ConnectSql
            Should -Invoke -CommandName Grant-SqlDscServerPermission -ParameterFilter {
                $Permission -contains 'ConnectSql' -and -not $WithGrant
            } -Exactly -Times 1 -Scope It

            # Should grant AlterAnyDatabase with grant
            Should -Invoke -CommandName Grant-SqlDscServerPermission -ParameterFilter {
                $Permission -contains 'AlterAnyDatabase' -and $WithGrant -eq $true
            } -Exactly -Times 1 -Scope It

            # Should deny ViewAnyDatabase
            Should -Invoke -CommandName Deny-SqlDscServerPermission -ParameterFilter {
                $Permission -contains 'ViewAnyDatabase'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using parameter Force' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                return $null
            }

            Mock -CommandName Grant-SqlDscServerPermission
        }

        It 'Should not prompt for confirmation when Force is specified' {
            # This test verifies that Force parameter works by ensuring the operation completes
            Set-SqlDscServerPermission -Login $mockLoginObject -Grant 'ConnectSql' -Force

            Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using parameter Confirm with value $false' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLoginObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList @($mockServerObject, 'DOMAIN\MyLogin')

            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                return $null
            }

            Mock -CommandName Grant-SqlDscServerPermission
        }

        It 'Should not prompt for confirmation when Confirm is $false' {
            Set-SqlDscServerPermission -Login $mockLoginObject -Grant 'ConnectSql' -Confirm:$false

            Should -Invoke -CommandName Get-SqlDscServerPermission -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Grant-SqlDscServerPermission -Exactly -Times 1 -Scope It
        }
    }
}
