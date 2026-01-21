<#
    .SYNOPSIS
        Unit test for helper functions in module SqlServerDsc.Common.

    .NOTES
        SMO stubs
        ---------
        These are loaded at the start so that it is known that they are left in the
        session after test finishes, and will spill over to other tests. There does
        not exist a way to unload assemblies. It is possible to load these in a
        InModuleScope but the classes are still present in the parent scope when
        Pester has ran.

        SqlServer/SQLPS stubs
        ---------------------
        These are imported using Import-SqlModuleStub in a BeforeAll-block in only
        a test that requires them, and must be removed in an AfterAll-block using
        Remove-SqlModuleStub so the stub cmdlets does not spill over to another
        test.
#>

# Suppressing this rule because ConvertTo-SecureString is used to simplify the tests.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:subModuleName = 'SqlServerDsc.Common'

    $script:parentModule = Get-Module -Name $script:moduleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\TestHelpers\CommonTestHelper.psm1')

    # Loading SMO stubs.
    if (-not ('Microsoft.SqlServer.Management.Smo.Server' -as [Type]))
    {
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs') -ChildPath 'SMO.cs')
    }

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlServerDsc.Common\Test-LoginEffectivePermissions' -Tag 'TestLoginEffectivePermissions' {
    BeforeAll {
        $mockAllServerPermissionsPresent = @(
            'Connect SQL',
            'Alter Any Availability Group',
            'View Server State'
        )

        $mockServerPermissionsMissing = @(
            'Connect SQL',
            'View Server State'
        )

        $mockAllLoginPermissionsPresent = @(
            'View Definition',
            'Impersonate'
        )

        $mockLoginPermissionsMissing = @(
            'View Definition'
        )

        $mockInvokeQueryPermissionsSet = @() # Will be set dynamically in the check

        $mockInvokeQueryPermissionsResult = {
            return New-Object -TypeName PSObject -Property @{
                Tables = @{
                    Rows = @{
                        permission_name = $mockInvokeQueryPermissionsSet
                    }
                }
            }
        }

        $testLoginEffectiveServerPermissionsParams = @{
            ServerName   = 'Server1'
            InstanceName = 'MSSQLSERVER'
            Login        = 'NT SERVICE\ClusSvc'
            Permissions  = @()
        }

        $testLoginEffectiveLoginPermissionsParams = @{
            ServerName     = 'Server1'
            InstanceName   = 'MSSQLSERVER'
            Login          = 'NT SERVICE\ClusSvc'
            Permissions    = @()
            SecurableClass = 'LOGIN'
            SecurableName  = 'Login1'
        }
    }

    BeforeEach {
        Mock -CommandName Invoke-SqlDscQuery -MockWith $mockInvokeQueryPermissionsResult
    }

    Context 'When all of the permissions are present' {
        It 'Should return $true when the desired server permissions are present' {
            $mockInvokeQueryPermissionsSet = $mockAllServerPermissionsPresent.Clone()
            $testLoginEffectiveServerPermissionsParams.Permissions = $mockAllServerPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveServerPermissionsParams | Should -BeTrue

            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 1 -Exactly
        }

        It 'Should return $true when the desired login permissions are present' {
            $mockInvokeQueryPermissionsSet = $mockAllLoginPermissionsPresent.Clone()
            $testLoginEffectiveLoginPermissionsParams.Permissions = $mockAllLoginPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveLoginPermissionsParams | Should -BeTrue

            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 1 -Exactly
        }
    }

    Context 'When a permission is missing' {
        It 'Should return $false when the desired server permissions are not present' {
            $mockInvokeQueryPermissionsSet = $mockServerPermissionsMissing.Clone()
            $testLoginEffectiveServerPermissionsParams.Permissions = $mockAllServerPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveServerPermissionsParams | Should -BeFalse

            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 1 -Exactly
        }

        It 'Should return $false when the specified login has no server permissions assigned' {
            $mockInvokeQueryPermissionsSet = @()
            $testLoginEffectiveServerPermissionsParams.Permissions = $mockAllServerPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveServerPermissionsParams | Should -BeFalse

            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 1 -Exactly
        }

        It 'Should return $false when the desired login permissions are not present' {
            $mockInvokeQueryPermissionsSet = $mockLoginPermissionsMissing.Clone()
            $testLoginEffectiveLoginPermissionsParams.Permissions = $mockAllLoginPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveLoginPermissionsParams | Should -BeFalse

            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 1 -Exactly
        }

        It 'Should return $false when the specified login has no login permissions assigned' {
            $mockInvokeQueryPermissionsSet = @()
            $testLoginEffectiveLoginPermissionsParams.Permissions = $mockAllLoginPermissionsPresent.Clone()

            Test-LoginEffectivePermissions @testLoginEffectiveLoginPermissionsParams | Should -BeFalse

            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 1 -Exactly
        }
    }
}
