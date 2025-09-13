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

Describe 'Get-AgentAlertObject' -Tag 'Private' {
    Context 'When getting an alert object' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock the alert object using SMO stub types
                $script:mockAlertObject = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
                $script:mockAlertObject.Name = 'TestAlert'
                $script:mockAlertObject.Severity = 16
                $script:mockAlertObject.MessageID = 0

                # Mock alert collection
                $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
                $script:mockAlertCollection.Add($script:mockAlertObject)

                # Mock JobServer object
                $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
                $script:mockJobServer.Alerts = $script:mockAlertCollection

                # Mock the server object
                $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
                $script:mockServerObject.JobServer = $script:mockJobServer
            }
        }

        It 'Should return the correct alert object when alert exists' {
            InModuleScope -ScriptBlock {
                $result = Get-AgentAlertObject -ServerObject $script:mockServerObject -Name 'TestAlert'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestAlert'
                $result.Severity | Should -Be '16'
            }
        }

        It 'Should return null when alert does not exist' {
            InModuleScope -ScriptBlock {
                $result = Get-AgentAlertObject -ServerObject $script:mockServerObject -Name 'NonExistentAlert'

                $result | Should -BeNull
            }
        }
    }

    Context 'When server object has no alerts' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock alert collection (empty)
                $script:mockEmptyAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()

                # Mock JobServer object
                $script:mockEmptyJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
                $script:mockEmptyJobServer.Alerts = $script:mockEmptyAlertCollection

                # Mock server object with empty alerts collection
                $script:mockEmptyServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
                $script:mockEmptyServerObject.JobServer = $script:mockEmptyJobServer
            }
        }

        It 'Should return null when no alerts exist' {
            InModuleScope -ScriptBlock {
                $result = Get-AgentAlertObject -ServerObject $script:mockEmptyServerObject -Name 'TestAlert'

                $result | Should -BeNull
            }
        }
    }
}
