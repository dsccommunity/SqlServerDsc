<#
    .SYNOPSIS
        Unit test for DSC_SqlAlias DSC resource.
#>

BeforeDiscovery {
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlAlias'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force
}

# $name = 'MyAlias'
# $serverNameTcp = 'sqlnode.company.local'
# $tcpPort = 1433
# $UseDynamicTcpPort = $false
# $serverNameNamedPipes = 'sqlnode'
# $pipeName = "\\$serverNameNamedPipes\PIPE\sql\query"

# $unknownName = 'UnknownAlias'
# $unknownServerName = 'unknownserver'

# $nameDifferentTcpPort = 'DifferentTcpPort'
# $nameDifferentServerNameTcp = 'DifferentServerNameTcp'
# $nameDifferentPipeName = 'DifferentPipeName'
# $differentTcpPort = 1500
# $differentServerNameTcp = "$unknownServerName.company.local"
# $differentPipeName = "\\$unknownServerName\PIPE\sql\query"

# $nameWow6432NodeDifferFrom64BitOS = 'Wow6432NodeDifferFrom64BitOS'

# $defaultParameters = @{
#     Name = $name
#     ServerName = $serverNameTcp
#     Protocol = 'TCP'
#     TcpPort = '1433'
#     Ensure = 'Present'
# }

Describe 'SqlAlias\Get-TargetResource' {
    BeforeAll {
        $mockRegistryPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
        $mockRegistryPathWow6432Node = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                Name = 'MyAlias'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When <OSArchitecture> node is using TCP' -ForEach @(
            @{
                OSArchitecture = '64-bit'
            }
            @{
                OSArchitecture = '32-bit'
            }
         ) {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value $OSArchitecture -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }
            }

            Context 'When the alias that using a specific TCP port already exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return @{
                            'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                        }
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return @{
                            'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -Be 'sqlnode.company.local'
                        $result.Protocol | Should -Be 'TCP'
                        $result.TcpPort | Should -BeExactly 1433
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias that using a specific TCP port does not exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockGetTargetResourceParameters.Name = 'UnknownAlias'

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -BeNullOrEmpty
                        $result.Protocol | Should -Be ''
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias that using dynamic TCP port already exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return @{
                            'MyAlias' = 'DBMSSOCN,sqlnode.company.local'
                        }
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return @{
                            'MyAlias' = 'DBMSSOCN,sqlnode.company.local'
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -Be 'sqlnode.company.local'
                        $result.Protocol | Should -Be 'TCP'
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $true
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias that using dynamic TCP port does not exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockGetTargetResourceParameters.Name = 'UnknownAlias'

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -BeNullOrEmpty
                        $result.Protocol | Should -Be ''
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }
        }

        Context 'When <OSArchitecture> node is using Named Pipes' -ForEach @(
            @{
                OSArchitecture = '64-bit'
            }
            @{
                OSArchitecture = '32-bit'
            }
         ) {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value $OSArchitecture -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }
            }

            Context 'When the alias that using a specific TCP port already exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return @{
                            'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
                        }
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return @{
                            'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -BeNullOrEmpty
                        $result.Protocol | Should -Be 'NP'
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be '\\sqlnode\PIPE\sql\query'
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias does not exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockGetTargetResourceParameters.Name = 'UnknownAlias'

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -BeNullOrEmpty
                        $result.Protocol | Should -Be ''
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }
        }

        Context 'When the registry key under Wow6432Node differ from the one at the regular path' {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value '64-bit' -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }

                # Mocking for protocol TCP
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                    return @{
                        'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
                    }
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                    return $null
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.ServerName | Should -BeNullOrEmpty
                    $result.Protocol | Should -Be ''
                    $result.TcpPort | Should -BeExactly 0
                    $result.UseDynamicTcpPort | Should -Be $false
                    $result.PipeName | Should -Be ''
                }
            }

            It 'Should call the correct mocks' {
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'win32_OperatingSystem'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq $mockRegistryPath
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq $mockRegistryPathWow6432Node
                } -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When the registry key exist but does not have any value' {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value '64-bit' -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }

                # Mocking for protocol TCP
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                    return @{
                        'MyAlias' = ''
                    }
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                    return @{
                        'MyAlias' = ''
                    }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.ServerName | Should -BeNullOrEmpty
                    $result.Protocol | Should -Be ''
                    $result.TcpPort | Should -BeExactly 0
                    $result.UseDynamicTcpPort | Should -Be $false
                    $result.PipeName | Should -Be ''
                }
            }

            It 'Should call the correct mocks' {
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'win32_OperatingSystem'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq $mockRegistryPath
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq $mockRegistryPathWow6432Node
                } -Exactly -Times 1 -Scope Context
            }
        }
    }
}

# Describe 'SqlAlias\Set-TargetResource' {
#     Mock -CommandName New-Item
#     Mock -CommandName Set-ItemProperty
#     Mock -CommandName Remove-ItemProperty
#     Mock -CommandName Test-Path -MockWith {
#         return $false
#     }

#     # Mocking 64-bit OS
#     Mock -CommandName Get-CimInstance -MockWith {
#         return New-Object -TypeName Object |
#             Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
#     } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }

#     Context 'When the system is not in the desired state for 64-bit OS using TCP' {
#         It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty twice each when desired state should be present for protocol TCP' {
#             $testParameters = @{
#                 Name = $name
#                 Protocol = 'TCP'
#                 ServerName = $serverNameTcp
#                 TcpPort = $tcpPort
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 2 -Scope It
#             Should -Invoke -CommandName New-Item -Exactly 2 -Scope It
#             Should -Invoke -CommandName Set-ItemProperty -Exactly 2 -Scope It
#         }

#         It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty twice each when desired state should be present for protocol Named Pipes' {
#             $testParameters = @{
#                 Name = $name
#                 Protocol = 'NP'
#                 ServerName = $serverNameNamedPipes
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 2 -Scope It
#             Should -Invoke -CommandName New-Item -Exactly 2 -Scope It
#             Should -Invoke -CommandName Set-ItemProperty -Exactly 2 -Scope It
#         }

#         It 'Should call mocked functions Test-Path and Remove-ItemProperty twice each when desired state should be absent for 64-bit OS' {
#             Mock -CommandName Test-Path -MockWith {
#                 return $true
#             }

#             $testParameters = @{
#                 Ensure = 'Absent'
#                 Name = $name
#                 ServerName = $serverNameTcp
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 2 -Scope It
#             Should -Invoke -CommandName Remove-ItemProperty -Exactly 2 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state for 64-bit OS using UseDynamicTcpPort' {
#         It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty twice each when desired state should be present for protocol TCP' {
#             $testParameters = @{
#                 Name = $name
#                 Protocol = 'TCP'
#                 ServerName = $serverNameTcp
#                 UseDynamicTcpPort = $true
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 2 -Scope It
#             Should -Invoke -CommandName New-Item -Exactly 2 -Scope It
#             Should -Invoke -CommandName Set-ItemProperty -Exactly 2 -Scope It
#         }

#         It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty twice each when desired state should be present for protocol Named Pipes' {
#             $testParameters = @{
#                 Name = $name
#                 Protocol = 'NP'
#                 ServerName = $serverNameNamedPipes
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 2 -Scope It
#             Should -Invoke -CommandName New-Item -Exactly 2 -Scope It
#             Should -Invoke -CommandName Set-ItemProperty -Exactly 2 -Scope It
#         }

#         It 'Should call mocked functions Test-Path and Remove-ItemProperty twice each when desired state should be absent for 64-bit OS' {
#             Mock -CommandName Test-Path -MockWith {
#                 return $true
#             }

#             $testParameters = @{
#                 Ensure = 'Absent'
#                 Name = $name
#                 ServerName = $serverNameTcp
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 2 -Scope It
#             Should -Invoke -CommandName Remove-ItemProperty -Exactly 2 -Scope It
#         }
#     }

#     # Mocking 32-bit OS
#     Mock -CommandName Get-CimInstance -MockWith {
#         return New-Object -TypeName Object |
#             Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '32-bit' -PassThru -Force
#     } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }

#     Context 'When the system is not in the desired state for 32-bit OS using TCP' {
#         It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty once each when desired state should be present for protocol TCP' {
#             $testParameters = @{
#                 Name = $name
#                 Protocol = 'TCP'
#                 ServerName = $serverNameTcp
#                 TcpPort = $tcpPort
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 1 -Scope It
#             Should -Invoke -CommandName New-Item -Exactly 1 -Scope It
#             Should -Invoke -CommandName Set-ItemProperty -Exactly 1 -Scope It
#         }

#         It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty once each when desired state should be present for protocol Named Pipes' {
#             $testParameters = @{
#                 Name = $name
#                 Protocol = 'NP'
#                 ServerName = $serverNameNamedPipes
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 1 -Scope It
#             Should -Invoke -CommandName New-Item -Exactly 1 -Scope It
#             Should -Invoke -CommandName Set-ItemProperty -Exactly 1 -Scope It
#         }

#         It 'Should call mocked functions Test-Path and Remove-ItemProperty once each when desired state should be absent for 32-bit OS' {
#             Mock -CommandName Test-Path -MockWith {
#                 return $true
#             }

#             $testParameters = @{
#                 Ensure = 'Absent'
#                 Name = $name
#                 ServerName = $serverNameNamedPipes
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 1 -Scope It
#             Should -Invoke -CommandName Remove-ItemProperty -Exactly 1 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state for 32-bit OS using UseDynamicTcpPort' {
#         It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty once each when desired state should be present for protocol TCP' {
#             $testParameters = @{
#                 Name = $name
#                 Protocol = 'TCP'
#                 ServerName = $serverNameTcp
#                 UseDynamicTcpPort = $true
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 1 -Scope It
#             Should -Invoke -CommandName New-Item -Exactly 1 -Scope It
#             Should -Invoke -CommandName Set-ItemProperty -Exactly 1 -Scope It
#         }

#         It 'Should call mocked functions Test-Path, New-Item and Set-ItemProperty once each when desired state should be present for protocol Named Pipes' {
#             $testParameters = @{
#                 Name = $name
#                 Protocol = 'NP'
#                 ServerName = $serverNameNamedPipes
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 1 -Scope It
#             Should -Invoke -CommandName New-Item -Exactly 1 -Scope It
#             Should -Invoke -CommandName Set-ItemProperty -Exactly 1 -Scope It
#         }

#         It 'Should call mocked functions Test-Path and Remove-ItemProperty once each when desired state should be absent for 32-bit OS' {
#             Mock -CommandName Test-Path -MockWith {
#                 return $true
#             }

#             $testParameters = @{
#                 Ensure = 'Absent'
#                 Name = $name
#                 ServerName = $serverNameNamedPipes
#             }

#             Set-TargetResource @testParameters

#             Should -Invoke -CommandName Test-Path -Exactly 1 -Scope It
#             Should -Invoke -CommandName Remove-ItemProperty -Exactly 1 -Scope It
#         }
#     }
# }

# Describe 'SqlAlias\Test-TargetResource' {
#     Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
#         return @{
#             'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
#         }
#     }

#     Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
#         return @{
#             'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
#         }
#     }

#     Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
#         return $null
#     }

#     # Mocking 64-bit OS
#     Mock -CommandName Get-CimInstance -MockWith {
#         return New-Object -TypeName Object |
#             Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
#     } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }

#     Context 'When the system is in the desired state (Absent)' {
#         BeforeAll {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Absent'
#                 }
#             }

#             $testParameters = @{
#                 Ensure = 'Absent'
#                 Name = $name
#                 ServerName = $serverNameTcp
#             }
#         }

#         It "Should return true from the test method" {
#             Test-TargetResource @testParameters | Should -Be $true

#             Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When the system is in the desired state (when using TCP)' {
#         $testParameters = @{
#             Name = $name
#             ServerName = $serverNameTcp
#         }

#         It "Should return true from the test method" {
#             Test-TargetResource @testParameters | Should -Be $true
#         }

#         It 'Should call the mocked functions exactly 1 time each' {
#             Should -Invoke -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
#                 -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is in the desired state (when using UseDynamicTcpPort)' {
#         $testParameters = @{
#             Name = $name
#             ServerName = $serverNameTcp
#         }

#         It "Should return true from the test method" {
#             Test-TargetResource @testParameters | Should -Be $true
#         }

#         It 'Should call the mocked functions exactly 1 time each' {
#             Should -Invoke -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
#                 -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is not in the desired state (when using TCP)' {
#         $testParameters = @{
#             Name = $unknownName
#             ServerName = $serverNameTcp
#         }

#         It "Should return false from the test method" {
#             Test-TargetResource @testParameters | Should -Be $false
#         }

#         It 'Should call the mocked functions exactly 1 time each' {
#             Should -Invoke -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
#                 -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is not in the desired state (when using UseDynamicTcpPort)' {
#         $testParameters = @{
#             Name = $unknownName
#             ServerName = $serverNameTcp
#         }

#         It "Should return false from the test method" {
#             Test-TargetResource @testParameters | Should -Be $false
#         }

#         It 'Should call the mocked functions exactly 1 time each' {
#             Should -Invoke -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
#                 -Exactly -Times 1 -Scope Context
#         }
#     }

#     Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
#         return @{
#             'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
#         }
#     }

#     Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
#         return @{
#             'MyAlias' = 'DBNMPNTW,\\sqlnode\PIPE\sql\query'
#         }
#     }

#     Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
#         return $null
#     }

#     Context 'When the system is in the desired state (when using Named Pipes)' {
#         $testParameters = @{
#             Name = $name
#             ServerName = $serverNameNamedPipes
#         }

#         It "Should return true from the test method" {
#             $testParameters.Add('Protocol','NP')
#             Test-TargetResource @testParameters | Should -Be $true
#         }

#         It 'Should call the mocked functions exactly 1 time each' {
#             Should -Invoke -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
#                 -Exactly -Times 1 -Scope Context
#         }
#     }

#     Context 'When the system is not in the desired state (when using Named Pipes)' {
#         $testParameters = @{
#             Name = $unknownName
#             ServerName = $unknownServerName
#         }

#         It "Should return false from the test method" {
#             Test-TargetResource @testParameters | Should -Be $false
#         }

#         It 'Should call the mocked functions exactly 1 time each' {
#             Should -Invoke -CommandName Get-CimInstance -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath } `
#                 -Exactly -Times 1 -Scope Context

#             Should -Invoke -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node } `
#                 -Exactly -Times 1 -Scope Context
#         }
#     }
# }
