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
    Context 'When using the constructor' {
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

    Context 'When using the Get() method' {
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
                    Severity     = 17
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
                    Severity     = 17
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

    Context 'When using the Test() method' {
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

    Context 'When using the Set() method' {
        Context 'When it does not exist and Ensure is Present' {
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

    Context 'When using the hidden Modify() method' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }

            Mock -CommandName 'New-SqlDscAgentAlert'
            Mock -CommandName 'Remove-SqlDscAgentAlert'
            Mock -CommandName 'Set-SqlDscAgentAlert'
        }

        Context 'When Ensure is Present and alert exists' {
            It 'Should update alert when Severity property differs' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                        $mockAlertObject = New-Object -TypeName 'PSCustomObject'
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlert'
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value 10
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'MessageId' -Value 0

                        return $mockAlertObject
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

                    $properties = @{
                        Severity = 16
                    }

                    { $instance.Modify($properties) } | Should -Not -Throw

                    Should -Invoke -CommandName 'Get-SqlDscAgentAlert' -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName 'Set-SqlDscAgentAlert' -ParameterFilter {
                        $AlertObject.Name -eq 'TestAlert' -and
                        $Severity -eq 16
                    } -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName 'New-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName 'Remove-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                }
            }

            It 'Should update alert when MessageId property differs' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                        $mockAlertObject = New-Object -TypeName 'PSCustomObject'
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlert'
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value 0
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'MessageId' -Value 50001

                        return $mockAlertObject
                    }

                    $instance = [SqlAgentAlert] @{
                        Name         = 'TestAlert'
                        InstanceName = 'MSSQLSERVER'
                        Ensure       = 'Present'
                        MessageId    = 50002
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return $script:mockServerObject
                        } -PassThru

                    $properties = @{
                        MessageId = 50002
                    }

                    { $instance.Modify($properties) } | Should -Not -Throw

                    Should -Invoke -CommandName 'Get-SqlDscAgentAlert' -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName 'Set-SqlDscAgentAlert' -ParameterFilter {
                        $AlertObject.Name -eq 'TestAlert' -and
                        $MessageId -eq 50002
                    } -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName 'New-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName 'Remove-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                }
            }

            It 'Should not update alert when no properties differ' {
                InModuleScope -ScriptBlock {
                    Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                        $mockAlertObject = New-Object -TypeName 'PSCustomObject'
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestAlert'
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'Severity' -Value 16
                        $mockAlertObject | Add-Member -MemberType 'NoteProperty' -Name 'MessageId' -Value 0

                        return $mockAlertObject
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

                    $properties = @{
                        Severity = 16
                    }

                    { $instance.Modify($properties) } | Should -Not -Throw

                    Should -Invoke -CommandName 'Get-SqlDscAgentAlert' -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName 'Set-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName 'New-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                    Should -Invoke -CommandName 'Remove-SqlDscAgentAlert' -Exactly -Times 0 -Scope It
                }
            }
        }
    }

    Context 'When using the hidden AssertProperties() method' {
        Context 'When passing mutually exclusive parameters' {
            Context 'When passing both Severity and MessageId' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlAgentAlertInstance = [SqlAgentAlert]::new()
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Present'
                            Severity = 16
                            MessageId = 50001
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*may be used at the same time*'
                    }
                }
            }
        }

        Context 'When passing valid parameter combinations' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAgentAlertInstance = [SqlAgentAlert]::new()
                }
            }

            Context 'When Ensure is Present' {
                It 'Should throw when neither Severity nor MessageId are specified' {
                    InModuleScope -ScriptBlock {
                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Present'
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*(DRC0052)*'
                    }
                }

                It 'Should not throw when only Severity is specified' {
                    InModuleScope -ScriptBlock {
                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Present'
                            Severity = 16
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Not -Throw
                    }
                }

                It 'Should not throw when only MessageId is specified' {
                    InModuleScope -ScriptBlock {
                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Present'
                            MessageId = 50001
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Not -Throw
                    }
                }
            }

            Context 'When Ensure is Absent' {
                It 'Should not throw when only Name and Ensure are specified' {
                    InModuleScope -ScriptBlock {
                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Absent'
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Not -Throw
                    }
                }
            }
        }

        Context 'When passing invalid parameter combinations' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAgentAlertInstance = [SqlAgentAlert]::new()
                }
            }

            Context 'When Ensure is Absent and Severity or MessageId are specified' {
                It 'Should throw the correct error when Severity is specified' {
                    InModuleScope -ScriptBlock {
                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Absent'
                            Severity = 16
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*(DRC0053)*'
                    }
                }

                It 'Should throw the correct error when MessageId is specified' {
                    InModuleScope -ScriptBlock {
                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Absent'
                            MessageId = 50001
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*(DRC0053)*'
                    }
                }

                It 'Should throw the correct error when both Severity and MessageId are specified' {
                    InModuleScope -ScriptBlock {
                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Absent'
                            Severity = 16
                            MessageId = 50001
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*(DRC0053)*'
                    }
                }
            }
        }

        Context 'When validating Assert-BoundParameter calls' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAgentAlertInstance = [SqlAgentAlert]::new()
                }
            }

            Context 'When Ensure is Present' {
                It 'Should call Assert-BoundParameter to validate at least one of Severity or MessageId is specified' {
                    InModuleScope -ScriptBlock {
                        Mock -CommandName 'Assert-BoundParameter' -MockWith { }

                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Present'
                            Severity = 16
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Not -Throw

                        Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                            $BoundParameterList -is [hashtable] -and
                            $AtLeastOneList -contains 'Severity' -and
                            $AtLeastOneList -contains 'MessageId' -and
                            $IfEqualParameterList.Ensure -eq 'Present'
                        } -Exactly -Times 1 -Scope It
                    }
                }

                It 'Should call Assert-BoundParameter to validate Severity and MessageId are mutually exclusive' {
                    InModuleScope -ScriptBlock {
                        Mock -CommandName 'Assert-BoundParameter' -MockWith { }

                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Present'
                            Severity = 16
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Not -Throw

                        Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                            $BoundParameterList -is [hashtable] -and
                            $MutuallyExclusiveList1 -contains 'Severity' -and
                            $MutuallyExclusiveList2 -contains 'MessageId' -and
                            $IfEqualParameterList.Ensure -eq 'Present'
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When Ensure is Absent' {
                It 'Should call Assert-BoundParameter to validate Severity and MessageId are not allowed' {
                    InModuleScope -ScriptBlock {
                        Mock -CommandName 'Assert-BoundParameter' -MockWith { }

                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Absent'
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Not -Throw

                        Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                            $BoundParameterList -is [hashtable] -and
                            $NotAllowedList -contains 'Severity' -and
                            $NotAllowedList -contains 'MessageId' -and
                            $IfEqualParameterList.Ensure -eq 'Absent'
                        } -Exactly -Times 1 -Scope It
                    }
                }

                It 'Should call Assert-BoundParameter with correct parameters when Severity is specified' {
                    InModuleScope -ScriptBlock {
                        Mock -CommandName 'Assert-BoundParameter' -MockWith {
                            # Simulate the Assert-BoundParameter throwing an exception for NotAllowed parameters
                            if ($NotAllowedList -and ($BoundParameterList.ContainsKey('Severity') -or $BoundParameterList.ContainsKey('MessageId'))) {
                                throw 'Parameter validation failed'
                            }
                        }

                        $properties = @{
                            Name = 'TestAlert'
                            Ensure = 'Absent'
                            Severity = 16
                        }

                        { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw

                        Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                            $BoundParameterList -is [hashtable] -and
                            $NotAllowedList -contains 'Severity' -and
                            $NotAllowedList -contains 'MessageId' -and
                            $IfEqualParameterList.Ensure -eq 'Absent'
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }
}
