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

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-SqlDscInstalledInstance' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            MockExpectedParameters = '[[-InstanceName] <string>] [[-ServiceType] <string[]>] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Get-SqlDscInstalledInstance').ParameterSets |
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
            Mock -CommandName Get-ChildItem -ParameterFilter {
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names'
            } -MockWith { return @() }
        }

        It 'Should return an empty array' {
            $result = Get-SqlDscInstalledInstance
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When SQL Server instances are installed' {
        BeforeEach {
            $mockSQLRegistryItem = [PSCustomObject] @{
                PSChildName   = 'SQL'
            }

            $mockSQLRegistryItem = $mockSQLRegistryItem |
                Add-Member -MemberType 'ScriptMethod' -Name 'GetValueNames' -Value {
                    return @(
                        'MSSQLSERVER'
                        'NAMED1'
                    )
                } -PassThru |
                Add-Member -MemberType 'ScriptMethod' -Name 'GetValue' -Value {
                    param($name)
                    if ($name -eq 'MSSQLSERVER')
                    {
                        return 'MSSQL14.MSSQLSERVER'
                    }
                    elseif ($name -eq 'NAMED1')
                    {
                        return 'MSSQL14.NAMED1'
                    }
                } -PassThru -Force

            $mockOLAPRegistryItem = [PSCustomObject] @{
                PSChildName   = 'OLAP'
            }

            # cSpell: ignore MSAS
            $mockOLAPRegistryItem = $mockOLAPRegistryItem |
                Add-Member -MemberType 'ScriptMethod' -Name 'GetValueNames' -Value {
                    return @(
                        'MSSQLSERVER'
                        'NAMED2'
                    )
                } -PassThru |
                Add-Member -MemberType 'ScriptMethod' -Name 'GetValue' -Value {
                    param($name)
                    if ($name -eq 'MSSQLSERVER')
                    {
                        return 'MSAS14.MSSQLSERVER'
                    }
                    elseif ($name -eq 'NAMED2')
                    {
                        return 'MSAS14.NAMED2'
                    }
                } -PassThru -Force

            $mockRSRegistryItem = [PSCustomObject] @{
                PSChildName   = 'RS'
            }

            # cSpell: ignore MSRS
            $mockRSRegistryItem = $mockRSRegistryItem |
                Add-Member -MemberType 'ScriptMethod' -Name 'GetValueNames' -Value {
                    return @(
                        'NAMED2'
                    )
                } -PassThru |
                Add-Member -MemberType 'ScriptMethod' -Name 'GetValue' -Value {
                    param($name)
                    if ($name -eq 'MSSQLSERVER')
                    {
                        return 'MSRS14.MSSQLSERVER'
                    }
                } -PassThru -Force
        }

        Context 'When all service types are installed' {
            BeforeAll {
                Mock -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names'
                } -MockWith {
                    return @($mockSQLRegistryItem, $mockOLAPRegistryItem, $mockRSRegistryItem)
                }
            }

            It 'Should return all instances' {
                $result = Get-SqlDscInstalledInstance
                $result | Should -HaveCount 5
                $result.Where({ $_.ServiceType -eq 'DatabaseEngine' }) | Should -HaveCount 2
                $result.Where({ $_.ServiceType -eq 'AnalysisServices' }) | Should -HaveCount 2
                $result.Where({ $_.ServiceType -eq 'ReportingServices' }) | Should -HaveCount 1
            }
        }

        Context 'When filtering by InstanceName' {
            BeforeAll {
                Mock -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names'
                } -MockWith {
                    return @($mockSQLRegistryItem, $mockOLAPRegistryItem, $mockRSRegistryItem)
                }
            }

            It 'Should return only instances matching the specified name' {
                $result = Get-SqlDscInstalledInstance -InstanceName 'MSSQLSERVER'
                $result | Should -HaveCount 2
                $result | ForEach-Object -Process {
                    $_.InstanceName | Should -Be 'MSSQLSERVER'
                }
            }

            It 'Should return only the specified named instance' {
                $result = Get-SqlDscInstalledInstance -InstanceName 'NAMED1'
                $result | Should -HaveCount 1
                $result.InstanceName | Should -Be 'NAMED1'
                $result.ServiceType | Should -Be 'DatabaseEngine'
            }
        }

        Context 'When filtering by ServiceType' {
            BeforeAll {
                Mock -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names'
                } -MockWith {
                    return @($mockSQLRegistryItem, $mockOLAPRegistryItem, $mockRSRegistryItem)
                }
            }

            It 'Should return only DatabaseEngine instances' {
                $result = Get-SqlDscInstalledInstance -ServiceType 'DatabaseEngine'
                $result | Should -HaveCount 2
                $result | ForEach-Object -Process {
                    $_.ServiceType | Should -Be 'DatabaseEngine'
                }
            }

            It 'Should return only AnalysisServices instances' {
                $result = Get-SqlDscInstalledInstance -ServiceType 'AnalysisServices'
                $result | Should -HaveCount 2
                $result | ForEach-Object -Process {
                    $_.ServiceType | Should -Be 'AnalysisServices'
                }
            }

            It 'Should return only ReportingServices instances' {
                $result = Get-SqlDscInstalledInstance -ServiceType 'ReportingServices'
                $result | Should -HaveCount 1
                $result.ServiceType | Should -Be 'ReportingServices'
            }

            It 'Should return multiple service types when specified' {
                $result = Get-SqlDscInstalledInstance -ServiceType 'DatabaseEngine', 'ReportingServices'
                $result | Should -HaveCount 3
                $result.ServiceType | Should -Contain 'DatabaseEngine'
                $result.ServiceType | Should -Contain 'ReportingServices'
            }
        }

        Context 'When filtering by both InstanceName and ServiceType' {
            BeforeAll {
                Mock -CommandName Get-ChildItem -ParameterFilter {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names'
                } -MockWith {
                    return @($mockSQLRegistryItem, $mockOLAPRegistryItem, $mockRSRegistryItem)
                }
            }

            It 'Should return only instances matching both filters' {
                $result = Get-SqlDscInstalledInstance -InstanceName 'MSSQLSERVER' -ServiceType 'DatabaseEngine'
                $result | Should -HaveCount 1
                $result.InstanceName | Should -Be 'MSSQLSERVER'
                $result.ServiceType | Should -Be 'DatabaseEngine'
            }
        }
    }
}
