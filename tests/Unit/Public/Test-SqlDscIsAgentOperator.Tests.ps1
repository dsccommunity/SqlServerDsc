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

Describe 'Test-SqlDscIsAgentOperator' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <string> [-Refresh] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscIsAgentOperator').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsAgentOperator').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsAgentOperator').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When testing operator existence' {
        BeforeAll {
            # Mock existing operator
            $script:mockOperator = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
            $script:mockOperator.Name = 'TestOperator'
            $script:mockOperator.EmailAddress = 'test@contoso.com'

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
        }

        It 'Should return true when operator exists' {
            Mock -CommandName Get-AgentOperatorObject -MockWith {
                return $script:mockOperator
            }

            $result = Test-SqlDscIsAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator'

            $result | Should -BeTrue
            Should -Invoke -CommandName Get-AgentOperatorObject -Exactly -Times 1 -Scope It
        }

        It 'Should return false when operator does not exist' {
            Mock -CommandName Get-AgentOperatorObject -MockWith {
                return $null
            }

            $result = Test-SqlDscIsAgentOperator -ServerObject $script:mockServerObject -Name 'NonExistentOperator'

            $result | Should -BeFalse
            Should -Invoke -CommandName Get-AgentOperatorObject -Exactly -Times 1 -Scope It
        }

        Context 'When using pipeline input' {
            It 'Should return true when operator exists using pipeline input' {
                Mock -CommandName Get-AgentOperatorObject -MockWith {
                    return $script:mockOperator
                }

                $result = $script:mockServerObject | Test-SqlDscIsAgentOperator -Name 'TestOperator'

                $result | Should -BeTrue
                Should -Invoke -CommandName Get-AgentOperatorObject -Exactly -Times 1 -Scope It
            }
        }

        Context 'When using Refresh parameter' {
            It 'Should return true when operator exists' {
                Mock -CommandName Get-AgentOperatorObject -MockWith {
                    return $script:mockOperator
                }

                $result = Test-SqlDscIsAgentOperator -ServerObject $script:mockServerObject -Name 'TestOperator' -Refresh

                $result | Should -BeTrue
                Should -Invoke -CommandName Get-AgentOperatorObject -Exactly -Times 1 -Scope It
            }
        }
    }
}
