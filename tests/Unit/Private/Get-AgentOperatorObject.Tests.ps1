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
            # Create a mock operator object
            $mockOperatorObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Agent.Operator'
            $mockOperatorObject.Name = 'TestOperator'

            # Create a mock server object with a JobServer that contains operators
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockJobServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Agent.JobServer'
            $mockOperators = New-Object -TypeName 'System.Collections.ArrayList'
            $null = $mockOperators.Add($mockOperatorObject)

            $mockJobServer | Add-Member -MemberType NoteProperty -Name 'Operators' -Value $mockOperators -Force
            $mockServerObject | Add-Member -MemberType NoteProperty -Name 'JobServer' -Value $mockJobServer -Force
        }

        It 'Should return the operator object when found' {
            InModuleScope -Parameters @{ mockServerObject = $mockServerObject } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'TestOperator'
                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestOperator'
            }
        }

        It 'Should write verbose message when getting operator' {
            InModuleScope -Parameters @{ mockServerObject = $mockServerObject } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $verboseOutput = @()
                Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'TestOperator' -Verbose 4>&1 |
                    ForEach-Object { $verboseOutput += $_ }

                $verboseOutput -join ' ' | Should -Match "Getting SQL Agent Operator 'TestOperator' from server object"
            }
        }
    }

    Context 'When operator does not exist' {
        BeforeAll {
            # Create a mock server object with an empty JobServer operators collection
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockJobServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Agent.JobServer'
            $mockOperators = New-Object -TypeName 'System.Collections.ArrayList'

            $mockJobServer | Add-Member -MemberType NoteProperty -Name 'Operators' -Value $mockOperators -Force
            $mockServerObject | Add-Member -MemberType NoteProperty -Name 'JobServer' -Value $mockJobServer -Force
        }

        It 'Should return null when operator not found and IgnoreNotFound is specified' {
            InModuleScope -Parameters @{ mockServerObject = $mockServerObject } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'NonExistentOperator' -IgnoreNotFound
                $result | Should -BeNull
            }
        }

        It 'Should throw a terminating error when operator not found and IgnoreNotFound is not specified' {
            InModuleScope -Parameters @{ mockServerObject = $mockServerObject } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'NonExistentOperator' } |
                    Should -Throw -ExpectedMessage "*NonExistentOperator*not found*"
            }
        }

        It 'Should throw an error with the correct error record when IgnoreNotFound is not specified' {
            InModuleScope -Parameters @{ mockServerObject = $mockServerObject } -ScriptBlock {
                Set-StrictMode -Version 1.0

                try
                {
                    Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'NonExistentOperator'
                }
                catch
                {
                    $_.FullyQualifiedErrorId | Should -Be 'GAOO0001,Get-AgentOperatorObject'
                    $_.CategoryInfo.Category | Should -Be 'ObjectNotFound'
                    $_.TargetObject | Should -Be 'NonExistentOperator'
                }
            }
        }
    }
}
