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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Load SMO stub types
    Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"

    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}

Describe 'Set-SqlDscAgentAlert' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Severity <int>] [-MessageId <int>] [-PassThru] [-Refresh] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'AlertObject'
                ExpectedParameters = '-AlertObject <Alert> [-Severity <int>] [-MessageId <int>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscAgentAlert').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentAlert').Parameters['ServerObject']
            $serverObjectParameterSet = $parameterInfo.ParameterSets['ServerObject']
            $serverObjectParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have AlertObject as a mandatory parameter in AlertObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Set-SqlDscAgentAlert').Parameters['AlertObject']
            $alertObjectParameterSet = $parameterInfo.ParameterSets['AlertObject']
            $alertObjectParameterSet.IsMandatory | Should -BeTrue
        }
    }

    Context 'When validating parameter ranges' {
        It 'Should accept valid Severity values (0-25)' {
            $command = Get-Command -Name 'Set-SqlDscAgentAlert'
            $severityParam = $command.Parameters['Severity']
            $validateRangeAttribute = $severityParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }

            $validateRangeAttribute.MinRange | Should -Be 0
            $validateRangeAttribute.MaxRange | Should -Be 25
        }

        It 'Should accept valid MessageId values (0-2147483647)' {
            $command = Get-Command -Name 'Set-SqlDscAgentAlert'
            $messageIdParam = $command.Parameters['MessageId']
            $validateRangeAttribute = $messageIdParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }

            $validateRangeAttribute.MinRange | Should -Be 0
            $validateRangeAttribute.MaxRange | Should -Be 2147483647
        }
    }

    Context 'When updating alert using ServerObject parameter set' {
        BeforeAll {
            # Mock the alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'
            $script:mockAlert.Severity = 14
            $script:mockAlert.MessageId = 0

            # Mock alert collection using SMO stub types with refresh tracking
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
            $script:refreshCalled = $false
            $script:mockAlertCollection | Add-Member -MemberType ScriptMethod -Name 'Refresh' -Value { $script:refreshCalled = $true } -Force

            # Mock the JobServer using SMO stub types
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer

            Mock -CommandName 'Assert-BoundParameter'
            Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockAlert }
        }

        BeforeEach {
            # Reset the refresh tracking before each test
            $script:refreshCalled = $false
        }

        It 'Should update alert severity successfully' {
            $null = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -Force

            Should -Invoke -CommandName 'Assert-BoundParameter' -Times 1 -Exactly
            Should -Invoke -CommandName 'Get-AgentAlertObject' -Times 1 -Exactly
            $script:mockAlert.Severity | Should -Be 16
            $script:mockAlert.MessageId | Should -Be 0
        }

        It 'Should set MessageId to 0 when updating Severity to ensure no conflicts' {
            # Set up alert with existing MessageId
            $script:mockAlert.Severity = 0
            $script:mockAlert.MessageId = 12345

            $null = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -Force

            $script:mockAlert.Severity | Should -Be 16
            $script:mockAlert.MessageId | Should -Be 0
        }

        It 'Should set Severity to 0 when updating MessageId to ensure no conflicts' {
            # Set up alert with existing Severity
            $script:mockAlert.Severity = 15
            $script:mockAlert.MessageId = 0

            $null = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId 50001 -Force

            $script:mockAlert.MessageId | Should -Be 50001
            $script:mockAlert.Severity | Should -Be 0
        }

        It 'Should call Alter method when changes are made' {
            $script:alterCalled = $false
            $script:mockAlert | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { $script:alterCalled = $true } -Force

            # Set initial values different from what we'll set
            $script:mockAlert.Severity = 10
            $script:mockAlert.MessageId = 0

            $null = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -Force

            $script:alterCalled | Should -BeTrue
        }

        Context 'When using PassThru parameter' {
            It 'Should update alert message ID successfully' {
                $null = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId 50001 -Force

                $script:mockAlert.MessageId | Should -Be 50001
                $script:mockAlert.Severity | Should -Be 0  # Should be set to 0 to avoid conflicts
            }

            It 'Should return alert object' {
                $result = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -Force -PassThru

                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.Agent.Alert]
                $result.Name | Should -Be 'TestAlert'
                $result.Severity | Should -Be 16
            }

            It 'Should not return alert object without PassThru' {
                $result = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -Force

                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When Refresh is not specified' {
            It 'Should not refresh server object when Refresh is not specified' {
                $null = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -Force

                $script:refreshCalled | Should -BeFalse
            }
        }

        Context 'When testing change detection logic' {
            It 'Should detect changes when Severity is different' {
                $script:alterCalled = $false
                $script:mockAlert | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { $script:alterCalled = $true } -Force

                # Set up alert with different severity
                $script:mockAlert.Severity = 10
                $script:mockAlert.MessageId = 0

                $null = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -Force

                $script:alterCalled | Should -BeTrue
                $script:mockAlert.Severity | Should -Be 16
                $script:mockAlert.MessageId | Should -Be 0  # Should be reset to 0
            }

            It 'Should detect changes when MessageId is different' {
                $script:alterCalled = $false
                $script:mockAlert | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { $script:alterCalled = $true } -Force

                # Set up alert with different message ID
                $script:mockAlert.Severity = 0
                $script:mockAlert.MessageId = 12345

                $null = Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId 50001 -Force

                $script:alterCalled | Should -BeTrue
                $script:mockAlert.MessageId | Should -Be 50001
                $script:mockAlert.Severity | Should -Be 0  # Should be reset to 0
            }
        }
    }

    Context 'When updating alert using AlertObject parameter set' {
        BeforeAll {
            # Mock the alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'
            $script:mockAlert.Severity = 14
            $script:mockAlert.MessageId = 0

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:moduleName
        }

        It 'Should update alert using AlertObject parameter' {
            $null = Set-SqlDscAgentAlert -AlertObject $script:mockAlert -Severity 16 -Force

            Should -Invoke -CommandName 'Assert-BoundParameter' -ModuleName $script:moduleName -Times 1 -Exactly
            $script:mockAlert.Severity | Should -Be 16
            $script:mockAlert.MessageId | Should -Be 0
        }

        It 'Should set MessageId to 0 when updating Severity using AlertObject' {
            # Set up alert with existing MessageId
            $script:mockAlert.Severity = 10
            $script:mockAlert.MessageId = 12345

            $null = Set-SqlDscAgentAlert -AlertObject $script:mockAlert -Severity 16 -Force

            $script:mockAlert.Severity | Should -Be 16
            $script:mockAlert.MessageId | Should -Be 0
        }

        It 'Should set Severity to 0 when updating MessageId using AlertObject' {
            # Set up alert with existing Severity
            $script:mockAlert.Severity = 15
            $script:mockAlert.MessageId = 0

            $null = Set-SqlDscAgentAlert -AlertObject $script:mockAlert -MessageId 50001 -Force

            $script:mockAlert.MessageId | Should -Be 50001
            $script:mockAlert.Severity | Should -Be 0
        }

        It 'Should call Alter method when changes are made using AlertObject' {
            $script:alterCalled = $false
            $script:mockAlert | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { $script:alterCalled = $true } -Force

            # Set initial values different from what we'll set
            $script:mockAlert.Severity = 10
            $script:mockAlert.MessageId = 0

            $null = Set-SqlDscAgentAlert -AlertObject $script:mockAlert -Severity 16 -Force

            $script:alterCalled | Should -BeTrue
        }
    }

    Context 'When alert does not exist' {
        BeforeAll {
            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:moduleName
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:moduleName
        }

        It 'Should throw error when alert does not exist' {
            { Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'NonExistentAlert' -Severity 16 -Force } |
                Should -Throw -ExpectedMessage '*was not found*'
        }
    }

    Context 'When no changes are needed' {
        BeforeAll {
            # Mock the alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'
            $script:mockAlert.Severity = 14
            $script:mockAlert.MessageId = 0

            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:moduleName
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:moduleName -MockWith { return $script:mockAlert }
        }

        It 'Should not call Alter when Severity is already correct' {
            $script:alterCalled = $false
            $script:mockAlert | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { $script:alterCalled = $true } -Force

            # Set up alert with the same severity we're going to set
            $script:mockAlert.Severity = 14
            $script:mockAlert.MessageId = 0

            Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 14 -Force

            $script:alterCalled | Should -BeFalse
        }

        It 'Should not call Alter when MessageId is already correct' {
            $script:alterCalled = $false
            $script:mockAlert | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { $script:alterCalled = $true } -Force

            # Set up alert with the same message ID we're going to set
            $script:mockAlert.Severity = 0
            $script:mockAlert.MessageId = 50001

            Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId 50001 -Force

            $script:alterCalled | Should -BeFalse
        }

        It 'Should not call Alter when both Severity and MessageId parameters are provided but values are unchanged' {
            $script:alterCalled = $false
            $script:mockAlert | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { $script:alterCalled = $true } -Force

            # Set up alert with same values we're going to set
            $script:mockAlert.Severity = 14
            $script:mockAlert.MessageId = 0

            Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 14 -MessageId 0 -Force

            $script:alterCalled | Should -BeFalse
        }
    }

    Context 'When update fails' {
        BeforeAll {
            # Mock the alert object that will fail on Alter using SMO stub types
            $script:mockFailingAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockFailingAlert.Name = 'TestAlert'
            $script:mockFailingAlert.Severity = 14
            $script:mockFailingAlert.MessageId = 0
            # Mock the Alter method to throw an exception
            $script:mockFailingAlert | Add-Member -MemberType ScriptMethod -Name 'Alter' -Value { throw 'Update failed' } -Force

            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:moduleName
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:moduleName -MockWith { return $script:mockFailingAlert }
        }

        It 'Should throw error when update fails' {
            { Set-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -Force } |
                Should -Throw -ExpectedMessage '*Failed to update*'
        }
    }
}
