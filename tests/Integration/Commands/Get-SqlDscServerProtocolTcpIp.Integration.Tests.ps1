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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

# cSpell: ignore DSCSQLTEST
Describe 'Get-SqlDscServerProtocolTcpIp' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockServerName = Get-ComputerName
    }

    Context 'When using parameter set ByServerName' {
        Context 'When getting a specific IP address group' {
            It 'Should return IPAll address group information' {
                $result = Get-SqlDscServerProtocolTcpIp -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -IpAddressGroup 'IPAll' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress])
                $result.Name | Should -Be 'IPAll'
                $result.IPAddressProperties | Should -Not -BeNullOrEmpty

                # IPAll should have TcpPort property
                $tcpPortProperty = $result.IPAddressProperties['TcpPort']
                $tcpPortProperty | Should -Not -BeNullOrEmpty
                $tcpPortProperty.Name | Should -Be 'TcpPort'

                # IPAll should have TcpDynamicPorts property
                $tcpDynamicPortsProperty = $result.IPAddressProperties['TcpDynamicPorts']
                $tcpDynamicPortsProperty | Should -Not -BeNullOrEmpty
                $tcpDynamicPortsProperty.Name | Should -Be 'TcpDynamicPorts'
            }

            It 'Should return IP1 address group information' {
                $result = Get-SqlDscServerProtocolTcpIp -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -IpAddressGroup 'IP1' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress])
                $result.Name | Should -Be 'IP1'
                $result.IPAddressProperties | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When getting all IP address groups' {
            It 'Should return all available IP address groups' {
                $result = Get-SqlDscServerProtocolTcpIp -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress])
                $result.Count | Should -BeGreaterThan 0

                # Should contain the IPAll group
                $ipAddressNames = $result | ForEach-Object -Process { $_.Name }
                $ipAddressNames | Should -Contain 'IPAll'
            }
        }

        Context 'When using default server name' {
            It 'Should use local computer name when ServerName is not specified' {
                $result = Get-SqlDscServerProtocolTcpIp -InstanceName $script:mockInstanceName -IpAddressGroup 'IPAll' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'IPAll'
            }
        }
    }

    Context 'When using parameter set ByServerProtocolObject' {
        BeforeAll {
            $script:serverProtocolObject = Get-SqlDscServerProtocol -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ProtocolName 'TcpIp' -ErrorAction 'Stop'
        }

        Context 'When getting a specific IP address group from server protocol object' {
            It 'Should return IPAll address group information' {
                $result = $script:serverProtocolObject | Get-SqlDscServerProtocolTcpIp -IpAddressGroup 'IPAll' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress])
                $result.Name | Should -Be 'IPAll'
                $result.IPAddressProperties | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When getting all IP address groups from server protocol object' {
            It 'Should return all available IP address groups' {
                $result = $script:serverProtocolObject | Get-SqlDscServerProtocolTcpIp -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerIPAddress])
                $result.Count | Should -BeGreaterThan 0

                # Should contain the IPAll group
                $ipAddressNames = $result | ForEach-Object -Process { $_.Name }
                $ipAddressNames | Should -Contain 'IPAll'
            }
        }
    }

    Context 'When using TCP port information for connections' {
        It 'Should be able to retrieve TCP port from IPAll group' {
            $ipAllAddress = Get-SqlDscServerProtocolTcpIp -InstanceName $script:mockInstanceName -IpAddressGroup 'IPAll' -ErrorAction 'Stop'

            $tcpPort = $ipAllAddress.IPAddressProperties['TcpPort'].Value
            $tcpDynamicPort = $ipAllAddress.IPAddressProperties['TcpDynamicPorts'].Value

            # At least one should have a value
            $hasPort = -not [System.String]::IsNullOrEmpty($tcpPort) -or -not [System.String]::IsNullOrEmpty($tcpDynamicPort)
            $hasPort | Should -BeTrue

            # Get the effective port
            $effectivePort = if (-not [System.String]::IsNullOrEmpty($tcpPort)) { $tcpPort } else { $tcpDynamicPort }

            Write-Verbose -Message ('Instance {0} is using TCP port: {1}' -f $script:mockInstanceName, $effectivePort) -Verbose

            $effectivePort | Should -Match '^\d+$'
        }
    }
}
