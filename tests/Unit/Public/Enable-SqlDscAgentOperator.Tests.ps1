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

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

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

    Remove-Item -Path 'Env:\SqlServerDscCI' -ErrorAction 'SilentlyContinue'
}

Describe 'Enable-SqlDscAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'OperatorObject'
                ExpectedParameters = '-OperatorObject <Operator> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Enable-SqlDscAgentOperator').ParameterSets |
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
        It 'Should have ServerObject as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Enable-SqlDscAgentOperator').Parameters['ServerObject']
            $parameterInfo.ParameterSets['ServerObject'].IsMandatory | Should -BeTrue
        }

        It 'Should have OperatorObject as a mandatory parameter in OperatorObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Enable-SqlDscAgentOperator').Parameters['OperatorObject']
            $parameterInfo.ParameterSets['OperatorObject'].IsMandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ServerObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Enable-SqlDscAgentOperator').Parameters['Name']
            $parameterInfo.ParameterSets['ServerObject'].IsMandatory | Should -BeTrue
        }
    }

    Context 'When enabling an operator using ServerObject parameter set' {
        BeforeAll {
            # Mock operator object
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'test@contoso.com'
            $script:mockOperator.Enabled = $false

            # Mock parent objects for verbose messages
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'
            $script:mockJobServer.Parent = $script:mockServerObject
            $script:mockOperator.Parent = $script:mockJobServer

            # Mock the Get-AgentOperatorObject function
            Mock -CommandName Get-AgentOperatorObject -MockWith {
                return $script:mockOperator
            }
        }

        It 'Should enable the operator successfully' {
            Enable-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator' -Force

            $script:mockOperator.Enabled | Should -BeTrue
            Should -Invoke -CommandName Get-AgentOperatorObject -Exactly -Times 1 -Scope It
        }

        It 'Should enable the operator with Refresh parameter' {
            Enable-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator' -Refresh -Force

            $script:mockOperator.Enabled | Should -BeTrue
            Should -Invoke -CommandName Get-AgentOperatorObject -ParameterFilter {
                $Refresh -eq $true
            } -Exactly -Times 1 -Scope It
        }

        It 'Should use pipeline input for ServerObject' {
            $script:mockServerObject | Enable-SqlDscAgentOperator -Name 'TestOperator' -Force

            $script:mockOperator.Enabled | Should -BeTrue
            Should -Invoke -CommandName Get-AgentOperatorObject -Exactly -Times 1 -Scope It
        }

        It 'Should throw when operator cannot be found' {
            Mock -CommandName Get-AgentOperatorObject -MockWith {
                throw 'Operator not found'
            }

            { Enable-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'NonExistentOperator' -Force } |
                Should -Throw -ExpectedMessage 'Operator not found'
        }

        It 'Should support WhatIf' {
            $script:mockOperator.Enabled = $false

            Enable-SqlDscAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator' -WhatIf

            $script:mockOperator.Enabled | Should -BeFalse
            Should -Invoke -CommandName Get-AgentOperatorObject -Exactly -Times 1 -Scope It
        }
    }

    Context 'When enabling an operator using OperatorObject parameter set' {
        BeforeAll {
            # Mock operator object
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'test@contoso.com'
            $script:mockOperator.Enabled = $false

            # Mock parent objects for verbose messages
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'
            $script:mockJobServer.Parent = $script:mockServerObject
            $script:mockOperator.Parent = $script:mockJobServer
        }

        It 'Should enable the operator successfully using OperatorObject' {
            Enable-SqlDscAgentOperator -OperatorObject $script:mockOperator -Force

            $script:mockOperator.Enabled | Should -BeTrue
        }

        It 'Should use pipeline input for OperatorObject' {
            $script:mockOperator.Enabled = $false

            $script:mockOperator | Enable-SqlDscAgentOperator -Force

            $script:mockOperator.Enabled | Should -BeTrue
        }

        It 'Should support WhatIf with OperatorObject' {
            $script:mockOperator.Enabled = $false

            Enable-SqlDscAgentOperator -OperatorObject $script:mockOperator -WhatIf

            $script:mockOperator.Enabled | Should -BeFalse
        }
    }

    Context 'When enabling an operator fails' {
        BeforeAll {
            # Mock operator object that will fail to alter
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'test@contoso.com'
            $script:mockOperator.Enabled = $false

            # Mock parent objects for verbose messages
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'
            $script:mockJobServer.Parent = $script:mockServerObject
            $script:mockOperator.Parent = $script:mockJobServer

            # Add a method to throw exception when Alter() is called
            $script:mockOperator | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                throw 'Failed to alter operator'
            } -Force
        }

        It 'Should throw terminating error when enabling fails' {
            { Enable-SqlDscAgentOperator -OperatorObject $script:mockOperator -Force } |
                Should -Throw -ExpectedMessage "*Failed to enable SQL Agent Operator 'TestOperator'*"
        }
    }
}
