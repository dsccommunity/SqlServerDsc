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

Describe 'New-SqlDscAgentAlert' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [[-Severity] <int>] [[-MessageId] <int>] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'New-SqlDscAgentAlert').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'New-SqlDscAgentAlert').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscAgentAlert').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Severity as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscAgentAlert').Parameters['Severity']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have MessageId as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'New-SqlDscAgentAlert').Parameters['MessageId']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When validating parameter ranges' {
        It 'Should accept valid Severity values (0-25)' {
            $command = Get-Command -Name 'New-SqlDscAgentAlert'
            $severityParam = $command.Parameters['Severity']
            $validateRangeAttribute = $severityParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }

            $validateRangeAttribute.MinRange | Should -Be 0
            $validateRangeAttribute.MaxRange | Should -Be 25
        }

        It 'Should accept valid MessageId values (0-2147483647)' {
            $command = Get-Command -Name 'New-SqlDscAgentAlert'
            $messageIdParam = $command.Parameters['MessageId']
            $validateRangeAttribute = $messageIdParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }

            $validateRangeAttribute.MinRange | Should -Be 0
            $validateRangeAttribute.MaxRange | Should -Be 2147483647
        }
    }

    Context 'When creating a new alert' {
        BeforeAll {
            # Mock alert collection (empty for new alert creation)
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()

            # Mock the JobServer using SMO stub types
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer

            # Mock the alert object that will be created
            $script:mockNewAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockNewAlert.Name = 'TestAlert'
            $script:mockNewAlert.Severity = 16
            $script:mockNewAlert.MessageID = 0

            # Mock the private functions
            Mock -CommandName 'Get-AgentAlertObject'
            Mock -CommandName 'Assert-BoundParameter'
        }

        It 'Should create alert with severity successfully' {
            $null = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16

            Should -Invoke -CommandName 'Assert-BoundParameter' -Times 1 -Exactly
            Should -Invoke -CommandName 'Get-AgentAlertObject' -Times 1 -Exactly
        }

        It 'Should create alert with message ID successfully' {
            $null = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId 50001

            Should -Invoke -CommandName 'Assert-BoundParameter' -Times 1 -Exactly
            Should -Invoke -CommandName 'Get-AgentAlertObject' -Times 1 -Exactly
        }

        It 'Should return alert object when PassThru is specified' {
            $result = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestAlert'
        }

        It 'Should not return alert object when PassThru is not specified' {
            $result = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16

            $result | Should -BeNullOrEmpty
        }

        It 'Should create alert with boundary severity values' {
            # Test minimum value (0)
            $null = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert1' -Severity 0

            # Test maximum value (25)
            $null = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert2' -Severity 25
        }

        It 'Should create alert with boundary message ID values' {
            # Test minimum value (0)
            $null = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert3' -MessageId 0

            # Test maximum value (2147483647)
            $null = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert4' -MessageId 2147483647
        }
    }

    Context 'When alert already exists' {
        BeforeAll {
            # Mock alert collection with existing alert
            $script:mockExistingAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockExistingAlert.Name = 'ExistingAlert'

            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()
            $script:mockAlertCollection.Add($script:mockExistingAlert)

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer

            Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockExistingAlert }
            Mock -CommandName 'Assert-BoundParameter'
        }

        It 'Should throw error when alert already exists' {
            { New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'ExistingAlert' -Severity 16 } |
                Should -Throw -ExpectedMessage '*already exists*'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            # Mock alert collection (empty)
            $script:mockAlertCollection = [Microsoft.SqlServer.Management.Smo.Agent.AlertCollection]::CreateTypeInstance()

            # Mock JobServer object
            $script:mockJobServer = [Microsoft.SqlServer.Management.Smo.Agent.JobServer]::CreateTypeInstance()
            $script:mockJobServer.Alerts = $script:mockAlertCollection

            # Mock server object
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()
            $script:mockServerObject.JobServer = $script:mockJobServer

            # Mock alert object
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()

            Mock -CommandName 'Get-AgentAlertObject'
            Mock -CommandName 'Assert-BoundParameter'
        }

        It 'Should not create alert when WhatIf is specified' {
            $null = New-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -WhatIf
        }
    }
}
