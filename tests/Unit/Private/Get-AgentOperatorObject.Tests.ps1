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
}

Describe 'Get-AgentOperatorObject' -Tag 'Private' {
    Context 'When getting an operator that exists' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock operator objects using SMO stub types
                $script:mockOperator1 = [Microsoft.SqlServer.Management.Smo.Agent.Operator]::CreateTypeInstance()
                $script:mockOperator1.Name = 'TestOperator'
                $script:mockOperator1.EmailAddress = 'test@contoso.com'

                # Mock operator collection
                $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()
                $script:mockOperatorCollection.Add($script:mockOperator1)

                # Mock JobServer object
                $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
                $script:mockJobServer.Operators = $script:mockOperatorCollection

                # Mock server object
                $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
                $script:mockServerObject.JobServer = $script:mockJobServer
            }
        }

        It 'Should return the operator when it exists' {
            InModuleScope -ScriptBlock {
                $result = Get-AgentOperatorObject -ServerObject $script:mockServerObject -Name 'TestOperator'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestOperator'
                $result.EmailAddress | Should -Be 'test@contoso.com'
            }
        }
    }

    Context 'When getting an operator that does not exist' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock empty operator collection
                $script:mockOperatorCollection = [Microsoft.SqlServer.Management.Smo.Agent.OperatorCollection]::CreateTypeInstance()

                # Mock JobServer object
                $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
                $script:mockJobServer.Operators = $script:mockOperatorCollection

                # Mock server object
                $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
                $script:mockServerObject.JobServer = $script:mockJobServer
            }
        }

        It 'Should return null when operator does not exist' {
            InModuleScope -ScriptBlock {
                $result = Get-AgentOperatorObject -ServerObject $script:mockServerObject -Name 'NonExistentOperator'

                $result | Should -BeNull
            }
        }
    }
}