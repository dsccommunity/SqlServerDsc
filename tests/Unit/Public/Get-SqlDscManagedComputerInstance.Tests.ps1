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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

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

Describe 'Get-SqlDscManagedComputerInstance' -Tag 'Public' {
    Context 'When testing localized strings' {
        It 'Should have localized string for getting instance from server' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ManagedComputerInstance_GetFromServer | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for getting instance from object' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ManagedComputerInstance_GetFromObject | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for getting specific instance' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ManagedComputerInstance_GetSpecificInstance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for getting all instances' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ManagedComputerInstance_GetAllInstances | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should have localized string for instance not found error' {
            InModuleScope -ScriptBlock {
                $script:localizedData.ManagedComputerInstance_InstanceNotFound | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'When getting server instance by server name' {
        BeforeAll {
            Mock -CommandName Get-ComputerName -MockWith {
                return 'LocalServer'
            }

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

        It 'Should use local computer name when ServerName is not provided' {
            $result = Get-SqlDscManagedComputerInstance -InstanceName 'MSSQLSERVER'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance'
            Should -Invoke -CommandName Get-ComputerName -Exactly -Times 1
            Should -Invoke -CommandName Get-SqlDscManagedComputer -ParameterFilter {
                $ServerName -eq 'LocalServer'
            } -Exactly -Times 1
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

        It 'Should throw terminating error when instance does not exist' {
            { Get-SqlDscManagedComputerInstance -ServerName 'TestServer' -InstanceName 'NonExistent' } | Should -Throw -ExpectedMessage '*Could not find SQL Server instance*NonExistent*TestServer*'
        }

        It 'Should throw terminating error with correct error record properties when instance does not exist' {
            { Get-SqlDscManagedComputerInstance -ServerName 'TestServer' -InstanceName 'NonExistent' } | Should -Throw -ErrorId 'SqlServerInstanceNotFound,Get-SqlDscManagedComputerInstance'
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

        It 'Should throw terminating error when instance does not exist using pipeline' {
            { $mockManagedComputerObject | Get-SqlDscManagedComputerInstance -InstanceName 'NonExistent' } | Should -Throw -ExpectedMessage '*Could not find SQL Server instance*NonExistent*TestServer*'
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
