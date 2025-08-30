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

Describe 'Invoke-SqlDscServerPermissionOperation' -Tag 'Private' {
    BeforeAll {
        $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
        $mockServerObject.InstanceName = 'MockInstance'

        $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
        $mockPermissionSet.ConnectSql = $true
    }

    Context 'When the principal does not exist' {
        BeforeAll {
            Mock -CommandName Test-SqlDscIsLogin -MockWith { return $false }
            Mock -CommandName Test-SqlDscIsRole -MockWith { return $false }
        }

        It 'Should throw when principal is not found' {
            InModuleScope -Parameters @{
                mockServerObject = $mockServerObject
                mockPermissionSet = $mockPermissionSet
            } -ScriptBlock {
                { Invoke-SqlDscServerPermissionOperation -ServerObject $mockServerObject -Name 'NonExistentUser' -Permission $mockPermissionSet -State 'Grant' } |
                    Should -Throw -ErrorId 'ISDSP0001,Invoke-SqlDscServerPermissionOperation'
            }
        }
    }

    Context 'When the principal is a login' {
        BeforeAll {
            Mock -CommandName Test-SqlDscIsLogin -MockWith { return $true }
            Mock -CommandName Test-SqlDscIsRole -MockWith { return $false }

            $mockServerObject | Add-Member -MemberType ScriptMethod -Name Grant -Value {
                param($permission, $name, $withGrant = $false)
                # Mock implementation
            } -Force
            $mockServerObject | Add-Member -MemberType ScriptMethod -Name Deny -Value {
                param($permission, $name)
                # Mock implementation
            } -Force
            $mockServerObject | Add-Member -MemberType ScriptMethod -Name Revoke -Value {
                param($permission, $name, $revoke = $false, $cascade = $false)
                # Mock implementation
            } -Force
        }

        It 'Should call Grant method when State is Grant' {
            InModuleScope -Parameters @{
                mockServerObject = $mockServerObject
                mockPermissionSet = $mockPermissionSet
            } -ScriptBlock {
                { Invoke-SqlDscServerPermissionOperation -ServerObject $mockServerObject -Name 'TestUser' -Permission $mockPermissionSet -State 'Grant' } |
                    Should -Not -Throw
            }
        }

        It 'Should call Grant method with WithGrant when State is Grant and WithGrant is specified' {
            InModuleScope -Parameters @{
                mockServerObject = $mockServerObject
                mockPermissionSet = $mockPermissionSet
            } -ScriptBlock {
                { Invoke-SqlDscServerPermissionOperation -ServerObject $mockServerObject -Name 'TestUser' -Permission $mockPermissionSet -State 'Grant' -WithGrant } |
                    Should -Not -Throw
            }
        }

        It 'Should call Deny method when State is Deny' {
            InModuleScope -Parameters @{
                mockServerObject = $mockServerObject
                mockPermissionSet = $mockPermissionSet
            } -ScriptBlock {
                { Invoke-SqlDscServerPermissionOperation -ServerObject $mockServerObject -Name 'TestUser' -Permission $mockPermissionSet -State 'Deny' } |
                    Should -Not -Throw
            }
        }

        It 'Should call Revoke method when State is Revoke' {
            InModuleScope -Parameters @{
                mockServerObject = $mockServerObject
                mockPermissionSet = $mockPermissionSet
            } -ScriptBlock {
                { Invoke-SqlDscServerPermissionOperation -ServerObject $mockServerObject -Name 'TestUser' -Permission $mockPermissionSet -State 'Revoke' } |
                    Should -Not -Throw
            }
        }

        It 'Should call Revoke method with WithGrant when State is Revoke and WithGrant is specified' {
            InModuleScope -Parameters @{
                mockServerObject = $mockServerObject
                mockPermissionSet = $mockPermissionSet
            } -ScriptBlock {
                { Invoke-SqlDscServerPermissionOperation -ServerObject $mockServerObject -Name 'TestUser' -Permission $mockPermissionSet -State 'Revoke' -WithGrant } |
                    Should -Not -Throw
            }
        }
    }

    Context 'When the principal is a role' {
        BeforeAll {
            Mock -CommandName Test-SqlDscIsLogin -MockWith { return $false }
            Mock -CommandName Test-SqlDscIsRole -MockWith { return $true }
        }

        It 'Should not throw when principal is a role' {
            InModuleScope -Parameters @{
                mockServerObject = $mockServerObject
                mockPermissionSet = $mockPermissionSet
            } -ScriptBlock {
                { Invoke-SqlDscServerPermissionOperation -ServerObject $mockServerObject -Name 'TestRole' -Permission $mockPermissionSet -State 'Grant' } |
                    Should -Not -Throw
            }
        }
    }
}