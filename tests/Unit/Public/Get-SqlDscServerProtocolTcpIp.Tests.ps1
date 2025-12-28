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

    Import-Module -Name $script:moduleName

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

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-SqlDscServerProtocolTcpIp' -Tag 'Public' {
    Context 'When testing localized strings' {
        It 'Should have localized string for getting specific IP address group' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocolTcpIp_GetIpAddressGroup | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for getting all IP address groups' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocolTcpIp_GetAllIpAddressGroups | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for getting IP address group from protocol' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocolTcpIp_GetIpAddressGroupFromProtocol | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for getting all IP address groups from protocol' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocolTcpIp_GetAllIpAddressGroupsFromProtocol | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for invalid protocol error' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocolTcpIp_InvalidProtocol | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for IP address group not found error' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocolTcpIp_IpAddressGroupNotFound | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When getting TCP/IP address group information using server name and instance name' {
        BeforeAll {
            # Create mock ServerIPAddress objects
            $mockIpAllAddress = [Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress]::CreateTypeInstance()
            $mockIpAllAddress.Name = 'IPAll'

            $mockIpAllProperties = [Microsoft.SqlServer.Management.Smo.Wmi.IPAddressPropertyCollection]::CreateTypeInstance()

            $mockTcpPortProperty = [Microsoft.SqlServer.Management.Smo.Wmi.ProtocolProperty]::CreateTypeInstance()
            $mockTcpPortProperty.Name = 'TcpPort'
            $mockTcpPortProperty.Value = '1433'
            $mockIpAllProperties['TcpPort'] = $mockTcpPortProperty

            $mockTcpDynamicPortsProperty = [Microsoft.SqlServer.Management.Smo.Wmi.ProtocolProperty]::CreateTypeInstance()
            $mockTcpDynamicPortsProperty.Name = 'TcpDynamicPorts'
            $mockTcpDynamicPortsProperty.Value = ''
            $mockIpAllProperties['TcpDynamicPorts'] = $mockTcpDynamicPortsProperty

            $mockIpAllAddress.IPAddressProperties = $mockIpAllProperties

            # Create mock IP1 address
            $mockIp1Address = [Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress]::CreateTypeInstance()
            $mockIp1Address.Name = 'IP1'

            $mockIp1Properties = [Microsoft.SqlServer.Management.Smo.Wmi.IPAddressPropertyCollection]::CreateTypeInstance()

            $mockIp1TcpPortProperty = [Microsoft.SqlServer.Management.Smo.Wmi.ProtocolProperty]::CreateTypeInstance()
            $mockIp1TcpPortProperty.Name = 'TcpPort'
            $mockIp1TcpPortProperty.Value = '1434'
            $mockIp1Properties['TcpPort'] = $mockIp1TcpPortProperty

            $mockIp1Address.IPAddressProperties = $mockIp1Properties

            # Create ServerIPAddressCollection with both addresses
            $mockIpAddressCollection = [Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddressCollection]::CreateTypeInstance()
            $mockIpAddressCollection['IPAll'] = $mockIpAllAddress
            $mockIpAddressCollection['IP1'] = $mockIp1Address

            # Create mock ServerProtocol
            $mockServerProtocol = [Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol]::CreateTypeInstance()
            $mockServerProtocol.Name = 'Tcp'
            $mockServerProtocol.DisplayName = 'TCP/IP'
            $mockServerProtocol.IPAddresses = $mockIpAddressCollection

            Mock -CommandName Get-SqlDscServerProtocol -MockWith {
                return $mockServerProtocol
            }

            Mock -CommandName Get-ComputerName -MockWith {
                return 'LocalComputer'
            }
        }

        It 'Should return IPAll address group when specified' {
            $result = Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER' -IpAddressGroup 'IPAll'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'IPAll'
            $result.IPAddressProperties['TcpPort'].Value | Should -Be '1433'

            Should -Invoke -CommandName Get-SqlDscServerProtocol -ParameterFilter {
                $InstanceName -eq 'MSSQLSERVER' -and $ProtocolName -eq 'TcpIp'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should return IP1 address group when specified' {
            $result = Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER' -IpAddressGroup 'IP1'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'IP1'
            $result.IPAddressProperties['TcpPort'].Value | Should -Be '1434'
        }

        It 'Should return all IP address groups when IpAddressGroup is not specified' {
            $result = Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2

            $ipAll = $result | Where-Object -FilterScript { $_.Name -eq 'IPAll' }
            $ipAll | Should -Not -BeNullOrEmpty

            $ip1 = $result | Where-Object -FilterScript { $_.Name -eq 'IP1' }
            $ip1 | Should -Not -BeNullOrEmpty
        }

        It 'Should use specified server name' {
            $null = Get-SqlDscServerProtocolTcpIp -ServerName 'TestServer' -InstanceName 'MSSQLSERVER' -IpAddressGroup 'IPAll'

            Should -Invoke -CommandName Get-SqlDscServerProtocol -ParameterFilter {
                $ServerName -eq 'TestServer'
            } -Exactly -Times 1 -Scope It
        }

        It 'Should use local computer name when ServerName is not provided' {
            $null = Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER' -IpAddressGroup 'IPAll'

            Should -Invoke -CommandName Get-SqlDscServerProtocol -ParameterFilter {
                $ServerName -eq 'LocalComputer'
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using pipeline with server protocol object' {
        BeforeAll {
            # Create mock ServerIPAddress objects
            $mockIpAllAddress = [Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress]::CreateTypeInstance()
            $mockIpAllAddress.Name = 'IPAll'

            $mockIpAllProperties = [Microsoft.SqlServer.Management.Smo.Wmi.IPAddressPropertyCollection]::CreateTypeInstance()

            $mockTcpPortProperty = [Microsoft.SqlServer.Management.Smo.Wmi.ProtocolProperty]::CreateTypeInstance()
            $mockTcpPortProperty.Name = 'TcpPort'
            $mockTcpPortProperty.Value = '1433'
            $mockIpAllProperties['TcpPort'] = $mockTcpPortProperty

            $mockIpAllAddress.IPAddressProperties = $mockIpAllProperties

            # Create ServerIPAddressCollection
            $mockIpAddressCollection = [Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddressCollection]::CreateTypeInstance()
            $mockIpAddressCollection['IPAll'] = $mockIpAllAddress

            # Create mock ServerProtocol
            $script:mockServerProtocol = [Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol]::CreateTypeInstance()
            $script:mockServerProtocol.Name = 'Tcp'
            $script:mockServerProtocol.DisplayName = 'TCP/IP'
            $script:mockServerProtocol.IPAddresses = $mockIpAddressCollection

            # Should not call Get-SqlDscServerProtocol when using pipeline
            Mock -CommandName Get-SqlDscServerProtocol
        }

        It 'Should work with pipeline input from server protocol object' {
            $result = $script:mockServerProtocol | Get-SqlDscServerProtocolTcpIp -IpAddressGroup 'IPAll'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'IPAll'

            # Should not call Get-SqlDscServerProtocol when using pipeline
            Should -Invoke -CommandName Get-SqlDscServerProtocol -Exactly -Times 0 -Scope It
        }

        It 'Should return all IP address groups from pipeline input' {
            $result = $script:mockServerProtocol | Get-SqlDscServerProtocolTcpIp

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 1
            $result.Name | Should -Be 'IPAll'

            Should -Invoke -CommandName Get-SqlDscServerProtocol -Exactly -Times 0 -Scope It
        }
    }

    Context 'When passing non-TcpIp protocol object via pipeline' {
        BeforeAll {
            # Create a NamedPipes protocol object
            $script:mockNamedPipesProtocol = [Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol]::CreateTypeInstance()
            $script:mockNamedPipesProtocol.Name = 'Np'
            $script:mockNamedPipesProtocol.DisplayName = 'Named Pipes'
        }

        It 'Should throw an error when protocol is not TcpIp' {
            { $script:mockNamedPipesProtocol | Get-SqlDscServerProtocolTcpIp } | Should -Throw '*is not the TCP/IP protocol*'
        }

        It 'Should throw terminating error with correct error record properties' {
            { $script:mockNamedPipesProtocol | Get-SqlDscServerProtocolTcpIp } | Should -Throw -ErrorId 'InvalidServerProtocol,Get-SqlDscServerProtocolTcpIp'
        }
    }

    Context 'When the IP address group is not found' {
        BeforeAll {
            # Create empty ServerIPAddressCollection
            $mockEmptyIpAddressCollection = [Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddressCollection]::CreateTypeInstance()

            # Create mock ServerProtocol with no IP addresses
            $mockServerProtocol = [Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol]::CreateTypeInstance()
            $mockServerProtocol.Name = 'Tcp'
            $mockServerProtocol.DisplayName = 'TCP/IP'
            $mockServerProtocol.IPAddresses = $mockEmptyIpAddressCollection

            Mock -CommandName Get-SqlDscServerProtocol -MockWith {
                return $mockServerProtocol
            }

            Mock -CommandName Get-ComputerName -MockWith {
                return 'LocalComputer'
            }
        }

        It 'Should throw an error when IP address group is not found' {
            { Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER' -IpAddressGroup 'IPAll' } | Should -Throw '*Could not find TCP/IP address group*'
        }

        It 'Should throw terminating error with correct error record properties' {
            { Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER' -IpAddressGroup 'IPAll' } | Should -Throw -ErrorId 'IpAddressGroupNotFound,Get-SqlDscServerProtocolTcpIp'
        }

        It 'Should return null when no IP address groups exist and IpAddressGroup is not specified' {
            $result = Get-SqlDscServerProtocolTcpIp -InstanceName 'MSSQLSERVER'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set ByServerName' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByServerName'
                ExpectedParameters = '-InstanceName <string> [-ServerName <string>] [-IpAddressGroup <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscServerProtocolTcpIp').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have the correct parameters in parameter set ByServerProtocolObject' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByServerProtocolObject'
                ExpectedParameters = '-ServerProtocolObject <ServerProtocol> [-IpAddressGroup <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscServerProtocolTcpIp').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have InstanceName as a mandatory parameter in ByServerName set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocolTcpIp').Parameters['InstanceName']
            $parameterSetAttribute = $parameterInfo.Attributes | Where-Object -FilterScript { $_.ParameterSetName -eq 'ByServerName' }
            $parameterSetAttribute.Mandatory | Should -BeTrue
        }

        It 'Should have IpAddressGroup as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocolTcpIp').Parameters['IpAddressGroup']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have ServerProtocolObject as a pipeline parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscServerProtocolTcpIp').Parameters['ServerProtocolObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Not -Contain $false
        }
    }
}
