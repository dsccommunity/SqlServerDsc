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

Describe 'Add-SqlDscTraceFlag' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        # Test trace flags to use for testing
        $script:testTraceFlags = @(4199, 3226)
        $script:singleTestTraceFlag = 1118
        $script:additionalTestTraceFlag = 2544
    }

    Context 'When adding trace flags using ServerName and InstanceName parameters' {
        BeforeAll {
            # Clean up any existing test trace flags before starting tests
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            $testFlagsToRemove = $currentTraceFlags | Where-Object { $_ -in (@($script:testTraceFlags) + $script:singleTestTraceFlag + $script:additionalTestTraceFlag) }
            if ($testFlagsToRemove)
            {
                Remove-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $testFlagsToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        AfterAll {
            # Clean up test trace flags after tests
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            $testFlagsToRemove = $currentTraceFlags | Where-Object { $_ -in (@($script:testTraceFlags) + $script:singleTestTraceFlag + $script:additionalTestTraceFlag) }
            if ($testFlagsToRemove)
            {
                Remove-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $testFlagsToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should add a single trace flag without error' {
            # Act - Add the trace flag
            $null = Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            # Assert - Verify the trace flag was added
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            $currentTraceFlags | Should -Contain $script:singleTestTraceFlag
        }

        It 'Should add multiple trace flags without error' {
            # Act - Add the trace flags
            $null = Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:testTraceFlags -Force -ErrorAction 'Stop'

            # Assert - Verify the trace flags were added
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            foreach ($traceFlag in $script:testTraceFlags)
            {
                $currentTraceFlags | Should -Contain $traceFlag
            }
        }

        It 'Should not duplicate existing trace flags when adding them again' {
            # Arrange - Ensure a trace flag is already set
            Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            $beforeAddTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            $beforeCount = ($beforeAddTraceFlags | Where-Object { $_ -eq $script:singleTestTraceFlag }).Count

            # Act - Try to add the same trace flag again
            $null = Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            # Assert - Verify no duplicate was created
            $afterAddTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            $afterCount = ($afterAddTraceFlags | Where-Object { $_ -eq $script:singleTestTraceFlag }).Count

            $afterCount | Should -Be $beforeCount
            $afterAddTraceFlags | Should -Contain $script:singleTestTraceFlag
        }

        It 'Should preserve existing trace flags when adding new ones' {
            # Arrange - Add an initial trace flag
            Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            # Act - Add additional trace flags
            $null = Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag $script:additionalTestTraceFlag -Force -ErrorAction 'Stop'

            # Assert - Verify both old and new trace flags exist
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            $currentTraceFlags | Should -Contain $script:singleTestTraceFlag
            $currentTraceFlags | Should -Contain $script:additionalTestTraceFlag
        }

        It 'Should de-duplicate trace flags provided in the input array' {
            # Act - Add trace flags with duplicates in the input array
            $null = Add-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -TraceFlag @($script:singleTestTraceFlag, $script:singleTestTraceFlag, $script:additionalTestTraceFlag, $script:additionalTestTraceFlag) -Force -ErrorAction 'Stop'

            # Assert - Verify each trace flag appears only once
            $currentTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
            ($currentTraceFlags | Where-Object { $_ -eq $script:singleTestTraceFlag }).Count | Should -Be 1
            ($currentTraceFlags | Where-Object { $_ -eq $script:additionalTestTraceFlag }).Count | Should -Be 1
        }
    }

    Context 'When adding trace flags using ServiceObject parameter' {
        BeforeAll {
            # Get the service object for the test instance
            $script:serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

            # Clean up any existing test trace flags before starting tests
            $currentTraceFlags = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject -ErrorAction 'Stop'
            $testFlagsToRemove = $currentTraceFlags | Where-Object { $_ -in (@($script:testTraceFlags) + $script:singleTestTraceFlag + $script:additionalTestTraceFlag) }
            if ($testFlagsToRemove)
            {
                Remove-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag $testFlagsToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        AfterAll {
            # Clean up test trace flags after tests
            $currentTraceFlags = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject -ErrorAction 'Stop'
            $testFlagsToRemove = $currentTraceFlags | Where-Object { $_ -in (@($script:testTraceFlags) + $script:singleTestTraceFlag + $script:additionalTestTraceFlag) }
            if ($testFlagsToRemove)
            {
                Remove-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag $testFlagsToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should add a single trace flag using ServiceObject parameter' {
            # Act - Add the trace flag
            $null = Add-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag $script:singleTestTraceFlag -Force -ErrorAction 'Stop'

            # Assert - Verify the trace flag was added
            $currentTraceFlags = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject -ErrorAction 'Stop'
            $currentTraceFlags | Should -Contain $script:singleTestTraceFlag
        }

        It 'Should add multiple trace flags using ServiceObject parameter' {
            # Act - Add the trace flags
            $null = Add-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag $script:testTraceFlags -Force -ErrorAction 'Stop'

            # Assert - Verify the trace flags were added
            $currentTraceFlags = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject -ErrorAction 'Stop'
            foreach ($traceFlag in $script:testTraceFlags)
            {
                $currentTraceFlags | Should -Contain $traceFlag
            }
        }

        It 'Should de-duplicate trace flags provided in the input array using ServiceObject parameter' {
            # Act - Add trace flags with duplicates in the input array
            $null = Add-SqlDscTraceFlag -ServiceObject $script:serviceObject -TraceFlag @($script:singleTestTraceFlag, $script:singleTestTraceFlag, $script:additionalTestTraceFlag, $script:additionalTestTraceFlag) -Force -ErrorAction 'Stop'

            # Assert - Verify each trace flag appears only once
            $currentTraceFlags = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject -ErrorAction 'Stop'
            ($currentTraceFlags | Where-Object { $_ -eq $script:singleTestTraceFlag }).Count | Should -Be 1
            ($currentTraceFlags | Where-Object { $_ -eq $script:additionalTestTraceFlag }).Count | Should -Be 1
        }
    }
}
