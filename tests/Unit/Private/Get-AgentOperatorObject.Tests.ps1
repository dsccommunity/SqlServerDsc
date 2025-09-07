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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../../Unit') -ChildPath 'Stubs/SMO.cs')

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
}

Describe 'Get-AgentOperatorObject' -Tag 'Private' {
    Context 'When operator exists' {
        BeforeAll {
            Mock -CommandName Get-SqlDscAgentOperator -MockWith {
                $mockOperatorObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Agent.Operator'
                return $mockOperatorObject
            }
        }

        It 'Should return the operator object when found' {
            InModuleScope -ScriptBlock {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $result = Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'TestOperator'
                $result | Should -Not -BeNullOrEmpty
                $result.GetType().Name | Should -Be 'Operator'
            }
        }

        It 'Should call Get-SqlDscAgentOperator with correct parameters' {
            InModuleScope -ScriptBlock {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'TestOperator'

                Should -Invoke -CommandName Get-SqlDscAgentOperator -ParameterFilter {
                    $Name -eq 'TestOperator' -and
                    $ErrorAction -eq 'Stop'
                } -Exactly -Times 1
            }
        }
    }

    Context 'When operator does not exist' {
        BeforeAll {
            Mock -CommandName Get-SqlDscAgentOperator -MockWith {
                return $null
            }
        }

        It 'Should throw a terminating error when operator not found' {
            InModuleScope -ScriptBlock {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                { Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'NonExistentOperator' } | Should -Throw -ExpectedMessage "*NonExistentOperator*not found*"
            }
        }

        It 'Should call Get-SqlDscAgentOperator once before throwing error' {
            InModuleScope -ScriptBlock {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                try 
                {
                    Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'NonExistentOperator'
                }
                catch 
                {
                    # Expected to throw
                }

                Should -Invoke -CommandName Get-SqlDscAgentOperator -Exactly -Times 1
            }
        }
    }
}