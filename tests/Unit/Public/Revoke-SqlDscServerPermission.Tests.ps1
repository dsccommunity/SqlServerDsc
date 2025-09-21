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

Describe 'Revoke-SqlDscServerPermission' -Tag 'Public' {
    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Login'
                ExpectedParameters = '-Login <Login> -Permission <SqlServerPermission[]> [-WithGrant] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ServerRole'
                ExpectedParameters = '-ServerRole <ServerRole> -Permission <SqlServerPermission[]> [-WithGrant] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Revoke-SqlDscServerPermission').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Revoke-SqlDscServerPermission').Parameters['Login']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerRole as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Revoke-SqlDscServerPermission').Parameters['ServerRole']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Permission as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Revoke-SqlDscServerPermission').Parameters['Permission']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Force as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Revoke-SqlDscServerPermission').Parameters['Force']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have WithGrant as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Revoke-SqlDscServerPermission').Parameters['WithGrant']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When revoking permissions successfully' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $script:mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'
            $script:mockServerRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList $mockServerObject, 'TestRole'

            # Mock the Revoke method on the server object
            $mockServerObject | Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                param($PermissionSet, $PrincipalName, $RevokeGrant, $Cascade)
                # Do nothing - just succeed
            } -Force
        }

        It 'Should revoke permissions from a login' {
            $null = Revoke-SqlDscServerPermission -Login $script:mockLogin -Permission 'ConnectSql' -Force
        }

        It 'Should revoke permissions from a server role' {
            $null = Revoke-SqlDscServerPermission -ServerRole $script:mockServerRole -Permission 'ConnectSql' -Force
        }

        It 'Should handle WithGrant parameter correctly' {
            $null = Revoke-SqlDscServerPermission -Login $script:mockLogin -Permission 'ConnectSql' -WithGrant -Force
        }
    }

    Context 'When revoking permissions fails' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $script:mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'

            # Mock the Revoke method to throw an error
            $mockServerObject | Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                param($PermissionSet, $PrincipalName, $RevokeGrant, $Cascade)
                throw 'Mocked Revoke failure'
            } -Force
        }

        It 'Should throw a descriptive error when operation fails' {
            { Revoke-SqlDscServerPermission -Login $script:mockLogin -Permission 'ConnectSql' -Force } |
                Should -Throw -ExpectedMessage '*Failed to revoke server permissions*'
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            $script:mockLogin = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Login' -ArgumentList $mockServerObject, 'TestUser'
            $script:mockServerRole = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerRole' -ArgumentList $mockServerObject, 'TestRole'

            # Mock the Revoke method on the server object
            $mockServerObject | Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                param($PermissionSet, $PrincipalName, $RevokeGrant, $Cascade)
                # Do nothing - just succeed
            } -Force
        }

        It 'Should accept Login from pipeline' {
            $null = $script:mockLogin | Revoke-SqlDscServerPermission -Permission 'ConnectSql' -Force
        }

        It 'Should accept ServerRole from pipeline' {
            $null = $script:mockServerRole | Revoke-SqlDscServerPermission -Permission 'ConnectSql' -Force
        }
    }
}
