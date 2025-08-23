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

Describe 'Get-SqlDscAgentAlert' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [[-Name] <String>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscAgentAlert').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Get-SqlDscAgentAlert').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscAgentAlert').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscAgentAlert').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When getting all alerts' {
        BeforeAll {
            # Mock alert objects using SMO stub types
            $script:mockAlert1 = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert1.Name = 'Alert1'
            $script:mockAlert1.Severity = 16

            $script:mockAlert2 = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert2.Name = 'Alert2'
            $script:mockAlert2.MessageID = 50001

            # Mock alert collection
            # Mock alert collection
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
            $script:mockAlertCollection.Add($script:mockAlert1)
            $script:mockAlertCollection.Add($script:mockAlert2)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should return all alerts when no name is specified' {
            $result = Get-SqlDscAgentAlert -ServerObject $script:mockServerObject

            $result | Should -HaveCount 2
            $result[0].Name | Should -Be 'Alert1'
            $result[1].Name | Should -Be 'Alert2'
        }
    }

    Context 'When getting a specific alert' {
        BeforeAll {
            # Mock alert objects using SMO stub types
            $script:mockAlert1 = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert1.Name = 'TestAlert'
            $script:mockAlert1.Severity = 16

            # Mock alert collection
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
            $script:mockAlertCollection.Add($script:mockAlert1)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should return specific alert when name matches' {
            $result = Get-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestAlert'
            $result.Severity | Should -Be 16
        }

        It 'Should return null when alert does not exist' {
            $result = Get-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'NonExistentAlert'

            $result | Should -BeNull
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            # Mock alert collection
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer
        }

        It 'Should accept server object from pipeline' {
            $result = $script:mockServerObject | Get-SqlDscAgentAlert
            $result | Should -BeNullOrEmpty
        }
    }
}
