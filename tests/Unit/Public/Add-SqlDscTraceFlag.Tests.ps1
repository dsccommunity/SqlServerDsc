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

    Context 'When there are no existing trace flags' {
        BeforeAll {
            Mock -CommandName Set-SqlDscTraceFlag
            Mock -CommandName Get-SqlDscTraceFlag -MockWith {
                return @()
            }
        }

        Context 'When adding a trace flag by a service object' {
            BeforeAll {
                $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
                $mockServiceObject.Name = 'MSSQL$SQL2022'
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mocked method and have correct value in the object' {
                    { Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -Confirm:$false } | Should -Not -Throw

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mocked method and have correct value in the object' {
                    { Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -Force } | Should -Not -Throw

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should not call the mocked method and should not have changed the value in the object' {
                    { Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -WhatIf } | Should -Not -Throw

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -Exactly -Times 0 -Scope It
                }
            }

            Context 'When passing parameter ServerObject over the pipeline' {
                It 'Should call the mocked method and have correct value in the object' {
                    { $mockServiceObject | Add-SqlDscTraceFlag -TraceFlag 4199 -Force } | Should -Not -Throw

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When adding a trace flag by default parameter set and parameters default values' {
            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mocked method and have correct value in the object' {
                    { Add-SqlDscTraceFlag -TraceFlag 4199 -Confirm:$false } | Should -Not -Throw

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mocked method and have correct value in the object' {
                    { Add-SqlDscTraceFlag -TraceFlag 4199 -Force } | Should -Not -Throw

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                        $TraceFlag -contains 4199
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should not call the mocked method and should not have changed the value in the object' {
                    { Add-SqlDscTraceFlag -TraceFlag 4199 -WhatIf } | Should -Not -Throw

                    Should -Invoke -CommandName Set-SqlDscTraceFlag -Exactly -Times 0 -Scope It
                }
            }
        }
    }

    Context 'When there are an existing trace flag' {
        BeforeAll {
            Mock -CommandName Set-SqlDscTraceFlag
            Mock -CommandName Get-SqlDscTraceFlag -MockWith {
                return @(3226)
            }

            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.Name = 'MSSQL$SQL2022'
        }

        It 'Should call the mocked method and have correct value in the object' {
            { Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -Force } | Should -Not -Throw

            Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                $TraceFlag.Count -eq 2 -and
                $TraceFlag -contains 4199 -and
                $TraceFlag -contains 3226
            } -Exactly -Times 1 -Scope It
        }

        It 'Should not add duplicate if it already exist' {
            { Add-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 3226 -Force } | Should -Not -Throw

            Should -Invoke -CommandName Set-SqlDscTraceFlag -ParameterFilter {
                $TraceFlag.Count -eq 1 -and
                $TraceFlag -contains 3226
            } -Exactly -Times 1 -Scope It
        }
    }
}
