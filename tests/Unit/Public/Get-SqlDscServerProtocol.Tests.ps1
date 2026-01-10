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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Get-SqlDscServerProtocol' -Tag 'Public' {
    Context 'When testing localized strings' {
        It 'Should have localized string for getting specific protocol state' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocol_GetState | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for getting all protocols' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocol_GetAllProtocols | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for protocol not found error' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocol_ProtocolNotFound | Should -Not -BeNullOrEmpty
            }
        }
    }

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
            Mock -CommandName Get-ComputerName -MockWith {
                return 'LocalComputer'
            }

            $null = Get-SqlDscServerProtocol -ServerName 'TestServer' -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -ParameterFilter {
                $ServerName -eq 'TestServer'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should use local computer name when ServerName is not provided' {
            Mock -CommandName Get-ComputerName -MockWith {
                return 'LocalComputer'
            }

            $null = Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -ParameterFilter {
                $ServerName -eq 'LocalComputer'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should work with named instances' {
            $result = Get-SqlDscServerProtocol -InstanceName 'SQL2019' -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Tcp'

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -ParameterFilter {
                $InstanceName -eq 'SQL2019'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using pipeline with managed computer object' {
        BeforeAll {
            Mock -CommandName Get-SqlDscManagedComputerInstance -MockWith {
                $mockServerInstance = [PSCustomObject]@{
                    ServerProtocols = @{
                        'Tcp' = [PSCustomObject]@{
                            Name = 'Tcp'
                            DisplayName = 'TCP/IP'
                            IsEnabled = $true
                        }
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

            $mockManagedComputerObject = [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer]::new()
            $mockManagedComputerObject.Name = 'TestServer'
        }

        It 'Should work with pipeline input from managed computer object' {
            $result = $mockManagedComputerObject | Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Tcp'

            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -ParameterFilter {
                $ManagedComputerObject -eq $mockManagedComputerObject -and $InstanceName -eq 'MSSQLSERVER'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using pipeline with managed computer instance object' {
        BeforeAll {
            # Mock Get-SqlDscManagedComputerInstance - it should not be called in this scenario
            Mock -CommandName Get-SqlDscManagedComputerInstance

            Mock -CommandName Get-SqlDscServerProtocolName -MockWith {
                return [PSCustomObject]@{ Name = 'TcpIp'; DisplayName = 'TCP/IP'; ShortName = 'Tcp' }
            }

            $mockManagedComputerInstanceObject = [Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance]::CreateTypeInstance()

            # Create a real ServerProtocol object
            $mockServerProtocol = [Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol]::CreateTypeInstance()
            $mockServerProtocol.Name = 'Tcp'
            $mockServerProtocol.DisplayName = 'TCP/IP'
            $mockServerProtocol.IsEnabled = $true

            # Create a ServerProtocolCollection with indexer support
            $mockServerProtocolCollection = [Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocolCollection]::CreateTypeInstance()
            $mockServerProtocolCollection['Tcp'] = $mockServerProtocol

            $mockManagedComputerInstanceObject.ServerProtocols = $mockServerProtocolCollection
            $mockManagedComputerInstanceObject.Parent = [PSCustomObject]@{
                Name = 'TestServer'
            }
        }

        It 'Should work with pipeline input from managed computer instance object' {
            $result = $mockManagedComputerInstanceObject | Get-SqlDscServerProtocol -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Tcp'

            # Should not call Get-SqlDscManagedComputerInstance when using instance object
            Should -Invoke -CommandName Get-SqlDscManagedComputerInstance -Exactly -Times 0 -Scope It
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

        It 'Should throw terminating error with correct error record properties when protocol is not found' {
            { Get-SqlDscServerProtocol -InstanceName 'MSSQLSERVER' -ProtocolName 'TcpIp' } | Should -Throw -ErrorId 'SqlServerProtocolNotFound,Get-SqlDscServerProtocol'
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
                ExpectedParameters = '-ManagedComputerInstanceObject <ServerInstance> [-ProtocolName <string>] [<CommonParameters>]'
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
            $parameterInfo.Attributes.ValueFromPipeline | Should -Not -Contain $false
        }

        It 'Should have ManagedComputerInstanceObject as a pipeline parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocol').Parameters['ManagedComputerInstanceObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Not -Contain $false
        }
    }
}
