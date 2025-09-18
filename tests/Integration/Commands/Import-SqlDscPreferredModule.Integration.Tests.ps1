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
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Import-SqlDscPreferredModule' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Store original environment variable value to restore later
        $script:originalSMODefaultModuleName = $env:SMODefaultModuleName
        
        # Get list of initially loaded modules to restore session state
        $script:initialModules = Get-Module | Where-Object { $_.Name -in @('SqlServer', 'SQLPS') }
    }

    AfterAll {
        # Restore original environment variable
        if ($null -ne $script:originalSMODefaultModuleName)
        {
            $env:SMODefaultModuleName = $script:originalSMODefaultModuleName
        }
        else
        {
            Remove-Item -Path 'env:SMODefaultModuleName' -ErrorAction 'SilentlyContinue'
        }

        # Clean up any modules that were imported during testing
        $currentModules = Get-Module | Where-Object { $_.Name -in @('SqlServer', 'SQLPS') }
        foreach ($module in $currentModules)
        {
            if ($module.Name -notin $script:initialModules.Name)
            {
                Remove-Module -Name $module.Name -Force -ErrorAction 'SilentlyContinue'
            }
        }
    }

    Context 'When importing the default preferred module' {
        BeforeEach {
            # Remove any SQL modules that might be loaded
            Get-Module -Name @('SqlServer', 'SQLPS') | Remove-Module -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should import a module without throwing' {
            { Import-SqlDscPreferredModule -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should import SqlServer module when available' {
            Import-SqlDscPreferredModule -ErrorAction 'Stop'
            
            $importedModule = Get-Module -Name @('SqlServer', 'SQLPS') | Select-Object -First 1
            $importedModule | Should -Not -BeNullOrEmpty
            $importedModule.Name | Should -BeIn @('SqlServer', 'SQLPS')
        }
    }

    Context 'When using the Force parameter' {
        BeforeEach {
            # Remove any SQL modules that might be loaded
            Get-Module -Name @('SqlServer', 'SQLPS') | Remove-Module -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should import a module without throwing when using Force' {
            { Import-SqlDscPreferredModule -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should reload module when Force is used' {
            # First import
            Import-SqlDscPreferredModule -ErrorAction 'Stop'
            $firstImport = Get-Module -Name @('SqlServer', 'SQLPS') | Select-Object -First 1
            
            # Force reimport
            Import-SqlDscPreferredModule -Force -ErrorAction 'Stop'
            $secondImport = Get-Module -Name @('SqlServer', 'SQLPS') | Select-Object -First 1
            
            $secondImport | Should -Not -BeNullOrEmpty
            $secondImport.Name | Should -Be $firstImport.Name
        }
    }

    Context 'When specifying a preferred module name' {
        BeforeEach {
            # Remove any SQL modules that might be loaded
            Get-Module -Name @('SqlServer', 'SQLPS') | Remove-Module -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should import SQLPS when specifically requested' {
            # Skip if SQLPS is not available
            $sqlpsModule = Get-Module -Name 'SQLPS' -ListAvailable
            if (-not $sqlpsModule)
            {
                Set-ItResult -Skipped -Because 'SQLPS module is not available on this system'
                return
            }

            { Import-SqlDscPreferredModule -Name 'SQLPS' -ErrorAction 'Stop' } | Should -Not -Throw
            
            $importedModule = Get-Module -Name 'SQLPS'
            $importedModule | Should -Not -BeNullOrEmpty
            $importedModule.Name | Should -Be 'SQLPS'
        }

        It 'Should import SqlServer when specifically requested' {
            # Skip if SqlServer is not available
            $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable
            if (-not $sqlServerModule)
            {
                Set-ItResult -Skipped -Because 'SqlServer module is not available on this system'
                return
            }

            { Import-SqlDscPreferredModule -Name 'SqlServer' -ErrorAction 'Stop' } | Should -Not -Throw
            
            $importedModule = Get-Module -Name 'SqlServer'
            $importedModule | Should -Not -BeNullOrEmpty
            $importedModule.Name | Should -Be 'SqlServer'
        }
    }

    Context 'When SMODefaultModuleName environment variable is set' {
        BeforeEach {
            # Remove any SQL modules that might be loaded
            Get-Module -Name @('SqlServer', 'SQLPS') | Remove-Module -Force -ErrorAction 'SilentlyContinue'
        }

        AfterEach {
            # Clean up environment variable after each test
            Remove-Item -Path 'env:SMODefaultModuleName' -ErrorAction 'SilentlyContinue'
        }

        It 'Should respect SMODefaultModuleName environment variable when set to SqlServer' {
            # Skip if SqlServer is not available
            $sqlServerModule = Get-Module -Name 'SqlServer' -ListAvailable
            if (-not $sqlServerModule)
            {
                Set-ItResult -Skipped -Because 'SqlServer module is not available on this system'
                return
            }

            $env:SMODefaultModuleName = 'SqlServer'
            
            { Import-SqlDscPreferredModule -ErrorAction 'Stop' } | Should -Not -Throw
            
            $importedModule = Get-Module -Name @('SqlServer', 'SQLPS') | Select-Object -First 1
            $importedModule | Should -Not -BeNullOrEmpty
            $importedModule.Name | Should -Be 'SqlServer'
        }
    }

    Context 'When handling module availability' {
        BeforeEach {
            # Remove any SQL modules that might be loaded
            Get-Module -Name @('SqlServer', 'SQLPS') | Remove-Module -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should handle the case when neither preferred module is available gracefully' {
            # This test verifies error handling when no SQL modules are available
            # We can't easily simulate this in CI where modules are installed, so we test with a non-existent module
            { Import-SqlDscPreferredModule -Name 'NonExistentSqlModule' -ErrorAction 'Stop' } | Should -Throw
        }
    }
}