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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    # Import the SMO module to ensure real SMO types are available
    Import-SqlDscPreferredModule
}

Describe 'New-SqlDscFileGroup' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'When creating a standalone FileGroup with real SMO types' {
        It 'Should create a standalone FileGroup successfully' {
            $result = New-SqlDscFileGroup -Name 'TestFileGroup'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'TestFileGroup'
            $result.Parent | Should -BeNullOrEmpty
        }

        It 'Should create a standalone PRIMARY FileGroup successfully' {
            $result = New-SqlDscFileGroup -Name 'PRIMARY'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'PRIMARY'
            $result.Parent | Should -BeNullOrEmpty
        }
    }

    Context 'When creating a FileGroup with a Database object' {
        BeforeAll {
            # Create a real SMO Database object (not connected to SQL Server)
            $script:mockDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:mockDatabase.Name = 'TestDatabase'
        }

        It 'Should create a FileGroup with Database successfully' {
            $result = New-SqlDscFileGroup -Database $script:mockDatabase -Name 'TestFileGroup' -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'TestFileGroup'
            $result.Parent | Should -Be $script:mockDatabase
        }

        It 'Should accept Database parameter from pipeline' {
            $result = $script:mockDatabase | New-SqlDscFileGroup -Name 'PipelineFileGroup' -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'PipelineFileGroup'
            $result.Parent | Should -Be $script:mockDatabase
        }

        It 'Should support Force parameter to bypass confirmation' {
            $result = New-SqlDscFileGroup -Database $script:mockDatabase -Name 'ForcedFileGroup' -Force

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result.Name | Should -Be 'ForcedFileGroup'
            $result.Parent | Should -Be $script:mockDatabase
        }

        It 'Should return null when user declines confirmation' {
            $result = New-SqlDscFileGroup -Database $script:mockDatabase -Name 'DeclinedFileGroup' -Confirm:$false -WhatIf

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When verifying FileGroup properties' {
        It 'Should have Files collection initialized' {
            $result = New-SqlDscFileGroup -Name 'TestFileGroup'

            $result.Files | Should -Not -BeNullOrEmpty
            $result.Files | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFileCollection'
            $result.Files.Count | Should -Be 0
        }
    }
}

