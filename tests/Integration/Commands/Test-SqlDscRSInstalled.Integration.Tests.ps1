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

Describe 'Test-SqlDscRSInstalled' {
    Context 'When testing if a specific Reporting Services instance exists' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
        It 'Should return $false for a non-existing instance' {
            # We'll test with a fake instance name that we know doesn't exist.
            $result = Test-SqlDscRSInstalled -InstanceName 'FAKE_RS_INSTANCE'

            $result | Should -BeFalse
        }
    }

    Context 'When testing if a specific Reporting Services instance exists' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should return $true for an existing instance' {
            # We'll test with a real instance name that we know exists.
            $result = Test-SqlDscRSInstalled -InstanceName 'SSRS'

            $result | Should -BeTrue
        }
    }

    Context 'When testing if a specific Reporting Services instance exists' -Tag @('Integration_PowerBI') {
        It 'Should return $true for an existing instance' {
            # We'll test with a real instance name that we know exists. cSpell:ignore PBIRS
            $result = Test-SqlDscRSInstalled -InstanceName 'PBIRS'

            $result | Should -BeTrue
        }
    }
}
