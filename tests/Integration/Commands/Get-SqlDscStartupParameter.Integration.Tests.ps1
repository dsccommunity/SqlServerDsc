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
Describe 'Get-SqlDscStartupParameter' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockServerName = Get-ComputerName
    }

    Context 'When using parameter set ByServerName' {
        Context 'When getting startup parameters with default parameters' {
            It 'Should return a StartupParameters object for the test instance' {
                $result = Get-SqlDscStartupParameter -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType (InModuleScope -ModuleName $script:moduleName -ScriptBlock { [StartupParameters] })
                $result.DataFilePath | Should -Not -BeNullOrEmpty
                $result.LogFilePath | Should -Not -BeNullOrEmpty
                $result.ErrorLogPath | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When getting startup parameters for a specific instance' {
            It 'Should return a StartupParameters object for the specified instance' {
                $result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType (InModuleScope -ModuleName $script:moduleName -ScriptBlock { [StartupParameters] })
                $result.DataFilePath | Should -Not -BeNullOrEmpty
                $result.LogFilePath | Should -Not -BeNullOrEmpty
                $result.ErrorLogPath | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When getting startup parameters for a specific server name' {
            It 'Should return a StartupParameters object for the specified server' {
                $result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType (InModuleScope -ModuleName $script:moduleName -ScriptBlock { [StartupParameters] })
                $result.DataFilePath | Should -Not -BeNullOrEmpty
                $result.LogFilePath | Should -Not -BeNullOrEmpty
                $result.ErrorLogPath | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When getting startup parameters for a non-existent instance' {
            It 'Should throw an error when the instance does not exist' {
                {
                    Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName 'NonExistentInstance' -ErrorAction 'Stop'
                } | Should -Throw -ErrorId 'GSDSP0001,Get-SqlDscStartupParameter'
            }
        }
    }

    Context 'When using parameter set ByServiceObject' {
        BeforeAll {
            $script:serviceObject = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ServiceType 'DatabaseEngine' -ErrorAction 'Stop'
        }

        Context 'When getting startup parameters using a service object' {
            It 'Should return a StartupParameters object for the service object' {
                $result = Get-SqlDscStartupParameter -ServiceObject $script:serviceObject -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType (InModuleScope -ModuleName $script:moduleName -ScriptBlock { [StartupParameters] })
                $result.DataFilePath | Should -Not -BeNullOrEmpty
                $result.LogFilePath | Should -Not -BeNullOrEmpty
                $result.ErrorLogPath | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When getting startup parameters using pipeline input' {
            It 'Should accept ServiceObject from pipeline and return StartupParameters' {
                $result = $script:serviceObject | Get-SqlDscStartupParameter -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType (InModuleScope -ModuleName $script:moduleName -ScriptBlock { [StartupParameters] })
                $result.DataFilePath | Should -Not -BeNullOrEmpty
                $result.LogFilePath | Should -Not -BeNullOrEmpty
                $result.ErrorLogPath | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When passing wrong service type' {
            BeforeAll {
                # Get a non-DatabaseEngine service for testing
                $script:wrongServiceObject = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ServiceType 'SqlServerAgent' -ErrorAction 'Stop'
            }

            It 'Should throw an error when the service type is not DatabaseEngine' {
                {
                    Get-SqlDscStartupParameter -ServiceObject $script:wrongServiceObject -ErrorAction 'Stop'
                } | Should -Throw
            }
        }
    }

    Context 'When validating output properties' {
        BeforeAll {
            $script:result = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
        }

        It 'Should return an object with expected DataFilePath property' {
            $script:result.DataFilePath | Should -Not -BeNullOrEmpty
            $script:result.DataFilePath | Should -BeOfType ([System.String])
            $script:result.DataFilePath | Should -Match '\.mdf$'
        }

        It 'Should return an object with expected LogFilePath property' {
            $script:result.LogFilePath | Should -Not -BeNullOrEmpty
            $script:result.LogFilePath | Should -BeOfType ([System.String])
            $script:result.LogFilePath | Should -Match '\.ldf$'
        }

        It 'Should return an object with expected ErrorLogPath property' {
            $script:result.ErrorLogPath | Should -Not -BeNullOrEmpty
            $script:result.ErrorLogPath | Should -BeOfType ([System.String])
            $script:result.ErrorLogPath | Should -Match 'ERRORLOG$'
        }

        It 'Should return TraceFlag property as expected type' {
            # TraceFlag can be null, a single UInt32, or an array
            if ($null -ne $script:result.TraceFlag) {
                # Check if it's either a single UInt32 or UInt32 array
                ($script:result.TraceFlag -is [System.UInt32]) -or ($script:result.TraceFlag -is [System.UInt32[]]) | Should -BeTrue -Because 'TraceFlag can be a single value or array depending on how many flags are set'
            } else {
                $script:result.TraceFlag | Should -BeNullOrEmpty -Because 'TraceFlag can be empty/null if no trace flags are set'
            }
        }

        It 'Should return InternalTraceFlag property as expected type' {
            # InternalTraceFlag can be null, a single UInt32, or an array
            if ($null -ne $script:result.InternalTraceFlag) {
                # Check if it's either a single UInt32 or UInt32 array
                ($script:result.InternalTraceFlag -is [System.UInt32]) -or ($script:result.InternalTraceFlag -is [System.UInt32[]]) | Should -BeTrue -Because 'InternalTraceFlag can be a single value or array depending on how many flags are set'
            } else {
                $script:result.InternalTraceFlag | Should -BeNullOrEmpty -Because 'InternalTraceFlag can be empty/null if no internal trace flags are set'
            }
        }
    }

    Context 'When comparing results from different parameter sets' {
        It 'Should return the same results for ByServerName and ByServiceObject parameter sets' {
            $resultByServerName = Get-SqlDscStartupParameter -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

            $serviceObject = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ServiceType 'DatabaseEngine' -ErrorAction 'Stop'
            $resultByServiceObject = Get-SqlDscStartupParameter -ServiceObject $serviceObject -ErrorAction 'Stop'

            $resultByServerName.DataFilePath | Should -Be $resultByServiceObject.DataFilePath
            $resultByServerName.LogFilePath | Should -Be $resultByServiceObject.LogFilePath
            $resultByServerName.ErrorLogPath | Should -Be $resultByServiceObject.ErrorLogPath
            $resultByServerName.TraceFlag | Should -Be $resultByServiceObject.TraceFlag
            $resultByServerName.InternalTraceFlag | Should -Be $resultByServiceObject.InternalTraceFlag
        }
    }
}
