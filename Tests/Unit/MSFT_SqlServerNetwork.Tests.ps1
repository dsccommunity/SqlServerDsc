<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlServerNetwork DSC resource.

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

$script:dscModuleName      = 'SqlServerDsc'
$script:dscResourceName    = 'MSFT_SqlServerNetwork'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
        $mockInstanceName = 'TEST'
        $mockTcpProtocolName = 'Tcp'
        $mockNamedPipesProtocolName = 'NP'
        $mockTcpDynamicPortNumber = '24680'

        $script:WasMethodAlterCalled = $false

        $mockFunction_NewObject_ManagedComputer = {
                return New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name 'ServerInstances' -Value {
                        return @{
                            $mockInstanceName = New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'ServerProtocols' -Value {
                                    return @{
                                        $mockDynamicValue_TcpProtocolName = New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $mockDynamicValue_IsEnabled -PassThru |
                                            Add-Member -MemberType ScriptProperty -Name 'IPAddresses' -Value {
                                                return @{
                                                    'IPAll' = New-Object -TypeName Object |
                                                        Add-Member -MemberType ScriptProperty -Name 'IPAddressProperties' -Value {
                                                            return @{
                                                                'TcpDynamicPorts' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_TcpDynamicPort -PassThru -Force
                                                                'TcpPort' = New-Object -TypeName Object |
                                                                    Add-Member -MemberType NoteProperty -Name 'Value' -Value $mockDynamicValue_TcpPort -PassThru -Force
                                                            }
                                                        } -PassThru -Force
                                                }
                                            } -PassThru |
                                            Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                                <#
                                                    It is not possible to verify that the correct value was set here for TcpDynamicPorts and
                                                    TcpPort with the current implementation.
                                                    If `$this.IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value` would be
                                                    called it would just return the same value over an over again, not the value that was
                                                    set in the function Set-TargetResource.
                                                    To be able to do this check for TcpDynamicPorts and TcpPort, then the class must be mocked
                                                    in SMO.cs.
                                                #>
                                                if ($this.IsEnabled -ne $mockExpectedValue_IsEnabled)
                                                {
                                                    throw ('Mock method Alter() was called with an unexpected value for IsEnabled. Expected ''{0}'', but was ''{1}''' -f $mockExpectedValue_IsEnabled, $this.IsEnabled)
                                                }

                                                # This can be used to verify so that alter method was actually called.
                                                $script:WasMethodAlterCalled = $true
                                            } -PassThru -Force
                                    }
                                } -PassThru -Force
                        }
                    } -PassThru -Force
        }

        $mockFunction_NewObject_ManagedComputer_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        }

        $mockDefaultParameters = @{
            InstanceName = $mockInstanceName
            ProtocolName = $mockTcpProtocolName
        }

        $mockConnectSQL = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Roles -Value {
                        return @{
                            $mockSqlServerRole = ( New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name Name -Value $mockSqlServerRole -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name EnumMemberNames -Value {
                                    if ($mockInvalidOperationForEnumMethod)
                                    {
                                        throw 'Mock EnumMemberNames Method was called with invalid operation.'
                                    }
                                    else
                                    {
                                        $mockEnumMemberNames
                                    }
                                } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name Drop -Value {
                                    if ($mockInvalidOperationForDropMethod)
                                    {
                                        throw 'Mock Drop Method was called with invalid operation.'
                                    }

                                    if ( $this.Name -ne $mockExpectedServerRoleToDrop )
                                    {
                                        throw "Called mocked drop() method without dropping the right server role. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedServerRoleToDrop, $this.Name
                                    }
                                } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name AddMember -Value {
                                    if ($mockInvalidOperationForAddMemberMethod)
                                    {
                                        throw 'Mock AddMember Method was called with invalid operation.'
                                    }

                                    if ( $mockSqlServerLoginToAdd -ne $mockExpectedMemberToAdd )
                                    {
                                        throw "Called mocked AddMember() method without adding the right login. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedMemberToAdd, $mockSqlServerLoginToAdd
                                    }
                                } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name DropMember -Value {
                                    if ($mockInvalidOperationForDropMemberMethod)
                                    {
                                        throw 'Mock DropMember Method was called with invalid operation.'
                                    }

                                    if ( $mockSqlServerLoginToDrop -ne $mockExpectedMemberToDrop )
                                    {
                                        throw "Called mocked DropMember() method without removing the right login. Expected '{0}'. But was '{1}'." `
                                            -f $mockExpectedMemberToDrop, $mockSqlServerLoginToDrop
                                    }
                                } -PassThru
                            )
                        }
                    } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Logins -Value {
                        return @{
                            $mockSqlServerLoginOne  = @((
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                            $mockSqlServerLoginTwo  = @((
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                            $mockSqlServerLoginTree = @((
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                            $mockSqlServerLoginFour = @((
                                    New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name LoginType -Value $mockSqlServerLoginType -PassThru
                                ))
                        }
                    } -PassThru -Force
                )
            )
        }

        Describe "MSFT_SqlServerNetwork\Get-TargetResource" -Tag 'Get'{
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Import-SQLPSModule
                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable
            }

            Context 'When Get-TargetResource is called' {
                BeforeEach {
                    $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPort = ''
                    $mockDynamicValue_TcpPort = '4509'
                }

                It 'Should return the correct values' {
                    $result = Get-TargetResource @testParameters
                    $result.IsEnabled | Should -Be $mockDynamicValue_IsEnabled
                    $result.TcpDynamicPort | Should -Be $false
                    $result.TcpPort | Should -Be $mockDynamicValue_TcpPort

                    Assert-MockCalled -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.ProtocolName | Should -Be $testParameters.ProtocolName
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerNetwork\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Import-SQLPSModule
                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPort = ''
                    $mockDynamicValue_TcpPort = '4509'
                }

                <#
                    This test does not work until support for more than one protocol
                    is added. See issue #14.
                #>
                <#
                Context 'When Protocol is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            IsEnabled = $true
                            TcpDynamicPort = $false
                            TcpPort = '4509'
                        }

                        $testParameters.ProtocolName = $mockNamedPipesProtocolName
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false
                    }
                }
                #>

                Context 'When IsEnabled is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            IsEnabled = $false
                            TcpDynamicPort = $false
                            TcpPort = '4509'
                        }
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $false
                    }
                }

                Context 'When ProtocolName is not in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            IsEnabled = $false
                            TcpDynamicPort = $false
                            TcpPort = '4509'
                        }

                        # Not supporting any other than 'TCP' yet.
                        $testParameters['ProtocolName'] = 'Unknown'
                    }

                    # Skipped since no other protocol is supported yet (issue #14).
                    It 'Should return $false' -Skip:$true {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $false
                    }
                }

                Context 'When current state is using static tcp port' {
                    Context 'When TcpDynamicPort is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                TcpDynamicPort = $true
                                IsEnabled = $false
                            }
                        }

                        It 'Should return $false' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $false
                        }
                    }

                    Context 'When TcpPort is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                TcpPort = '1433'
                                IsEnabled = $true
                            }
                        }

                        It 'Should return $false' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $false
                        }
                    }
                }

                Context 'When current state is using dynamic tcp port' {
                    BeforeEach {
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled = $true
                        $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                        $mockDynamicValue_TcpPort = ''
                    }

                    Context 'When TcpPort is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                TcpPort = '1433'
                                IsEnabled = $true
                            }
                        }

                        It 'Should return $false' {
                            $result = Test-TargetResource @testParameters
                            $result | Should -Be $false
                        }
                    }
                }

                Context 'When both TcpDynamicPort and TcpPort are being set' {
                    BeforeEach {
                        $testParameters += @{
                            TcpDynamicPort = $true
                            TcpPort = '1433'
                            IsEnabled = $false
                        }
                    }

                    It 'Should throw the correct error message' {
                        $testErrorMessage = $script:localizedData.ErrorDynamicAndStaticPortSpecified
                        { Test-TargetResource @testParameters } | Should -Throw $testErrorMessage
                    }
                }
            }

            Context 'When the system is in the desired state' {
                BeforeEach {
                    $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                    $mockDynamicValue_TcpPort = '1433'
                }

                Context 'When TcpPort is in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            TcpPort = '1433'
                            IsEnabled = $true
                        }
                    }

                    It 'Should return $true' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $true
                    }
                }

                Context 'When TcpDynamicPort is in desired state' {
                    BeforeEach {
                        $testParameters += @{
                            TcpDynamicPort = $true
                            IsEnabled = $true
                        }
                    }

                    It 'Should return $true' {
                        $result = Test-TargetResource @testParameters
                        $result | Should -Be $true
                    }
                }
            }

            Assert-VerifiableMock
        }

        Describe "MSFT_SqlServerNetwork\Set-TargetResource" -Tag 'Set'{
            BeforeEach {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Restart-SqlService -Verifiable
                Mock -CommandName Import-SQLPSModule
                Mock -CommandName New-Object `
                    -MockWith $mockFunction_NewObject_ManagedComputer `
                    -ParameterFilter $mockFunction_NewObject_ManagedComputer_ParameterFilter -Verifiable

                # This is used to evaluate if mocked Alter() method was called.
                $script:WasMethodAlterCalled = $false
            }

            Context 'When the system is not in the desired state' {
                BeforeEach {
                    # This is the values the mock will return
                    $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPort = ''
                    $mockDynamicValue_TcpPort = '4509'

                    <#
                        This is the values we expect to be set when Alter() method is called.
                        These values will set here to same as the values the mock will return,
                        but before each test the these will be set to the correct value that is
                        expected to be returned for that particular test.
                    #>
                    $mockExpectedValue_IsEnabled = $mockDynamicValue_IsEnabled
                }

                Context 'When IsEnabled is not in desired state' {
                    Context 'When IsEnabled should be $false' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $false
                                TcpDynamicPort = $false
                                TcpPort = '4509'
                                RestartService = $true
                            }

                            $mockExpectedValue_IsEnabled = $false
                        }

                        It 'Should call Set-TargetResource without throwing and should call Alter()' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw
                            $script:WasMethodAlterCalled | Should -Be $true

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When IsEnabled should be $true' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $true
                                TcpDynamicPort = $false
                                TcpPort = '4509'
                                RestartService = $true
                            }

                            $mockExpectedValue_IsEnabled = $true

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    ProtocolName   = $mockTcpProtocolName
                                    IsEnabled      = $false
                                    TcpDynamicPort = $testParameters.TcpDynamicPort
                                    TcpPort        = $testParameters.TcpPort
                                }
                            }
                        }

                        It 'Should call Set-TargetResource without throwing and should call Alter()' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw
                            $script:WasMethodAlterCalled | Should -Be $true

                            Assert-MockCalled -CommandName Restart-SqlService -ParameterFilter {
                                $SkipClusterCheck -eq $true
                            } -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When current state is using static tcp port' {
                    Context 'When TcpDynamicPort is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $true
                                TcpDynamicPort = $true
                            }
                        }

                        It 'Should call Set-TargetResource without throwing and should call Alter()' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw
                            $script:WasMethodAlterCalled | Should -Be $true

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                        }
                    }

                    Context 'When TcpPort is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $true
                                TcpDynamicPort = $false
                                TcpPort = '4508'
                            }
                        }

                        It 'Should call Set-TargetResource without throwing and should call Alter()' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw
                            $script:WasMethodAlterCalled | Should -Be $true

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context 'When current state is using dynamic tcp port ' {
                    BeforeEach {
                        # This is the values the mock will return
                        $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                        $mockDynamicValue_IsEnabled = $true
                        $mockDynamicValue_TcpDynamicPort = $mockTcpDynamicPortNumber
                        $mockDynamicValue_TcpPort = ''

                        <#
                            This is the values we expect to be set when Alter() method is called.
                            These values will set here to same as the values the mock will return,
                            but before each test the these will be set to the correct value that is
                            expected to be returned for that particular test.
                        #>
                        $mockExpectedValue_IsEnabled = $mockDynamicValue_IsEnabled
                    }

                    Context 'When TcpPort is not in desired state' {
                        BeforeEach {
                            $testParameters += @{
                                IsEnabled = $true
                                TcpDynamicPort = $false
                                TcpPort = '4508'
                            }
                        }

                        It 'Should call Set-TargetResource without throwing and should call Alter()' {
                            { Set-TargetResource @testParameters } | Should -Not -Throw
                            $script:WasMethodAlterCalled | Should -Be $true

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context 'When both TcpDynamicPort and TcpPort are being set' {
                    BeforeEach {
                        $testParameters += @{
                            TcpDynamicPort = $true
                            TcpPort = '1433'
                            IsEnabled = $false
                        }
                    }

                    It 'Should throw the correct error message' {
                        $testErrorMessage = ($script:localizedData.ErrorDynamicAndStaticPortSpecified)
                        { Set-TargetResource @testParameters } | Should -Throw $testErrorMessage
                    }
                }
            }

            Context 'When the system is in the desired state' {
                BeforeEach {
                    # This is the values the mock will return
                    $mockDynamicValue_TcpProtocolName = $mockTcpProtocolName
                    $mockDynamicValue_IsEnabled = $true
                    $mockDynamicValue_TcpDynamicPort = ''
                    $mockDynamicValue_TcpPort = '4509'

                    <#
                        We do not expect Alter() method to be called. So we set this to $null so
                        if it is, then it will throw an error.
                    #>
                    $mockExpectedValue_IsEnabled = $null

                    $testParameters += @{
                        IsEnabled = $true
                        TcpDynamicPort = $false
                        TcpPort = '4509'
                    }
                }

                It 'Should call Set-TargetResource without throwing and should not call Alter()' {
                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:WasMethodAlterCalled | Should -Be $false

                    Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'SqlServerNetwork\Export-TargetResource' {
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

            # Mocking for protocol TCP
            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $name } -MockWith {
                return @{
                    'MyAlias' = 'DBMSSOCN,sqlnode.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentTcpPort } -MockWith {
                return @{
                    'DifferentTcpPort' = 'DBMSSOCN,sqlnode.company.local,1500'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPathWow6432Node -and $Name -eq $nameDifferentServerNameTcp } -MockWith {
                return @{
                    'DifferentServerNameTcp' = 'DBMSSOCN,unknownserver.company.local,1433'
                }
            } -Verifiable

            Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $registryPath -and $Name -eq $unknownName } -MockWith {
                return $null
            } -Verifiable

            # Mocking 64-bit OS
            Mock -CommandName Get-CimInstance -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name OSArchitecture -Value '64-bit' -PassThru -Force
            } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' } -Verifiable

            Context 'Extract the existing configuration' {
                $result = Export-TargetResource


                It 'Should return content from the extraction' {
                    $result | Should -Not -Be $null
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

