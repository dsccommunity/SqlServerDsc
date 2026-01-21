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

Describe 'SqlServerDsc.Common\Test-AvailabilityReplicaSeedingModeAutomatic' -Tag 'TestAvailabilityReplicaSeedingModeAutomatic' {
    BeforeAll {
        $mockConnectSql = {
            $mock = @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Version' -Value $mockSqlVersion -PassThru
                )
            )

            # Type the mock as a server object
            $mock.PSObject.TypeNames.Insert(0, 'Microsoft.SqlServer.Management.Smo.Server')

            return $mock
        }

        $mockDynamic_SeedingMode = 'Manual'
        $mockInvokeQuery = {
            return @{
                Tables = @{
                    Rows = @{
                        seeding_mode_desc = $mockDynamic_SeedingMode
                    }
                }
            }
        }

        $testAvailabilityReplicaSeedingModeAutomaticParams = @{
            ServerName              = 'Server1'
            InstanceName            = 'MSSQLSERVER'
            AvailabilityGroupName   = 'Group1'
            AvailabilityReplicaName = 'Replica2'
        }
    }

    Context 'When the replica seeding mode is manual' {
        BeforeEach {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSql
            Mock -CommandName Invoke-SqlDscQuery -MockWith $mockInvokeQuery
        }

        It 'Should return $false when the instance version is <_>' -ForEach @(11, 12) {
            $mockSqlVersion = $_

            Test-AvailabilityReplicaSeedingModeAutomatic @testAvailabilityReplicaSeedingModeAutomaticParams | Should -BeFalse

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 0 -Exactly
        }

        # Test SQL 2016 and later where Seeding Mode is supported.
        It 'Should return $false when the instance version is <_> and the replica seeding mode is manual' -ForEach @(13, 14, 15) {
            $mockSqlVersion = $_

            Test-AvailabilityReplicaSeedingModeAutomatic @testAvailabilityReplicaSeedingModeAutomaticParams | Should -BeFalse

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 1 -Exactly
        }
    }

    Context 'When the replica seeding mode is automatic' {
        BeforeEach {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSql
            Mock -CommandName Invoke-SqlDscQuery -MockWith $mockInvokeQuery
        }

        # Test SQL 2016 and later where Seeding Mode is supported.
        It 'Should return $true when the instance version is <_> and the replica seeding mode is automatic' -ForEach @(13, 14, 15) {
            $mockSqlVersion = $_
            $mockDynamic_SeedingMode = 'Automatic'

            Test-AvailabilityReplicaSeedingModeAutomatic @testAvailabilityReplicaSeedingModeAutomaticParams | Should -BeTrue

            Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
            Should -Invoke -CommandName Invoke-SqlDscQuery -Scope It -Times 1 -Exactly
        }
    }
}
