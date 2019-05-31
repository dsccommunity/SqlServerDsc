<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlAgentAlert DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlAgentAlert'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
    # Loading mocked classes
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'MSSQLSERVER'
        $mockSqlAgentAlertSevName = 'TestAlertSev'
        $mockSqlAgentAlertSeverity = '17'
        $mockSqlAgentAlertMsgName = 'TestAlertMsg'
        $mockSqlAgentAlertMessageId = '825'
        $mockInvalidOperationForCreateMethod = $false
        $mockInvalidOperationForDropMethod = $false
        $mockInvalidOperationForAlterMethod = $false
        $mockExpectedSqlAgentAlertToCreate = 'Sev16'
        $mockExpectedSqlAgentAlertToDrop = 'Sev18'

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
        }

        #region Function mocks
        $mockConnectSQL = {
            return @(
                (
                New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
                    Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
                    Add-Member -MemberType ScriptProperty -Name JobServer -Value {
                        return (New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name Name -Value $mockServerName -PassThru |
                            Add-Member -MemberType ScriptProperty -Name Alerts -Value {
                                return ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.Alert |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlAgentAlertSevName -PassThru -Force |
                                    Add-Member -MemberType NoteProperty -Name Severity -Value $mockSqlAgentAlertSeverity -PassThru -Force |
                                    Add-Member -MemberType NoteProperty -Name MessageId -Value 0 -PassThru -Force |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                        if ($mockInvalidOperationForDropMethod)
                                        {
                                            throw 'Mock Drop Method was called with invalid operation.'
                                        }
                                        if ( $this.Name -ne $mockExpectedSqlAgentAlertToDrop )
                                        {
                                            throw "Called mocked Drop() method without dropping the right sql agent alert. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedSqlAgentAlertToDrop, $this.Name
                                        }
                                    } -PassThru -Force |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                        if ($mockInvalidOperationForAlterMethod)
                                        {
                                            throw 'Mock Alter Method was called with invalid operation.'
                                        }
                                    } -PassThru -Force
                                ),
                                ( New-Object -TypeName Microsoft.SqlServer.Management.Smo.Agent.Alert |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlAgentAlertMsgName -PassThru -Force |
                                    Add-Member -MemberType NoteProperty -Name Severity -Value 0 -PassThru -Force |
                                    Add-Member -MemberType NoteProperty -Name MessageId -Value $mockSqlAgentAlertMessageId -PassThru -Force |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                        if ($mockInvalidOperationForDropMethod)
                                        {
                                            throw 'Mock Drop Method was called with invalid operation.'
                                        }
                                        if ( $this.Name -ne $mockExpectedSqlAgentAlertToDrop )
                                        {
                                            throw "Called mocked Drop() method without dropping the right sql agent alert. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedSqlAgentAlertToDrop, $this.Name
                                        }
                                    } -PassThru -Force |
                                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                                        if ($mockInvalidOperationForAlterMethod)
                                        {
                                            throw 'Mock Alter Method was called with invalid operation.'
                                        }
                                    } -PassThru -Force
                                )
                            } -PassThru
                        )
                    } -PassThru -Force
                )
            )
        }

        $mockNewSqlAgentAlert  = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlAgentAlertSevName -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Create -Value {
                            if ($mockInvalidOperationForCreateMethod)
                            {
                                throw 'Mock Create Method was called with invalid operation.'
                            }

                            if ( $this.Name -ne $mockExpectedSqlAgentAlertToCreate )
                            {
                                throw "Called mocked Create() method without adding the right sql agent alert. Expected '{0}'. But was '{1}'." `
                                    -f $mockExpectedSqlAgentAlertToCreate, $this.Name
                            }
                        } -PassThru -Force
                )
            )
        }
        #endregion

        Describe "MSFT_SqlAgentAlert\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewSqlAgentAlert -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                } -Verifiable
            }

            Context 'When the system is not in the desired state' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name         = 'MissingAlert'
                }

                It 'Should return the state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 4 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }

            Context 'When the system is in the desired state for a sql agent alert' {

                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name         = 'TestAlertSev'
                }

                It 'Should return the state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.Name | Should -Be $testParameters.Name
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 2 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 4 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlAgentAlert\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewSqlAgentAlert -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                } -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should return the state as false when desired sql agent alert does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name         = 'MissingAlert'
                        Severity     = '25'
                        Ensure       = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should return the state as false when desired sql agent alert exists but has the incorrect severity' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name            = 'TestAlertSev'
                        Ensure          = 'Present'
                        Severity        = '25'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should return the state as false when desired sql agent alert exists but has the incorrect message id' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name            = 'TestAlertSev'
                        Ensure          = 'Present'
                        MessageId       = '825'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 3 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 6 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should return the state as false when non-desired sql agent alert exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'TestAlertSev'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Present' {
                It 'Should return the state as true when desired sql agent alert exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'TestAlertSev'
                        Ensure    = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should return the state as true when desired sql agent alert exists and has the correct severity' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name            = 'TestAlertSev'
                        Ensure          = 'Present'
                        Severity        = '17'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should return the state as true when desired sql agent alert exists and has the correct message id' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name            = 'TestAlertMsg'
                        Ensure          = 'Present'
                        MessageId       = '825'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 3 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 6 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }

            Context 'When the system is in the desired state and Ensure is set to Absent' {
                It 'Should return the state as true when desired sql agent alert does not exist' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'MissingAlert'
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should -Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlAgentAlert\Set-TargetResource" -Tag 'Set' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewSqlAgentAlert -ParameterFilter {
                    $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                } -Verifiable
            }

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should not throw when creating the sql agent alert' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'TestAlertSev'
                        Ensure = 'Present'
                    }
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should not throw when changing the severity' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name      = 'TestAlertSev'
                        Ensure    = 'Present'
                        Severity  = '17'
                    }
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should not throw when changing the message id' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name       = 'TestAlertMsg'
                        Ensure     = 'Present'
                        MessageId  = '825'
                    }
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 3 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 6 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to Absent' {
                It 'Should not throw when dropping the sql agent alert' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'Sev16'
                        Ensure = 'Absent'
                    }
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }

            $mockInvalidOperationForCreateMethod = $true
            $mockInvalidOperationForAlterMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Present' {
                It 'Should throw the correct error when Create() method was called with invalid operation' {
                    $testParameters = $mockDefaultParameters
                    $testParameters += @{
                        Name   = 'NewAlert'
                        Ensure = 'Present'
                    }
                    $errorMessage = ($script:localizedData.CreateAlertSetError -f $testParameters.Name, $testParameters.ServerName, $testParameters.InstanceName)
                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 3 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }
            $mockInvalidOperationForDropMethod = $true

            Context 'When the system is not in the desired state and Ensure is set to Absent' {

                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Name      = 'TestAlertSev'
                    Ensure    = 'Absent'
                }

                $errorMessage = ($script:localizedData.DropAlertSetError -f $testParameters.Name, $testParameters.ServerName, $testParameters.InstanceName)

                It 'Should throw the correct error when Drop() method was called with invalid operation' {
                    { Set-TargetResource @testParameters } | Should -Throw $errorMessage
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function New-Object with TypeName equal to Microsoft.SqlServer.Management.Smo.Agent.Alert' {
                    Assert-MockCalled -CommandName New-Object -Exactly -Times 2 -ParameterFilter {
                        $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Agent.Alert'
                    } -Scope Context
                }
            }
            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}
