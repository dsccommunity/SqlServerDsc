[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

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

Describe 'Get-SqlDscServerProtocolName' -Tag 'Public' {
    Context 'When testing localized strings' {
        It 'Should have localized string for getting protocol mappings' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ServerProtocolName_GetProtocolMappings | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When getting protocol mappings by protocol name' {
        It 'Should return correct mapping for TcpIp protocol' {
            $result = Get-SqlDscServerProtocolName -ProtocolName 'TcpIp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TcpIp'
            $result.DisplayName | Should -Be 'TCP/IP'
            $result.ShortName | Should -Be 'Tcp'
        }

        It 'Should return correct mapping for NamedPipes protocol' {
            $result = Get-SqlDscServerProtocolName -ProtocolName 'NamedPipes'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'NamedPipes'
            $result.DisplayName | Should -Be 'Named Pipes'
            $result.ShortName | Should -Be 'Np'
        }

        It 'Should return correct mapping for SharedMemory protocol' {
            $result = Get-SqlDscServerProtocolName -ProtocolName 'SharedMemory'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'SharedMemory'
            $result.DisplayName | Should -Be 'Shared Memory'
            $result.ShortName | Should -Be 'Sm'
        }
    }

    Context 'When getting protocol mappings by display name' {
        It 'Should return correct mapping for TCP/IP display name' {
            $result = Get-SqlDscServerProtocolName -DisplayName 'TCP/IP'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TcpIp'
            $result.DisplayName | Should -Be 'TCP/IP'
            $result.ShortName | Should -Be 'Tcp'
        }

        It 'Should return correct mapping for Named Pipes display name' {
            $result = Get-SqlDscServerProtocolName -DisplayName 'Named Pipes'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'NamedPipes'
            $result.DisplayName | Should -Be 'Named Pipes'
            $result.ShortName | Should -Be 'Np'
        }

        It 'Should return correct mapping for Shared Memory display name' {
            $result = Get-SqlDscServerProtocolName -DisplayName 'Shared Memory'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'SharedMemory'
            $result.DisplayName | Should -Be 'Shared Memory'
            $result.ShortName | Should -Be 'Sm'
        }
    }

    Context 'When getting protocol mappings by short name' {
        It 'Should return correct mapping for Tcp short name' {
            $result = Get-SqlDscServerProtocolName -ShortName 'Tcp'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TcpIp'
            $result.DisplayName | Should -Be 'TCP/IP'
            $result.ShortName | Should -Be 'Tcp'
        }

        It 'Should return correct mapping for Np short name' {
            $result = Get-SqlDscServerProtocolName -ShortName 'Np'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'NamedPipes'
            $result.DisplayName | Should -Be 'Named Pipes'
            $result.ShortName | Should -Be 'Np'
        }

        It 'Should return correct mapping for Sm short name' {
            $result = Get-SqlDscServerProtocolName -ShortName 'Sm'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'SharedMemory'
            $result.DisplayName | Should -Be 'Shared Memory'
            $result.ShortName | Should -Be 'Sm'
        }
    }

    Context 'When getting all protocol mappings' {
        It 'Should return all three protocol mappings' {
            $result = Get-SqlDscServerProtocolName -All

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 3

            $tcpMapping = $result | Where-Object -FilterScript { $_.Name -eq 'TcpIp' }
            $tcpMapping | Should -Not -BeNullOrEmpty
            $tcpMapping.DisplayName | Should -Be 'TCP/IP'
            $tcpMapping.ShortName | Should -Be 'Tcp'

            $npMapping = $result | Where-Object -FilterScript { $_.Name -eq 'NamedPipes' }
            $npMapping | Should -Not -BeNullOrEmpty
            $npMapping.DisplayName | Should -Be 'Named Pipes'
            $npMapping.ShortName | Should -Be 'Np'

            $smMapping = $result | Where-Object -FilterScript { $_.Name -eq 'SharedMemory' }
            $smMapping | Should -Not -BeNullOrEmpty
            $smMapping.DisplayName | Should -Be 'Shared Memory'
            $smMapping.ShortName | Should -Be 'Sm'
        }

        It 'Should return all protocol mappings when no parameters are specified' {
            $result = Get-SqlDscServerProtocolName

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 3
        }
    }

    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByProtocolName'
                ExpectedParameters = '-ProtocolName <string> [<CommonParameters>]'
            },
            @{
                ExpectedParameterSetName = 'ByDisplayName'
                ExpectedParameters = '-DisplayName <string> [<CommonParameters>]'
            },
            @{
                ExpectedParameterSetName = 'ByShortName'
                ExpectedParameters = '-ShortName <string> [<CommonParameters>]'
            },
            @{
                ExpectedParameterSetName = 'All'
                ExpectedParameters = '[-All] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscServerProtocolName').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ProtocolName as a mandatory parameter in ByProtocolName parameter set' {
            $parameterSets = (Get-Command -Name 'Get-SqlDscServerProtocolName').ParameterSets
            $byProtocolNameSet = $parameterSets | Where-Object -FilterScript { $_.Name -eq 'ByProtocolName' }
            $protocolNameParam = $byProtocolNameSet.Parameters | Where-Object -FilterScript { $_.Name -eq 'ProtocolName' }
            $protocolNameParam.IsMandatory | Should -BeTrue
        }

        It 'Should have DisplayName as a mandatory parameter in ByDisplayName parameter set' {
            $parameterSets = (Get-Command -Name 'Get-SqlDscServerProtocolName').ParameterSets
            $byDisplayNameSet = $parameterSets | Where-Object -FilterScript { $_.Name -eq 'ByDisplayName' }
            $displayNameParam = $byDisplayNameSet.Parameters | Where-Object -FilterScript { $_.Name -eq 'DisplayName' }
            $displayNameParam.IsMandatory | Should -BeTrue
        }

        It 'Should have ShortName as a mandatory parameter in ByShortName parameter set' {
            $parameterSets = (Get-Command -Name 'Get-SqlDscServerProtocolName').ParameterSets
            $byShortNameSet = $parameterSets | Where-Object -FilterScript { $_.Name -eq 'ByShortName' }
            $shortNameParam = $byShortNameSet.Parameters | Where-Object -FilterScript { $_.Name -eq 'ShortName' }
            $shortNameParam.IsMandatory | Should -BeTrue
        }

        It 'Should have All as an optional parameter in All parameter set' {
            $parameterSets = (Get-Command -Name 'Get-SqlDscServerProtocolName').ParameterSets
            $allSet = $parameterSets | Where-Object -FilterScript { $_.Name -eq 'All' }
            $allParam = $allSet.Parameters | Where-Object -FilterScript { $_.Name -eq 'All' }
            $allParam.IsMandatory | Should -BeFalse
        }
    }
}
