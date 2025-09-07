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
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    # Load SMO stub types
    Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    $env:SqlServerDscCI = $false

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Set-SqlDscAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByName'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-EmailAddress <string>] [-CategoryName <string>] [-NetSendAddress <string>] [-PagerAddress <string>] [-PagerDays <WeekDays>] [-SaturdayPagerEndTime <timespan>] [-SaturdayPagerStartTime <timespan>] [-SundayPagerEndTime <timespan>] [-SundayPagerStartTime <timespan>] [-WeekdayPagerEndTime <timespan>] [-WeekdayPagerStartTime <timespan>] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ByObject'
                ExpectedParameters = '-OperatorObject <Operator> [-EmailAddress <string>] [-CategoryName <string>] [-NetSendAddress <string>] [-PagerAddress <string>] [-PagerDays <WeekDays>] [-SaturdayPagerEndTime <timespan>] [-SaturdayPagerStartTime <timespan>] [-SundayPagerEndTime <timespan>] [-SundayPagerStartTime <timespan>] [-WeekdayPagerEndTime <timespan>] [-WeekdayPagerStartTime <timespan>] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscAgentOperator').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['ServerObject']
            $byNameParameterSet = $parameterInfo.ParameterSets['ByName']
            $byNameParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have OperatorObject as a mandatory parameter in ByObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['OperatorObject']
            $byObjectParameterSet = $parameterInfo.ParameterSets['ByObject']
            $byObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have OperatorObject accept pipeline input in ByObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['OperatorObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ByName parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentOperator').Parameters['Name']
            $byNameParameterSet = $parameterInfo.ParameterSets['ByName']
            $byNameParameterSet.IsMandatory | Should -BeTrue
        }
    }

    Context 'When updating operator using ByName parameter set' {
        BeforeAll {
            # Mock existing operator
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'old@contoso.com'

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

            $script:mockMethodAlterCallCount = 0
            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                $script:mockMethodAlterCallCount++
            } -Force
        }

        It 'Should update operator email address when specified' {
            $script:mockMethodAlterCallCount = 0
            $script:mockOperator.EmailAddress = 'old@contoso.com'

            Set-SqlDscAgentOperator -Confirm:$false -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'new@contoso.com'

            $script:mockOperator.EmailAddress | Should -Be 'new@contoso.com'
            $script:mockMethodAlterCallCount | Should -Be 1
        }

        It 'Should update when email address is already correct (always set user-specified properties)' {
            $script:mockMethodAlterCallCount = 0
            $script:mockOperator.EmailAddress = 'correct@contoso.com'

            Set-SqlDscAgentOperator -Confirm:$false -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'correct@contoso.com'

            $script:mockMethodAlterCallCount | Should -Be 1
        }

        It 'Should throw when operator does not exist' {
            { Set-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'NonExistentOperator' -EmailAddress 'test@contoso.com' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*SQL Agent Operator ''NonExistentOperator'' was not found*'
        }

        Context 'When using parameter WhatIf' {
            It 'Should not call Alter method when using WhatIf' {
                $script:mockMethodAlterCallCount = 0
                $script:mockOperator.EmailAddress = 'old@contoso.com'

                Set-SqlDscAgentOperator -WhatIf -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'new@contoso.com'

                $script:mockMethodAlterCallCount | Should -Be 0
            }
        }

        Context 'When passing parameter ServerObject over the pipeline' {
            It 'Should update operator email address using pipeline input' {
                $script:mockMethodAlterCallCount = 0
                $script:mockOperator.EmailAddress = 'old@contoso.com'

                $script:mockServerObject | Set-SqlDscAgentOperator -Confirm:$false -Name 'TestOperator' -EmailAddress 'new@contoso.com'

                $script:mockOperator.EmailAddress | Should -Be 'new@contoso.com'
                $script:mockMethodAlterCallCount | Should -Be 1
            }
        }
    }

    Context 'When updating operator using ByObject parameter set' {
        BeforeAll {
            # Mock existing operator with parent hierarchy
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'old@contoso.com'

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Set up parent hierarchy
            $script:mockOperator.Parent = $script:mockJobServer
            $script:mockJobServer.Parent = $script:mockServerObject

            $script:mockMethodAlterCallCount = 0
            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                $script:mockMethodAlterCallCount++
            } -Force
        }

        It 'Should update operator email address when using operator object' {
            $script:mockMethodAlterCallCount = 0
            $script:mockOperator.EmailAddress = 'old@contoso.com'

            Set-SqlDscAgentOperator -Confirm:$false -OperatorObject $script:mockOperator -EmailAddress 'new@contoso.com'

            $script:mockOperator.EmailAddress | Should -Be 'new@contoso.com'
            $script:mockMethodAlterCallCount | Should -Be 1
        }

        Context 'When passing parameter OperatorObject over the pipeline' {
            It 'Should update operator email address using pipeline input' {
                $script:mockMethodAlterCallCount = 0
                $script:mockOperator.EmailAddress = 'old@contoso.com'

                $script:mockOperator | Set-SqlDscAgentOperator -Confirm:$false -EmailAddress 'new@contoso.com'

                $script:mockOperator.EmailAddress | Should -Be 'new@contoso.com'
                $script:mockMethodAlterCallCount | Should -Be 1
            }
        }
    }

    Context 'When update operation fails' {
        BeforeAll {
            # Mock existing operator
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'old@contoso.com'

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

            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                throw 'Mocked alter failure'
            } -Force
        }

        It 'Should throw when alter operation fails' {
            { Set-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator' -EmailAddress 'new@contoso.com' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage '*Failed to update SQL Agent Operator ''TestOperator''*'
        }
    }
}
