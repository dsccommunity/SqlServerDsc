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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Get-SqlDscServerProtocolName' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Define expected protocol mappings for validation
        $script:expectedProtocolMappings = @{
            'TcpIp' = @{
                Name = 'TcpIp'
                DisplayName = 'TCP/IP'
                ShortName = 'Tcp'
            }
            'NamedPipes' = @{
                Name = 'NamedPipes'
                DisplayName = 'Named Pipes'
                ShortName = 'Np'
            }
            'SharedMemory' = @{
                Name = 'SharedMemory'
                DisplayName = 'Shared Memory'
                ShortName = 'Sm'
            }
        }
    }

    Context 'When using parameter set ByProtocolName' {
        It 'Should return correct mapping for TcpIp protocol' {
            $result = Get-SqlDscServerProtocolName -ProtocolName 'TcpIp' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['TcpIp'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['TcpIp'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['TcpIp'].ShortName
        }

        It 'Should return correct mapping for NamedPipes protocol' {
            $result = Get-SqlDscServerProtocolName -ProtocolName 'NamedPipes' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['NamedPipes'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['NamedPipes'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['NamedPipes'].ShortName
        }

        It 'Should return correct mapping for SharedMemory protocol' {
            $result = Get-SqlDscServerProtocolName -ProtocolName 'SharedMemory' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['SharedMemory'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['SharedMemory'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['SharedMemory'].ShortName
        }
    }

    Context 'When using parameter set ByDisplayName' {
        It 'Should return correct mapping for TCP/IP display name' {
            $result = Get-SqlDscServerProtocolName -DisplayName 'TCP/IP' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['TcpIp'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['TcpIp'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['TcpIp'].ShortName
        }

        It 'Should return correct mapping for Named Pipes display name' {
            $result = Get-SqlDscServerProtocolName -DisplayName 'Named Pipes' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['NamedPipes'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['NamedPipes'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['NamedPipes'].ShortName
        }

        It 'Should return correct mapping for Shared Memory display name' {
            $result = Get-SqlDscServerProtocolName -DisplayName 'Shared Memory' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['SharedMemory'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['SharedMemory'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['SharedMemory'].ShortName
        }
    }

    Context 'When using parameter set ByShortName' {
        It 'Should return correct mapping for Tcp short name' {
            $result = Get-SqlDscServerProtocolName -ShortName 'Tcp' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['TcpIp'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['TcpIp'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['TcpIp'].ShortName
        }

        It 'Should return correct mapping for Np short name' {
            $result = Get-SqlDscServerProtocolName -ShortName 'Np' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['NamedPipes'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['NamedPipes'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['NamedPipes'].ShortName
        }

        It 'Should return correct mapping for Sm short name' {
            $result = Get-SqlDscServerProtocolName -ShortName 'Sm' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:expectedProtocolMappings['SharedMemory'].Name
            $result.DisplayName | Should -Be $script:expectedProtocolMappings['SharedMemory'].DisplayName
            $result.ShortName | Should -Be $script:expectedProtocolMappings['SharedMemory'].ShortName
        }
    }

    Context 'When using parameter set All' {
        It 'Should return all protocol mappings when -All is specified' {
            $result = Get-SqlDscServerProtocolName -All -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 3

            # Verify all expected protocols are present
            $tcpProtocol = $result | Where-Object -FilterScript { $_.Name -eq 'TcpIp' }
            $tcpProtocol | Should -Not -BeNullOrEmpty
            $tcpProtocol.DisplayName | Should -Be 'TCP/IP'
            $tcpProtocol.ShortName | Should -Be 'Tcp'

            $namedPipesProtocol = $result | Where-Object -FilterScript { $_.Name -eq 'NamedPipes' }
            $namedPipesProtocol | Should -Not -BeNullOrEmpty
            $namedPipesProtocol.DisplayName | Should -Be 'Named Pipes'
            $namedPipesProtocol.ShortName | Should -Be 'Np'

            $sharedMemoryProtocol = $result | Where-Object -FilterScript { $_.Name -eq 'SharedMemory' }
            $sharedMemoryProtocol | Should -Not -BeNullOrEmpty
            $sharedMemoryProtocol.DisplayName | Should -Be 'Shared Memory'
            $sharedMemoryProtocol.ShortName | Should -Be 'Sm'
        }

        It 'Should return all protocol mappings when no parameters are specified (default)' {
            $result = Get-SqlDscServerProtocolName -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 3

            # Verify all expected protocols are present
            $protocolNames = $result | ForEach-Object -Process { $_.Name }
            $protocolNames | Should -Contain 'TcpIp'
            $protocolNames | Should -Contain 'NamedPipes'
            $protocolNames | Should -Contain 'SharedMemory'
        }
    }

    Context 'When validating output object properties' {
        It 'Should return PSCustomObject with correct properties' {
            $result = Get-SqlDscServerProtocolName -ProtocolName 'TcpIp' -ErrorAction 'Stop'

            $result | Should -BeOfType 'Should -BeOfType 'System.Management.Automation.PSCustomObject''
            $result.PSObject.Properties.Name | Should -Contain 'Name'
            $result.PSObject.Properties.Name | Should -Contain 'DisplayName'
            $result.PSObject.Properties.Name | Should -Contain 'ShortName'
        }

        It 'Should return consistent object types for all parameter sets' {
            $resultByProtocolName = Get-SqlDscServerProtocolName -ProtocolName 'TcpIp' -ErrorAction 'Stop'
            $resultByDisplayName = Get-SqlDscServerProtocolName -DisplayName 'TCP/IP' -ErrorAction 'Stop'
            $resultByShortName = Get-SqlDscServerProtocolName -ShortName 'Tcp' -ErrorAction 'Stop'

            $resultByProtocolName.GetType() | Should -Be $resultByDisplayName.GetType()
            $resultByDisplayName.GetType() | Should -Be $resultByShortName.GetType()

            # Verify all return the same data
            $resultByProtocolName.Name | Should -Be $resultByDisplayName.Name
            $resultByDisplayName.Name | Should -Be $resultByShortName.Name
        }
    }
}
