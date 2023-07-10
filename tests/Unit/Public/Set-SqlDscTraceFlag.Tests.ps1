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

Describe 'Set-SqlDscTraceFlag' -Tag 'Public' {
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
        $result = (Get-Command -Name 'Set-SqlDscTraceFlag').ParameterSets |
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

            { Set-SqlDscTraceFlag -ServiceObject $null } | Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When setting a trace flag by a service object' {
        BeforeAll {
            Mock -CommandName Set-SqlDscStartupParameter

            $mockServiceObject = [Microsoft.SqlServer.Management.Smo.Wmi.Service]::CreateTypeInstance()
            $mockServiceObject.Name = 'MSSQL$SQL2022'
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct value in the object' {
                { Set-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Set-SqlDscStartupParameter -ParameterFilter {
                    $TraceFlag -contains 4199
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct value in the object' {
                { Set-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -Force } | Should -Not -Throw

                Should -Invoke -CommandName Set-SqlDscStartupParameter -ParameterFilter {
                    $TraceFlag -contains 4199
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should not call the mocked method and should not have changed the value in the object' {
                { Set-SqlDscTraceFlag -ServiceObject $mockServiceObject -TraceFlag 4199 -WhatIf } | Should -Not -Throw

                Should -Invoke -CommandName Set-SqlDscStartupParameter -Exactly -Times 0 -Scope It
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should call the mocked method and have correct value in the object' {
                { $mockServiceObject | Set-SqlDscTraceFlag -TraceFlag 4199 -Force } | Should -Not -Throw

                Should -Invoke -CommandName Set-SqlDscStartupParameter -ParameterFilter {
                    $TraceFlag -contains 4199
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When setting a trace flag by default parameter set and parameters default values' {
        BeforeAll {
            Mock -CommandName Set-SqlDscStartupParameter
        }

        Context 'When using parameter Confirm with value $false' {
            It 'Should call the mocked method and have correct value in the object' {
                { Set-SqlDscTraceFlag -TraceFlag 4199 -Confirm:$false } | Should -Not -Throw

                Should -Invoke -CommandName Set-SqlDscStartupParameter -ParameterFilter {
                    $TraceFlag -contains 4199
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using parameter Force' {
            It 'Should call the mocked method and have correct value in the object' {
                { Set-SqlDscTraceFlag -TraceFlag 4199 -Force } | Should -Not -Throw

                Should -Invoke -CommandName Set-SqlDscStartupParameter -ParameterFilter {
                    $TraceFlag -contains 4199
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using parameter WhatIf' {
            It 'Should not call the mocked method and should not have changed the value in the object' {
                { Set-SqlDscTraceFlag -TraceFlag 4199 -WhatIf } | Should -Not -Throw

                Should -Invoke -CommandName Set-SqlDscStartupParameter -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When clearing all trace flags' {
        BeforeAll {
            Mock -CommandName Set-SqlDscStartupParameter
        }

        It 'Should call the mocked method and have correct value in the object' {
            { Set-SqlDscTraceFlag -TraceFlag @() -Force } | Should -Not -Throw

            Should -Invoke -CommandName Set-SqlDscStartupParameter -ParameterFilter {
                $TraceFlag.Count -eq 0
            } -Exactly -Times 1 -Scope It
        }
    }
}
