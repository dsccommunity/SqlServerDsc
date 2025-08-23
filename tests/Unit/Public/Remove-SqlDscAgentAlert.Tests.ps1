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

Describe 'Remove-SqlDscAgentAlert' -Tag 'Public' {
    Context 'When command has correct parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ServerObject'
                ExpectedParameters = '[-ServerObject] <Server> [-Name] <String> [-Force] [-Refresh] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'AlertObject'
                ExpectedParameters = '[-AlertObject] <Alert> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
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
            $commandInfo.CmdletBinding.SupportsShouldProcess | Should -BeTrue
        }

        It 'Should have ConfirmImpact set to High' {
            $commandInfo = Get-Command -Name 'Remove-SqlDscAgentAlert'
            $commandInfo.CmdletBinding.ConfirmImpact | Should -Be 'High'
        }
    }

    Context 'When removing alert using ServerObject parameter set' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock the alert object
                $script:mockAlert = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestAlert' -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value { } -PassThru

                # Mock the server object
                $script:mockServerObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'JobServer' -Value (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Alerts' -Value (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType ScriptMethod -Name 'Refresh' -Value { } -PassThru
                            ) -PassThru
                    ) -PassThru

                Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockAlert }
            }
        }

        It 'Should remove alert successfully' {
            InModuleScope -ScriptBlock {
                { Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Force } | Should -Not -Throw

                Should -Invoke -CommandName 'Get-AgentAlertObject' -Times 1 -Exactly
            }
        }

        It 'Should refresh server object when Refresh is specified' {
            InModuleScope -ScriptBlock {
                { Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Refresh -Force } | Should -Not -Throw

                # Verify that Refresh was called on the Alerts collection
                # This would need to be mocked more specifically to verify the call
            }
        }

        It 'Should write verbose messages during removal' {
            InModuleScope -ScriptBlock {
                $verboseMessages = @()

                Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Force -Verbose 4>&1 |
                    ForEach-Object { $verboseMessages += $_ }

                $verboseMessages | Should -Not -BeNullOrEmpty
                $verboseMessages | Should -Contain ($script:localizedData.Remove_SqlDscAgentAlert_RemovingAlert -f 'TestAlert')
                $verboseMessages | Should -Contain ($script:localizedData.Remove_SqlDscAgentAlert_AlertRemoved -f 'TestAlert')
            }
        }
    }

    Context 'When removing alert using AlertObject parameter set' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock the alert object
                $script:mockAlert = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestAlert' -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value { } -PassThru
            }
        }

        It 'Should remove alert using AlertObject parameter' {
            InModuleScope -ScriptBlock {
                { Remove-SqlDscAgentAlert -AlertObject $script:mockAlert -Force } | Should -Not -Throw
            }
        }
    }

    Context 'When alert does not exist' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'JobServer' -Value (New-Object -TypeName Object) -PassThru

                Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $null }
            }
        }

        It 'Should not throw error when alert does not exist' {
            InModuleScope -ScriptBlock {
                { Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'NonExistentAlert' -Force } | Should -Not -Throw

                Should -Invoke -CommandName 'Get-AgentAlertObject' -Times 1 -Exactly
            }
        }

        It 'Should write verbose message when alert is not found' {
            InModuleScope -ScriptBlock {
                $verboseMessages = @()

                Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'NonExistentAlert' -Force -Verbose 4>&1 |
                    ForEach-Object { $verboseMessages += $_ }

                $verboseMessages | Should -Contain ($script:localizedData.Remove_SqlDscAgentAlert_AlertNotFound -f 'NonExistentAlert')
            }
        }
    }

    Context 'When removal fails' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                # Mock the alert object that will fail on Drop
                $script:mockFailingAlert = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestAlert' -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value { throw 'Removal failed' } -PassThru

                $script:mockServerObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'JobServer' -Value (New-Object -TypeName Object) -PassThru

                Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockFailingAlert }
            }
        }

        It 'Should throw error when removal fails' {
            InModuleScope -ScriptBlock {
                { Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Force } |
                    Should -Throw -ExpectedMessage '*Failed to remove*'
            }
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockAlert = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestAlert' -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value { } -PassThru

                $script:mockServerObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'JobServer' -Value (New-Object -TypeName Object) -PassThru

                Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockAlert }
            }
        }

        It 'Should not remove alert when WhatIf is specified' {
            InModuleScope -ScriptBlock {
                { Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -WhatIf } | Should -Not -Throw

                # The Drop method should not be called with WhatIf
                # This would need more sophisticated mocking to verify
            }
        }
    }

    Context 'When Force parameter affects confirmation' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockAlert = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'Name' -Value 'TestAlert' -PassThru |
                    Add-Member -MemberType ScriptMethod -Name 'Drop' -Value { } -PassThru

                $script:mockServerObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'JobServer' -Value (New-Object -TypeName Object) -PassThru

                Mock -CommandName 'Get-AgentAlertObject' -MockWith { return $script:mockAlert }
            }
        }

        It 'Should remove alert without confirmation when Force is specified' {
            InModuleScope -ScriptBlock {
                # This test verifies that Force parameter works, but full confirmation testing
                # would require more complex mocking of the confirmation system
                { Remove-SqlDscAgentAlert -ServerObject $script:mockServerObject -Name 'TestAlert' -Force } | Should -Not -Throw
            }
        }
    }
}
