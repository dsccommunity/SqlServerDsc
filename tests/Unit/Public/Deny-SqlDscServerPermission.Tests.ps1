[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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

Describe 'Deny-SqlDscServerPermission' -Tag 'Public' {
    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Login'
                ExpectedParameters = '-Login <Login> -Permission <SqlServerPermission[]> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ServerRole'
                ExpectedParameters = '-ServerRole <ServerRole> -Permission <SqlServerPermission[]> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Deny-SqlDscServerPermission').ParameterSets |
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
        It 'Should have Login as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Deny-SqlDscServerPermission').Parameters['Login']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerRole as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Deny-SqlDscServerPermission').Parameters['ServerRole']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Permission as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Deny-SqlDscServerPermission').Parameters['Permission']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Force as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Deny-SqlDscServerPermission').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When denying permissions successfully' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'
            $mockServerRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList $mockServerObject, 'TestRole'

            # Mock the Deny method on the server object
            $mockServerObject | Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                param($PermissionSet, $PrincipalName)
                # Do nothing - just succeed
            } -Force
        }

        It 'Should deny permissions to a login without throwing' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                { Deny-SqlDscServerPermission -Login $mockLogin -Permission ConnectSql -Force } |
                    Should -Not -Throw
            }
        }

        It 'Should deny permissions to a server role without throwing' {
            InModuleScope -Parameters @{
                mockServerRole = $mockServerRole
            } -ScriptBlock {
                { Deny-SqlDscServerPermission -ServerRole $mockServerRole -Permission ConnectSql -Force } |
                    Should -Not -Throw
            }
        }
    }

    Context 'When denying permissions fails' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'

            # Mock the Deny method to throw an error
            $mockServerObject | Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                param($PermissionSet, $PrincipalName)
                throw 'Mocked Deny failure'
            } -Force
        }

        It 'Should throw a descriptive error when operation fails' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                { Deny-SqlDscServerPermission -Login $mockLogin -Permission ConnectSql -Force } |
                    Should -Throw -ExpectedMessage '*Failed to deny server permissions*'
            }
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'
            $mockServerRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList $mockServerObject, 'TestRole'

            # Mock the Deny method on the server object
            $mockServerObject | Add-Member -MemberType ScriptMethod -Name 'Deny' -Value {
                param($PermissionSet, $PrincipalName)
                # Do nothing - just succeed
            } -Force
        }

        It 'Should accept Login from pipeline' {
            InModuleScope -Parameters @{
                mockLogin = $mockLogin
            } -ScriptBlock {
                { $mockLogin | Deny-SqlDscServerPermission -Permission ConnectSql -Force } |
                    Should -Not -Throw
            }
        }

        It 'Should accept ServerRole from pipeline' {
            InModuleScope -Parameters @{
                mockServerRole = $mockServerRole
            } -ScriptBlock {
                { $mockServerRole | Deny-SqlDscServerPermission -Permission ConnectSql -Force } |
                    Should -Not -Throw
            }
        }
    }
}
