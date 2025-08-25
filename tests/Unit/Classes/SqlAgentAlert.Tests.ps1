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

    # Load SMO stub types
    Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    # Set the environment variable for CI to suppress SMO warnings
    $env:SqlServerDscCI = $true
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Remove the environment variable for CI
    Remove-Item -Path 'env:SqlServerDscCI' -ErrorAction 'SilentlyContinue'

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'SqlAgentAlert' -Tag 'SqlAgentAlert' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { [SqlAgentAlert]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()
                $instance.GetType().Name | Should -Be 'SqlAgentAlert'
            }
        }
    }

    Context 'When setting and getting properties' {
        It 'Should be able to set and get the Name property' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()
                $instance.Name = 'TestAlert'
                $instance.Name | Should -Be 'TestAlert'
            }
        }

        It 'Should be able to set and get the InstanceName property' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()
                $instance.InstanceName = 'MSSQLSERVER'
                $instance.InstanceName | Should -Be 'MSSQLSERVER'
            }
        }

        It 'Should be able to set and get the ServerName property' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()
                $instance.ServerName = 'TestServer'
                $instance.ServerName | Should -Be 'TestServer'
            }
        }

        It 'Should be able to set and get the Ensure property' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()
                $instance.Ensure = 'Present'
                $instance.Ensure | Should -Be 'Present'
            }
        }

        It 'Should be able to set and get the Severity property' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()
                $instance.Severity = 16
                $instance.Severity | Should -Be 16
            }
        }

        It 'Should be able to set and get the MessageId property' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()
                $instance.MessageId = 50001
                $instance.MessageId | Should -Be 50001
            }
        }
    }

    Context 'When testing Get() method' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                $script:mockAlertObject = New-Object -TypeName 'PSCustomObject'
                $script:mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlert'
                $script:mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value 16
                # MessageId is not set when using Severity-based alerts
            }
        }

        It 'Should return current state when alert exists' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                    return $script:mockAlertObject
                }

                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return $script:mockServerObject
                    } -PassThru

                $result = $instance.Get()

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestAlert'
                $result.Ensure | Should -Be 'Present'
                $result.Severity | Should -Be 16
            }
        }

        It 'Should return absent state when alert does not exist' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                    return $null
                }

                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return $script:mockServerObject
                    } -PassThru

                $result = $instance.Get()

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestAlert'
                $result.Ensure | Should -Be 'Absent'
            }
        }
    }

    Context 'When testing Test() method' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }
        }

        It 'Should return true when alert exists and is in desired state' {
            InModuleScope -ScriptBlock {
                $script:mockAlertObject = New-Object -TypeName 'PSCustomObject'
                $script:mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlert'
                $script:mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value 16
                $script:mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'MessageId' -Value 0

                Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                    return $script:mockAlertObject
                }

                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    Severity     = 16
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return $script:mockServerObject
                    } -PassThru

                $result = $instance.Test()

                $result | Should -BeTrue
            }
        }

        It 'Should return false when alert does not exist but should be present' {
            InModuleScope -ScriptBlock {
                Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                    return $null
                }

                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    Severity     = 16
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return $script:mockServerObject
                    } -PassThru

                $result = $instance.Test()

                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing Set() method' {
        Context 'when it does not exist and Ensure is Present' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName 'Get-SqlDscAgentAlert'
                Mock -CommandName 'New-SqlDscAgentAlert'
                Mock -CommandName 'Remove-SqlDscAgentAlert'
            }

            It 'Should create alert' {
                InModuleScope -ScriptBlock {
                    $instance = [SqlAgentAlert] @{
                        Name         = 'TestAlert'
                        InstanceName = 'MSSQLSERVER'
                        Ensure       = 'Present'
                        Severity     = 16
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return $script:mockServerObject
                        } -PassThru

                    { $instance.Set() } | Should -Not -Throw

                    Should -Invoke -CommandName 'New-SqlDscAgentAlert' -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName 'Remove-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When it exists and Ensure is Absent' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                }

                Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                    $mockAlertObject = New-Object -TypeName 'PSCustomObject'
                    $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlert'
                    $mockAlertObject | Add-Member -MemberType 'ScriptMethod' -Name 'Drop' -Value { }

                    return $mockAlertObject
                }

                Mock -CommandName 'New-SqlDscAgentAlert'
                Mock -CommandName 'Remove-SqlDscAgentAlert'
            }

            It 'Should remove alert' {
                InModuleScope -ScriptBlock {
                    $instance = [SqlAgentAlert] @{
                        Name         = 'TestAlert'
                        InstanceName = 'MSSQLSERVER'
                        Ensure       = 'Absent'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return $script:mockServerObject
                        } -PassThru

                    { $instance.Set() } | Should -Not -Throw

                    Should -Invoke -CommandName 'New-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName 'Remove-SqlDscAgentAlert' -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When testing AssertProperties() method' {
        It 'Should throw an error when both Severity and MessageId are specified' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()

                $properties = @{
                    Name = 'TestAlert'
                    Ensure = 'Present'
                    Severity = 16
                    MessageId = 50001
                }

                { $instance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*may be used at the same time*'
            }
        }

        It 'Should not throw when neither Severity nor MessageId are specified' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()

                $properties = @{
                    Name = 'TestAlert'
                    Ensure = 'Present'
                }

                { $instance.AssertProperties($properties) } | Should -Not -Throw
            }
        }

        It 'Should not throw when only Severity is specified' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()

                $properties = @{
                    Name = 'TestAlert'
                    Ensure = 'Present'
                    Severity = 16
                }

                { $instance.AssertProperties($properties) } | Should -Not -Throw
            }
        }

        It 'Should not throw when only MessageId is specified' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()

                $properties = @{
                    Name = 'TestAlert'
                    Ensure = 'Present'
                    MessageId = 50001
                }

                { $instance.AssertProperties($properties) } | Should -Not -Throw
            }
        }

        It 'Should not throw when Ensure is Absent' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert]::new()

                $properties = @{
                    Name = 'TestAlert'
                    Ensure = 'Absent'
                }

                { $instance.AssertProperties($properties) } | Should -Not -Throw
            }
        }
    }
}
