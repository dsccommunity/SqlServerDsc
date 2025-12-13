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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

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

Describe 'Test-SqlDscIsInstalledInstance' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            MockExpectedParameters = '[[-InstanceName] <string>] [[-ServiceType] <string[]>] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Test-SqlDscIsInstalledInstance').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name       = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name       = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    Context 'When no SQL Server instances are installed' {
        BeforeAll {
            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @()
            }
        }

        It 'Should return $false when checking for any instance' {
            $result = Test-SqlDscIsInstalledInstance
            $result | Should -BeFalse
        }

        It 'Should return $false when checking for a specific instance' {
            $result = Test-SqlDscIsInstalledInstance -InstanceName 'MSSQLSERVER'
            $result | Should -BeFalse
        }

        It 'Should return $false when checking for a specific service type' {
            $result = Test-SqlDscIsInstalledInstance -ServiceType 'DatabaseEngine'
            $result | Should -BeFalse
        }

        It 'Should return $false when checking for both instance name and service type' {
            $result = Test-SqlDscIsInstalledInstance -InstanceName 'MSSQLSERVER' -ServiceType 'DatabaseEngine'
            $result | Should -BeFalse
        }
    }

    Context 'When SQL Server instances are installed' {
        BeforeAll {
            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return @(
                    [PSCustomObject] @{
                        ServiceType  = 'DatabaseEngine'
                        InstanceName = 'MSSQLSERVER'
                        InstanceId   = 'MSSQL14.MSSQLSERVER'
                    }
                    [PSCustomObject] @{
                        ServiceType  = 'DatabaseEngine'
                        InstanceName = 'NAMED1'
                        InstanceId   = 'MSSQL14.NAMED1'
                    }
                    [PSCustomObject] @{
                        ServiceType  = 'AnalysisServices'
                        InstanceName = 'NAMED2'
                        InstanceId   = 'MSAS14.NAMED2'
                    }
                    [PSCustomObject] @{
                        ServiceType  = 'ReportingServices'
                        InstanceName = 'SSRS'
                        InstanceId   = 'MSRS14.SSRS'
                    }
                )
            }
        }

        It 'Should return $true when instances exist' {
            $result = Test-SqlDscIsInstalledInstance
            $result | Should -BeTrue
        }

        Context 'When filtering by InstanceName' {
            BeforeAll {
                Mock -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                    $InstanceName -eq 'MSSQLSERVER'
                } -MockWith {
                    return @(
                        [PSCustomObject] @{
                            ServiceType  = 'DatabaseEngine'
                            InstanceName = 'MSSQLSERVER'
                            InstanceId   = 'MSSQL14.MSSQLSERVER'
                        }
                    )
                }

                Mock -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                    $InstanceName -eq 'NAMED1'
                } -MockWith {
                    return @(
                        [PSCustomObject] @{
                            ServiceType  = 'DatabaseEngine'
                            InstanceName = 'NAMED1'
                            InstanceId   = 'MSSQL14.NAMED1'
                        }
                    )
                }

                Mock -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                    $InstanceName -eq 'NonExistent'
                } -MockWith {
                    return @()
                }
            }

            It 'Should return $true when the specified instance exists' {
                $result = Test-SqlDscIsInstalledInstance -InstanceName 'MSSQLSERVER'
                $result | Should -BeTrue
            }

            It 'Should return $true when a named instance exists' {
                $result = Test-SqlDscIsInstalledInstance -InstanceName 'NAMED1'
                $result | Should -BeTrue
            }

            It 'Should return $false when the specified instance does not exist' {
                $result = Test-SqlDscIsInstalledInstance -InstanceName 'NonExistent'
                $result | Should -BeFalse
            }
        }

        Context 'When filtering by ServiceType' {
            BeforeAll {
                Mock -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                    $ServiceType -contains 'DatabaseEngine'
                } -MockWith {
                    return @(
                        [PSCustomObject] @{
                            ServiceType  = 'DatabaseEngine'
                            InstanceName = 'MSSQLSERVER'
                            InstanceId   = 'MSSQL14.MSSQLSERVER'
                        }
                        [PSCustomObject] @{
                            ServiceType  = 'DatabaseEngine'
                            InstanceName = 'NAMED1'
                            InstanceId   = 'MSSQL14.NAMED1'
                        }
                    )
                }

                Mock -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                    $ServiceType -contains 'AnalysisServices'
                } -MockWith {
                    return @(
                        [PSCustomObject] @{
                            ServiceType  = 'AnalysisServices'
                            InstanceName = 'NAMED2'
                            InstanceId   = 'MSAS14.NAMED2'
                        }
                    )
                }

                Mock -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                    $ServiceType -contains 'ReportingServices'
                } -MockWith {
                    return @(
                        [PSCustomObject] @{
                            ServiceType  = 'ReportingServices'
                            InstanceName = 'SSRS'
                            InstanceId   = 'MSRS14.SSRS'
                        }
                    )
                }
            }

            It 'Should return $true when DatabaseEngine instances exist' {
                $result = Test-SqlDscIsInstalledInstance -ServiceType 'DatabaseEngine'
                $result | Should -BeTrue
            }

            It 'Should return $true when AnalysisServices instances exist' {
                $result = Test-SqlDscIsInstalledInstance -ServiceType 'AnalysisServices'
                $result | Should -BeTrue
            }

            It 'Should return $true when ReportingServices instances exist' {
                $result = Test-SqlDscIsInstalledInstance -ServiceType 'ReportingServices'
                $result | Should -BeTrue
            }

            It 'Should return $true when multiple service types are specified and at least one exists' {
                $result = Test-SqlDscIsInstalledInstance -ServiceType 'DatabaseEngine', 'ReportingServices'
                $result | Should -BeTrue
            }
        }

        Context 'When filtering by both InstanceName and ServiceType' {
            BeforeAll {
                Mock -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                    $InstanceName -eq 'MSSQLSERVER' -and $ServiceType -contains 'DatabaseEngine'
                } -MockWith {
                    return @(
                        [PSCustomObject] @{
                            ServiceType  = 'DatabaseEngine'
                            InstanceName = 'MSSQLSERVER'
                            InstanceId   = 'MSSQL14.MSSQLSERVER'
                        }
                    )
                }

                Mock -CommandName Get-SqlDscInstalledInstance -ParameterFilter {
                    $InstanceName -eq 'MSSQLSERVER' -and $ServiceType -contains 'AnalysisServices'
                } -MockWith {
                    return @()
                }
            }

            It 'Should return $true when both instance name and service type match' {
                $result = Test-SqlDscIsInstalledInstance -InstanceName 'MSSQLSERVER' -ServiceType 'DatabaseEngine'
                $result | Should -BeTrue
            }

            It 'Should return $false when instance name exists but service type does not match' {
                $result = Test-SqlDscIsInstalledInstance -InstanceName 'MSSQLSERVER' -ServiceType 'AnalysisServices'
                $result | Should -BeFalse
            }
        }
    }

    Context 'When Get-SqlDscInstalledInstance returns $null' {
        BeforeAll {
            Mock -CommandName Get-SqlDscInstalledInstance -MockWith {
                return $null
            }
        }

        It 'Should return $false when Get-SqlDscInstalledInstance returns $null' {
            $result = Test-SqlDscIsInstalledInstance
            $result | Should -BeFalse
        }
    }
}
