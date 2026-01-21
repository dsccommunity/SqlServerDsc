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

Describe 'SqlServerDsc.Common\Test-ImpersonatePermissions' -Tag 'TestImpersonatePermissions' {
    BeforeAll {
        $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter = {
            $Permissions -eq @('IMPERSONATE ANY LOGIN')
        }

        $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter = {
            $Permissions -eq @('CONTROL SERVER')
        }

        $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter = {
            $Permissions -eq @('IMPERSONATE')
        }

        $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter = {
            $Permissions -eq @('CONTROL')
        }

        $mockConnectionContextObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerConnection
        $mockConnectionContextObject.TrueLogin = 'Login1'

        $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
        $mockServerObject.ComputerNamePhysicalNetBIOS = 'Server1'
        $mockServerObject.ServiceName = 'MSSQLSERVER'
        $mockServerObject.ConnectionContext = $mockConnectionContextObject
    }

    BeforeEach {
        Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -MockWith { $false }
        Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -MockWith { $false }
        Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -MockWith { $false }
        Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -MockWith { $false }
    }

    Context 'When impersonate permissions are present for the login' {
        It 'Should return true when the impersonate any login permissions are present for the login' {
            Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -MockWith { $true }
            Test-ImpersonatePermissions -ServerObject $mockServerObject | Should -BeTrue

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -Scope It -Times 1 -Exactly
        }

        It 'Should return true when the control server permissions are present for the login' {
            Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -MockWith { $true }
            Test-ImpersonatePermissions -ServerObject $mockServerObject | Should -BeTrue

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -Scope It -Times 1 -Exactly
        }

        It 'Should return true when the impersonate login permissions are present for the login' {
            Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -MockWith { $true }
            Test-ImpersonatePermissions -ServerObject $mockServerObject -SecurableName 'Login1' | Should -BeTrue

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -Scope It -Times 1 -Exactly
        }

        It 'Should return true when the control login permissions are present for the login' {
            Mock -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -MockWith { $true }
            Test-ImpersonatePermissions -ServerObject $mockServerObject -SecurableName 'Login1' | Should -BeTrue

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -Scope It -Times 1 -Exactly
        }
    }

    Context 'When impersonate permissions are missing for the login' {
        It 'Should return false when the server permissions are missing for the login' {
            Test-ImpersonatePermissions -ServerObject $mockServerObject | Should -BeFalse

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -Scope It -Times 0 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -Scope It -Times 0 -Exactly
        }

        It 'Should return false when the login permissions are missing for the login' {
            Test-ImpersonatePermissions -ServerObject $mockServerObject -SecurableName 'Login1' | Should -BeFalse

            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateAnyLogin_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlServer_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ImpersonateLogin_ParameterFilter -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Test-LoginEffectivePermissions -ParameterFilter $mockTestLoginEffectivePermissions_ControlLogin_ParameterFilter -Scope It -Times 1 -Exactly
        }
    }
}
