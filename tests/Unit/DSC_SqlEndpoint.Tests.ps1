<#
    .SYNOPSIS
        Automated unit test for DSC_SqlEndpoint DSC resource.

#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

$script:dscModuleName      = 'SqlServerDsc'
$script:dscResourceName    = 'DSC_SqlEndpoint'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $mockServerName = 'localhost'
        $mockInstanceName = 'INSTANCE1'
        $mockPrincipal = 'COMPANY\SqlServiceAcct'
        $mockOtherPrincipal = 'COMPANY\OtherAcct'
        $mockEndpointName = 'DefaultEndpointMirror'
        $mockEndpointType = 'DatabaseMirroring'
        $mockEndpointListenerPort = 5022
        $mockEndpointListenerIpAddress = '0.0.0.0'  # 0.0.0.0 means listen on all IP addresses.
        $mockEndpointOwner = 'sa'

        $mockOtherEndpointName = 'UnknownEndpoint'
        $mockOtherEndpointType = 'UnknownType'
        $mockOtherEndpointListenerPort = 9001
        $mockOtherEndpointListenerIpAddress = '192.168.0.20'
        $mockOtherEndpointOwner = 'COMPANY\OtherAcct'

        $mockSsbrEndpointName = 'SSBR'
        $mockSsbrEndpointType = 'ServiceBroker'
        $mockSsbrEndpointListenerPort = 5023
        $mockSsbrEndpointListenerIpAddress = '192.168.0.20'
        $mockSsbrEndpointOwner = 'COMPANY\OtherAcct'
        $mockSsbrIsMessageForwardingEnabled = $true
        $mockSsbrMessageForwardingSize = 2
        $mockSsbrEndpointState = 'Started'

        $script:mockMethodAlterRan = $false
        $script:mockMethodCreateRan = $false
        $script:mockMethodDropRan = $false
        $script:mockMethodStartRan = $false

        $mockDynamicEndpointName = $mockEndpointName
        $mockDynamicEndpointType = $mockEndpointType
        $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
        $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress
        $mockDynamicEndpointOwner = $mockEndpointOwner
        $mockDynamicIsMessageForwardingEnabled = $null
        $mockDynamicMessageForwardingSize = $null
        $mockDynamicEndpointState = 'Started'

        $mockEndpointObject = {
            # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
            return New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDynamicEndpointName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value $mockDynamicEndpointType -PassThru |
                Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value $mockDynamicEndpointState -PassThru |
                Add-Member -MemberType NoteProperty -Name 'ProtocolType' -Value $null -PassThru |
                Add-Member -MemberType NoteProperty -Name 'Owner' -Value $mockDynamicEndpointOwner -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'Protocol' -Value {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name 'Tcp' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'ListenerPort' -Value $mockDynamicEndpointListenerPort -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'ListenerIPAddress' -Value $mockDynamicEndpointListenerIpAddress -PassThru -Force
                        } -PassThru -Force
                } -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'Payload' -Value {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name 'DatabaseMirroring' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'ServerMirroringRole' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru -Force
                        } -PassThru -Force |
                        Add-Member -MemberType ScriptProperty -Name 'ServiceBroker' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'IsMessageForwardingEnabled' -Value $mockDynamicIsMessageForwardingEnabled -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'MessageForwardingSize' -Value $mockDynamicMessageForwardingSize -PassThru
                        } -PassThru -Force
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                    $script:mockMethodAlterRan = $true

                    if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
                    {
                        throw "Called mocked Alter() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedNameWhenCallingMethod, $this.Name
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
                    $script:mockMethodDropRan = $true

                    if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
                    {
                        throw "Called mocked Drop() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedNameWhenCallingMethod, $this.Name
                    }
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Start' -Value {
                    $script:mockMethodStartRan = $true
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Stop' -Value {
                    $script:mockMethodStopRan = $true
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Disable' -Value {
                    $script:mockMethodDisableRan = $true
                } -PassThru |
                Add-Member -MemberType ScriptMethod -Name 'Create' -Value {
                    $script:mockMethodCreateRan = $true

                    if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
                    {
                        throw "Called mocked Create() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
                                -f $mockExpectedNameWhenCallingMethod, $this.Name
                    }
                } -PassThru -Force
        }

        $mockConnectSql = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name Endpoints -Value {
                    return @(
                        @{
                            # This executes the script block $mockEndpointObject and returns a mocked Microsoft.SqlServer.Management.Smo.Endpoint
                            $mockDynamicEndpointName =  & $mockEndpointObject
                        }
                    )
                } -PassThru -Force
        }

        $mockNewObjectEndPoint = {
            # This executes the script block $mockEndpointObject and returns a mocked Microsoft.SqlServer.Management.Smo.Endpoint
            return & $mockEndpointObject
        }

        $mockNewObjectEndPoint_ParameterFilter = {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Endpoint'
        }

        $defaultParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
            EndpointName = $mockEndpointName
            EndpointType = $mockEndpointType
        }

        $defaultSsbrParameters = @{
            InstanceName = $mockInstanceName
            ServerName   = $mockServerName
            EndpointName = $mockSsbrEndpointName
            EndpointType = $mockSsbrEndpointType
        }

        Describe 'DSC_SqlEndpoint\Get-TargetResource' -Tag 'Get' {
            BeforeEach {
                $testParameters = $defaultParameters

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock -CommandName New-Object -MockWith $mockNewObjectEndPoint -ParameterFilter $mockNewObjectEndPoint_ParameterFilter -Verifiable
            }

            # Make sure the mock does not return the correct endpoint
            $mockDynamicEndpointName = $mockOtherEndpointName

            Context 'When the system is not in the desired state' {
                It 'Should return the desired state as absent' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                }

                It 'Should not return any values in the properties for the endpoint' {
                    $result = Get-TargetResource @testParameters
                    $result.EndpointName | Should -Be ''
                    $result.Port | Should -Be ''
                    $result.IpAddress | Should -Be ''
                    $result.Owner | Should -Be ''
                    $result.IsMessageForwardingEnabled | Should -Be $null
                    $result.MessageForwardingSize | Should -Be $null
                }

                It 'Should call the mock function Connect-SQL' {
                    Get-TargetResource @testParameters | Out-Null
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            # Make sure the mock do return the correct endpoint
            $mockDynamicEndpointName = $mockEndpointName

            Context 'When the system is in the desired state (mirror)' {
                It 'Should return the desired state as present' {
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.EndpointName | Should -Be $testParameters.EndpointName
                    $result.Port | Should -Be $mockEndpointListenerPort
                    $result.IpAddress | Should -Be $mockEndpointListenerIpAddress
                    $result.Owner | Should -Be $mockEndpointOwner
                }

                It 'Should call the mock function Connect-SQL' {
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock return the endpoint with wrong endpoint type
                $mockDynamicEndpointType = $mockOtherEndpointType

                Context 'When endpoint exist but with wrong endpoint type' {
                    It 'Should throw the correct error' {
                        { Get-TargetResource @testParameters } | Should -Throw ($script:localizedData.EndpointFoundButWrongType -f $testParameters.EndpointName, $mockOtherEndpointType, $mockEndpointType)
                    }
                }

                # Make sure the mock return the endpoint with correct endpoint type
                $mockDynamicEndpointType = $mockEndpointType
            }

            # Make sure the mock returns the ServiceBroker endpoint
            $mockDynamicEndpointName = $mockSsbrEndpointName
            $mockDynamicEndpointType = $mockSsbrEndpointType
            $mockDynamicEndpointListenerPort = $mockSsbrEndpointListenerPort
            $mockDynamicEndpointListenerIpAddress = $mockSsbrEndpointListenerIpAddress
            $mockDynamicEndpointOwner = $mockSsbrEndpointOwner
            $mockDynamicIsMessageForwardingEnabled = $mockSsbrIsMessageForwardingEnabled
            $mockDynamicMessageForwardingSize = $mockSsbrMessageForwardingSize



            Context 'When the system is in the desired state (ServiceBroker)' {
                It 'Should return the desired state as present' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()
                    $result = Get-TargetResource @testParameters
                    $result.Ensure | Should -Be 'Present'
                }

                It 'Should return the same values as passed as parameters' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()
                    $result = Get-TargetResource @testParameters
                    $result.ServerName | Should -Be $testParameters.ServerName
                    $result.InstanceName | Should -Be $testParameters.InstanceName
                    $result.EndpointName | Should -Be $testParameters.EndpointName
                    $result.Port | Should -Be $mockSsbrEndpointListenerPort
                    $result.IpAddress | Should -Be $mockSsbrEndpointListenerIpAddress
                    $result.Owner | Should -Be $mockSsbrEndpointOwner
                    $result.IsMessageForwardingEnabled | Should -Be $mockSsbrIsMessageForwardingEnabled
                    $result.MessageForwardingSize | Should -Be $mockSsbrMessageForwardingSize
                }

                It 'Should call the mock function Connect-SQL' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()
                    $result = Get-TargetResource @testParameters
                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock return the endpoint with wrong endpoint type
                $mockDynamicEndpointType = $mockOtherEndpointType

                Context 'When endpoint exist but with wrong endpoint type' {
                    It 'Should throw the correct error' {
                        #Setting parameters here because of the beforeeach block.
                        $testParameters = $defaultSsbrParameters.Clone()
                        { Get-TargetResource @testParameters } | Should -Throw ($script:localizedData.EndpointFoundButWrongType -f $testParameters.EndpointName, $mockOtherEndpointType, $mockSSbrEndpointType)
                    }
                }

                # Make sure the mock return the endpoint with original endpoint type
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointType = $mockEndpointType
                $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
                $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress
                $mockDynamicEndpointOwner = $mockEndpointOwner
                $mockDynamicIsMessageForwardingEnabled = $null
                $mockDynamicMessageForwardingSize = $null
            }

            $testParameters = $defaultParameters.Clone()

            Context 'When Connect-SQL returns nothing' {
                It 'Should throw the correct error' {
                    Mock -CommandName Connect-SQL -MockWith {
                        return $null
                    }

                    { Get-TargetResource @testParameters } | Should -Throw ($script:localizedData.NotConnectedToInstance -f $testParameters.ServerName, $testParameters.InstanceName)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'DSC_SqlEndpoint\Test-TargetResource' -Tag 'Test' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
            }

            Context 'When the system is not in the desired state' {
                # Make sure the mock does not return the correct endpoint
                $mockDynamicEndpointName = $mockOtherEndpointName

                It 'Should return that desired state is absent when wanted desired state is to be Present (using default values)' {
                    $testParameters.Add('Ensure', 'Present')

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                It 'Should return that desired state is absent when wanted desired state is to be Present (setting all parameters)' {
                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Port', $mockEndpointListenerPort)
                    $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
                    $testParameters.Add('Owner', $mockEndpointOwner)

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock do return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName

                It 'Should return that desired state is absent when wanted desired state is to be Absent' {
                    $testParameters.Add('Ensure', 'Absent')

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock do return the correct endpoint, but does not return the correct endpoint listener port
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointListenerPort = $mockOtherEndpointListenerPort

                Context 'When listener port is not in desired state' {
                    It 'Should return that desired state is absent' {
                        $testParameters.Add('Ensure', 'Present')
                        $testParameters.Add('Port', $mockEndpointListenerPort)

                        $result = Test-TargetResource @testParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When State is not in desired state' {
                    It 'Should return that desired state is absent' {
                        $testParameters.Add('Ensure', 'Present')
                        $testParameters.Add('State', 'Stopped')

                        $result = Test-TargetResource @testParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                # Make sure the mock do return the correct endpoint listener port
                $mockDynamicEndpointListenerPort = $mockEndpointListenerPort

                # Make sure the mock do return the correct endpoint, but does not return the correct endpoint listener IP address
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointListenerIpAddress = $mockOtherEndpointListenerIpAddress

                Context 'When listener IP address is not in desired state' {
                    It 'Should return that desired state is absent' {
                        $testParameters.Add('Ensure', 'Present')
                        $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)


                        $result = Test-TargetResource @testParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                # Make sure the mock do return the correct endpoint listener IP address
                $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress

                # Make sure the mock do return the correct endpoint, but does not return the correct endpoint owner
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointOwner = $mockOtherEndpointOwner

                Context 'When listener Owner is not in desired state' {
                    It 'Should return that desired state is absent' {
                        $testParameters.Add('Ensure', 'Present')
                        $testParameters.Add('Owner', $mockEndpointOwner)


                        $result = Test-TargetResource @testParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                # Make sure the mock return the endpoint with ServiceBroker endpoint type
                $mockDynamicEndpointName = $mockSsbrEndpointName
                $mockDynamicEndpointType = $mockSsbrEndpointType
                $mockDynamicEndpointListenerPort = $mockSsbrEndpointListenerPort
                $mockDynamicEndpointListenerIpAddress = $mockSsbrEndpointListenerIpAddress
                $mockDynamicEndpointOwner = $mockSsbrEndpointOwner
                $mockDynamicIsMessageForwardingEnabled = $false
                $mockDynamicMessageForwardingSize = 1
                $mockDynamicEndpointState = 'Started'

                Context 'When ServiceBroker message forwarding is not in desired state' {
                    It 'Should return that desired state is absent' {
                        $testParameters = $defaultSsbrParameters.Clone()
                        $testParameters.Add('Ensure', 'Present')
                        $testParameters.Add('IsMessageForwardingEnabled', $mockSsbrIsMessageForwardingEnabled)

                        $result = Test-TargetResource @testParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When ServiceBroker message forwarding size is not in desired state' {
                    It 'Should return that desired state is absent' {
                        $testParameters = $defaultSsbrParameters.Clone()
                        $testParameters.Add('Ensure', 'Present')
                        $testParameters.Add('MessageForwardingSize', $mockSsbrMessageForwardingSize)


                        $result = Test-TargetResource @testParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                    }
                }

                # Make sure the mock return the endpoint with original endpoint type
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointType = $mockEndpointType
                $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
                $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress
                $mockDynamicEndpointOwner = $mockEndpointOwner
                $mockDynamicIsMessageForwardingEnabled = $null
                $mockDynamicMessageForwardingSize = $null
                $mockDynamicEndpointState = 'Started'

                # Make sure the mock do return the correct endpoint owner
                $mockDynamicEndpointOwner = $mockEndpointOwner
            }

            $testParameters = $defaultParameters.Clone()

            Context 'When the system is in the desired state' {
                # Make sure the mock do return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName

                It 'Should return that desired state is present when wanted desired state is to be Present (using default values)' {
                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock does not return the correct endpoint
                $mockDynamicEndpointName = $mockOtherEndpointName

                It 'Should return that desired state is present when wanted desired state is to be Absent' {
                    $testParameters.Add('Ensure', 'Absent')

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }


            Assert-VerifiableMock
        }

        Describe 'DSC_SqlEndpoint\Set-TargetResource' -Tag 'Set' {
            BeforeEach {
                $testParameters = $defaultParameters.Clone()

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

                It 'Should call the method Create when desired state is to be Present (using default values)' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    } -Verifiable

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeTrue
                    $script:mockMethodStartRan | Should -BeTrue
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                # Set what the expected endpoint name should be when Create() method is called.
                $mockExpectedNameWhenCallingMethod = $mockEndpointName

                It 'Should call the method Create when desired state is to be Present (setting all parameters for Mirror endpoint)' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Port', $mockEndpointListenerPort)
                    $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
                    $testParameters.Add('Owner', $mockEndpointOwner)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeTrue
                    $script:mockMethodStartRan | Should -BeTrue
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false


                $mockExpectedNameWhenCallingMethod = $mockSsbrEndpointName
                $mockDynamicEndpointName = $mockSsbrEndpointName

                It 'Should call the method Create when desired state is to be Present (setting parameters for ServiceBroker endpoint)' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Absent'
                        }
                    } -Verifiable

                    $testParameters.EndpointName = $mockSsbrEndpointName
                    $testParameters.EndpointType = $mockSsbrEndpointType
                    $testParameters.Add('Ensure', 'Present')

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeTrue
                    $script:mockMethodStartRan | Should -BeTrue
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should call the method Alter when desired state is to be Present (setting Port parameter for endpoint)' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    } -Verifiable

                    $testParameters.EndpointName = $mockSsbrEndpointName
                    $testParameters.EndpointType = $mockSsbrEndpointType
                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Port', $mockSsbrEndpointListenerPort)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should call the method Alter when desired state is to be Present (setting IpAddress parameter for endpoint)' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    } -Verifiable

                    $testParameters.EndpointName = $mockSsbrEndpointName
                    $testParameters.EndpointType = $mockSsbrEndpointType
                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('IpAddress', $mockSsbrEndpointListenerIpAddress)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should call the method Alter when desired state is to be Present (setting Owner parameter for endpoint)' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    } -Verifiable
                    $testParameters.EndpointName = $mockSsbrEndpointName
                    $testParameters.EndpointType = $mockSsbrEndpointType
                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Owner', $mockSsbrEndpointOwner)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should call the method Alter when desired state is to be Present (setting IsMessageForwardingEnabled parameter for ServiceBroker endpoint)' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            IsMessageForwardingEnabled = $False
                        }
                    } -Verifiable
                    $testParameters.EndpointName = $mockSsbrEndpointName
                    $testParameters.EndpointType = $mockSsbrEndpointType
                    $testParameters.Add('IsMessageForwardingEnabled', $mockSsbrIsMessageForwardingEnabled)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                It 'Should call the method Alter when desired state is to be Present (setting MessageForwardingSize parameters for ServiceBroker endpoint)' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            IsMessageForwardingEnabled = $true
                            MessageForwardingSize = 1
                        }
                    } -Verifiable
                    $testParameters.EndpointName = $mockSsbrEndpointName
                    $testParameters.EndpointType = $mockSsbrEndpointType
                    $testParameters.Add('MessageForwardingSize', $mockSsbrMessageForwardingSize)

                    { Set-TargetResource @testParameters } | Should -Not -Throw

                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                # Set what the expected endpoint name should be when Drop() method is called.
                $mockExpectedNameWhenCallingMethod = $mockEndpointName
                $mockDynamicEndpointName = $mockEndpointName

                It 'Should call the method Drop when desired state is to be Absent' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Absent')

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeTrue

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                # Set what the expected endpoint name should be when Alter() method is called. (Mirror)
                $mockExpectedNameWhenCallingMethod = $mockEndpointName

                It 'Should call Alter method when listener port is not in desired state' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            Port = $mockEndpointListenerPort
                            IpAddress = $mockEndpointListenerIpAddress
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Port', $mockOtherEndpointListenerPort)
                    $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
                    $testParameters.Add('Owner', $mockEndpointOwner)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false


                # Set what the expected endpoint name should be when Alter() method is called. (ServiceBroker)
                $mockExpectedNameWhenCallingMethod = $mockSsbrEndpointName
                $mockDynamicEndpointName = $mockSsbrEndpointName

                It 'Should call the method Alter when desired state is to be Present (setting all parameters for ServiceBroker endpoint)' {
                    #Setting parameters here because of the beforeeach block.
                    $testParameters = $defaultSsbrParameters.Clone()

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            Port = $mockEndpointListenerPort
                            IpAddress = $mockEndpointListenerIpAddress
                            IsMessageForwardingEnabled = $false
                            MessageForwardingSize = 1
                        }
                    } -Verifiable

                    $testParameters.EndpointName = $mockSsbrEndpointName
                    $testParameters.EndpointType = $mockSsbrEndpointType
                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Port', $mockEndpointListenerPort)
                    $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
                    $testParameters.Add('Owner', $mockEndpointOwner)
                    $testParameters.Add('IsMessageForwardingEnabled', $mockSsbrIsMessageForwardingEnabled)
                    $testParameters.Add('MessageForwardingSize', $mockSsbrMessageForwardingSize)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false


                # Set what the expected endpoint name should be when Alter() method is called.
                $mockExpectedNameWhenCallingMethod = $mockEndpointName
                $mockDynamicEndpointName = $mockEndpointName

                It 'Should call Alter method when listener IP address is not in desired state' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            Port = $mockEndpointListenerPort
                            IpAddress = $mockEndpointListenerIpAddress
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Port', $mockEndpointListenerPort)
                    $testParameters.Add('IpAddress', $mockOtherEndpointListenerIpAddress)
                    $testParameters.Add('Owner', $mockEndpointOwner)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Set all method call tests variables to $false
                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false

                # Set what the expected endpoint name should be when Alter() method is called.
                $mockExpectedNameWhenCallingMethod = $mockEndpointName

                It 'Should call Alter method when Owner is not in desired state' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            Owner = $mockEndpointOwner
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Owner', $mockOtherEndpointOwner)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeTrue
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false
                $script:mockMethodStopRan = $false
                $script:mockMethodDisableRan = $false

                $mockDynamicEndpointState = 'Stopped'

                It 'Should call Start() method when State is not ''Started''' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            State = 'Stopped'
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('State', 'Started')

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeTrue
                    $script:mockMethodStopRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeFalse
                    $script:mockMethodDisableRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false
                $script:mockMethodStopRan = $false
                $script:mockMethodDisableRan = $false

                $mockDynamicEndpointState = 'Running'

                It 'Should call Stop() method when State is not ''Stopped''' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            State = 'Running'
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('State', 'Stopped')

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodStopRan | Should -BeTrue
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeFalse
                    $script:mockMethodDisableRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                $script:mockMethodCreateRan = $false
                $script:mockMethodStartRan = $false
                $script:mockMethodAlterRan = $false
                $script:mockMethodDropRan = $false
                $script:mockMethodStopRan = $false
                $script:mockMethodDisableRan = $false

                $mockDynamicEndpointState = 'Running'

                It 'Should call Disable() method when State is not ''Disabled''' {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure = 'Present'
                            State = 'Running'
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('State', 'Disabled')

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodStopRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeFalse
                    $script:mockMethodDisableRan | Should -BeTrue

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }

                # Make sure the mock does not return the correct endpoint
                $mockDynamicEndpointName = $mockOtherEndpointName

                Context 'When endpoint is missing when Ensure is set to Present' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                            }
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.EndpointNotFound -f $testParameters.EndpointName)
                    }
                }

                Context 'When endpoint is missing when Ensure is set to Absent' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                            }
                        } -Verifiable

                        $testParameters.Add('Ensure', 'Absent')

                        { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.EndpointNotFound -f $testParameters.EndpointName)
                    }
                }

                Context 'When Connect-SQL returns nothing' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -Verifiable
                        Mock -CommandName Connect-SQL -MockWith {
                            return $null
                        }

                        { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.NotConnectedToInstance -f $testParameters.ServerName, $testParameters.InstanceName)
                    }
                }
            }

            Context 'When the system is in the desired state' {
                # Make sure the mock do return the correct endpoint
                $mockDynamicEndpointName = $mockEndpointName
                $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
                $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress
                $mockDynamicEndpointOwner = $mockEndpointOwner

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
                            Owner = $mockEndpointOwner
                            IsMessageForwardingEnabled = $mockSsbrIsMessageForwardingEnabled
                            MessageForwardingSize = $mockSsbrMessageForwardingSize
                        }
                    } -Verifiable

                    $testParameters.Add('Ensure', 'Present')
                    $testParameters.Add('Port', $mockEndpointListenerPort)
                    $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
                    $testParameters.Add('Owner', $mockEndpointOwner)
                    $testParameters.Add('IsMessageForwardingEnabled', $mockSsbrIsMessageForwardingEnabled)
                    $testParameters.Add('MessageForwardingSize', $mockSsbrMessageForwardingSize)

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
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

                    $testParameters.Add('Ensure', 'Absent')

                    { Set-TargetResource @testParameters } | Should -Not -Throw
                    $script:mockMethodCreateRan | Should -BeFalse
                    $script:mockMethodStartRan | Should -BeFalse
                    $script:mockMethodAlterRan | Should -BeFalse
                    $script:mockMethodDropRan | Should -BeFalse

                    Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            # Make sure the mock do return the correct endpoint
            $mockDynamicEndpointName = $mockEndpointName
            $mockExpectedNameWhenCallingMethod = $mockOtherEndpointName

            Context 'Testing mocks' {
                Context 'When mocked Create() method is called with the wrong endpoint name' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Absent'
                            }
                        } -Verifiable

                        { Set-TargetResource @testParameters } | Should -Throw 'Exception calling "Create" with "0" argument(s): "Called mocked Create() method on and endpoint with wrong name. Expected ''UnknownEndpoint''. But was ''DefaultEndpointMirror''."'
                    }
                }

                Context 'When mocked Drop() method is called with the wrong endpoint name' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                            }
                        } -Verifiable

                        $testParameters.Add('Ensure', 'Absent')

                        { Set-TargetResource @testParameters } | Should -Throw 'Exception calling "Drop" with "0" argument(s): "Called mocked Drop() method on and endpoint with wrong name. Expected ''UnknownEndpoint''. But was ''DefaultEndpointMirror''."'
                    }
                }

                Context 'When mocked Alter() method is called with the wrong endpoint name' {
                    It 'Should throw the correct error' {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Ensure = 'Present'
                                Port = $mockEndpointListenerPort
                                IpAddress = $mockEndpointListenerIpAddress
                            }
                        } -Verifiable

                        $testParameters.Add('Ensure', 'Present')
                        $testParameters.Add('Port', $mockOtherEndpointListenerPort)
                        $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
                        $testParameters.Add('Owner', $mockEndpointOwner)

                        { Set-TargetResource @testParameters } | Should -Throw 'Exception calling "Alter" with "0" argument(s): "Called mocked Alter() method on and endpoint with wrong name. Expected ''UnknownEndpoint''. But was ''DefaultEndpointMirror''."'
                    }
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
