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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
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

Describe 'Remove-SqlDscRole' -Tag 'Public' {
    Context 'When removing a server role using ServerObject parameter set' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockServerObject.InstanceName = 'TestInstance'

                # Create mock role that can be removed
                $script:mockRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($script:mockServerObject, 'CustomRole')
                $script:mockRole | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -Force
                $script:mockRole | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $script:mockServerObject -Force
                $script:mockRole | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                    # Mock implementation
                } -Force

                # Create mock roles collection
                $mockRoleCollection = @{
                    'CustomRole' = $script:mockRole
                }

                $script:mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                    return [PSCustomObject]@{
                        PSTypeName = 'MockRoleCollection'
                    } | Add-Member -MemberType 'ScriptMethod' -Name 'get_Item' -Value {
                        param($roleName)
                        return $mockRoleCollection[$roleName]
                    } -PassThru | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                        # Mock implementation
                    } -PassThru
                } -Force
            }
        }

        It 'Should remove the server role successfully' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Write-Verbose'

                { Remove-SqlDscRole -ServerObject $script:mockServerObject -Name 'CustomRole' -Force } |
                    Should -Not -Throw
            }
        }

        It 'Should call Refresh when Refresh parameter is specified' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Write-Verbose'

                # Track Refresh call
                $refreshCalled = $false
                $script:mockServerObject.Roles | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                    $refreshCalled = $true
                } -Force

                Remove-SqlDscRole -ServerObject $script:mockServerObject -Name 'CustomRole' -Refresh -Force

                $refreshCalled | Should -BeTrue
            }
        }

        It 'Should throw an error when role does not exist' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Write-Verbose'

                { Remove-SqlDscRole -ServerObject $script:mockServerObject -Name 'NonExistentRole' -Force } |
                    Should -Throw -ExpectedMessage '*was not found*'
            }
        }
    }

    Context 'When removing a server role using RoleObject parameter set' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockServerObject.InstanceName = 'TestInstance'

                # Create mock role that can be removed
                $script:mockRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($script:mockServerObject, 'CustomRole')
                $script:mockRole | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -Force
                $script:mockRole | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $script:mockServerObject -Force
                $script:mockRole | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                    # Mock implementation
                } -Force
            }
        }

        It 'Should remove the server role successfully' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Write-Verbose'

                { Remove-SqlDscRole -RoleObject $script:mockRole -Force } |
                    Should -Not -Throw
            }
        }
    }

    Context 'When trying to remove a built-in role' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockServerObject.InstanceName = 'TestInstance'

                # Create mock built-in role
                $script:mockBuiltInRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($script:mockServerObject, 'sysadmin')
                $script:mockBuiltInRole | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $true -Force
                $script:mockBuiltInRole | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $script:mockServerObject -Force

                # Create mock roles collection
                $mockRoleCollection = @{
                    'sysadmin' = $script:mockBuiltInRole
                }

                $script:mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                    return [PSCustomObject]@{
                        PSTypeName = 'MockRoleCollection'
                    } | Add-Member -MemberType 'ScriptMethod' -Name 'get_Item' -Value {
                        param($roleName)
                        return $mockRoleCollection[$roleName]
                    } -PassThru | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                        # Mock implementation
                    } -PassThru
                } -Force
            }
        }

        It 'Should throw an error when trying to remove a built-in role using ServerObject' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Write-Verbose'

                { Remove-SqlDscRole -ServerObject $script:mockServerObject -Name 'sysadmin' -Force } |
                    Should -Throw -ExpectedMessage '*Cannot remove built-in*'
            }
        }

        It 'Should throw an error when trying to remove a built-in role using RoleObject' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Write-Verbose'

                { Remove-SqlDscRole -RoleObject $script:mockBuiltInRole -Force } |
                    Should -Throw -ExpectedMessage '*Cannot remove built-in*'
            }
        }
    }

    Context 'When role removal fails' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockServerObject.InstanceName = 'TestInstance'

                # Create mock role that fails to be removed
                $script:mockRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList @($script:mockServerObject, 'CustomRole')
                $script:mockRole | Add-Member -MemberType 'NoteProperty' -Name 'IsFixedRole' -Value $false -Force
                $script:mockRole | Add-Member -MemberType 'NoteProperty' -Name 'Parent' -Value $script:mockServerObject -Force
                $script:mockRole | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value {
                    throw 'Removal failed'
                } -Force

                # Create mock roles collection
                $mockRoleCollection = @{
                    'CustomRole' = $script:mockRole
                }

                $script:mockServerObject | Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                    return [PSCustomObject]@{
                        PSTypeName = 'MockRoleCollection'
                    } | Add-Member -MemberType 'ScriptMethod' -Name 'get_Item' -Value {
                        param($roleName)
                        return $mockRoleCollection[$roleName]
                    } -PassThru | Add-Member -MemberType 'ScriptMethod' -Name 'Refresh' -Value {
                        # Mock implementation
                    } -PassThru
                } -Force
            }
        }

        It 'Should throw an error when role removal fails' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Write-Verbose'

                { Remove-SqlDscRole -ServerObject $script:mockServerObject -Name 'CustomRole' -Force } |
                    Should -Throw -ExpectedMessage '*Failed to remove*'
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set ServerObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscRole').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set RoleObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'RoleObject'
                ExpectedParameters = '[-RoleObject] <ServerRole> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscRole').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ServerObject as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['ServerObject']
            $serverObjectParameterSet = $parameterInfo.ParameterSets['ServerObject']
            $serverObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['Name']
            $nameParameterSet = $parameterInfo.ParameterSets['ServerObject']
            $nameParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have RoleObject as a mandatory parameter in RoleObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['RoleObject']
            $roleObjectParameterSet = $parameterInfo.ParameterSets['RoleObject']
            $roleObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Force as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have Refresh as a non-mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscRole').Parameters['Refresh']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }
}