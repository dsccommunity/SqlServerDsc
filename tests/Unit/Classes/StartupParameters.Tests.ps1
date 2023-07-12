[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'StartupParameters' -Tag 'StartupParameters' {
    Context 'When instantiating the class' {
        It 'Should not throw an error' {
            $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                [StartupParameters]::new()
            }
        }

        It 'Should be of the correct type' {
            $mockStartupParametersInstance.GetType().Name | Should -Be 'StartupParameters'
        }
    }

    Context 'When setting and reading single values' {
        It 'Should be able to set value in instance' {
            $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                $startupParametersInstance = [StartupParameters]::new()

                $startupParametersInstance.DataFilePath = $TestDrive
                $startupParametersInstance.LogFilePath = $TestDrive
                $startupParametersInstance.ErrorLogPath = $TestDrive
                $startupParametersInstance.TraceFlag = 4199
                $startupParametersInstance.InternalTraceFlag = 8688

                return $startupParametersInstance
            }
        }

        It 'Should be able read the values from instance' {
            $mockStartupParametersInstance | Should -Not -BeNullOrEmpty

            $mockStartupParametersInstance.DataFilePath | Should -Be $TestDrive
            $mockStartupParametersInstance.LogFilePath | Should -Be $TestDrive
            $mockStartupParametersInstance.ErrorLogPath | Should -Be $TestDrive
            $mockStartupParametersInstance.TraceFlag | Should -Be 4199
            $mockStartupParametersInstance.InternalTraceFlag | Should -Be 8688
        }
    }

    Context 'When setting and reading multiple values' {
        It 'Should be able to set value in instance' {
            $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                $startupParametersInstance = [StartupParameters]::new()

                $startupParametersInstance.DataFilePath = @($TestDrive, 'C:\Temp')
                $startupParametersInstance.LogFilePath = @($TestDrive, 'C:\Temp')
                $startupParametersInstance.ErrorLogPath = @($TestDrive, 'C:\Temp')
                $startupParametersInstance.TraceFlag = @(4199, 3226)
                $startupParametersInstance.InternalTraceFlag = @(8678, 8688)

                return $startupParametersInstance
            }
        }

        It 'Should be able read the values from instance' {
            $mockStartupParametersInstance | Should -Not -BeNullOrEmpty

            $mockStartupParametersInstance.DataFilePath | Should -HaveCount 2
            $mockStartupParametersInstance.DataFilePath | Should -Contain $TestDrive
            $mockStartupParametersInstance.DataFilePath | Should -Contain 'C:\Temp'

            $mockStartupParametersInstance.LogFilePath | Should -HaveCount 2
            $mockStartupParametersInstance.LogFilePath | Should -Contain $TestDrive
            $mockStartupParametersInstance.LogFilePath | Should -Contain 'C:\Temp'

            $mockStartupParametersInstance.ErrorLogPath | Should -HaveCount 2
            $mockStartupParametersInstance.ErrorLogPath | Should -Contain $TestDrive
            $mockStartupParametersInstance.ErrorLogPath | Should -Contain 'C:\Temp'

            $mockStartupParametersInstance.TraceFlag | Should -HaveCount 2
            $mockStartupParametersInstance.TraceFlag | Should -Contain 4199
            $mockStartupParametersInstance.TraceFlag | Should -Contain 3226

            $mockStartupParametersInstance.InternalTraceFlag | Should -HaveCount 2
            $mockStartupParametersInstance.InternalTraceFlag | Should -Contain 8678
            $mockStartupParametersInstance.InternalTraceFlag | Should -Contain 8688
        }
    }

    Context 'When parsing startup parameters' {
        Context 'When there are only default startup parameters' {
            It 'Should parse the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::Parse('-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf')

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance | Should -Not -BeNullOrEmpty
            }

            It 'Should have the correct value for <MockPropertyName>' -ForEach @(
                @{
                    MockPropertyName = 'DataFilePath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf'
                }
                @{
                    MockPropertyName = 'LogFilePath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'
                }
                @{
                    MockPropertyName = 'ErrorLogPath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG'
                }
            ) {
                $mockStartupParametersInstance.$MockPropertyName | Should -Be $MockExpectedValue
            }

            It 'Should have the correct value for TraceFlag' {
                $mockStartupParametersInstance.TraceFlag | Should -BeNullOrEmpty
                $mockStartupParametersInstance.TraceFlag | Should -HaveCount 0
            }

            It 'Should have the correct value for InternalTraceFlag' {
                $mockStartupParametersInstance.InternalTraceFlag | Should -BeNullOrEmpty
                $mockStartupParametersInstance.InternalTraceFlag | Should -HaveCount 0
            }
        }

        Context 'When there are a single trace flag' {
            It 'Should parse the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::Parse('-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf;-T4199')

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance | Should -Not -BeNullOrEmpty
            }

            It 'Should have the correct value for <MockPropertyName>' -ForEach @(
                @{
                    MockPropertyName = 'DataFilePath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf'
                }
                @{
                    MockPropertyName = 'LogFilePath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'
                }
                @{
                    MockPropertyName = 'ErrorLogPath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG'
                }
            ) {
                $mockStartupParametersInstance.$MockPropertyName | Should -Be $MockExpectedValue
            }

            It 'Should have the correct value for TraceFlag' {
                $mockStartupParametersInstance.TraceFlag | Should -HaveCount 1
                $mockStartupParametersInstance.TraceFlag | Should -Be 4199
            }
        }

        Context 'When there are multiple trace flags' {
            It 'Should parse the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::Parse('-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf;-T4199;-T3226')

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance | Should -Not -BeNullOrEmpty
            }

            It 'Should have the correct value for <MockPropertyName>' -ForEach @(
                @{
                    MockPropertyName = 'DataFilePath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf'
                }
                @{
                    MockPropertyName = 'LogFilePath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'
                }
                @{
                    MockPropertyName = 'ErrorLogPath'
                    MockExpectedValue = 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG'
                }
            ) {
                $mockStartupParametersInstance.$MockPropertyName | Should -Be $MockExpectedValue
            }

            It 'Should have the correct value for TraceFlag' {
                $mockStartupParametersInstance.TraceFlag | Should -HaveCount 2
                $mockStartupParametersInstance.TraceFlag | Should -Contain 4199
                $mockStartupParametersInstance.TraceFlag | Should -Contain 3226
            }
        }

        Context 'When there are a single internal trace flag' {
            It 'Should parse the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::Parse('-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf;-t8688')

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance | Should -Not -BeNullOrEmpty
            }

            # Evaluates that startup parameter '-t' is not also interpreted as '-T'.
            It 'Should have the correct value for TraceFlag' {
                $mockStartupParametersInstance.TraceFlag | Should -HaveCount 0
            }

            It 'Should have the correct value for InternalTraceFlag' {
                $mockStartupParametersInstance.InternalTraceFlag | Should -HaveCount 1
                $mockStartupParametersInstance.InternalTraceFlag | Should -Be 8688
            }
        }

        Context 'When there are multiple internal trace flags' {
            It 'Should parse the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::Parse('-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf;-t8688;-t8678')

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance | Should -Not -BeNullOrEmpty
            }

            It 'Should have the correct value for InternalTraceFlag' {
                $mockStartupParametersInstance.InternalTraceFlag | Should -HaveCount 2
                $mockStartupParametersInstance.InternalTraceFlag | Should -Contain 8688
                $mockStartupParametersInstance.InternalTraceFlag | Should -Contain 8678
            }
        }
    }

    Context 'When converting startup parameters to string representation' {
        BeforeAll {
            $mockDefaultExpectedValue = '-d{0};-e{0};-l{0}' -f $TestDrive
        }

        Context 'When there are no trace flags' {
            It 'Should output the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::new()

                    $startupParametersInstance.DataFilePath = $TestDrive
                    $startupParametersInstance.LogFilePath = $TestDrive
                    $startupParametersInstance.ErrorLogPath = $TestDrive

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance.ToString() | Should -Be $mockDefaultExpectedValue
            }
        }

        Context 'When there are a single trace flag' {
            It 'Should output the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::new()

                    $startupParametersInstance.DataFilePath = $TestDrive
                    $startupParametersInstance.LogFilePath = $TestDrive
                    $startupParametersInstance.ErrorLogPath = $TestDrive
                    $startupParametersInstance.TraceFlag = 4199

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance.ToString() | Should -Be ($mockDefaultExpectedValue + ';-T4199')
            }
        }

        Context 'When there are a single trace flag' {
            It 'Should output the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::new()

                    $startupParametersInstance.DataFilePath = $TestDrive
                    $startupParametersInstance.LogFilePath = $TestDrive
                    $startupParametersInstance.ErrorLogPath = $TestDrive
                    $startupParametersInstance.TraceFlag = @(4199, 3226)

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance.ToString() | Should -BeLike ($mockDefaultExpectedValue + '*')
                $mockStartupParametersInstance.ToString() | Should -MatchExactly ';-T4199'
                $mockStartupParametersInstance.ToString() | Should -MatchExactly ';-T3226'
            }
        }

        Context 'When there are a single internal trace flag' {
            It 'Should output the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::new()

                    $startupParametersInstance.DataFilePath = $TestDrive
                    $startupParametersInstance.LogFilePath = $TestDrive
                    $startupParametersInstance.ErrorLogPath = $TestDrive
                    $startupParametersInstance.InternalTraceFlag = 8688

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance.ToString() | Should -Be ($mockDefaultExpectedValue + ';-t8688')
            }
        }

        Context 'When there are multiple internal trace flags' {
            It 'Should output the values correctly' {
                $script:mockStartupParametersInstance = InModuleScope -ScriptBlock {
                    $startupParametersInstance = [StartupParameters]::new()

                    $startupParametersInstance.DataFilePath = $TestDrive
                    $startupParametersInstance.LogFilePath = $TestDrive
                    $startupParametersInstance.ErrorLogPath = $TestDrive
                    $startupParametersInstance.InternalTraceFlag = @(8688, 8678)

                    return $startupParametersInstance
                }

                $mockStartupParametersInstance.ToString() | Should -BeLike ($mockDefaultExpectedValue + '*')
                $mockStartupParametersInstance.ToString() | Should -MatchExactly ';-t8688'
                $mockStartupParametersInstance.ToString() | Should -MatchExactly ';-t8678'
            }

            It 'Should not have set any ''-T'' parameters' {
                $mockStartupParametersInstance.ToString() | Should -Not -MatchExactly ';-T8688'
                $mockStartupParametersInstance.ToString() | Should -Not -MatchExactly ';-T8678'
            }
        }
    }
}
