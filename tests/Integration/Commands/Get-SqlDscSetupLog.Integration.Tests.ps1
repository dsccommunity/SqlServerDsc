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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

Describe 'Get-SqlDscSetupLog' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    Context 'When retrieving SQL Server setup log' {
        It 'Should retrieve the setup log from the most recent installation' {
            # This test verifies that Get-SqlDscSetupLog can successfully retrieve the
            # SQL Server setup log (Summary.txt) from the CI test instance installation
            # Using ErrorAction Stop to ensure the command does not throw on valid path
            $setupLog = Get-SqlDscSetupLog -ErrorAction 'Stop'

            # The log should not be null if SQL Server is installed
            $setupLog | Should -Not -BeNullOrEmpty

            # Each line in the log should be a string
            $setupLog | Should -BeOfType ([System.String])

            # The log content should contain typical SQL Server setup log information
            # We check for common patterns that appear in Summary.txt
            $logContent = $setupLog -join "`n"
            $logContent | Should -Match '(Setup completed|Installation|SQL Server|Feature)'

            Write-Verbose -Message "Retrieved setup log with $($setupLog.Count) lines" -Verbose
        }

        It 'Should throw when setup log path does not exist' {
            # Test that the command throws a terminating error for non-existent paths
            # when using ErrorAction Stop
            {
                Get-SqlDscSetupLog -Path 'C:\NonExistentPath' -ErrorAction 'Stop'
            } | Should -Throw
        }

        It 'Should support custom Path parameter' {
            # Test that a custom path parameter works
            # Using ErrorAction Stop to ensure the command does not throw on valid path
            $result = Get-SqlDscSetupLog -Path 'C:\Program Files\Microsoft SQL Server' -ErrorAction 'Stop'

            # Using the standard path should return results
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should include header and footer in the output' {
            # Verify that the output includes the formatted header and footer
            # that Get-SqlDscSetupLog adds to the raw log content
            # Using ErrorAction Stop to ensure the command does not throw on valid path
            $setupLog = Get-SqlDscSetupLog -ErrorAction 'Stop'

            $setupLog | Should -Not -BeNullOrEmpty

            # The command adds a header line and footer line to the output
            # Verify the output contains multiple lines (header + content + footer)
            $setupLog.Count | Should -BeGreaterThan 2

            # The first line should be a header containing "Summary.txt"
            $setupLog[0] | Should -Match 'Summary\.txt'

            # The last line should be a footer
            $setupLog[-1] | Should -Match 'Summary\.txt'
        }
    }
}
