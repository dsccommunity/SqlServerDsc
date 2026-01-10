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
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Test-SqlDscIsSupportedFeature' -Tag 'Public' {
    Context 'When testing a feature that is not specified as neither added or removed' {
        It 'Should return $true for major version <_>' -ForEach @(6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 999) {
            Test-SqlDscIsSupportedFeature -Feature 'SQLENGINE' -ProductVersion $_ | Should -BeTrue
        }
    }

    Context 'When a feature has been removed for the target major version' {
        It 'Should return $false' {
            Test-SqlDscIsSupportedFeature -Feature 'RS' -ProductVersion 14 | Should -BeFalse
        }
    }

    Context 'When a feature has been removed in a previous major version than target major version' {
        It 'Should return $false' {
            Test-SqlDscIsSupportedFeature -Feature 'RS' -ProductVersion 999 | Should -BeFalse
        }
    }

    Context 'When a feature has been remove in a newer major version than target major version' {
        It 'Should return $true' {
            Test-SqlDscIsSupportedFeature -Feature 'RS' -ProductVersion 13 | Should -BeTrue
        }
    }

    Context 'When a feature has been added in a newer major version than target major version' {
        It 'Should return $false' {
            Test-SqlDscIsSupportedFeature -Feature 'PolyBaseCore' -ProductVersion 14 | Should -BeFalse
        }
    }

    Context 'When a feature has been added for the target major version' {
        It 'Should return $true' {
            Test-SqlDscIsSupportedFeature -Feature 'PolyBaseCore' -ProductVersion 15 | Should -BeTrue
        }
    }

    Context 'When a feature has been added in a previous major version than target major version' {
        It 'Should return $true' {
            Test-SqlDscIsSupportedFeature -Feature 'PolyBaseCore' -ProductVersion 999 | Should -BeTrue
        }
    }

    Context 'When a feature is only supported by a specific major version' {
        It 'Should return $true for the supported major version' {
            Test-SqlDscIsSupportedFeature -Feature 'PolyBaseJava' -ProductVersion 15 | Should -BeTrue
        }

        It 'Should return $false for a newer major version' {
            Test-SqlDscIsSupportedFeature -Feature 'PolyBaseJava' -ProductVersion 16 | Should -BeFalse
        }

        It 'Should return $false for an older major version' {
            Test-SqlDscIsSupportedFeature -Feature 'PolyBaseJava' -ProductVersion 14 | Should -BeFalse
        }
    }

    Context 'When DQ, DQC, and MDS features are discontinued in SQL Server 2025 (17.x)' {
        It 'Should return $true for feature <Feature> on major version 16' -ForEach @(
            @{ Feature = 'DQ' }
            @{ Feature = 'DQC' }
            @{ Feature = 'MDS' }
        ) {
            Test-SqlDscIsSupportedFeature -Feature $Feature -ProductVersion 16 | Should -BeTrue
        }

        It 'Should return $false for feature <Feature> on major version 17' -ForEach @(
            @{ Feature = 'DQ' }
            @{ Feature = 'DQC' }
            @{ Feature = 'MDS' }
        ) {
            Test-SqlDscIsSupportedFeature -Feature $Feature -ProductVersion 17 | Should -BeFalse
        }

        It 'Should return $false for feature <Feature> on major version 999 (future version)' -ForEach @(
            @{ Feature = 'DQ' }
            @{ Feature = 'DQC' }
            @{ Feature = 'MDS' }
        ) {
            Test-SqlDscIsSupportedFeature -Feature $Feature -ProductVersion 999 | Should -BeFalse
        }
    }
}
