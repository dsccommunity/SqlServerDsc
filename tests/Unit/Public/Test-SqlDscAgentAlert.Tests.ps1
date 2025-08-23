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

Describe 'Test-SqlDscAgentAlert' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [[-Severity] <String>] [[-MessageId] <String>] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscAgentAlert').ParameterSets |
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
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlert').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlert').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Severity as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlert').Parameters['Severity']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }

        It 'Should have MessageId as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscAgentAlert').Parameters['MessageId']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When testing alert existence only' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock the alert object using SMO stub types
                $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
                $script:mockAlert.Name = 'TestAlert'
                $script:mockAlert.Severity = 16
                $script:mockAlert.MessageId = 0

                # Mock server object using SMO stub types
                $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

                Mock -CommandName 'Assert-BoundParameter' -MockWith { }
                Mock -CommandName 'Get-SqlDscAgentAlertObject' -MockWith { return $script:mockAlert }
            }
        }

        It 'Should return true when alert exists and no properties are specified' {
            InModuleScope -ScriptBlock {
                $result = Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert'

                $result | Should -BeTrue
                Should -Invoke -CommandName 'Assert-BoundParameter' -Times 1 -Exactly
                Should -Invoke -CommandName 'Get-SqlDscAgentAlertObject' -Times 1 -Exactly
            }
        }
    }

    Context 'When testing alert with severity' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock the alert object with specific severity using SMO stub types
                $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
                $script:mockAlert.Name = 'TestAlert'
                $script:mockAlert.Severity = 16
                $script:mockAlert.MessageId = 0

                # Mock server object using SMO stub types
                $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

                Mock -CommandName 'Assert-BoundParameter' -MockWith { }
                Mock -CommandName 'Get-SqlDscAgentAlertObject' -MockWith { return $script:mockAlert }
            }
        }

        It 'Should return true when alert exists and severity matches' {
            InModuleScope -ScriptBlock {
                $result = Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity '16'

                $result | Should -BeTrue
            }
        }

        It 'Should return false when alert exists but severity does not match' {
            InModuleScope -ScriptBlock {
                $result = Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity '14'

                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing alert with message ID' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock the alert object with specific message ID using SMO stub types
                $script:mockAlert = [Microsoft.SqlServer.Management.Smo.Agent.Alert]::CreateTypeInstance()
                $script:mockAlert.Name = 'TestAlert'
                $script:mockAlert.Severity = 0
                $script:mockAlert.MessageId = 50001

                # Mock server object using SMO stub types
                $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

                Mock -CommandName 'Assert-BoundParameter' -MockWith { }
                Mock -CommandName 'Get-SqlDscAgentAlertObject' -MockWith { return $script:mockAlert }
            }
        }

        It 'Should return true when alert exists and message ID matches' {
            InModuleScope -ScriptBlock {
                $result = Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId '50001'

                $result | Should -BeTrue
            }
        }

        It 'Should return false when alert exists but message ID does not match' {
            InModuleScope -ScriptBlock {
                $result = Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -MessageId '50002'

                $result | Should -BeFalse
            }
        }
    }

    Context 'When alert does not exist' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock server object using SMO stub types
                $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

                Mock -CommandName 'Assert-BoundParameter' -MockWith { }
                Mock -CommandName 'Get-SqlDscAgentAlertObject' -MockWith { return $null }
            }
        }

        It 'Should return false when alert does not exist' {
            InModuleScope -ScriptBlock {
                $result = Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'NonExistentAlert'

                $result | Should -BeFalse
                Should -Invoke -CommandName 'Get-SqlDscAgentAlertObject' -Times 1 -Exactly
            }
        }
    }

    Context 'When parameter validation is called' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock server object using SMO stub types
                $script:mockServerObject = [Microsoft.SqlServer.Management.Smo.Server]::CreateTypeInstance()

                Mock -CommandName 'Assert-BoundParameter' -MockWith { }
                Mock -CommandName 'Get-SqlDscAgentAlertObject' -MockWith { return $null }
            }
        }

        It 'Should call parameter validation with both severity and message ID' {
            InModuleScope -ScriptBlock {
                Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity '16' -MessageId '50001'

                Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                    $BoundParameterList.ContainsKey('Severity') -and $BoundParameterList.ContainsKey('MessageId')
                } -Times 1 -Exactly
            }
        }

        It 'Should call parameter validation with only severity' {
            InModuleScope -ScriptBlock {
                Test-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Severity '16'

                Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                    $BoundParameterList.ContainsKey('Severity') -and -not $BoundParameterList.ContainsKey('MessageId')
                } -Times 1 -Exactly
            }
        }
    }
}
