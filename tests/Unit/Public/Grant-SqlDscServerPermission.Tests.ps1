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

Describe 'Grant-SqlDscServerPermission' -Tag 'Public' {
    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [-Permission] <String[]> [-WithGrant] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Grant-SqlDscServerPermission').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Grant-SqlDscServerPermission').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Grant-SqlDscServerPermission').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Permission as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Grant-SqlDscServerPermission').Parameters['Permission']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Force as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Grant-SqlDscServerPermission').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have WithGrant as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Grant-SqlDscServerPermission').Parameters['WithGrant']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When granting permissions successfully' {
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

        It 'Should grant permissions without throwing' {
            InModuleScope -Parameters @{
                mockServerObject = $mockServerObject
            } -ScriptBlock {
                { Grant-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission @('ConnectSql') -Force } |
                    Should -Not -Throw
            }
        }

        It 'Should call Invoke-SqlDscServerPermissionOperation for each non-empty permission' {
            Grant-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission @('ConnectSql') -Force

            Should -Invoke -CommandName Invoke-SqlDscServerPermissionOperation -Times 1
        }

        It 'Should handle GrantWithGrant state correctly' {
            { Grant-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission @('ConnectSql') -WithGrant -Force } |
                Should -Not -Throw

            Should -Invoke -CommandName Invoke-SqlDscServerPermissionOperation -ParameterFilter {
                $State -eq 'Grant' -and $WithGrant.IsPresent
            }
        }
    }

    Context 'When granting permissions fails' {
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
            { Grant-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Permission @('ConnectSql') -Force } |
                Should -Throw -ExpectedMessage '*Failed to grant server permissions*'
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
            { $mockServerObject | Grant-SqlDscServerPermission -Name 'TestUser' -Permission @('ConnectSql') -Force } |
                Should -Not -Throw
        }
    }
}
