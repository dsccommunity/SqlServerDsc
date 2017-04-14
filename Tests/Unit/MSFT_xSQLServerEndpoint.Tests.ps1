$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerEndpoint'

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
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
    # Loading mocked classes
    Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'Tests\Unit\Stubs\SMO.cs')
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockNodeName = 'localhost'
        $mockInstanceName = 'DEFAULT'
        $mockPrincipal = 'COMPANY\SqlServiceAcct'
        $mockOtherPrincipal = 'COMPANY\OtherAcct'
        $mockEndpointName = 'DefaultEndpointMirror'
        $mockEndpointType = 'DatabaseMirroring'
        $mockEndpointListenerPort = 5022
        $mockEndpointListenerIpAddress = '0.0.0.0'  # 0.0.0.0 means listen on all IP addresses.

        $mockOtherEndpointName = 'UnknownEndpoint'
        $mockOtherEndpointType = 'UnknownType'
        $mockOtherEndpointListenerPort = 9001
        $mockOtherEndpointListenerIpAddress = '192.168.0.20'

        $script:mockMethodAlterRan = $false
        $script:mockMethodCreateRan = $false
        $script:mockMethodDropRan = $false
        $script:mockMethodStartRan = $false

        $mockDynamicEndpointName = $mockEndpointName
        $mockDynamicEndpointType = $mockEndpointType
        $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
        $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress

        $mockEndPointObject = {
            # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
            return New-Object Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDynamicEndpointName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value $mockDynamicEndpointType -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ProtocolType' -Value $null -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'Protocol' {
                    return New-Object Object |
                        Add-Member -MemberType ScriptProperty -Name 'Tcp' {
                            return New-Object Object |
                                Add-Member -MemberType NoteProperty -Name 'ListenerPort' -Value $mockDynamicEndpointListenerPort -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ListenerIPAddress' -Value $mockDynamicEndpointListenerIpAddress -PassThru -Force
                        } -PassThru -Force
                } -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'Payload' {
                    return New-Object Object |
                        Add-Member -MemberType ScriptProperty -Name 'DatabaseMirroring' {
                            return New-Object Object |
                                Add-Member -MemberType NoteProperty -Name 'ServerMirroringRole' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru -Force
                        } -PassThru -Force
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Alter' {
                    $script:mockMethodAlterRan = $true

                    if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
                    {
                        throw "Called mocked Alter() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedNameWhenCallingMethod, $this.Name
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Drop' {
                    $script:mockMethodDropRan = $true

                    if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
                    {
                        throw "Called mocked Drop() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedNameWhenCallingMethod, $this.Name
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Start' {
                    $script:mockMethodStartRan = $true
                    if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
                    {
                        throw "Called mocked Start() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedNameWhenCallingMethod, $this.Name
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Create' {
                    $script:mockMethodCreateRan = $true

                    if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
                    {
                        throw "Called mocked Create() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedNameWhenCallingMethod, $this.Name
                    }
                } -PassThru -Force
        }

        $mockConnectSql = {
            return New-Object Object |
                Add-Member ScriptProperty Endpoints {
                    return @(
                        @{
                            $mockDynamicEndpointName =  & $mockEndPointObject
                        }
                    )
                } -PassThru -Force
        }

        $mockNewObjectEndPoint = {
            return & $mockEndPointObject
        }

        $mockNewObjectEndPoint_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Endpoint'
        }

        $defaultParameters = @{
            SQLInstanceName = $mockInstanceName
            SQLServer = $mockNodeName
            EndpointName = $mockEndpointName
        }

        Describe 'MSFT_xSQLServerEndpoint\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            # Make sure the mock does not return the correct endpoint
            $mockDynamicEndpointName = $mockOtherEndpointName

            Context 'When the system is not in the desired state' {
                It 'Should return the desired state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                }

                It 'Should not return any values in the properties for the endpoint' {
                    $result = Get-TargetResource @testParameters
                    $result.EndpointName | Should Be ''
                    $result.Port | Should Be ''
                    $result.IpAddress | Should Be ''
                }

                It 'Should call the mock function Connect-SQL' {
                    Get-TargetResource @testParameters | Out-Null
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            # Make sure the mock do return the correct endpoint
            $mockDynamicEndpointName = $mockEndpointName

            Context 'When the system is in the desired state' {
                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                    $result.EndpointName | Should Be $testParameters.EndpointName
                    $result.Port | Should Be $mockEndpointListenerPort
                    $result.IpAddress | Should Be $mockEndpointListenerIpAddress
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock return the endpoint with wrong endpoint type
                $mockDynamicEndpointType = $mockOtherEndpointType

                Context 'When endpoint exist but with wrong endpoint type' {
                    It 'Should throw the correct error' {
                        { Get-TargetResource @testParameters } | Should Throw 'Endpoint ''DefaultEndpointMirror'' does exist, but it is not of type ''DatabaseMirroring''.'
                    }
                }

                # Make sure the mock return the endpoint with correct endpoint type
                $mockDynamicEndpointType = $mockEndpointType
            }

            Context 'When Connect-SQL returns nothing' {
                It 'Should throw the correct error' {
                    Mock -CommandName Connect-SQL -MockWith {
                        return $null
                    }

                    { Get-TargetResource @testParameters } | Should Throw 'Was unable to connect to the instance ''localhost\DEFAULT'''
                }
            }

            Assert-VerifiableMocks
        }

        Describe 'MSFT_xSQLServerEndpoint\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {
                # Make sure the mock does not return the correct endpoint
                $mockDynamicEndpointName = $mockOtherEndpointName

                It 'Should return that desired state is absent when wanted desired state is to be Present (using default values)' {
                    $testParameters += @{
                        Ensure = 'Present'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when wanted desired state is to be Present (setting all parameters)' {
                    $testParameters += @{
                        Ensure = 'Present'
                        Port = $mockEndpointListenerPort
                        IpAddress = $mockEndpointListenerIpAddress
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock do return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName

                It 'Should return that desired state is absent when wanted desired state is to be Absent' {
                    $testParameters += @{
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock do return the correct endpoint, but does not return the correct endpoint listener port
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointListenerPort = $mockOtherEndpointListenerPort

                Context 'When listener port is not in desired state' {
                    It 'Should return that desired state is absent' {
                        $testParameters += @{
                            Ensure = 'Present'
                            Port = $mockEndpointListenerPort
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                # Make sure the mock do return the correct endpoint listener port
                $mockDynamicEndpointListenerPort = $mockEndpointListenerPort

                # Make sure the mock do return the correct endpoint, but does not return the correct endpoint listener IP address
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointListenerIpAddress = $mockOtherEndpointListenerIpAddress

                Context 'When listener IP address is not in desired state' {
                    It 'Should return that desired state is absent' {
                        $testParameters += @{
                            Ensure = 'Present'
                            IpAddress = $mockEndpointListenerIpAddress
                        }

                        $result = Test-TargetResource @testParameters
                        $result | Should Be $false

                        Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                # Make sure the mock do return the correct endpoint listener IP address
                $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress
            }

            Context 'When the system is in the desired state' {
                # Make sure the mock do return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName

                It 'Should return that desired state is present when wanted desired state is to be Present (using default values)' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock does not return the correct endpoint
                $mockDynamicEndpointName = $mockOtherEndpointName

                It 'Should return that desired state is present when wanted desired state is to be Absent' {
                    $testParameters += @{
                        Ensure = 'Absent'
                    }

                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMocks
        }

        Describe 'MSFT_xSQLServerEndpoint\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectEndPoint -ParameterFilter $mockNewObjectEndPoint_ParameterFilter -Verifiable
            }

            Context 'When the system is not in the desired state' {
                # Make sure the mock do return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                # Set what the expected endpoint name should be when Create() method is called.
                $mockExpectedNameWhenCallingMethod = $mockEndpointName

                It 'Should call the the method Create when desired state is to be Present (using default values)' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    } -Verifiable

                    { Set-TargetResource @testParameters } | Should Not Throw
                    $script:mockMethodCreateRan | Should Be $true
                    $script:mockMethodStartRan | Should Be $true
                    $script:mockMethodAlterRan | Should Be $false
                    $script:mockMethodDropRan | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should call the the method Create when desired state is to be Present (setting all parameters)' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    } -Verifiable

                   $testParameters += @{
                        Ensure = 'Present'
                        Port = $mockEndpointListenerPort
                        IpAddress = $mockEndpointListenerIpAddress
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                    $script:mockMethodCreateRan | Should Be $true
                    $script:mockMethodStartRan | Should Be $true
                    $script:mockMethodAlterRan | Should Be $false
                    $script:mockMethodDropRan | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock do return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should call the the method Drop when desired state is to be Absent' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    } -Verifiable

                    $testParameters += @{
                        Ensure = 'Absent'
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                    $script:mockMethodCreateRan | Should Be $false
                    $script:mockMethodStartRan | Should Be $false
                    $script:mockMethodAlterRan | Should Be $false
                    $script:mockMethodDropRan | Should Be $true

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should not call Alter method when listener port is not in desired state' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            Port = $mockEndpointListenerPort
                            IpAddress = $mockEndpointListenerIpAddress
                        }
                    } -Verifiable

                    $testParameters += @{
                        Ensure = 'Present'
                        Port = $mockOtherEndpointListenerPort
                        IpAddress = $mockEndpointListenerIpAddress
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                    $script:mockMethodCreateRan | Should Be $false
                    $script:mockMethodStartRan | Should Be $false
                    $script:mockMethodAlterRan | Should Be $true
                    $script:mockMethodDropRan | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should not call Alter method when listener IP address is not in desired state' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            Port = $mockEndpointListenerPort
                            IpAddress = $mockEndpointListenerIpAddress
                        }
                    } -Verifiable

                    $testParameters += @{
                        Ensure = 'Present'
                        Port = $mockEndpointListenerPort
                        IpAddress = $mockOtherEndpointListenerIpAddress
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                    $script:mockMethodCreateRan | Should Be $false
                    $script:mockMethodStartRan | Should Be $false
                    $script:mockMethodAlterRan | Should Be $true
                    $script:mockMethodDropRan | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock does not return the correct endpoint
                $mockDynamicEndpointName = $mockOtherEndpointName

                Context 'When endpoint is missing when Ensure is set to Present' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                                Port = $mockEndpointListenerPort
                                IpAddress = $mockEndpointListenerIpAddress
                            }
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should Throw 'Endpoint ''DefaultEndpointMirror'' does not exist'
                    }
                }

                Context 'When endpoint is missing when Ensure is set to Absent' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                                Port = $mockEndpointListenerPort
                                IpAddress = $mockEndpointListenerIpAddress
                            }
                        } -Verifiable

                        $testParameters += @{
                            Ensure = 'Absent'
                        }

                        { Set-TargetResource @testParameters } | Should Throw 'Endpoint ''DefaultEndpointMirror'' does not exist'
                    }
                }

                Context 'When Connect-SQL returns nothing' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -MockWith {} -Verifiable
                        Mock -CommandName Connect-SQL -MockWith {
                            return $null
                        }

                        { Set-TargetResource @testParameters } | Should Throw 'Was unable to connect to the instance ''localhost\DEFAULT'''
                    }
                }

                # Make sure the mock does not return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName
            }

            Context 'When the system is in the desired state' {
                # Make sure the mock do return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
                $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should not call any methods when desired state is already Present' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            Port = $mockEndpointListenerPort
                            IpAddress = $mockEndpointListenerIpAddress
                        }
                    } -Verifiable

                    $testParameters += @{
                        Ensure = 'Present'
                        Port = $mockEndpointListenerPort
                        IpAddress = $mockEndpointListenerIpAddress
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                    $script:mockMethodCreateRan | Should Be $false
                    $script:mockMethodStartRan | Should Be $false
                    $script:mockMethodAlterRan | Should Be $false
                    $script:mockMethodDropRan | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock does not return the correct endpoint
                $mockDynamicEndpointName = $mockOtherEndpointName

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should not call any methods when desired state is already Absent' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    } -Verifiable

                    $testParameters += @{
                        Ensure = 'Absent'
                    }

                    { Set-TargetResource @testParameters } | Should Not Throw
                    $script:mockMethodCreateRan | Should Be $false
                    $script:mockMethodStartRan | Should Be $false
                    $script:mockMethodAlterRan | Should Be $false
                    $script:mockMethodDropRan | Should Be $false

                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}
