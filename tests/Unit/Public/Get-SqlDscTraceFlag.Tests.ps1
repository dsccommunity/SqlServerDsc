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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Get-SqlDscTraceFlag' -Tag 'Public' {
    Context 'When passing $null as ServiceObject' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Cannot bind argument to parameter ''ServiceObject'' because it is null.'

            { Get-SqlDscTraceFlag -ServiceObject $null } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When passing a ServiceObject with wrong service type' {
        BeforeAll {
            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.Type = 'SqlAgent'

            Mock -CommandName Assert-ElevatedUser
        }

        Context 'When passing the value Stop for parameter ErrorAction' {
            It 'Should throw the correct error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.TraceFlag_Get_WrongServiceType
                }

                $mockErrorMessage = $mockErrorMessage -f 'SqlServer', 'SqlAgent'

                { Get-SqlDscTraceFlag -ServiceObject $mockServiceObject -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        Context 'When passing the value SilentlyContinue for parameter ErrorAction' {
            It 'Should still throw the correct terminating error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.TraceFlag_Get_WrongServiceType
                }

                $mockErrorMessage = $mockErrorMessage -f 'SqlServer', 'SqlAgent'

                { Get-SqlDscTraceFlag -ServiceObject $mockServiceObject -ErrorAction 'SilentlyContinue' } |
                    Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When passing server name but an Managed Computer Service object is not returned' {
        BeforeAll {
            Mock -CommandName Assert-ElevatedUser

            Mock -CommandName Get-SqlDscManagedComputerService -MockWith {
                return $null
            }
        }

        It 'Should return an empty array' {
            $result = Get-SqlDscTraceFlag -ServerName 'localhost'

            Should -ActualValue $result -BeOfType 'System.UInt32[]'

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
        }
    }

    Context 'When no trace flag exist' {
        BeforeAll {
            # cSpelL: disable-next
            $mockStartupParameters = '-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\mastlog.ldf'

            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.StartupParameters = $mockStartupParameters
            $mockServiceObject.Type = 'SqlServer'

            Mock -CommandName Assert-ElevatedUser

            Mock -CommandName Get-SqlDscManagedComputerService -MockWith {
                return $mockServiceObject
            }
        }

        Context 'When passing no parameters' {
            It 'Should return an empty array' {
                $result = Get-SqlDscTraceFlag

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing specific server name' {
            It 'Should return an empty array' {
                $result = Get-SqlDscTraceFlag -ServerName 'localhost'

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -ParameterFilter {
                    $ServerName -eq 'localhost'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing specific instance name' {
            It 'Should return an empty array' {
                $result = Get-SqlDscTraceFlag -InstanceName 'SQL2022'

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -ParameterFilter {
                    $InstanceName -eq 'SQL2022'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing a service object' {
            It 'Should return an empty array' {
                $result = Get-SqlDscTraceFlag -ServiceObject $mockServiceObject

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -BeNullOrEmpty

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When one trace flag exist' {
        BeforeAll {
            $mockStartupParameters = '-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf;-T4199'

            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.StartupParameters = $mockStartupParameters
            $mockServiceObject.Type = 'SqlServer'

            Mock -CommandName Assert-ElevatedUser

            Mock -CommandName Get-SqlDscManagedComputerService -MockWith {
                return $mockServiceObject
            }
        }

        Context 'When passing no parameters' {
            It 'Should return the correct values' {
                $result = Get-SqlDscTraceFlag

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -HaveCount 1
                $result | Should -Contain 4199

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing specific server name' {
            It 'Should return the correct values' {
                $result = Get-SqlDscTraceFlag -ServerName 'localhost'

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -HaveCount 1
                $result | Should -Contain 4199

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -ParameterFilter {
                    $ServerName -eq 'localhost'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing specific instance name' {
            It 'Should return the correct values' {
                $result = Get-SqlDscTraceFlag -InstanceName 'SQL2022'

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -HaveCount 1
                $result | Should -Contain 4199

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -ParameterFilter {
                    $InstanceName -eq 'SQL2022'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing a service object' {
            It 'Should return the correct values' {
                $result = Get-SqlDscTraceFlag -ServiceObject $mockServiceObject

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -HaveCount 1
                $result | Should -Contain 4199

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When multiple trace flag exist' {
        BeforeAll {
            $mockStartupParameters = '-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf;-T4199;-T3226'

            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.StartupParameters = $mockStartupParameters
            $mockServiceObject.Type = 'SqlServer'

            Mock -CommandName Assert-ElevatedUser

            Mock -CommandName Get-SqlDscManagedComputerService -MockWith {
                return $mockServiceObject
            }
        }

        Context 'When passing no parameters' {
            It 'Should return the correct values' {
                $result = Get-SqlDscTraceFlag

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -HaveCount 2
                $result | Should -Contain 4199
                $result | Should -Contain 3226

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing specific server name' {
            It 'Should return the correct values' {
                $result = Get-SqlDscTraceFlag -ServerName 'localhost'

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -HaveCount 2
                $result | Should -Contain 4199
                $result | Should -Contain 3226

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -ParameterFilter {
                    $ServerName -eq 'localhost'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing specific instance name' {
            It 'Should return the correct values' {
                $result = Get-SqlDscTraceFlag -InstanceName 'SQL2022'

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -HaveCount 2
                $result | Should -Contain 4199
                $result | Should -Contain 3226

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -ParameterFilter {
                    $InstanceName -eq 'SQL2022'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing a service object' {
            It 'Should return the correct values' {
                $result = Get-SqlDscTraceFlag -ServiceObject $mockServiceObject

                Should -ActualValue $result -BeOfType 'System.UInt32[]'

                $result | Should -HaveCount 2
                $result | Should -Contain 4199
                $result | Should -Contain 3226

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 0 -Scope It
            }
        }
    }
}
