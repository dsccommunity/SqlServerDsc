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
    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'Env:\SqlServerDscCI' -ErrorAction 'SilentlyContinue'

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
            $mockOperators = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $mockOperators.Add($mockOperatorObject)

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
    }

    Context 'When operator does not exist' {
        BeforeAll {
            # Create a mock server object with an empty JobServer operators collection
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockJobServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Agent.JobServer'
            $mockOperators = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()

            $mockJobServer | Add-Member -MemberType NoteProperty -Name 'Operators' -Value $mockOperators -Force
            $mockServerObject | Add-Member -MemberType NoteProperty -Name 'JobServer' -Value $mockJobServer -Force
        }

        It 'Should return null when operator not found and ErrorAction is SilentlyContinue' {
            InModuleScope -Parameters @{ mockServerObject = $mockServerObject } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'NonExistentOperator' -ErrorAction 'SilentlyContinue'
                $result | Should -BeNull
            }
        }

        It 'Should throw a terminating error when operator not found and ErrorAction is Stop' {
            InModuleScope -Parameters @{ mockServerObject = $mockServerObject } -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'NonExistentOperator' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "*NonExistentOperator*not found*"
            }
        }
    }

    Context 'When using Refresh parameter' {
        BeforeAll {
            # Create a mock operator object
            $mockOperatorObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Agent.Operator'
            $mockOperatorObject.Name = 'TestOperator'

            # Create a mock server object with a JobServer that contains operators
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockJobServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Agent.JobServer'
            $mockOperators = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
            $mockOperators.Add($mockOperatorObject)

            $mockJobServer | Add-Member -MemberType NoteProperty -Name 'Operators' -Value $mockOperators -Force
            $mockServerObject | Add-Member -MemberType NoteProperty -Name 'JobServer' -Value $mockJobServer -Force
        }

        It 'Should return the operator object when found' {
            InModuleScope -Parameters @{ mockServerObject = $mockServerObject } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-AgentOperatorObject -ServerObject $mockServerObject -Name 'TestOperator' -Refresh
                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestOperator'
            }
        }
    }
}
