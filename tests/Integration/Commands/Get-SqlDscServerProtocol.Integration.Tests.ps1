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
Describe 'Get-SqlDscServerProtocol' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockServerName = Get-ComputerName
    }

    AfterAll {
        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When using parameter set ByServerName' {
        Context 'When getting a specific protocol' {
            It 'Should return TcpIp protocol information' {
                $result = Get-SqlDscServerProtocol -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ProtocolName 'TcpIp' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
                $result.Name | Should -Be 'Tcp'
                $result.DisplayName | Should -Be 'TCP/IP'
                $result.Parent.Name | Should -Be $script:mockInstanceName
            }

            It 'Should return NamedPipes protocol information' {
                $result = Get-SqlDscServerProtocol -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ProtocolName 'NamedPipes' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
                $result.Name | Should -Be 'Np'
                $result.DisplayName | Should -Be 'Named Pipes'
                $result.Parent.Name | Should -Be $script:mockInstanceName
            }

            It 'Should return SharedMemory protocol information' {
                $result = Get-SqlDscServerProtocol -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ProtocolName 'SharedMemory' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
                $result.Name | Should -Be 'Sm'
                $result.DisplayName | Should -Be 'Shared Memory'
                $result.Parent.Name | Should -Be $script:mockInstanceName
            }
        }

        Context 'When getting all protocols' {
            It 'Should return all available protocols' {
                $result = Get-SqlDscServerProtocol -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
                $result.Count | Should -BeGreaterThan 0

                # Should contain the standard protocols
                $protocolNames = $result | ForEach-Object -Process { $_.Name }
                $protocolNames | Should -Contain 'Tcp'
                $protocolNames | Should -Contain 'Np'
                $protocolNames | Should -Contain 'Sm'
            }
        }

        Context 'When using default server name' {
            It 'Should use local computer name when ServerName is not specified' {
                $result = Get-SqlDscServerProtocol -InstanceName $script:mockInstanceName -ProtocolName 'TcpIp' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result.Parent.Name | Should -Be $script:mockInstanceName
                $result.Parent.Parent.Name | Should -Be $script:mockServerName
            }
        }
    }

    Context 'When using parameter set ByManagedComputerObject' {
        BeforeAll {
            $script:managedComputerObject = Get-SqlDscManagedComputer -ServerName $script:mockServerName -ErrorAction 'Stop'
        }

        Context 'When getting a specific protocol from managed computer object' {
            It 'Should return TcpIp protocol information' {
                $result = $script:managedComputerObject | Get-SqlDscServerProtocol -InstanceName $script:mockInstanceName -ProtocolName 'TcpIp' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
                $result.Name | Should -Be 'Tcp'
                $result.DisplayName | Should -Be 'TCP/IP'
                $result.Parent.Name | Should -Be $script:mockInstanceName
            }
        }

        Context 'When getting all protocols from managed computer object' {
            It 'Should return all available protocols' {
                $result = $script:managedComputerObject | Get-SqlDscServerProtocol -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
                $result.Count | Should -BeGreaterThan 0

                # Should contain the standard protocols
                $protocolNames = $result | ForEach-Object -Process { $_.Name }
                $protocolNames | Should -Contain 'Tcp'
                $protocolNames | Should -Contain 'Np'
                $protocolNames | Should -Contain 'Sm'
            }
        }
    }

    Context 'When using parameter set ByManagedComputerInstanceObject' {
        BeforeAll {
            $script:managedComputerInstanceObject = Get-SqlDscManagedComputerInstance -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
        }

        Context 'When getting a specific protocol from managed computer instance object' {
            It 'Should return TcpIp protocol information' {
                $result = $script:managedComputerInstanceObject | Get-SqlDscServerProtocol -ProtocolName 'TcpIp' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
                $result.Name | Should -Be 'Tcp'
                $result.DisplayName | Should -Be 'TCP/IP'
                $result.Parent.Name | Should -Be $script:mockInstanceName
            }
        }

        Context 'When getting all protocols from managed computer instance object' {
            It 'Should return all available protocols' {
                $result = $script:managedComputerInstanceObject | Get-SqlDscServerProtocol -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
                $result.Count | Should -BeGreaterThan 0

                # Should contain the standard protocols
                $protocolNames = $result | ForEach-Object -Process { $_.Name }
                $protocolNames | Should -Contain 'Tcp'
                $protocolNames | Should -Contain 'Np'
                $protocolNames | Should -Contain 'Sm'
            }
        }
    }

    Context 'When validating SMO object properties' {
        It 'Should return protocol objects with correct SMO properties' {
            $result = Get-SqlDscServerProtocol -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ProtocolName 'TcpIp' -ErrorAction 'Stop'

            # Verify it's a proper SMO ServerProtocol object
            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])

            # Verify key properties exist
            $result.Name | Should -Not -BeNullOrEmpty
            $result.DisplayName | Should -Not -BeNullOrEmpty
            $result.Parent | Should -Not -BeNullOrEmpty
            $result.Parent.Name | Should -Be $script:mockInstanceName

            # Verify protocol-specific properties are accessible
            $result.IsEnabled | Should -Not -BeNullOrEmpty
            $result.ProtocolProperties | Should -Not -BeNullOrEmpty

            # Verify IP addresses collection for TCP/IP protocol
            if ($result.Name -eq 'Tcp')
            {
                $result.IPAddresses | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should return multiple protocol objects when getting all protocols' {
            $result = Get-SqlDscServerProtocol -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol])
            $result.Count | Should -BeGreaterOrEqual 3

            # Verify each protocol has required properties
            foreach ($protocol in $result)
            {
                $protocol.Name | Should -Not -BeNullOrEmpty
                $protocol.DisplayName | Should -Not -BeNullOrEmpty
                $protocol.Parent.Name | Should -Be $script:mockInstanceName
                $protocol.IsEnabled | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When validating pipeline integration' {
        It 'Should work in a pipeline from Get-SqlDscManagedComputer to Get-SqlDscServerProtocol' {
            $result = Get-SqlDscManagedComputer -ServerName $script:mockServerName | Get-SqlDscServerProtocol -InstanceName $script:mockInstanceName -ProtocolName 'TcpIp' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Tcp'
            $result.DisplayName | Should -Be 'TCP/IP'
        }

        It 'Should work in a pipeline from Get-SqlDscManagedComputerInstance to Get-SqlDscServerProtocol' {
            $result = Get-SqlDscManagedComputerInstance -ServerName $script:mockServerName -InstanceName $script:mockInstanceName | Get-SqlDscServerProtocol -ProtocolName 'NamedPipes' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Np'
            $result.DisplayName | Should -Be 'Named Pipes'
        }
    }
}
