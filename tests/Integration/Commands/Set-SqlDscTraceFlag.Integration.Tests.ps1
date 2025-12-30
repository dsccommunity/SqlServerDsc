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

Describe 'Set-SqlDscTraceFlag' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockServerName = Get-ComputerName

        # Store the original trace flags to restore them later
        $script:originalTraceFlags = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
    }

    AfterAll {
        # Restore the original trace flags
        if ($script:originalTraceFlags)
        {
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag $script:originalTraceFlags -Force -ErrorAction 'SilentlyContinue'
        }
        else
        {
            # Clear all trace flags if there were none originally
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag @() -Force -ErrorAction 'SilentlyContinue'
        }
    }

    Context 'When setting trace flags' {
        It 'Should set a single trace flag and verify the change' {
            # Set trace flag 3226 (suppress successful backup messages)
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag 3226 -Force -ErrorAction 'Stop'

            # Verify it's set
            $result = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            $result | Should -Contain 3226
        }

        It 'Should set multiple trace flags and verify the change' {
            # Set multiple trace flags
            $testTraceFlags = @(3226, 1222)
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag $testTraceFlags -Force -ErrorAction 'Stop'

            # Verify they're set
            $result = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            foreach ($flag in $testTraceFlags)
            {
                $result | Should -Contain $flag
            }
        }

        It 'Should replace existing trace flags with new ones' {
            # First, set trace flag 3226
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag 3226 -Force -ErrorAction 'Stop'

            # Verify it's set
            $result = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            $result | Should -Contain 3226

            # Now replace with different trace flag
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag 1222 -Force -ErrorAction 'Stop'

            # Verify the old flag is gone and new one is present
            $result = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            $result | Should -Contain 1222
            $result | Should -Not -Contain 3226
        }

        It 'Should clear all trace flags when passing empty array' {
            # First, set some trace flags
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag @(3226, 1222) -Force -ErrorAction 'Stop'

            # Verify they're set
            $result = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            $result | Should -Contain 3226
            $result | Should -Contain 1222

            # Now clear all trace flags
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag @() -Force -ErrorAction 'Stop'

            # Verify they're cleared
            $result = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using ShouldProcess with WhatIf' {
        It 'Should not actually change the trace flags when using WhatIf' {
            # Get current trace flags
            $originalFlags = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName

            # Use WhatIf to simulate setting different trace flags
            Set-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag 4199 -WhatIf

            # Verify the trace flags haven't changed
            $currentFlags = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            if ($originalFlags)
            {
                $currentFlags | Should -HaveCount $originalFlags.Count
                foreach ($flag in $originalFlags)
                {
                    $currentFlags | Should -Contain $flag
                }
            }
            else
            {
                $currentFlags | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When using ServiceObject parameter' {
        It 'Should accept ServiceObject from pipeline and set trace flags' {
            # Get the service object
            $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName $script:mockInstanceName -ServerName $script:mockServerName -ErrorAction 'Stop'
            $serviceObject | Should -Not -BeNullOrEmpty

            # Set trace flag using pipeline
            $serviceObject | Set-SqlDscTraceFlag -TraceFlag 3226 -Force -ErrorAction 'Stop'

            # Verify it's set
            $result = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            $result | Should -Contain 3226
        }

        It 'Should accept ServiceObject parameter directly' {
            # Get the service object
            $serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName $script:mockInstanceName -ServerName $script:mockServerName -ErrorAction 'Stop'
            $serviceObject | Should -Not -BeNullOrEmpty

            # Set trace flag using direct parameter
            Set-SqlDscTraceFlag -ServiceObject $serviceObject -TraceFlag 1222 -Force -ErrorAction 'Stop'

            # Verify it's set
            $result = Get-SqlDscTraceFlag -ServerName $script:mockServerName -InstanceName $script:mockInstanceName
            $result | Should -Contain 1222
        }
    }

    Context 'When using default parameters' {
        It 'Should work with default server name and instance name' {
            # This test assumes the command is run on the same server as the SQL instance
            # and uses MSSQLSERVER as default instance, but our test instance is DSCSQLTEST
            # so we need to specify the instance name
            Set-SqlDscTraceFlag -InstanceName $script:mockInstanceName -TraceFlag 3226 -Force -ErrorAction 'Stop'

            # Verify it's set
            $result = Get-SqlDscTraceFlag -InstanceName $script:mockInstanceName
            $result | Should -Contain 3226
        }
    }
}
