[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Load SMO stub types
    Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"

    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Remove-SqlDscAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByName'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ByObject'
                ExpectedParameters = '-OperatorObject <Operator> [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscAgentOperator').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When command has correct parameter properties' {
        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscAgentOperator').Parameters['ServerObject']
            $byNameParameterSet = $parameterInfo.ParameterSets['ByName']
            $byNameParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have OperatorObject as a mandatory parameter in ByObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscAgentOperator').Parameters['OperatorObject']
            $byObjectParameterSet = $parameterInfo.ParameterSets['ByObject']
            $byObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have OperatorObject accept pipeline input in ByObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscAgentOperator').Parameters['OperatorObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ByName parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscAgentOperator').Parameters['Name']
            $byNameParameterSet = $parameterInfo.ParameterSets['ByName']
            $byNameParameterSet.IsMandatory | Should -BeTrue
        }
    }

    Context 'When removing operator using ByName parameter set' {
        BeforeAll {
            # Mock existing operator
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'test@contoso.com'
            
            # Mock operator collection with existing operator
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperator)

            # Mock JobServer object with mock refresh method
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection
            $script:mockOperatorCollection | Add-Member -MemberType ScriptMethod -Name 'Refresh' -Value { } -Force

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
            $script:mockServerObject.InstanceName = 'TestInstance'

            $script:mockMethodDropCallCount = 0
            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                $script:mockMethodDropCallCount++
            } -Force
        }

        It 'Should remove operator when it exists' {
            $script:mockMethodDropCallCount = 0

            Remove-SqlDscAgentOperator -Confirm:$false -ServerObject $script:mockServerObject -Name 'TestOperator'

            $script:mockMethodDropCallCount | Should -Be 1
        }

        It 'Should not throw when operator does not exist' {
            { Remove-SqlDscAgentOperator -Confirm:$false -ServerObject $script:mockServerObject -Name 'NonExistentOperator' } |
                Should -Not -Throw
        }

        Context 'When using parameter WhatIf' {
            It 'Should not call Drop method when using WhatIf' {
                $script:mockMethodDropCallCount = 0

                Remove-SqlDscAgentOperator -WhatIf -ServerObject $script:mockServerObject -Name 'TestOperator'

                $script:mockMethodDropCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should remove operator using pipeline input' {
                $script:mockMethodDropCallCount = 0

                $script:mockServerObject | Remove-SqlDscAgentOperator -Confirm:$false -Name 'TestOperator'

                $script:mockMethodDropCallCount | Should -Be 1
            }
        }
    }

    Context 'When removing operator using ByObject parameter set' {
        BeforeAll {
            # Mock existing operator with parent hierarchy
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'test@contoso.com'

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            # Mock server object  
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Set up parent hierarchy
            $script:mockOperator.Parent = $script:mockJobServer
            $script:mockJobServer.Parent = $script:mockServerObject

            $script:mockMethodDropCallCount = 0
            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                $script:mockMethodDropCallCount++
            } -Force
        }

        It 'Should remove operator when using operator object' {
            $script:mockMethodDropCallCount = 0

            Remove-SqlDscAgentOperator -Confirm:$false -OperatorObject $script:mockOperator

            $script:mockMethodDropCallCount | Should -Be 1
        }

        Context 'When passing parameter OperatorObject over the pipeline' {
            It 'Should remove operator using pipeline input' {
                $script:mockMethodDropCallCount = 0

                $script:mockOperator | Remove-SqlDscAgentOperator -Confirm:$false

                $script:mockMethodDropCallCount | Should -Be 1
            }
        }
    }

    Context 'When remove operation fails' {
        BeforeAll {
            # Mock existing operator
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'test@contoso.com'
            
            # Mock operator collection with existing operator
            $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $script:mockOperatorCollection.Add($script:mockOperator)

            # Mock JobServer object with mock refresh method
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Operators = $script:mockOperatorCollection
            $script:mockOperatorCollection | Add-Member -MemberType ScriptMethod -Name 'Refresh' -Value { } -Force

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Set up parent hierarchy
            $script:mockOperator.Parent = $script:mockJobServer
            $script:mockJobServer.Parent = $script:mockServerObject

            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                throw 'Mocked drop failure'
            } -Force
        }

        It 'Should throw when drop operation fails' {
            { Remove-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*Failed to remove SQL Agent Operator ''TestOperator''*'
        }
    }
}