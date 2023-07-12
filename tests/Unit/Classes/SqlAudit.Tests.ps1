<#
    .SYNOPSIS
        Unit test for DSC_SqlAudit DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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

    Import-Module -Name $script:dscModuleName

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../TestHelpers/CommonTestHelper.psm1')

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

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

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlAudit' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { [SqlAudit]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAudit]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                $instance = [SqlAudit]::new()
                $instance.GetType().Name | Should -Be 'SqlAudit'
            }
        }
    }
}

Describe 'SqlAudit\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        Context 'When having a File audit with default values' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Path         = 'C:\Temp'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockSqlAuditInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name         = 'MockAuditName'
                                InstanceName = 'NamedInstance'
                                Path         = 'C:\Temp'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlAuditInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.Name | Should -Be 'MockAuditName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty
                    $currentState.Reasons | Should -BeNullOrEmpty

                    $currentState.Path | Should -Be 'C:\Temp'
                }
            }

            Context 'When using parameter Credential' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlAuditInstance.Credential = [System.Management.Automation.PSCredential]::new(
                            'MyCredentialUserName',
                            [SecureString]::new()
                        )

                        <#
                            This mocks the method GetCurrentState().

                            Method Get() will call the base method Get() which will
                            call back to the derived class method GetCurrentState()
                            to get the result to return from the derived method Get().
                        #>
                        $script:mockSqlAuditInstance |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                                return [System.Collections.Hashtable] @{
                                    Name         = 'MockAuditName'
                                    InstanceName = 'NamedInstance'
                                    Path         = 'C:\Temp'
                                    Credential   = $this.Credential
                                }
                            } -PassThru |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                                return
                            }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        $currentState = $script:mockSqlAuditInstance.Get()

                        $currentState.InstanceName | Should -Be 'NamedInstance'
                        $currentState.Name | Should -Be 'MockAuditName'
                        $currentState.ServerName | Should -Be (Get-ComputerName)
                        $currentState.Reasons | Should -BeNullOrEmpty

                        $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]
                        $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'

                        $currentState.Path | Should -Be 'C:\Temp'
                    }
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When property Path have the wrong value for a File audit' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Path         = 'C:\NewFolder'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockSqlAuditInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                Name         = 'MockAuditName'
                                InstanceName = 'NamedInstance'
                                Path         = 'C:\Temp'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlAuditInstance.Get()

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.Name | Should -Be 'MockAuditName'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.Path | Should -Be 'C:\Temp'

                    $currentState.Reasons | Should -HaveCount 1
                    $currentState.Reasons[0].Code | Should -Be 'SqlAudit:SqlAudit:Path'
                    $currentState.Reasons[0].Phrase | Should -Be 'The property Path should be "C:\NewFolder", but was "C:\Temp"'
                }
            }
        }
    }
}

Describe 'SqlAudit\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlAuditInstance = [SqlAudit] @{
                Name         = 'MockAuditName'
                InstanceName = 'NamedInstance'
                Path         = 'C:\Temp'
            } |
                # Mock method Modify which is called by the base method Set().
                Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                    $script:mockMethodModifyCallCount += 1
                } -PassThru
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockMethodModifyCallCount = 0
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 0
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property      = 'Path'
                            ExpectedValue = 'C:\NewFolder'
                            ActualValue   = 'C:\Path'
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'SqlAudit\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlAuditInstance = [SqlAudit] @{
                Name         = 'MockAuditName'
                InstanceName = 'NamedInstance'
                Path         = 'C:\Temp'
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance.Test() | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Name         = 'MockAuditName'
                            InstanceName = 'NamedInstance'
                            Path         = 'C:\WrongFolder'
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance.Test() | Should -BeFalse
            }
        }
    }
}

Describe 'SqlAudit\GetCurrentState()' -Tag 'GetCurrentState' {
    Context 'When audit is missing in the current state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance = [SqlAudit] @{
                    Name         = 'MockAuditName'
                    InstanceName = 'NamedInstance'
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    } -PassThru
            }

            Mock -CommandName Get-SqlDscAudit
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlAuditInstance.GetCurrentState(
                    @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                    }
                )

                $currentState.InstanceName | Should -Be 'NamedInstance'
                $currentState.ServerName | Should -Be (Get-ComputerName)
                $currentState.Force | Should -BeFalse
                $currentState.Credential | Should -BeNullOrEmpty
            }
        }

        Context 'When using property Credential' {
            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance.Credential = [System.Management.Automation.PSCredential]::new(
                        'MyCredentialUserName',
                        [SecureString]::new()
                    )

                    $currentState = $script:mockSqlAuditInstance.GetCurrentState(
                        @{
                            Name         = 'MockAuditName'
                            InstanceName = 'NamedInstance'
                        }
                    )

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Force | Should -BeFalse

                    $currentState.Credential | Should -BeOfType [System.Management.Automation.PSCredential]
                    $currentState.Credential.UserName | Should -Be 'MyCredentialUserName'
                }
            }
        }
    }

    Context 'When the audit is present in the current state' {
        Context 'When the audit is of type file' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    $mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )

                    <#
                        All file properties is set to a value in this test regardless
                        that they can not all be set at the same time in a real scenario,
                        e.g. MaximumFiles and MaximumRolloverFiles that are not allowed
                        to be set to a non-zero value at the same time.
                    #>
                    $mockAuditObject.DestinationType = 'File'
                    $mockAuditObject.FilePath = 'C:\Temp'
                    $mockAuditObject.Filter = '([server_principal_name] like ''%ADMINISTRATOR'')'
                    $mockAuditObject.MaximumFiles = 2
                    $mockAuditObject.MaximumFileSize = 2
                    $mockAuditObject.MaximumFileSizeUnit = [Microsoft.SqlServer.Management.Smo.AuditFileSizeUnit]::Mb
                    $mockAuditObject.MaximumRolloverFiles = 2
                    $mockAuditObject.OnFailure = 'Continue'
                    $mockAuditObject.QueueDelay = 1000
                    $mockAuditObject.Guid = '06962963-ddd1-4a6b-86d6-0ef8d99b8e7b'
                    $mockAuditObject.ReserveDiskSpace = $true
                    $mockAuditObject.Enabled = $true

                    return $mockAuditObject
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlAuditInstance.GetCurrentState(
                        @{
                            Name         = 'MockAuditName'
                            InstanceName = 'NamedInstance'
                        }
                    )

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Force | Should -BeFalse
                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.LogType | Should -BeNullOrEmpty
                    $currentState.Path | Should -Be 'C:\Temp'
                    $currentState.AuditFilter | Should -Be '([server_principal_name] like ''%ADMINISTRATOR'')'
                    $currentState.MaximumFiles | Should -Be 2
                    $currentState.MaximumFileSize | Should -Be 2
                    $currentState.MaximumFileSizeUnit | Should -Be 'Megabyte'
                    $currentState.MaximumRolloverFiles | Should -Be 2
                    $currentState.ReserveDiskSpace | Should -BeTrue
                    $currentState.OnFailure | Should -Be 'Continue'
                    $currentState.QueueDelay | Should -Be 1000
                    $currentState.AuditGuid | Should -Be '06962963-ddd1-4a6b-86d6-0ef8d99b8e7b'
                    $currentState.Enabled | Should -BeTrue
                }
            }
        }

        Context 'When the audit is of type log' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    $mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )

                    <#
                        All file properties is set to a value in this test regardless
                        that they can not all be set at the same time in a real scenario,
                        e.g. MaximumFiles and MaximumRolloverFiles that are not allowed
                        to be set to a non-zero value at the same time.
                    #>
                    $mockAuditObject.DestinationType = 'SecurityLog'
                    $mockAuditObject.Filter = '([server_principal_name] like ''%ADMINISTRATOR'')'
                    $mockAuditObject.OnFailure = 'Continue'
                    $mockAuditObject.QueueDelay = 1000
                    $mockAuditObject.Guid = '06962963-ddd1-4a6b-86d6-0ef8d99b8e7b'
                    $mockAuditObject.Enabled = $true

                    return $mockAuditObject
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlAuditInstance.GetCurrentState(
                        @{
                            Name         = 'MockAuditName'
                            InstanceName = 'NamedInstance'
                        }
                    )

                    $currentState.InstanceName | Should -Be 'NamedInstance'
                    $currentState.ServerName | Should -Be (Get-ComputerName)
                    $currentState.Force | Should -BeFalse
                    $currentState.Credential | Should -BeNullOrEmpty

                    $currentState.LogType | Should -Be 'SecurityLog'
                    $currentState.Path | Should -BeNullOrEmpty
                    $currentState.AuditFilter | Should -Be '([server_principal_name] like ''%ADMINISTRATOR'')'
                    $currentState.MaximumFiles | Should -Be 0
                    $currentState.MaximumFileSize | Should -Be 0
                    $currentState.MaximumFileSizeUnit | Should -BeNullOrEmpty
                    $currentState.MaximumRolloverFiles | Should -Be 0
                    $currentState.ReserveDiskSpace | Should -BeNullOrEmpty
                    $currentState.OnFailure | Should -Be 'Continue'
                    $currentState.QueueDelay | Should -Be 1000
                    $currentState.AuditGuid | Should -Be '06962963-ddd1-4a6b-86d6-0ef8d99b8e7b'
                    $currentState.Enabled | Should -BeTrue
                }
            }
        }
    }
}

Describe 'SqlAudit\Modify()' -Tag 'Modify' {
    Context 'When the system is not in the desired state' {
        Context 'When audit is present but should be absent' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Ensure       = 'Absent'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Remove-SqlDscAudit
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Ensure = 'Absent'
                            Path   = 'C:\Temp'
                        }
                    )

                    Should -Invoke -CommandName Remove-SqlDscAudit -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When audit is absent but should be present' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Path         = 'C:\Temp'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName New-SqlDscAudit -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )
                } -RemoveParameterValidation 'Path'
            }

            It 'Should call the correct mock' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Ensure = 'Present'
                            Path   = 'C:\Temp'
                        }
                    )

                    Should -Invoke -CommandName New-SqlDscAudit -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the audit should also be enabled' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlAuditInstance = [SqlAudit] @{
                            Name         = 'MockAuditName'
                            InstanceName = 'NamedInstance'
                            Path         = 'C:\Temp'
                        } |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                            }  -PassThru |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                                return
                            } -PassThru
                    }

                    Mock -CommandName Enable-SqlDscAudit
                }

                It 'Should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlAuditInstance.Modify(
                            # This is the properties not in desired state.
                            @{
                                Ensure  = 'Present'
                                Path    = 'C:\Temp'
                                Enabled = $true
                            }
                        )

                        Should -Invoke -CommandName New-SqlDscAudit -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Enable-SqlDscAudit -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the audit should also be disabled' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlAuditInstance = [SqlAudit] @{
                            Name         = 'MockAuditName'
                            InstanceName = 'NamedInstance'
                            Path         = 'C:\Temp'
                        } |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                            }  -PassThru |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                                return
                            } -PassThru
                    }

                    Mock -CommandName Disable-SqlDscAudit
                }

                It 'Should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlAuditInstance.Modify(
                            # This is the properties not in desired state.
                            @{
                                Ensure  = 'Present'
                                Path    = 'C:\Temp'
                                Enabled = $false
                            }
                        )

                        Should -Invoke -CommandName New-SqlDscAudit -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Disable-SqlDscAudit -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the neither of the parameters LogType or Path was passed' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlAuditInstance = [SqlAudit] @{
                            Name         = 'MockAuditName'
                            InstanceName = 'NamedInstance'
                        } |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                            }  -PassThru |
                            Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                                return
                            } -PassThru
                    }

                    Mock -CommandName Disable-SqlDscAudit
                }

                It 'Should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        $mockErrorMessage = Get-InvalidOperationRecord -Message $mockSqlAuditInstance.localizedData.CannotCreateNewAudit

                        {
                            $script:mockSqlAuditInstance.Modify(
                                # This is the properties not in desired state.
                                @{
                                    Ensure  = 'Present'
                                    Enabled = $false
                                }
                            )
                        } | Should -Throw -ExpectedMessage $mockErrorMessage
                    }
                }
            }
        }

        Context 'When audit should be enabled but is disabled' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Enabled      = $false
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )
                }

                Mock -CommandName Enable-SqlDscAudit
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Enabled = $true
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscAudit -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Enable-SqlDscAudit -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the audit should be disabled but is enabled' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Enabled      = $true
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )
                }

                Mock -CommandName Disable-SqlDscAudit
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Enabled = $false
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscAudit -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Disable-SqlDscAudit -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the property <MockPropertyName> is not in desired state' -ForEach @(
            @{
                MockPropertyName = 'Path'
                MockExpectedValue = 'C:\NewValue'
            }
            @{
                MockPropertyName = 'AuditFilter'
                MockExpectedValue = 'object -like ''something'''
            }
            @{
                MockPropertyName = 'MaximumFiles'
                MockExpectedValue = 2
            }
            @{
                MockPropertyName = 'MaximumRolloverFiles'
                MockExpectedValue = 2
            }
            @{
                MockPropertyName = 'OnFailure'
                MockExpectedValue = 'FailOperation'
            }
            @{
                MockPropertyName = 'QueueDelay'
                MockExpectedValue = 2000
            }
            @{
                MockPropertyName = 'AuditGuid'
                MockExpectedValue = 'cfa0d47e-bf93-41ab-bc9a-b8511acbcdd6'
            }
        ) {
            BeforeAll {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name              = 'MockAuditName'
                        InstanceName      = 'NamedInstance'
                        $MockPropertyName = $MockExpectedValue
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )
                }

                Mock -CommandName Set-SqlDscAudit -RemoveParameterValidation 'Path'
            }

            It 'Should call the correct mocks' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            $MockPropertyName = $MockExpectedValue
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscAudit -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Set-SqlDscAudit -ParameterFilter {
                        $PesterBoundParameters.$MockPropertyName -eq $MockExpectedValue
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the property MaximumFileSize is not in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name                   = 'MockAuditName'
                        InstanceName           = 'NamedInstance'
                        MaximumFileSize        = 20
                        MaximumFileSizeUnit    = 'Megabyte'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )
                }

                Mock -CommandName Set-SqlDscAudit -RemoveParameterValidation 'Path'
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            MaximumFileSize = 20
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscAudit -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Set-SqlDscAudit -ParameterFilter {
                        $MaximumFileSize -eq 20
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the property MaximumFileSizeUnit is not in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name                   = 'MockAuditName'
                        InstanceName           = 'NamedInstance'
                        MaximumFileSize        = 20
                        MaximumFileSizeUnit    = 'Megabyte'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )
                }

                Mock -CommandName Set-SqlDscAudit -RemoveParameterValidation 'Path'
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            MaximumFileSizeUnit = 'Megabyte'
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscAudit -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Set-SqlDscAudit -ParameterFilter {
                        $MaximumFileSizeUnit -eq 'Megabyte'
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the property ReservDiskSpace is not in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name             = 'MockAuditName'
                        InstanceName     = 'NamedInstance'
                        MaximumFiles     = 20
                        ReserveDiskSpace = $true
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )
                }

                Mock -CommandName Set-SqlDscAudit -RemoveParameterValidation 'Path'
            }

            It 'Should call the correct mocks' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            MaximumFileSizeUnit = 'Megabyte'
                        }
                    )

                    Should -Invoke -CommandName Get-SqlDscAudit -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Set-SqlDscAudit -ParameterFilter {
                        $ReserveDiskSpace -eq $true
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When trying to change a File audit property when audit type is of a Log-type' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name             = 'MockAuditName'
                        InstanceName     = 'NamedInstance'
                        MaximumFiles     = 20
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    $mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )

                    $mockAuditObject.DestinationType = 'SecurityLog'

                    return $mockAuditObject
                }

                Mock -CommandName Set-SqlDscAudit -RemoveParameterValidation 'Path'
            }

            It 'Should call the correct mocks' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $mockErrorMessage = Get-InvalidOperationRecord -Message (
                        $mockSqlAuditInstance.localizedData.AuditOfWrongTypeForUseWithProperty -f 'SecurityLog'
                    )

                    {
                        $script:mockSqlAuditInstance.Modify(
                            # This is the properties not in desired state.
                            @{
                                MaximumFiles = 20
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When trying to change Path but audit type is of a Log-type' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name             = 'MockAuditName'
                        InstanceName     = 'NamedInstance'
                        Path             = 'C:\Temp'
                        Force            = $true
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'CreateAudit' -Value {
                            $script:mockMethodCreateAuditCallCount += 1
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    $mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )

                    $mockAuditObject.DestinationType = 'SecurityLog'

                    return $mockAuditObject
                }

                Mock -CommandName Remove-SqlDscAudit
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockMethodCreateAuditCallCount = 0
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            Path = 'C:\Temp'
                        }
                    )

                    Should -Invoke -CommandName Remove-SqlDscAudit -Exactly -Times 1 -Scope It

                    $script:mockMethodCreateAuditCallCount | Should -Be 1
                }
            }
        }

        Context 'When trying to change LogType but audit type is a File-type' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name             = 'MockAuditName'
                        InstanceName     = 'NamedInstance'
                        LogType          = 'ApplicationLog'
                        Force            = $true
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'CreateAudit' -Value {
                            $script:mockMethodCreateAuditCallCount += 1
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    $mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )

                    $mockAuditObject.DestinationType = 'File'

                    return $mockAuditObject
                }

                Mock -CommandName Remove-SqlDscAudit
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockMethodCreateAuditCallCount = 0
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $script:mockSqlAuditInstance.Modify(
                        # This is the properties not in desired state.
                        @{
                            LogType = 'ApplicationLog'
                        }
                    )

                    Should -Invoke -CommandName Remove-SqlDscAudit -Exactly -Times 1 -Scope It

                    $script:mockMethodCreateAuditCallCount | Should -Be 1
                }
            }
        }

        Context 'When trying to change Path but audit type is of a Log-type and Force is not set to $true' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name             = 'MockAuditName'
                        InstanceName     = 'NamedInstance'
                        Path             = 'C:\Temp'
                    } |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                        }  -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'CreateAudit' -Value {
                            $script:mockMethodCreateAuditCallCount += 1
                        } -PassThru
                }

                Mock -CommandName Get-SqlDscAudit -MockWith {
                    $mockAuditObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Audit' -ArgumentList @(
                        (New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'),
                        'MockAuditName'
                    )

                    $mockAuditObject.DestinationType = 'SecurityLog'

                    return $mockAuditObject
                }

                Mock -CommandName Remove-SqlDscAudit
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockMethodCreateAuditCallCount = 0
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $mockErrorMessage = Get-InvalidOperationRecord -Message (
                        $mockSqlAuditInstance.localizedData.AuditIsWrongType
                    )

                    {
                        $script:mockSqlAuditInstance.Modify(
                            # This is the properties not in desired state.
                            @{
                                Path = 'C:\Temp'
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockErrorMessage

                    Should -Invoke -CommandName Remove-SqlDscAudit -Exactly -Times 0 -Scope It

                    $script:mockMethodCreateAuditCallCount | Should -Be 0
                }
            }
        }
    }
}

Describe 'SqlAudit\AssertProperties()' -Tag 'AssertProperties' {
    Context 'When the path does not exist' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlAuditInstance = [SqlAudit] @{
                    Name         = 'MockAuditName'
                    InstanceName = 'NamedInstance'
                    Path         = 'C:\Temp'
                }
            }

            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error for Get()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockSqlAuditInstance.localizedData.PathInvalid -f 'C:\Temp'

                $mockErrorMessage += ' (Parameter ''Path'')'

                { $script:mockSqlAuditInstance.Get() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Set()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockSqlAuditInstance.localizedData.PathInvalid -f 'C:\Temp'

                $mockErrorMessage += ' (Parameter ''Path'')'

                { $script:mockSqlAuditInstance.Set() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        It 'Should throw the correct error for Test()' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:mockSqlAuditInstance.localizedData.PathInvalid -f 'C:\Temp'

                $mockErrorMessage += ' (Parameter ''Path'')'

                { $script:mockSqlAuditInstance.Test() } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    <#
        These tests just check for the string localized ID. Since the error is part
        of a command outside of SqlServerDsc, a small changes to the localized
        string should not fail these tests.
    #>
    Context 'When passing mutually exclusive parameters' {
        Context 'When passing MaximumFiles and MaximumRolloverFiles' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Path         = 'C:\Temp'
                    }
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    {
                        $mockSqlAuditInstance.AssertProperties(
                            @{
                                MaximumFiles         = 2
                                MaximumRolloverFiles = 2
                            }
                        )
                    } | Should -Throw -ExpectedMessage '*DRC0010*'
                }
            }
        }

        Context 'When passing LogType and a File audit property' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                    }
                }
            }

            It 'Should throw the correct error for property ''<MockPropertyName>''' -ForEach @(
                @{
                    MockPropertyName = 'Path'
                }
                @{
                    MockPropertyName = 'MaximumFiles'
                }
                @{
                    MockPropertyName = 'MaximumFileSize'
                }
                @{
                    MockPropertyName = 'MaximumFileSizeUnit'
                }
                @{
                    MockPropertyName = 'MaximumRolloverFiles'
                }
                @{
                    MockPropertyName = 'ReserveDiskSpace'
                }
            ) {
                InModuleScope -Parameters $_ -ScriptBlock {
                    {
                        $mockSqlAuditInstance.AssertProperties(
                            @{
                                LogType           = 'SecurityLog'
                                $MockPropertyName = 'AnyValue'
                            }
                        )
                    } | Should -Throw -ExpectedMessage '*DRC0010*'
                }
            }
        }

        Context 'When passing just one of either MaximumFileSize and MaximumFileSizeUnit' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Path         = 'C:\Temp'
                    }
                }
            }

            It 'Should throw the correct error for property ''<MockPropertyName>''' -ForEach @(
                @{
                    MockPropertyName = 'MaximumFileSize'
                }
                @{
                    MockPropertyName = 'MaximumFileSizeUnit'
                }
            ) {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $mockErrorMessage = $script:mockSqlAuditInstance.localizedData.BothFileSizePropertiesMustBeSet

                    $mockErrorMessage += ' (Parameter ''MaximumFileSize, MaximumFileSizeUnit'')'

                    {
                        $mockSqlAuditInstance.AssertProperties(
                            @{
                                $MockPropertyName = 'AnyValue'
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When passing MaximumFileSize with a value of 1' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Path         = 'C:\Temp'
                    }
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    $mockErrorMessage = $script:mockSqlAuditInstance.localizedData.MaximumFileSizeValueInvalid

                    $mockErrorMessage += ' (Parameter ''MaximumFileSize'')'

                    {
                        $mockSqlAuditInstance.AssertProperties(
                            @{
                                MaximumFileSize     = 1
                                MaximumFileSizeUnit = 'Megabyte'
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When passing QueueDelay with an invalid value' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Path         = 'C:\Temp'
                    }
                }
            }

            It 'Should throw the correct error with value <MockQueueDelayValue>' -ForEach @(
                @{
                    MockQueueDelayValue = 1
                }
                @{
                    MockQueueDelayValue = 457
                }
                @{
                    MockQueueDelayValue = 800
                }
                @{
                    MockQueueDelayValue = 999
                }
            ) {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $mockErrorMessage = $script:mockSqlAuditInstance.localizedData.QueueDelayValueInvalid

                    $mockErrorMessage += ' (Parameter ''QueueDelay'')'

                    {
                        $mockSqlAuditInstance.AssertProperties(
                            @{
                                QueueDelay = $MockQueueDelayValue
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When passing ReserveDiskSpace without passing MaximumFiles' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlAuditInstance = [SqlAudit] @{
                        Name         = 'MockAuditName'
                        InstanceName = 'NamedInstance'
                        Path         = 'C:\Temp'
                    }
                }
            }

            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    $mockErrorMessage = $script:mockSqlAuditInstance.localizedData.BothFileSizePropertiesMustBeSet

                    $mockErrorMessage += ' (Parameter ''ReserveDiskSpace'')'

                    {
                        $mockSqlAuditInstance.AssertProperties(
                            @{
                                ReserveDiskSpace = $true
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }
    }
}
