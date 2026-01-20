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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
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

Describe 'SqlServerDsc.Common\Get-SqlInstanceMajorVersion' -Tag 'GetSqlInstanceMajorVersion' {
    BeforeAll {
        $mockSqlMajorVersion = 13
        $mockInstanceName = 'TEST'

        $mockGetItemProperty_MicrosoftSQLServer_InstanceNames_SQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name $mockInstanceName -Value $mockInstance_InstanceId -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_MicrosoftSQLServer_FullInstanceId_Setup = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Version' -Value "$($mockSqlMajorVersion).0.4001.0" -PassThru -Force
                )
            )
        }

        $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL = {
            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'
        }

        $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup = {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$mockInstance_InstanceId\Setup"
        }
    }

    BeforeEach {
        Mock -CommandName Get-ItemProperty `
            -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL `
            -MockWith $mockGetItemProperty_MicrosoftSQLServer_InstanceNames_SQL

        Mock -CommandName Get-ItemProperty `
            -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup `
            -MockWith $mockGetItemProperty_MicrosoftSQLServer_FullInstanceId_Setup
    }

    $mockInstance_InstanceId = "MSSQL$($mockSqlMajorVersion).$($mockInstanceName)"

    Context 'When calling Get-SqlInstanceMajorVersion' {
        It 'Should return the correct major SQL version number' {
            $result = Get-SqlInstanceMajorVersion -InstanceName $mockInstanceName
            $result | Should -Be $mockSqlMajorVersion

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup
        }
    }

    Context 'When calling Get-SqlInstanceMajorVersion and nothing is returned' {
        It 'Should throw the correct error' {
            Mock -CommandName Get-ItemProperty `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup `
                -MockWith {
                return New-Object -TypeName Object
            }

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.SqlServerVersionIsInvalid
            }

            $mockErrorMessage = Get-InvalidResultRecord -Message (
                $mockLocalizedString -f $mockInstanceName
            )

            $mockErrorMessage | Should -Not -BeNullOrEmpty

            { Get-SqlInstanceMajorVersion -InstanceName $mockInstanceName } | Should -Throw -ExpectedMessage $mockErrorMessage

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_InstanceNames_SQL

            Should -Invoke -CommandName Get-ItemProperty -Exactly -Times 1 -Scope It `
                -ParameterFilter $mockGetItemProperty_ParameterFilter_MicrosoftSQLServer_FullInstanceId_Setup
        }
    }
}
