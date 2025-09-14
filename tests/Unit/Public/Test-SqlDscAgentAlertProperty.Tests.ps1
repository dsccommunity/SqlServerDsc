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

Describe 'Test-SqlDscAgentAlertProperty' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByServerAndName'
                ExpectedParameters = '-ServerObject <Server> -Name <string> [-Severity <int>] [-MessageId <int>] [<CommonParameters>]'
            },
            @{
                ExpectedParameterSetName = 'ByAlertObject'
                ExpectedParameters = '-AlertObject <Alert> [-Severity <int>] [-MessageId <int>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscAgentAlertProperty').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlertProperty').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have ServerObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlertProperty').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter in ByServerAndName parameter set' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlertProperty').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have AlertObject as a mandatory parameter in ByAlertObject parameter set' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlertProperty').Parameters['AlertObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have AlertObject accept pipeline input' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlertProperty').Parameters['AlertObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -BeTrue
        }

        It 'Should have Severity as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlertProperty').Parameters['Severity']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have MessageId as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlertProperty').Parameters['MessageId']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When validating parameter ranges' {
        It 'Should accept valid Severity values (0-25)' {
            $command = Get-Command -Name 'Test-SqlDscAgentAlertProperty'
            $severityParam = $command.Parameters['Severity']
            $validateRangeAttribute = $severityParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }

            $validateRangeAttribute.MinRange | Should -Be 0
            $validateRangeAttribute.MaxRange | Should -Be 25
        }

        It 'Should accept valid MessageId values (0-2147483647)' {
            $command = Get-Command -Name 'Test-SqlDscAgentAlertProperty'
            $messageIdParam = $command.Parameters['MessageId']
            $validateRangeAttribute = $messageIdParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }

            $validateRangeAttribute.MinRange | Should -Be 0
            $validateRangeAttribute.MaxRange | Should -Be 2147483647
        }
    }

    Context 'When no property parameters are specified' {
        BeforeAll {
            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName -MockWith { throw 'At least one parameter required' }
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName
        }

        It 'Should throw an error when no property parameters are specified' {
            { Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'TestAlert' } |
                Should -Throw

            Should -Invoke -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName -Times 1 -Exactly
        }
    }

    Context 'When testing alert with severity' {
        BeforeAll {
            # Mock the alert object with specific severity using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'
            $script:mockAlert.Severity = 16
            $script:mockAlert.MessageId = 0

            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -MockWith { return $script:mockAlert }
        }

        It 'Should return true when alert exists and severity matches' {
            $result = Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16

            $result | Should -BeTrue
            Should -Invoke -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName -Times 2 -Exactly
            Should -Invoke -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -Times 1 -Exactly
        }

        It 'Should return false when alert exists but severity does not match' {
            $result = Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 14

            $result | Should -BeFalse
        }
    }

    Context 'When testing alert with message ID' {
        BeforeAll {
            # Mock the alert object with specific message ID using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'
            $script:mockAlert.Severity = 0
            $script:mockAlert.MessageId = 50001

            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -MockWith { return $script:mockAlert }
        }

        It 'Should return true when alert exists and message ID matches' {
            $result = Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId 50001

            $result | Should -BeTrue
        }

        It 'Should return false when alert exists but message ID does not match' {
            $result = Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId 50002

            $result | Should -BeFalse
        }
    }

    Context 'When alert does not exist' {
        BeforeAll {
            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName
            Mock -CommandName 'Write-Error' -ModuleName $script:dscModuleName
        }

        It 'Should return false when alert does not exist (with Severity)' {
            $result = Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'NonExistentAlert' -Severity 16

            $result | Should -BeFalse
            Should -Invoke -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -Times 1 -Exactly
            Should -Invoke -CommandName 'Write-Error' -ModuleName $script:dscModuleName -Times 1 -Exactly
        }

        It 'Should return false when alert does not exist (with MessageId)' {
            $result = Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'NonExistentAlert' -MessageId 50001

            $result | Should -BeFalse
            Should -Invoke -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -Times 1 -Exactly
            Should -Invoke -CommandName 'Write-Error' -ModuleName $script:dscModuleName -Times 1 -Exactly
        }

        It 'Should call Write-Error with correct parameters when alert does not exist' {
            $result = Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'NonExistentAlert' -Severity 16

            $result | Should -BeFalse
            Should -Invoke -CommandName 'Write-Error' -ModuleName $script:dscModuleName -ParameterFilter {
                $Category -eq 'ObjectNotFound' -and $ErrorId -eq 'TSDAAP0001' -and $TargetObject -eq 'NonExistentAlert'
            } -Times 1 -Exactly
        }
    }

    Context 'When parameter validation is called' {
        BeforeAll {
            # Mock server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName -ParameterFilter { $MutuallyExclusiveList1 } -MockWith { throw 'Mutually exclusive parameters' }
            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName -ParameterFilter { $AtLeastOneList }
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName
        }

        It 'Should call parameter validation with both severity and message ID and throw' {
            { Test-SqlDscAgentAlertProperty -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity 16 -MessageId 50001 } |
                Should -Throw

            Should -Invoke -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName -Times 2 -Exactly
        }
    }

    Context 'When using AlertObject parameter set' {
        BeforeAll {
            # Mock the alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'
            $script:mockAlert.Severity = 16
            $script:mockAlert.MessageId = 0

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName
        }

        It 'Should return true when alert object has matching severity' {
            $result = $script:mockAlert | Test-SqlDscAgentAlertProperty -Severity 16

            $result | Should -BeTrue
            Should -Invoke -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName -Times 2 -Exactly
        }

        It 'Should return false when alert object has non-matching severity' {
            $result = $script:mockAlert | Test-SqlDscAgentAlertProperty -Severity 14

            $result | Should -BeFalse
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            # Mock the alert object using SMO stub types
            $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
            $script:mockAlert.Name = 'TestAlert'
            $script:mockAlert.Severity = 16

            # Mock the server object using SMO stub types
            $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

            Mock -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName
            Mock -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -MockWith { return $script:mockAlert }
        }

        It 'Should work with pipeline input' {
            $result = $script:mockServerObject | Test-SqlDscAgentAlertProperty -Name 'TestAlert' -Severity 16

            $result | Should -BeTrue
            Should -Invoke -CommandName 'Assert-BoundParameter' -ModuleName $script:dscModuleName -Times 2 -Exactly
            Should -Invoke -CommandName 'Get-AgentAlertObject' -ModuleName $script:dscModuleName -Times 1 -Exactly
        }
    }
}
