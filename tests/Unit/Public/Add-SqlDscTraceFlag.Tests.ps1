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

Describe 'Add-SqlDscTraceFlag' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'ByServiceObject'
            MockExpectedParameters = '-ServiceObject <Service> -TraceFlag <uint[]> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'ByServerName'
            MockExpectedParameters = '-TraceFlag <uint[]> [-ServerName <string>] [-InstanceName <string>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Add-SqlDscTraceFlag').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When passing $null as ServiceObject' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Cannot bind argument to parameter ''ServiceObject'' because it is null.'

            { Add-SqlDscTraceFlag -ServiceObject $null } | Should -Throw -ExpectedMessage $mockErrorMessage
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
                    $script:localizedData.TraceFlag_Set_WrongServiceType
                }

                $mockErrorMessage = $mockErrorMessage -f 'SqlServer', 'SqlAgent'

                { Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag @(4199) -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        Context 'When passing the value SilentlyContinue for parameter ErrorAction' {
            It 'Should still throw the correct terminating error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.TraceFlag_Get_WrongServiceType
                }

                $mockErrorMessage = $mockErrorMessage -f 'SqlServer', 'SqlAgent'

                { Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag @(4199) -ErrorAction 'SilentlyContinue' } |
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

        Context 'When passing SilentlyContinue to ErrorAction' {
            It 'Should not throw ' {
                { Add-SqlDscTraceFlag -ServerName 'localhost' -TraceFlag @(4199) -ErrorAction 'SilentlyContinue' } | Should -Not -Throw

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
            }
        }

        Context 'When passing Stop to ErrorAction' {
            It 'Should return an empty array' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.TraceFlag_Add_FailedToFindServiceObject
                }

                { Add-SqlDscTraceFlag -ServerName 'localhost' -TraceFlag @(4199) -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage $mockErrorMessage

                Should -Invoke -CommandName Get-SqlDscManagedComputerService -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When there are no existing trace flags' {
        BeforeAll {
            $mockStartupParameters = '-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'

            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Set-SqlDscTraceFlag
        }

        Context 'When adding a trace flag by a service object' {
            BeforeEach {
                $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
                $mockServiceObject.Name = 'MSSQL$SQL2022'
                $mockServiceObject.StartupParameters = $mockStartupParameters
                $mockServiceObject.Type = 'SqlServer'
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mocked method and have correct value in the object' {
                    Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -Confirm:$false

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mocked method and have correct value in the object' {
                    Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -Force

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should not call the mocked method and should not have changed the value in the object' {
                    Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -WhatIf

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -Exactly -Times 0 -Scope It
                }
            }

            Context 'When passing parameter ServerObject over the pipeline' {
                It 'Should call the mocked method and have correct value in the object' {
                    $mockServiceObject | Add-SqlDscTraceFlag -TraceFlag 4199 -Force

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When adding a trace flag by default parameter set and parameters default values' {
            BeforeAll {
                $mockStartupParameters = '-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf'

                Mock -CommandName Assert-ElevatedUser
                Mock -CommandName Get-SqlDscManagedComputerService -MockWith {
                    return $mockServiceObject
                }
            }

            BeforeEach {
                $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
                $mockServiceObject.StartupParameters = $mockStartupParameters
                $mockServiceObject.Type = 'SqlServer'
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mocked method and have correct value in the object' {
                    Add-SqlDscTraceFlag -TraceFlag 4199 -Confirm:$false

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mocked method and have correct value in the object' {
                    Add-SqlDscTraceFlag -TraceFlag 4199 -Force

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should not call the mocked method and should not have changed the value in the object' {
                    Add-SqlDscTraceFlag -TraceFlag 4199 -WhatIf

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -Exactly -Times 0 -Scope It
                }
            }
        }
    }

    Context 'When there are an existing trace flag' {
        BeforeAll {
            $mockStartupParameters = '-dC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\master.mdf;-eC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Log\ERRORLOG;-lC:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\log.ldf;-T3226'

            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Set-SqlDscTraceFlag
        }

        BeforeEach {
            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.Name = 'MSSQL$SQL2022'
            $mockServiceObject.StartupParameters = $mockStartupParameters
            $mockServiceObject.Type = 'SqlServer'
        }

        It 'Should call the mocked method and have correct value in the object' {
            Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -Force

            Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                $TraceFlag -contains 4199 -and
                $TraceFlag -contains 3226
            } -Exactly -Times 1 -Scope It
        }
    }
}
