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

    # Load SMO stub types
    Add-Type -Path "$PSScriptRoot/../Stubs/SMO.cs"

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    # Set the environment variable for CI to suppress SMO warnings
    $env:SqlServerDscCI = $true
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Remove the environment variable for CI
    Remove-Item -Path 'env:SqlServerDscCI' -ErrorAction 'SilentlyContinue'
}

Describe 'SqlAgentAlert' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $null = [SqlAgentAlert]::new()
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert]::new()
                $instance.GetType().Name | Should -Be 'SqlAgentAlert'
            }
        }

        It 'Should be able to set and get the Name property' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert]::new()
                $instance.Name = 'TestAlert'
                $instance.Name | Should -Be 'TestAlert'
            }
        }

        It 'Should be able to set and get the InstanceName property' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert]::new()
                $instance.InstanceName = 'MSSQLSERVER'
                $instance.InstanceName | Should -Be 'MSSQLSERVER'
            }
        }

        It 'Should be able to set and get the ServerName property' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert]::new()
                $instance.ServerName = 'TestServer'
                $instance.ServerName | Should -Be 'TestServer'
            }
        }

        It 'Should be able to set and get the Ensure property' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert]::new()
                $instance.Ensure = 'Present'
                $instance.Ensure | Should -Be 'Present'
            }
        }

        It 'Should be able to set and get the Severity property' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert]::new()
                $instance.Severity = 16
                $instance.Severity | Should -Be 16
            }
        }

        It 'Should be able to set and get the MessageId property' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert]::new()
                $instance.MessageId = 50001
                $instance.MessageId | Should -Be 50001
            }
        }
    }
}

Describe 'SqlAgentAlert\Get()' -Tag 'Get' {
    Context 'When the alert exists' {
        BeforeAll {
            Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                return [PSCustomObject] @{
                    Name     = 'TestAlert'
                    Severity = 16
                }
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Severity     = 17
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return [Microsoft.SqlServer.Management.Smo.Server]::new()
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Assert' -Value {
                        return
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Normalize' -Value {
                        return
                    } -PassThru
            }
        }

        It 'Should return current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = $script:mockInstance.Get()

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestAlert'
                $result.Ensure | Should -Be 'Present'
                $result.Severity | Should -Be 16
            }
        }
    }


    Context 'When the alert does not exist' {
        BeforeAll {
            Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                return $null
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Severity     = 17
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return [Microsoft.SqlServer.Management.Smo.Server]::new()
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Assert' -Value {
                        return
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Normalize' -Value {
                        return
                    } -PassThru
            }
        }

        It 'Should return absent state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = $script:mockInstance.Get()

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestAlert'
                $result.Ensure | Should -Be 'Absent'
            }
        }
    }

    Context 'When alert exists with MessageId' {
        BeforeAll {
            Mock -CommandName 'Get-SqlDscAgentAlert' -MockWith {
                return [PSCustomObject] @{
                    Name      = 'TestAlert'
                    Severity  = 0
                    MessageId = 50001
                }
            }

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    MessageId    = 50002
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return [Microsoft.SqlServer.Management.Smo.Server]::new()
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Assert' -Value {
                        return
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Normalize' -Value {
                        return
                    } -PassThru
            }
        }

        It 'Should return current state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = $script:mockInstance.Get()

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'TestAlert'
                $result.Ensure | Should -Be 'Present'
                $result.MessageId | Should -Be 50001
                $result.Severity | Should -BeNullOrEmpty
            }
        }
    }
}

Describe 'SqlAgentAlert\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockInstance = [SqlAgentAlert] @{
                Name         = 'TestAlert'
                InstanceName = 'MSSQLSERVER'
                Ensure       = 'Present'
                Severity     = 16
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockMethodGetCallCount = 0
        }
    }

    Context 'When alert exists and is in desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Get() which is called by the base method Test()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Get' -Value {
                        $script:mockMethodGetCallCount += 1
                    }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Test() | Should -BeTrue

                $script:mockMethodGetCallCount | Should -Be 1
            }
        }
    }

    Context 'When alert does not exist but should be present' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance |
                    # Mock method Get() which is called by the base method Test()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Get' -Value {
                        $script:mockMethodGetCallCount += 1
                    }

                $script:mockInstance.PropertiesNotInDesiredState = @(
                    @{
                        Property      = 'Ensure'
                        ExpectedValue = 'Present'
                        ActualValue   = 'Absent'
                    }
                )
            }
        }

        It 'Should return false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance.Test() | Should -BeFalse

                $script:mockMethodGetCallCount | Should -Be 1
            }
        }
    }
}

Describe 'SqlAgentAlert\Set()' -Tag 'Set' {
    BeforeEach {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:methodTestCallCount = 0
            $script:methodModifyCallCount = 0
        }
    }

    Context 'When it does not exist and Ensure is Present' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    Severity     = 16
                } |
                    # Mock method Modify which is called by the case method Set().
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                        $script:methodModifyCallCount += 1
                    } -PassThru |
                    # Mock method Test() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Test' -Value {
                        $script:methodTestCallCount += 1
                        return $false
                    } -PassThru
            }
        }

        It 'Should create alert' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $null = $mockInstance.Set()

                $script:methodModifyCallCount | Should -Be 1
                $script:methodTestCallCount | Should -Be 1
            }
        }

        It 'Should create alert with MessageId' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    MessageId    = 50001
                } |
                    # Mock method Modify which is called by the case method Set().
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                        $script:methodModifyCallCount += 1
                    } -PassThru |
                    # Mock method Test() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Test' -Value {
                        $script:methodTestCallCount += 1
                        return $false
                    } -PassThru

                $null = $mockInstance.Set()

                $script:methodModifyCallCount | Should -Be 1
                $script:methodTestCallCount | Should -Be 1
            }
        }
    }

    Context 'When it exists and Ensure is Absent' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockInstance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Absent'
                } |
                    # Mock method Modify which is called by the case method Set().
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                        $script:methodModifyCallCount += 1
                    } -PassThru |
                    # Mock method Test() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Test' -Value {
                        $script:methodTestCallCount += 1
                        return $false
                    } -PassThru
            }
        }

        It 'Should remove alert' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $null = $script:mockInstance.Set()

                $script:methodModifyCallCount | Should -Be 1
                $script:methodTestCallCount | Should -Be 1
            }
        }
    }
}

Describe 'SqlAgentAlert\Modify()' -Tag 'Modify' {
    BeforeAll {
        Mock -CommandName New-SqlDscAgentAlert
        Mock -CommandName Remove-SqlDscAgentAlert
        Mock -CommandName Set-SqlDscAgentAlert
    }


    Context 'When Ensure is Present and alert does not exist' {
        BeforeAll {
            Mock -CommandName Get-SqlDscAgentAlert
        }

        It 'Should create alert with Severity' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    Severity     = 16
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return [Microsoft.SqlServer.Management.Smo.Server]::new()
                    } -PassThru

                $properties = @{
                    Severity = 16
                }

                $null = $instance.Modify($properties)
            }

            Should -Invoke -CommandName Get-SqlDscAgentAlert -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-SqlDscAgentAlert -ParameterFilter {
                $Severity -eq 16
            } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-SqlDscAgentAlert -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Remove-SqlDscAgentAlert -Exactly -Times 0 -Scope It
        }

        It 'Should create alert with MessageId' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    MessageId    = 50001
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return [Microsoft.SqlServer.Management.Smo.Server]::new()
                    } -PassThru

                $properties = @{
                    MessageId = 50001
                }

                $null = $instance.Modify($properties)
            }

            Should -Invoke -CommandName Get-SqlDscAgentAlert -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-SqlDscAgentAlert -ParameterFilter {
                $MessageId -eq 50001
            } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-SqlDscAgentAlert -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Remove-SqlDscAgentAlert -Exactly -Times 0 -Scope It
        }
    }

    Context 'When Ensure is Present and alert exists' {
        BeforeAll {
            Mock -CommandName Get-SqlDscAgentAlert -MockWith {
                [PSCustomObject] @{
                    Name      = 'TestAlert'
                    Severity  = 10
                    MessageId = 0
                }
            }
        }

        It 'Should update alert when Severity property differs' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    Severity     = 16
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return [Microsoft.SqlServer.Management.Smo.Server]::new()
                    } -PassThru

                $properties = @{
                    Severity = 16
                }

                $null = $instance.Modify($properties)
            }

            Should -Invoke -CommandName Get-SqlDscAgentAlert -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-SqlDscAgentAlert -ParameterFilter {
                $AlertObject.Name -eq 'TestAlert' -and
                $Severity -eq 16
            } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-SqlDscAgentAlert -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Remove-SqlDscAgentAlert -Exactly -Times 0 -Scope It
        }

        It 'Should update alert when MessageId property differs' {
            Mock -CommandName Get-SqlDscAgentAlert -MockWith {
                [PSCustomObject] @{
                    Name      = 'TestAlert'
                    Severity  = 0
                    MessageId = 50001
                }
            }

            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    MessageId    = 50002
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return [Microsoft.SqlServer.Management.Smo.Server]::new()
                    } -PassThru

                $properties = @{
                    MessageId = 50002
                }

                $null = $instance.Modify($properties)
            }

            Should -Invoke -CommandName Get-SqlDscAgentAlert -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-SqlDscAgentAlert -ParameterFilter {
                $AlertObject.Name -eq 'TestAlert' -and
                $MessageId -eq 50002
            } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-SqlDscAgentAlert -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Remove-SqlDscAgentAlert -Exactly -Times 0 -Scope It
        }

        It 'Should not update alert when no properties differ' {
            Mock -CommandName Get-SqlDscAgentAlert -MockWith {
                [PSCustomObject] @{
                    Name      = 'TestAlert'
                    Severity  = 16
                    MessageId = 0
                }
            }

            InModuleScope -ScriptBlock {
                $instance = [SqlAgentAlert] @{
                    Name         = 'TestAlert'
                    InstanceName = 'MSSQLSERVER'
                    Ensure       = 'Present'
                    Severity     = 16
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return [Microsoft.SqlServer.Management.Smo.Server]::new()
                    } -PassThru

                $properties = @{
                    Severity = 16
                }

                $null = $instance.Modify($properties)
            }

            Should -Invoke -CommandName Get-SqlDscAgentAlert -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Set-SqlDscAgentAlert -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName New-SqlDscAgentAlert -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Remove-SqlDscAgentAlert -Exactly -Times 0 -Scope It
        }
    }
}

Describe 'SqlAgentAlert\AssertProperties()' -Tag 'AssertProperties' {
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
                        Name      = 'TestAlert'
                        Ensure    = 'Present'
                        Severity  = 16
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
                        Name   = 'TestAlert'
                        Ensure = 'Present'
                    }

                    { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*(DRC0052)*'
                }
            }

            It 'Should not throw when only Severity is specified' {
                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name     = 'TestAlert'
                        Ensure   = 'Present'
                        Severity = 16
                    }

                    $null = $script:mockSqlAgentAlertInstance.AssertProperties($properties)
                }
            }

            It 'Should not throw when only MessageId is specified' {
                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name      = 'TestAlert'
                        Ensure    = 'Present'
                        MessageId = 50001
                    }

                    $null = $script:mockSqlAgentAlertInstance.AssertProperties($properties)
                }
            }
        }

        Context 'When Ensure is Absent' {
            It 'Should not throw when only Name and Ensure are specified' {
                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name   = 'TestAlert'
                        Ensure = 'Absent'
                    }

                    $null = $script:mockSqlAgentAlertInstance.AssertProperties($properties)
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
                        Name     = 'TestAlert'
                        Ensure   = 'Absent'
                        Severity = 16
                    }

                    { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*(DRC0053)*'
                }
            }

            It 'Should throw the correct error when MessageId is specified' {
                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name      = 'TestAlert'
                        Ensure    = 'Absent'
                        MessageId = 50001
                    }

                    { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw -ExpectedMessage '*(DRC0053)*'
                }
            }

            It 'Should throw the correct error when both Severity and MessageId are specified' {
                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name      = 'TestAlert'
                        Ensure    = 'Absent'
                        Severity  = 16
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
            BeforeAll {
                Mock -CommandName 'Assert-BoundParameter'
            }

            It 'Should call Assert-BoundParameter to validate at least one of Severity or MessageId is specified' {
                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name     = 'TestAlert'
                        Ensure   = 'Present'
                        Severity = 16
                    }

                    $null = $script:mockSqlAgentAlertInstance.AssertProperties($properties)
                }

                Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                    $BoundParameterList -is [hashtable] -and
                    $AtLeastOneList -contains 'Severity' -and
                    $AtLeastOneList -contains 'MessageId' -and
                    $IfEqualParameterList.Ensure -eq 'Present'
                } -Exactly -Times 1 -Scope It
            }

            It 'Should call Assert-BoundParameter to validate Severity and MessageId are mutually exclusive' {
                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name     = 'TestAlert'
                        Ensure   = 'Present'
                        Severity = 16
                    }

                    $null = $script:mockSqlAgentAlertInstance.AssertProperties($properties)
                }

                Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                    $BoundParameterList -is [hashtable] -and
                    $MutuallyExclusiveList1 -contains 'Severity' -and
                    $MutuallyExclusiveList2 -contains 'MessageId' -and
                    $IfEqualParameterList.Ensure -eq 'Present'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Ensure is Absent' {
            It 'Should call Assert-BoundParameter to validate Severity and MessageId are not allowed' {
                Mock -CommandName 'Assert-BoundParameter'

                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name   = 'TestAlert'
                        Ensure = 'Absent'
                    }

                    $null = $script:mockSqlAgentAlertInstance.AssertProperties($properties)
                }

                Should -Invoke -CommandName 'Assert-BoundParameter' -ParameterFilter {
                    $BoundParameterList -is [hashtable] -and
                    $NotAllowedList -contains 'Severity' -and
                    $NotAllowedList -contains 'MessageId' -and
                    $IfEqualParameterList.Ensure -eq 'Absent'
                } -Exactly -Times 1 -Scope It
            }

            It 'Should call Assert-BoundParameter with correct parameters when Severity is specified' {
                Mock -CommandName 'Assert-BoundParameter' -MockWith {
                    # Simulate the Assert-BoundParameter throwing an exception for NotAllowed parameters
                    if ($NotAllowedList -and ($BoundParameterList.ContainsKey('Severity') -or $BoundParameterList.ContainsKey('MessageId')))
                    {
                        throw 'Parameter validation failed'
                    }
                }

                InModuleScope -ScriptBlock {
                    $properties = @{
                        Name     = 'TestAlert'
                        Ensure   = 'Absent'
                        Severity = 16
                    }

                    { $script:mockSqlAgentAlertInstance.AssertProperties($properties) } | Should -Throw
                }

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
