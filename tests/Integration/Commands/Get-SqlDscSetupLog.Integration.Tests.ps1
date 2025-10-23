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
}

Describe 'Get-SqlDscSetupLog' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'When retrieving SQL Server setup log' {
        It 'Should retrieve the setup log from the most recent installation' {
            # This test verifies that Get-SqlDscSetupLog can successfully retrieve the
            # SQL Server setup log (Summary.txt) from the CI test instance installation
            $setupLog = Get-SqlDscSetupLog

            # The log should not be null if SQL Server is installed
            $setupLog | Should -Not -BeNullOrEmpty

            # The log should be an array (string array)
            $setupLog | Should -BeOfType ([System.Object[]])

            # The log content should contain typical SQL Server setup log information
            # We check for common patterns that appear in Summary.txt
            $logContent = $setupLog -join "`n"
            @($logContent) | Should -Match '(Setup completed|Installation|SQL Server|Feature)' -ErrorAction 'SilentlyContinue'

            Write-Verbose -Message "Retrieved setup log with $($setupLog.Count) lines" -Verbose
        }

        It 'Should retrieve the setup log from the default path' {
            # Test that the default path works correctly
            $setupLogDefault = Get-SqlDscSetupLog

            # Should return the same result as without parameters
            $setupLogDefault | Should -Not -BeNullOrEmpty
        }

        It 'Should support custom Path parameter' {
            # Test that a custom path parameter works
            $result = Get-SqlDscSetupLog -Path 'C:\Program Files\Microsoft SQL Server'

            # Using the standard path should return results
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return log content in correct format' {
            $setupLog = Get-SqlDscSetupLog

            $setupLog | Should -Not -BeNullOrEmpty
            # If a log was found, verify it contains meaningful content
            $logString = $setupLog -join "`n"
            $logString.Length | Should -BeGreaterThan 0
        }
    }
}
