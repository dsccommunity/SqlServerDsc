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
    Context 'When getting server protocol information' {
        BeforeAll {
            # Mock the Get-SqlDscManagedComputerInstance command
            Mock -CommandName Get-SqlDscManagedComputerInstance -MockWith {
                $mockServerInstance = [PSCustomObject]@{
                    ServerProtocols = @{
                        'Tcp' = [PSCustomObject]@{
                            Name = 'Tcp'
                            DisplayName = 'TCP/IP'
                            IsEnabled = $true
                            ProtocolProperties = @{
                                ListenOnAllIPs = $true
                                KeepAlive = 30000
                            }
                        }
                        'Np' = [PSCustomObject]@{
                            Name = 'Np'
                            DisplayName = 'Named Pipes'
                            IsEnabled = $false
                        }
                        'Sm' = [PSCustomObject]@{
                            Name = 'Sm'
                            DisplayName = 'Shared Memory'
                            IsEnabled = $true
                        }
                    }
                    Parent = [PSCustomObject]@{
                        Name = 'TestServer'
                    }
                }

                return $mockServerInstance
            }

            # Mock Get-SqlDscServerProtocolName since it's the new command
            Mock -CommandName Get-SqlDscServerProtocolName -MockWith {
                param($ProtocolName, $All)
                
                if ($All)
                {
                    return @(
                        [PSCustomObject]@{ Name = 'TcpIp'; DisplayName = 'TCP/IP'; ShortName = 'Tcp' },
                        [PSCustomObject]@{ Name = 'NamedPipes'; DisplayName = 'Named Pipes'; ShortName = 'Np' },
                        [PSCustomObject]@{ Name = 'SharedMemory'; DisplayName = 'Shared Memory'; ShortName = 'Sm' }
                    )
                }
                else
                {
                    switch ($ProtocolName)
                    {
                        'TcpIp' { return [PSCustomObject]@{ Name = 'TcpIp'; DisplayName = 'TCP/IP'; ShortName = 'Tcp' } }
                        'NamedPipes' { return [PSCustomObject]@{ Name = 'NamedPipes'; DisplayName = 'Named Pipes'; ShortName = 'Np' } }
                        'SharedMemory' { return [PSCustomObject]@{ Name = 'SharedMemory'; DisplayName = 'Shared Memory'; ShortName = 'Sm' } }
                    }
                }
            }
        }

        It 'Should return TcpIp protocol information' {
            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Tcp'
            $result.DisplayName | Should -Be 'TCP/IP'
            $result.IsEnabled | Should -Be $true

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-SqlDscServerProtocolName -ParameterFilter {
                $ProtocolName -eq 'TcpIp'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should return NamedPipes protocol information' {
            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'NamedPipes'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Np'
            $result.DisplayName | Should -Be 'Named Pipes'
            $result.IsEnabled | Should -Be $false

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-SqlDscServerProtocolName -ParameterFilter {
                $ProtocolName -eq 'NamedPipes'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should return SharedMemory protocol information' {
            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'SharedMemory'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Sm'
            $result.DisplayName | Should -Be 'Shared Memory'
            $result.IsEnabled | Should -Be $true

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-SqlDscServerProtocolName -ParameterFilter {
                $ProtocolName -eq 'SharedMemory'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should return all protocols when ProtocolName is not specified' {
            $result = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 3

            $tcpProtocol = $result | Where-Object -FilterScript { $_.Name -eq 'Tcp' }
            $tcpProtocol | Should -Not -BeNullOrEmpty
            $tcpProtocol.DisplayName | Should -Be 'TCP/IP'

            $npProtocol = $result | Where-Object -FilterScript { $_.Name -eq 'Np' }
            $npProtocol | Should -Not -BeNullOrEmpty
            $npProtocol.DisplayName | Should -Be 'Named Pipes'

            $smProtocol = $result | Where-Object -FilterScript { $_.Name -eq 'Sm' }
            $smProtocol | Should -Not -BeNullOrEmpty
            $smProtocol.DisplayName | Should -Be 'Shared Memory'

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-SqlDscServerProtocolName -ParameterFilter {
                $All -eq $true
            } -Exactly -Times 1 -Scope It
        }

        It 'Should use specified server name' {
            $result = Get-SqlDscServerProtocol -ServerName 'TestServer' -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -ParameterFilter {
                $ServerName -eq 'TestServer'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should work with named instances' {
            $result = Get-SqlDscServerProtocol -InstanceName 'SQL2019' -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Tcp'
        }
    }

    Context 'When the SQL Server instance is not found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscManagedComputerInstance -MockWith {
                # Mock Get-SqlDscManagedComputerInstance to throw when instance not found
                throw "Could not find SQL Server instance 'NONEXISTENT' on server 'TestServer'"
            }
        }

        It 'Should throw an error when instance is not found' {
            { Get-SqlDscServerProtocol -InstanceName 'NONEXISTENT' -ProtocolName 'TcpIp' } | Should -Throw '*Could not find SQL Server instance*'
        }
    }

    Context 'When the protocol is not found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscManagedComputerInstance -MockWith {
                $mockServerInstance = [PSCustomObject]@{
                    ServerProtocols = @{
                        # Missing the Tcp protocol
                    }
                    Parent = [PSCustomObject]@{
                        Name = 'TestServer'
                    }
                }

                return $mockServerInstance
            }

            Mock -CommandName Get-SqlDscServerProtocolName -MockWith {
                return [PSCustomObject]@{ Name = 'TcpIp'; DisplayName = 'TCP/IP'; ShortName = 'Tcp' }
            }
        }

        It 'Should throw an error when protocol is not found' {
            { Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp' } | Should -Throw '*Could not find server protocol*'
        }
    }

    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set ByServerName' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByServerName'
                ExpectedParameters = '-InstanceName <string> [-ServerName <string>] [-ProtocolName <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscServerProtocol').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set ByManagedComputerObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByManagedComputerObject'
                ExpectedParameters = '-InstanceName <string> -ManagedComputerObject <ManagedComputer> [-ProtocolName <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscServerProtocol').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set ByManagedComputerInstanceObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByManagedComputerInstanceObject'
                ExpectedParameters = '-InstanceName <string> -ManagedComputerInstanceObject <ServerInstance> [-ProtocolName <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscServerProtocol').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have InstanceName as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocol').Parameters['InstanceName']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ProtocolName as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocol').Parameters['ProtocolName']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have ServerName as an optional parameter in ByServerName parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocol').Parameters['ServerName']
            $parameterSetAttribute = $parameterInfo.Attributes | Where-Object -FilterScript { $_.ParameterSetName -eq 'ByServerName' }
            $parameterSetAttribute.Mandatory | Should -BeFalse
        }

        It 'Should have ManagedComputerObject as a pipeline parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocol').Parameters['ManagedComputerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have ManagedComputerInstanceObject as a pipeline parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocol').Parameters['ManagedComputerInstanceObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }
    }
}