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

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'Env:SqlServerDscCI' -ErrorAction 'SilentlyContinue'
}

Describe 'Test-SqlDscIsAgentAlert' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <string> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscIsAgentAlert').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsAgentAlert').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsAgentAlert').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscIsAgentAlert').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }
    }

    Context 'When testing alert existence only' {
        BeforeAll {
            # Mock the alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'

            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -MockWith { return $script:mockAlert }
        }

        It 'Should return true when alert exists' {
            $result = Test-SqlDscIsAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert'

            $result | Should -BeTrue
            Should -Invoke -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -Times 1 -Exactly
        }
    }

    Context 'When alert does not exist' {
        BeforeAll {
            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName
        }

        It 'Should return false when alert does not exist' {
            $result = Test-SqlDscIsAgentAlert -ServerObject $script:mockServerObject -Name 'NonExistentAlert'

            $result | Should -BeFalse
            Should -Invoke -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -Times 1 -Exactly
        }
    }

    Context 'When using the alias Test-SqlDscAgentAlert' {
        BeforeAll {
            # Mock the alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'

            # Mock the server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -MockWith { return $script:mockAlert }
        }

        It 'Should work with alias Test-SqlDscAgentAlert' {
            $result = Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert'

            $result | Should -BeTrue
            Should -Invoke -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -Times 1 -Exactly
        }
    }
}
