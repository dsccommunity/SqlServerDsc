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

Describe 'Remove-SqlDscServerPermission' -Tag 'Public' {
    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [-Permission] <ServerPermission[]> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscServerPermission').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When testing parameter properties' {
        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscServerPermission').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscServerPermission').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Permission as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscServerPermission').Parameters['Permission']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Force as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscServerPermission').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When removing permissions successfully' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName ConvertFrom-SqlDscServerPermission -MockWith {
                $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockPermissionSet.ConnectSql = $true
                return $mockPermissionSet
            }

            Mock -CommandName Invoke-SqlDscServerPermissionOperation -MockWith {
                # Mock successful operation
            }
        }

        It 'Should remove permissions without throwing' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            { Remove-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission $permissions -Force } |
                Should -Not -Throw
        }

        It 'Should call Invoke-SqlDscServerPermissionOperation for each non-empty permission' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @()
                }
            )

            Remove-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission $permissions -Force

            Should -Invoke -CommandName Invoke-SqlDscServerPermissionOperation -Times 1
        }

        It 'Should handle GrantWithGrant state correctly' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @('ConnectSql')
                }
            )

            { Remove-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission $permissions -Force } |
                Should -Not -Throw

            Should -Invoke -CommandName Invoke-SqlDscServerPermissionOperation -ParameterFilter {
                $State -eq 'Revoke' -and $WithGrant.IsPresent
            }
        }

        It 'Should handle Grant state correctly' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            { Remove-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission $permissions -Force } |
                Should -Not -Throw

            Should -Invoke -CommandName Invoke-SqlDscServerPermissionOperation -ParameterFilter {
                $State -eq 'Revoke' -and -not $WithGrant.IsPresent
            }
        }
    }

    Context 'When removing permissions fails' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName ConvertFrom-SqlDscServerPermission -MockWith {
                $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockPermissionSet.ConnectSql = $true
                return $mockPermissionSet
            }

            Mock -CommandName Invoke-SqlDscServerPermissionOperation -MockWith {
                throw 'Mock error'
            }
        }

        It 'Should throw a descriptive error when operation fails' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            { Remove-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission $permissions -Force } |
                Should -Throw -ExpectedMessage '*Failed to revoke server permissions*'
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName ConvertFrom-SqlDscServerPermission -MockWith {
                $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockPermissionSet.ConnectSql = $true
                return $mockPermissionSet
            }

            Mock -CommandName Invoke-SqlDscServerPermissionOperation -MockWith {
                # Mock successful operation
            }
        }

        It 'Should accept ServerObject from pipeline' {
            $permissions = @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            )

            { $mockServerObject | Remove-SqlDscServerPermission -Name 'TestUser' -Permission $permissions -Force } |
                Should -Not -Throw
        }
    }
}