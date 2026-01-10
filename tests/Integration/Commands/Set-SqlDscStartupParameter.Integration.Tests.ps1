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

# cSpell: ignore DSCSQLTEST
Describe 'Set-SqlDscStartupParameter' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockServerName = Get-ComputerName

        # Get the service object for testing
        $script:serviceObject = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ServiceType 'DatabaseEngine' -ErrorAction 'Stop'

        # Store original startup parameters to restore later
        $script:originalStartupParameters = Get-SqlDscStartupParameter -ServiceObject $script:serviceObject -ErrorAction 'Stop'
    }

    AfterAll {
        # Restore original startup parameters
        if ($script:originalStartupParameters)
        {
            try
            {
                Set-SqlDscStartupParameter -ServiceObject $script:serviceObject -TraceFlag $script:originalStartupParameters.TraceFlag -InternalTraceFlag $script:originalStartupParameters.InternalTraceFlag -Force -ErrorAction 'SilentlyContinue'
            }
            catch
            {
                Write-Warning -Message "Failed to restore original startup parameters: $($_.Exception.Message)"
            }
        }
    }

    Context 'When using parameter set ByServerName' {
        Context 'When setting trace flags' {
            It 'Should set a single trace flag' {
                # Set a single trace flag
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag @(4199) -Force -ErrorAction 'Stop'

                # Verify the trace flag was set
                $result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
                $result.TraceFlag | Should -Contain 4199
            }

            It 'Should set multiple trace flags' {
                # Set multiple trace flags
                $testTraceFlags = @(4199, 1222)
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag $testTraceFlags -Force -ErrorAction 'Stop'

                # Verify the trace flags were set
                $result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
                $result.TraceFlag | Should -Contain 4199
                $result.TraceFlag | Should -Contain 1222
            }

            It 'Should clear all trace flags when given empty array' {
                # First set some trace flags
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag @(4199) -Force -ErrorAction 'Stop'

                # Then clear them
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag @() -Force -ErrorAction 'Stop'

                # Verify trace flags were cleared
                $result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
                $result.TraceFlag | Should -BeNullOrEmpty
            }
        }

        Context 'When setting internal trace flags' {
            It 'Should set internal trace flags' {
                # Set internal trace flags
                $testInternalTraceFlags = @(8011, 8012)
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -InternalTraceFlag $testInternalTraceFlags -Force -ErrorAction 'Stop'

                # Verify the internal trace flags were set
                $result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
                $result.InternalTraceFlag | Should -Contain 8011
                $result.InternalTraceFlag | Should -Contain 8012
            }

            It 'Should clear internal trace flags when given empty array' {
                # First set some internal trace flags
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -InternalTraceFlag @(8011) -Force -ErrorAction 'Stop'

                # Then clear them
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -InternalTraceFlag @() -Force -ErrorAction 'Stop'

                # Verify internal trace flags were cleared
                $result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
                $result.InternalTraceFlag | Should -BeNullOrEmpty
            }
        }

        Context 'When setting both trace flags and internal trace flags' {
            It 'Should set both types of flags simultaneously' {
                # Set both types of flags
                $testTraceFlags = @(4199)
                $testInternalTraceFlags = @(8011)
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag $testTraceFlags -InternalTraceFlag $testInternalTraceFlags -Force -ErrorAction 'Stop'

                # Verify both types were set
                $result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
                $result.TraceFlag | Should -Contain 4199
                $result.InternalTraceFlag | Should -Contain 8011
            }
        }

        Context 'When using default server name' {
            It 'Should use local computer name when ServerName is not specified' {
                Set-SqlDscStartupParameter -InstanceName $script:mockInstanceName -TraceFlag @(4199) -Force -ErrorAction 'Stop'

                # Verify the trace flag was set
                $result = Get-SqlDscStartupParameter -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
                $result.TraceFlag | Should -Contain 4199
            }
        }
    }

    Context 'When using parameter set ByServiceObject' {
        Context 'When setting trace flags via service object' {
            It 'Should set trace flags using service object from pipeline' {
                # Set trace flags using pipeline
                $script:serviceObject | Set-SqlDscStartupParameter -TraceFlag @(4199, 1222) -Force -ErrorAction 'Stop'

                # Verify the trace flags were set
                $result = Get-SqlDscStartupParameter -ServiceObject $script:serviceObject -ErrorAction 'Stop'
                $result.TraceFlag | Should -Contain 4199
                $result.TraceFlag | Should -Contain 1222
            }

            It 'Should set internal trace flags using service object parameter' {
                # Set internal trace flags using service object parameter
                Set-SqlDscStartupParameter -ServiceObject $script:serviceObject -InternalTraceFlag @(8011) -Force -ErrorAction 'Stop'

                # Verify the internal trace flags were set
                $result = Get-SqlDscStartupParameter -ServiceObject $script:serviceObject -ErrorAction 'Stop'
                $result.InternalTraceFlag | Should -Contain 8011
            }
        }
    }

    Context 'When using ShouldProcess with WhatIf' {
        It 'Should not actually change startup parameters when using WhatIf' {
            # Get current startup parameters
            $currentParams = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

            # Use WhatIf to simulate setting different trace flags
            Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -TraceFlag @(9999) -WhatIf

            # Verify the parameters haven't changed
            $newParams = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

            # Compare arrays properly handling nulls/empty arrays
            if ($currentParams.TraceFlag -and $newParams.TraceFlag) {
                Compare-Object -ReferenceObject $currentParams.TraceFlag -DifferenceObject $newParams.TraceFlag | Should -BeNullOrEmpty
            } elseif (-not $currentParams.TraceFlag -and -not $newParams.TraceFlag) {
                # Both should be null/empty - this is expected
                $true | Should -BeTrue
            } else {
                # One is null and the other isn't - this means something changed
                $false | Should -BeTrue -Because "Startup parameters should not change when using WhatIf"
            }
        }
    }

    Context 'When handling error conditions' {
        It 'Should throw an error when instance does not exist' {
            {
                Set-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName 'NonExistentInstance' -TraceFlag @(4199) -Force -ErrorAction 'Stop'
            } | Should -Throw
        }

        It 'Should throw an error when server does not exist' {
            {
                Set-SqlDscStartupParameter -ServerName 'NonExistentServer' -InstanceName $script:mockInstanceName -TraceFlag @(4199) -Force -ErrorAction 'Stop'
            } | Should -Throw
        }
    }
}
