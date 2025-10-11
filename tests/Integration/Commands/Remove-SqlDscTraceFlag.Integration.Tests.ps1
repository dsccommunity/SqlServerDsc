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

Describe 'Remove-SqlDscTraceFlag' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        # Test trace flags to use for testing
        $script:testTraceFlags = @(4199, 3226)
        $script:singleTestTraceFlag = 1118
    }

    Context 'When removing trace flags using ServerName and InstanceName parameters' {
        It 'Should remove a single trace flag without error' {
            # Arrange - Add a test trace flag first
            $null = Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            # Act - Remove the trace flag
            $null = Remove-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            # Assert - Verify the trace flag was removed
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            $currentTraceFlags | Should -Not -Contain $script:singleTestTraceFlag
        }

        It 'Should remove multiple trace flags without error' {
            # Arrange - Add test trace flags first
            $null = Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:testTraceFlags -Force -ErrorAction 'Stop'

            # Act - Remove the trace flags
            $null = Remove-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:testTraceFlags -Force -ErrorAction 'Stop'

            # Assert - Verify the trace flags were removed
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            foreach ($traceFlag in $script:testTraceFlags)
            {
                $currentTraceFlags | Should -Not -Contain $traceFlag
            }
        }

        It 'Should not error when removing non-existent trace flags' {
            # Act & Assert - Removing a trace flag that doesn't exist should not throw
            $null = Remove-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag 9999 -Force -ErrorAction 'Stop'
        }

        It 'Should preserve other existing trace flags when removing specific ones' {
            # Arrange - Add multiple trace flags
            $allTestFlags = @(4199, 3226, 1118, 2544)
            $flagsToRemove = @(4199, 1118)
            $flagsToKeep = @(3226, 2544)

            $null = Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $allTestFlags -Force -ErrorAction 'Stop'

            # Act - Remove only some of the trace flags
            $null = Remove-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $flagsToRemove -Force -ErrorAction 'Stop'

            # Assert - Verify correct flags were removed and others preserved
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

            foreach ($removedFlag in $flagsToRemove)
            {
                $currentTraceFlags | Should -Not -Contain $removedFlag
            }

            foreach ($keptFlag in $flagsToKeep)
            {
                $currentTraceFlags | Should -Contain $keptFlag
            }

            # Clean up - Remove remaining test flags
            Remove-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $flagsToKeep -Force -ErrorAction 'SilentlyContinue'
        }
    }

    Context 'When removing trace flags using ServiceObject parameter' {
        BeforeAll {
            # Get the service object for the test instance
            $script:serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
        }

        It 'Should remove a single trace flag using ServiceObject parameter' {
            # Arrange - Add a test trace flag first
            $null = Add-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            # Act - Remove the trace flag
            $null = Remove-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            # Assert - Verify the trace flag was removed
            $currentTraceFlags = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject -ErrorAction 'Stop'
            $currentTraceFlags | Should -Not -Contain $script:singleTestTraceFlag
        }

        It 'Should remove multiple trace flags using ServiceObject parameter' {
            # Arrange - Add test trace flags first
            $null = Add-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag $script:testTraceFlags -Force -ErrorAction 'Stop'

            # Act - Remove the trace flags
            $null = Remove-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag $script:testTraceFlags -Force -ErrorAction 'Stop'

            # Assert - Verify the trace flags were removed
            $currentTraceFlags = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject -ErrorAction 'Stop'
            foreach ($traceFlag in $script:testTraceFlags)
            {
                $currentTraceFlags | Should -Not -Contain $traceFlag
            }
        }
    }
}
