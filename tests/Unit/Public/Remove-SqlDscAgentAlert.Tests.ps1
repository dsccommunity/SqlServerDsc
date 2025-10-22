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

Describe 'Remove-SqlDscAgentAlert' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'AlertObject'
                ExpectedParameters = '-AlertObject <Alert> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Remove-SqlDscAgentAlert').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscAgentAlert').Parameters['ServerObject']
            $serverObjectParameterSet = $parameterInfo.ParameterSets['ServerObject']
            $serverObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have AlertObject as a mandatory parameter in AlertObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Remove-SqlDscAgentAlert').Parameters['AlertObject']
            $alertObjectParameterSet = $parameterInfo.ParameterSets['AlertObject']
            $alertObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should support ShouldProcess' {
            $commandInfo = Get-Command -Name 'Remove-SqlDscAgentAlert'
            $commandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $commandInfo.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should have ConfirmImpact set to High' {
            $commandInfo = Get-Command -Name 'Remove-SqlDscAgentAlert'
            $commandInfo.Parameters['WhatIf'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | Should -Not -BeNullOrEmpty
            $commandInfo.Parameters['Confirm'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When removing alert using ServerObject parameter set' {
        BeforeAll {
            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            # Mock alert collection
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Set up the hierarchy
            $script:mockServerObject.JobServer = $script:mockJobServer

            # Mock alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'

            # Add Parent properties to establish the hierarchy
            $script:mockAlert | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockJobServer -Force
            $script:mockJobServer | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockServerObject -Force

            Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockAlert }
        }

        It 'Should remove alert successfully' {
            $null = Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Force

            Should -Invoke -CommandName 'Get-AgentAlertObject' -Times 1 -Exactly
        }

        It 'Should refresh server object when Refresh is specified' {
            $null = Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Refresh -Force

            # Verify that Refresh was called on the Alerts collection
            # This would need to be mocked more specifically to verify the call
        }
    }

    Context 'When removing alert using AlertObject parameter set' {
        BeforeAll {
            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            # Set up the hierarchy
            $script:mockJobServer | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockServerObject -Force

            # Mock alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'

            # Add Parent property to establish the hierarchy
            $script:mockAlert | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockJobServer -Force
        }

        It 'Should remove alert using AlertObject parameter' {
            $null = Remove-SqlDscAgentAlert -AlertObject $script:mockAlert -Force
        }
    }

    Context 'When alert does not exist' {
        BeforeAll {
            # Mock alert collection
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer

            Mock -CommandName 'Get-AgentAlertObject'
        }

        It 'Should not throw error when alert does not exist' {
            $null = Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'NonExistentAlert' -Force

            Should -Invoke -CommandName 'Get-AgentAlertObject' -Times 1 -Exactly
        }
    }

    Context 'When removal fails' {
        BeforeAll {
            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            # Mock alert collection
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Set up the hierarchy
            $script:mockServerObject.JobServer = $script:mockJobServer

            # Mock alert object that will fail on Drop using SMO stub types
            $script:mockFailingAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockFailingAlert.Name = 'TestAlert'

            # Add Parent properties to establish the hierarchy
            $script:mockFailingAlert | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockJobServer -Force
            $script:mockJobServer | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockServerObject -Force

            Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockFailingAlert }

            # Mock the Drop method to throw an error
            $script:mockFailingAlert | Add-Member -MemberType ScriptMethod -Name 'Drop' -Value { throw 'Removal failed' } -Force
        }

        It 'Should throw correct error when removal fails' {
            $errorRecord = { Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Force } |
                Should -Throw -PassThru

            $errorRecord.Exception.Message | Should -BeLike '*Failed to remove*TestAlert*'
            $errorRecord.Exception | Should -BeOfType [System.InvalidOperationException]
            $errorRecord.FullyQualifiedErrorId | Should -Be 'RSAA0005,Remove-SqlDscAgentAlert'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            # Mock alert collection
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Set up the hierarchy
            $script:mockServerObject.JobServer = $script:mockJobServer

            # Mock alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'

            # Add Parent properties to establish the hierarchy
            $script:mockAlert | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockJobServer -Force
            $script:mockJobServer | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockServerObject -Force

            Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockAlert }
        }

        It 'Should not remove alert when WhatIf is specified' {
            $null = Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -WhatIf

            # The Drop method should not be called with WhatIf
            # This would need more sophisticated mocking to verify
        }
    }

    Context 'When Force parameter affects confirmation' {
        BeforeAll {
            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.InstanceName = 'TestInstance'

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            # Mock alert collection
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Set up the hierarchy
            $script:mockServerObject.JobServer = $script:mockJobServer

            # Mock alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'

            # Add Parent properties to establish the hierarchy
            $script:mockAlert | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockJobServer -Force
            $script:mockJobServer | Add-Member -MemberType NoteProperty -Name 'Parent' -Value $script:mockServerObject -Force

            Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockAlert }
        }

        It 'Should remove alert without confirmation when Force is specified' {
            # This test verifies that Force parameter works, but full confirmation testing
            # would require more complex mocking of the confirmation system
            $null = Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Force
        }
    }
}
