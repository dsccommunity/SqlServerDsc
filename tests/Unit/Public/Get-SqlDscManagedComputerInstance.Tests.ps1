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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

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

Describe 'Get-SqlDscManagedComputerInstance' -Tag 'Public' {
    Context 'When getting server instance by server name' {
        BeforeAll {
            Mock -CommandName Get-SqlDscManagedComputer -MockWith {
                $mockServerInstance = [Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance]::CreateTypeInstance()
                $mockServerInstance.Name = 'MSSQLSERVER'
                
                $mockManagedComputerObject = [PSCustomObject]@{
                    Name = 'TestServer'
                    ServerInstances = @{
                        'MSSQLSERVER' = $mockServerInstance
                        'SQL2019' = $mockServerInstance
                    }
                }
                
                return $mockManagedComputerObject
            }
        }

        It 'Should return specific instance when InstanceName is provided' {
            $result = Get-SqlDscManagedComputerInstance -ServerName 'TestServer' -InstanceName 'MSSQLSERVER'
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance'
            Should -Invoke -CommandName Get-SqlDscManagedComputer -Exactly -Times 1
        }

        It 'Should return all instances when InstanceName is not provided' {
            $result = Get-SqlDscManagedComputerInstance -ServerName 'TestServer'
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName Get-SqlDscManagedComputer -Exactly -Times 1
        }

        It 'Should throw error when instance does not exist' {
            { Get-SqlDscManagedComputerInstance -ServerName 'TestServer' -InstanceName 'NonExistent' } | Should -Throw -ExpectedMessage '*Could not find SQL Server instance*'
        }
    }

    Context 'When getting server instance by managed computer object' {
        BeforeAll {
            $mockServerInstance = [Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance]::CreateTypeInstance()
            $mockServerInstance.Name = 'MSSQLSERVER'
            
            $mockManagedComputerObject = [PSCustomObject]@{
                Name = 'TestServer'
                ServerInstances = @{
                    'MSSQLSERVER' = $mockServerInstance
                }
            }
        }

        It 'Should return specific instance from managed computer object' {
            $result = $mockManagedComputerObject | Get-SqlDscManagedComputerInstance -InstanceName 'MSSQLSERVER'
            
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance'
        }

        It 'Should return all instances from managed computer object' {
            $result = $mockManagedComputerObject | Get-SqlDscManagedComputerInstance
            
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When parameter sets are used correctly' {
        It 'Should have the correct parameters in parameter set ByServerName' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByServerName'
                ExpectedParameters = '[-ServerName <string>] [-InstanceName <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscManagedComputerInstance').ParameterSets |
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
                ExpectedParameters = '-ManagedComputerObject <Object> [-InstanceName <string>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscManagedComputerInstance').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When parameter properties are validated' {
        It 'Should have ManagedComputerObject as a pipeline parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscManagedComputerInstance').Parameters['ManagedComputerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have ManagedComputerObject as a mandatory parameter in ByManagedComputerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscManagedComputerInstance').Parameters['ManagedComputerObject']
            $parameterSetAttribute = $parameterInfo.Attributes | Where-Object -FilterScript { $_.ParameterSetName -eq 'ByManagedComputerObject' }
            $parameterSetAttribute.Mandatory | Should -BeTrue
        }
    }
}