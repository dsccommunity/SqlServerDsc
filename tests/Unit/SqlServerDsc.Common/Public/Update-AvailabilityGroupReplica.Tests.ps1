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

Describe 'SqlServerDsc.Common\Update-AvailabilityGroupReplica' -Tag 'UpdateAvailabilityGroupReplica' {
    Context 'When the Availability Group Replica is altered' {
        It 'Should silently alter the Availability Group Replica' {
            $availabilityReplica = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica

            $null = Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityReplica
        }

        It 'Should throw the correct error, AlterAvailabilityGroupReplicaFailed, when altering the Availability Group Replica fails' {
            $availabilityReplica = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityReplica
            $availabilityReplica.Name = 'AlterFailed'

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.AlterAvailabilityGroupReplicaFailed
            }

            $mockErrorRecord = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $availabilityReplica.Name
            )

            $mockErrorRecord.Exception.Message | Should -Not -BeNullOrEmpty

            { Update-AvailabilityGroupReplica -AvailabilityGroupReplica $availabilityReplica } |
                Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
        }
    }
}
