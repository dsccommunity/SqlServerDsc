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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Get-SqlDscServerProtocol' -Tag 'Public' {
    Context 'When using SMO approach' {
        BeforeAll {
            # Mock the private helper functions to avoid complexity
            Mock -CommandName Get-ServerProtocolObjectBySmo -MockWith {
                return [PSCustomObject]@{
                    Name = 'Tcp'
                    DisplayName = 'TCP/IP'
                    IsEnabled = $true
                    ProtocolProperties = @{
                        ListenOnAllIPs = $true
                        KeepAlive = 30000
                    }
                }
            }

            Mock -CommandName Get-ServerProtocolObjectByCim -MockWith {
                throw 'CIM not available'
            }

            InModuleScope -ScriptBlock {
                $script:preferCimOverSmo = $false
            }
        }

        It 'Should return server protocol information using SMO approach' {
            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Tcp'
            $result.DisplayName | Should -Be 'TCP/IP'
            $result.IsEnabled | Should -Be $true

            Should -Invoke -CommandName Get-ServerProtocolObjectBySmo -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ServerProtocolObjectByCim -Exactly -Times 0 -Scope It
        }

        It 'Should use specified server name' {
            $result = Get-SqlDscServerProtocol -ServerName 'TestServer' -InstanceName 'MSSQLSERVER' -ProtocolName 'NamedPipes'

            Should -Invoke -CommandName Get-ServerProtocolObjectBySmo -ParameterFilter {
                $ServerName -eq 'TestServer' -and $InstanceName -eq 'MSSQLSERVER' -and $ProtocolName -eq 'NamedPipes'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should accept all valid protocol names' {
            $protocols = @('TcpIp', 'NamedPipes', 'SharedMemory')

            foreach ($protocol in $protocols)
            {
                $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName $protocol

                $result | Should -Not -BeNullOrEmpty
                Should -Invoke -CommandName Get-ServerProtocolObjectBySmo -ParameterFilter {
                    $ProtocolName -eq $protocol
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When using CIM approach' {
        BeforeAll {
            Mock -CommandName Get-ServerProtocolObjectByCim -MockWith {
                return [PSCustomObject]@{
                    InstanceName = 'MSSQLSERVER'
                    ProtocolName = 'Tcp'
                    Enabled = $true
                    ListenOnAllIPs = $true
                }
            }

            Mock -CommandName Get-ServerProtocolObjectBySmo -MockWith {
                return [PSCustomObject]@{
                    Name = 'Tcp'
                    DisplayName = 'TCP/IP'
                    IsEnabled = $true
                }
            }

            InModuleScope -ScriptBlock {
                $script:preferCimOverSmo = $true
            }
        }

        It 'Should return server protocol information using CIM approach when preferred' {
            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'MSSQLSERVER'
            $result.ProtocolName | Should -Be 'Tcp'
            $result.Enabled | Should -Be $true

            Should -Invoke -CommandName Get-ServerProtocolObjectByCim -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ServerProtocolObjectBySmo -Exactly -Times 0 -Scope It
        }

        It 'Should use CIM approach when UseCim parameter is specified' {
            InModuleScope -ScriptBlock {
                $script:preferCimOverSmo = $false
            }

            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp' -UseCim

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName Get-ServerProtocolObjectByCim -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ServerProtocolObjectBySmo -Exactly -Times 0 -Scope It
        }
    }

    Context 'When CIM approach fails and falls back to SMO' {
        BeforeAll {
            Mock -CommandName Get-ServerProtocolObjectByCim -MockWith {
                throw 'CIM namespace not found'
            }

            Mock -CommandName Get-ServerProtocolObjectBySmo -MockWith {
                return [PSCustomObject]@{
                    Name = 'Tcp'
                    DisplayName = 'TCP/IP'
                    IsEnabled = $true
                }
            }

            InModuleScope -ScriptBlock {
                $script:preferCimOverSmo = $true
            }
        }

        It 'Should fall back to SMO approach when CIM fails' {
            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Tcp'
            $result.DisplayName | Should -Be 'TCP/IP'
            $result.IsEnabled | Should -Be $true

            Should -Invoke -CommandName Get-ServerProtocolObjectByCim -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ServerProtocolObjectBySmo -Exactly -Times 1 -Scope It
        }

        It 'Should fall back to SMO approach when using -UseCim and CIM fails' {
            InModuleScope -ScriptBlock {
                $script:preferCimOverSmo = $false
            }

            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp' -UseCim

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName Get-ServerProtocolObjectByCim -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ServerProtocolObjectBySmo -Exactly -Times 1 -Scope It
        }
    }

    Context 'When both approaches fail' {
        BeforeAll {
            Mock -CommandName Get-ServerProtocolObjectByCim -MockWith {
                throw 'CIM namespace not found'
            }

            Mock -CommandName Get-ServerProtocolObjectBySmo -MockWith {
                throw 'SMO connection failed'
            }
        }

        It 'Should throw an error when both CIM and SMO approaches fail' {
            { Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp' -UseCim } | Should -Throw 'SMO connection failed'

            Should -Invoke -CommandName Get-ServerProtocolObjectByCim -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-ServerProtocolObjectBySmo -Exactly -Times 1 -Scope It
        }
    }
}