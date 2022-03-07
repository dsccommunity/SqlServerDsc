<#
    .SYNOPSIS
        Unit test for DSC_SqlEndpoint DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlEndpoint'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

# $mockServerName = 'localhost'
# $mockInstanceName = 'INSTANCE1'
# $mockPrincipal = 'COMPANY\SqlServiceAcct'
# $mockOtherPrincipal = 'COMPANY\OtherAcct'
# $mockEndpointName = 'DefaultEndpointMirror'
# $mockEndpointType = 'DatabaseMirroring'
# $mockEndpointListenerPort = 5022
# $mockEndpointListenerIpAddress = '0.0.0.0'  # 0.0.0.0 means listen on all IP addresses.
# $mockEndpointOwner = 'sa'

# $mockOtherEndpointName = 'UnknownEndpoint'
# $mockOtherEndpointType = 'UnknownType'
# $mockOtherEndpointListenerPort = 9001
# $mockOtherEndpointListenerIpAddress = '192.168.0.20'
# $mockOtherEndpointOwner = 'COMPANY\OtherAcct'

# $mockSsbrEndpointName = 'SSBR'
# $mockSsbrEndpointType = 'ServiceBroker'
# $mockSsbrEndpointListenerPort = 5023
# $mockSsbrEndpointListenerIpAddress = '192.168.0.20'
# $mockSsbrEndpointOwner = 'COMPANY\OtherAcct'
# $mockSsbrIsMessageForwardingEnabled = $true
# $mockSsbrMessageForwardingSize = 2
# $mockSsbrEndpointState = 'Started'

# $script:mockMethodAlterRan = $false
# $script:mockMethodCreateRan = $false
# $script:mockMethodDropRan = $false
# $script:mockMethodStartRan = $false

# $mockDynamicEndpointName = $mockEndpointName
# $mockDynamicEndpointType = $mockEndpointType
# $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
# $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress
# $mockDynamicEndpointOwner = $mockEndpointOwner
# $mockDynamicIsMessageForwardingEnabled = $null
# $mockDynamicMessageForwardingSize = $null
# $mockDynamicEndpointState = 'Started'

# $mockEndpointObject = {
#     # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
#     return New-Object -TypeName Object |
#         Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDynamicEndpointName -PassThru |
#         Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value $mockDynamicEndpointType -PassThru |
#         Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value $mockDynamicEndpointState -PassThru |
#         Add-Member -MemberType NoteProperty -Name 'ProtocolType' -Value $null -PassThru |
#         Add-Member -MemberType NoteProperty -Name 'Owner' -Value $mockDynamicEndpointOwner -PassThru |
#         Add-Member -MemberType ScriptProperty -Name 'Protocol' -Value {
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType ScriptProperty -Name 'Tcp' -Value {
#                     return New-Object -TypeName Object |
#                         Add-Member -MemberType NoteProperty -Name 'ListenerPort' -Value $mockDynamicEndpointListenerPort -PassThru |
#                         Add-Member -MemberType NoteProperty -Name 'ListenerIPAddress' -Value $mockDynamicEndpointListenerIpAddress -PassThru -Force
#                 } -PassThru -Force
#         } -PassThru |
#         Add-Member -MemberType ScriptProperty -Name 'Payload' -Value {
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType ScriptProperty -Name 'DatabaseMirroring' -Value {
#                     return New-Object -TypeName Object |
#                         Add-Member -MemberType NoteProperty -Name 'ServerMirroringRole' -Value $null -PassThru |
#                         Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
#                         Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru -Force
#                 } -PassThru -Force |
#                 Add-Member -MemberType ScriptProperty -Name 'ServiceBroker' -Value {
#                     return New-Object -TypeName Object |
#                         Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
#                         Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru |
#                         Add-Member -MemberType NoteProperty -Name 'IsMessageForwardingEnabled' -Value $mockDynamicIsMessageForwardingEnabled -PassThru |
#                         Add-Member -MemberType NoteProperty -Name 'MessageForwardingSize' -Value $mockDynamicMessageForwardingSize -PassThru
#                 } -PassThru -Force
#         } -PassThru |
#         Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
#             $script:mockMethodAlterRan = $true

#             if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
#             {
#                 throw "Called mocked Alter() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
#                         -f $mockExpectedNameWhenCallingMethod, $this.Name
#             }
#         } -PassThru |
#         Add-Member -MemberType ScriptMethod -Name 'Drop' -Value {
#             $script:mockMethodDropRan = $true

#             if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
#             {
#                 throw "Called mocked Drop() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
#                         -f $mockExpectedNameWhenCallingMethod, $this.Name
#             }
#         } -PassThru |
#         Add-Member -MemberType ScriptMethod -Name 'Start' -Value {
#             $script:mockMethodStartRan = $true
#         } -PassThru |
#         Add-Member -MemberType ScriptMethod -Name 'Stop' -Value {
#             $script:mockMethodStopRan = $true
#         } -PassThru |
#         Add-Member -MemberType ScriptMethod -Name 'Disable' -Value {
#             $script:mockMethodDisableRan = $true
#         } -PassThru |
#         Add-Member -MemberType ScriptMethod -Name 'Create' -Value {
#             $script:mockMethodCreateRan = $true

#             if ( $this.Name -ne $mockExpectedNameWhenCallingMethod )
#             {
#                 throw "Called mocked Create() method on and endpoint with wrong name. Expected '{0}'. But was '{1}'." `
#                         -f $mockExpectedNameWhenCallingMethod, $this.Name
#             }
#         } -PassThru -Force
# }

# $mockConnectSql = {
#     return New-Object -TypeName Object |
#         Add-Member -MemberType ScriptProperty -Name Endpoints -Value {
#             return @(
#                 @{
#                     # This executes the script block $mockEndpointObject and returns a mocked Microsoft.SqlServer.Management.Smo.Endpoint
#                     $mockDynamicEndpointName =  & $mockEndpointObject
#                 }
#             )
#         } -PassThru -Force
# }

# $mockNewObjectEndPoint = {
#     # This executes the script block $mockEndpointObject and returns a mocked Microsoft.SqlServer.Management.Smo.Endpoint
#     return & $mockEndpointObject
# }

# $mockNewObjectEndPoint_ParameterFilter = {
#     $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Endpoint'
# }

# $defaultParameters = @{
#     InstanceName = $mockInstanceName
#     ServerName   = $mockServerName
#     EndpointName = $mockEndpointName
#     EndpointType = $mockEndpointType
# }

# $defaultSsbrParameters = @{
#     InstanceName = $mockInstanceName
#     ServerName   = $mockServerName
#     EndpointName = $mockSsbrEndpointName
#     EndpointType = $mockSsbrEndpointType
# }

Describe 'SqlEndpoint\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When using a Database Mirroring endpoint' {
            BeforeAll {
                $mockEndpointObject = {
                    # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                    return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DefaultEndpointMirror' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value 'DatabaseMirroring' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value 'Started' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'ProtocolType' -Value $null -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Owner' -Value 'sa' -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Protocol' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'Tcp' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ListenerPort' -Value 5022 -PassThru |
                                        # 0.0.0.0 means listen on all IP addresses.
                                        Add-Member -MemberType NoteProperty -Name 'ListenerIPAddress' -Value '0.0.0.0' -PassThru -Force
                                } -PassThru -Force
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Payload' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'DatabaseMirroring' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ServerMirroringRole' -Value $null -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru -Force
                                } -PassThru -Force
                        } -PassThru -Force
                }

                $mockConnectSql = {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name Endpoints -Value {
                            return @(
                                @{
                                    <#
                                        This executes the script block of $mockEndpointObject and returns
                                        a mocked Microsoft.SqlServer.Management.Smo.Endpoint
                                    #>
                                    'DefaultEndpointMirror' =  & $mockEndpointObject
                                }
                            )
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            Context 'When the endpoint should be absent' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'MissingEndpoint'
                        $mockGetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    }
                }

                It 'Should have property Ensure set to absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0


                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.EndpointType | Should -Be $mockGetTargetResourceParameters.EndpointType
                    }
                }

                It 'Should return the correct values in the rest of properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.EndpointName | Should -Be ''
                        $result.Port | Should -Be ''
                        $result.IpAddress | Should -Be ''
                        $result.Owner | Should -Be ''
                        $result.State | Should -BeNullOrEmpty
                        $result.IsMessageForwardingEnabled | Should -BeNullOrEmpty
                        $result.MessageForwardingSize | Should -BeNullOrEmpty
                    }
                }

                It 'Should call the mock function Connect-SQL' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the endpoint should be present' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockGetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    }
                }

                It 'Should have property Ensure set to present' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0


                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.EndpointType | Should -Be $mockGetTargetResourceParameters.EndpointType
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.EndpointName | Should -Be 'DefaultEndpointMirror'
                        $result.Port | Should -Be 5022
                        $result.IpAddress | Should -Be '0.0.0.0'
                        $result.Owner | Should -Be 'sa'
                        $result.State | Should -Be 'Started'
                        $result.IsMessageForwardingEnabled | Should -BeNullOrEmpty
                        $result.MessageForwardingSize | Should -BeNullOrEmpty
                    }
                }

                It 'Should call the mock function Connect-SQL' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When endpoint exist but with wrong endpoint type' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockGetTargetResourceParameters.EndpointType = 'ServiceBroker'
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockErrorMessage = $script:localizedData.EndpointFoundButWrongType -f $mockGetTargetResourceParameters.EndpointName, 'DatabaseMirroring', 'ServiceBroker'

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }
                }
            }
        }

        Context 'When using a Service Broker endpoint' {
            BeforeAll {
                $mockEndpointObject = {
                    # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                    return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value 'SSBR' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'EndpointType' -Value 'ServiceBroker' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'EndpointState' -Value 'Started' -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'ProtocolType' -Value $null -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'Owner' -Value 'COMPANY\OtherAcct' -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Protocol' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'Tcp' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ListenerPort' -Value 5023 -PassThru |
                                        # 0.0.0.0 means listen on all IP addresses.
                                        Add-Member -MemberType NoteProperty -Name 'ListenerIPAddress' -Value '192.168.0.20' -PassThru -Force
                                } -PassThru -Force
                        } -PassThru |
                        Add-Member -MemberType ScriptProperty -Name 'Payload' -Value {
                            return New-Object -TypeName Object |
                                Add-Member -MemberType ScriptProperty -Name 'ServiceBroker' -Value {
                                    return New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'EndpointEncryption' -Value $null -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'EndpointEncryptionAlgorithm' -Value $null -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'IsMessageForwardingEnabled' -Value $true -PassThru |
                                        Add-Member -MemberType NoteProperty -Name 'MessageForwardingSize' -Value 2 -PassThru -Force
                                } -PassThru -Force
                        } -PassThru -Force
                }

                $mockConnectSql = {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType ScriptProperty -Name Endpoints -Value {
                            return @(
                                @{
                                    <#
                                        This executes the script block of $mockEndpointObject and returns
                                        a mocked Microsoft.SqlServer.Management.Smo.Endpoint
                                    #>
                                    'SSBR' =  & $mockEndpointObject
                                }
                            )
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            Context 'When the endpoint should be absent' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'MissingEndpoint'
                        $mockGetTargetResourceParameters.EndpointType = 'ServiceBroker'
                    }
                }

                It 'Should have property Ensure set to absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0


                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.EndpointType | Should -Be $mockGetTargetResourceParameters.EndpointType
                    }
                }

                It 'Should return the correct values in the rest of properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.EndpointName | Should -Be ''
                        $result.Port | Should -Be ''
                        $result.IpAddress | Should -Be ''
                        $result.Owner | Should -Be ''
                        $result.State | Should -BeNullOrEmpty
                        $result.IsMessageForwardingEnabled | Should -BeNullOrEmpty
                        $result.MessageForwardingSize | Should -BeNullOrEmpty
                    }
                }

                It 'Should call the mock function Connect-SQL' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the endpoint should be present' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'SSBR'
                        $mockGetTargetResourceParameters.EndpointType = 'ServiceBroker'
                    }
                }

                It 'Should have property Ensure set to present' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.EndpointType | Should -Be $mockGetTargetResourceParameters.EndpointType
                    }
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.EndpointName | Should -Be 'SSBR'
                        $result.Port | Should -Be 5023
                        $result.IpAddress | Should -Be '192.168.0.20'
                        $result.Owner | Should -Be 'COMPANY\OtherAcct'
                        $result.State | Should -Be 'Started'
                        $result.IsMessageForwardingEnabled | Should -BeTrue
                        $result.MessageForwardingSize | Should -Be 2
                    }
                }

                It 'Should call the mock function Connect-SQL' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }

            Context 'When endpoint exist but with wrong endpoint type' {
                BeforeEach {
                    InModuleScope -ScriptBlock {
                        $mockGetTargetResourceParameters.EndpointName = 'SSBR'
                        $mockGetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    }
                }

                It 'Should throw the correct error' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockErrorMessage = $script:localizedData.EndpointFoundButWrongType -f $mockGetTargetResourceParameters.EndpointName, 'ServiceBroker', 'DatabaseMirroring'

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }
                }
            }
        }
    }

    Context 'When Connect-SQL returns nothing' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                return $null
            }
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                $mockGetTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                $mockGetTargetResourceParameters.EndpointType = 'DatabaseMirroring'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.NotConnectedToInstance -f $mockGetTargetResourceParameters.ServerName, $mockGetTargetResourceParameters.InstanceName

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}

Describe 'DSC_SqlEndpoint\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When using a Database Mirroring endpoint' {
            Context 'When the endpoint should be absent' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'DatabaseMirroring'
                            Ensure                     = 'Absent'
                            EndpointName               = ''
                            Port                       = ''
                            IpAddress                  = ''
                            Owner                      = ''
                            State                      = $null
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.Ensure = 'Absent'
                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }

            Context 'When the endpoint should be present' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'DatabaseMirroring'
                            Ensure                     = 'Present'
                            EndpointName               = 'DefaultEndpointMirror'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }
        }

        Context 'When using a Service Broker endpoint' {
            Context 'When the endpoint should be absent' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'ServiceBroker'
                            Ensure                     = 'Absent'
                            EndpointName               = ''
                            Port                       = ''
                            IpAddress                  = ''
                            Owner                      = ''
                            State                      = $null
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.Ensure = 'Absent'
                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'ServiceBroker'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }

            Context 'When the endpoint should be present' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'ServiceBroker'
                            Ensure                     = 'Present'
                            EndpointName               = 'SSBR'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $true
                            MessageForwardingSize      = 2
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                        $mockTestTargetResourceParameters.EndpointType = 'ServiceBroker'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }
        }

        Context 'When endpoint is a <MockEndpointType>' -ForEach @(
            @{
                MockEndpointType = 'DatabaseMirroring'
            }
            @{
                MockEndpointType = 'ServiceBroker'
            }
        ) {
            Context 'When the parameter <MockParameterName> is in desired state' -ForEach @(
                @{
                    MockParameterName = 'IsMessageForwardingEnabled'
                    MockParameterValue = $true
                }
                @{
                    MockParameterName = 'MessageForwardingSize'
                    MockParameterValue = 2
                }
            ) {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        $mockGetTargetResourceResult = @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = $MockEndpointType
                            Ensure                     = 'Present'
                            EndpointName               = 'SSBR'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }

                        $mockGetTargetResourceResult[$MockParameterName] = $MockParameterValue

                        return $mockGetTargetResourceResult
                    }
                }

                It 'Should return $true' {
                    $_.MockEndpointType = $MockEndpointType

                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                        $mockTestTargetResourceParameters.$MockParameterName = $MockParameterValue
                        $mockTestTargetResourceParameters.EndpointType = $MockEndpointType

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }
            }
        }

        Context 'When the parameter <MockParameterName> is in desired state' -ForEach @(
            @{
                MockParameterName = 'Owner'
                MockParameterValue = 'sa'
            }
            @{
                MockParameterName = 'State'
                MockParameterValue = 'Started'
            }
            @{
                MockParameterName = 'Port'
                MockParameterValue = '5022'
            }
            @{
                MockParameterName = 'IpAddress'
                MockParameterValue = '0.0.0.0'
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName                 = 'localhost'
                        InstanceName               = 'MSSQLSERVER'
                        EndpointType               = 'DatabaseMirroring'
                        Ensure                     = 'Present'
                        EndpointName               = 'SSBR'
                        Port                       = '5022'
                        IpAddress                  = '0.0.0.0'
                        Owner                      = 'sa'
                        State                      = 'Started'
                        IsMessageForwardingEnabled = $false
                        MessageForwardingSize      = 1
                    }
                }
            }

            It 'Should return $true' {
                $_.MockEndpointType = $MockEndpointType

                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                    $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    $mockTestTargetResourceParameters.$MockParameterName = $MockParameterValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When using a Database Mirroring endpoint' {
            Context 'When the endpoint should be absent but it exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'DatabaseMirroring'
                            Ensure                     = 'Present'
                            EndpointName               = 'DefaultEndpointMirror'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.Ensure = 'Absent'
                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }

            Context 'When the endpoint should be present but it does not exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'DatabaseMirroring'
                            Ensure                     = 'Absent'
                            EndpointName               = ''
                            Port                       = ''
                            IpAddress                  = ''
                            Owner                      = ''
                            State                      = $null
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }
        }

        Context 'When using a Service Broker endpoint' {
            Context 'When the endpoint should be absent' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'ServiceBroker'
                            Ensure                     = 'Present'
                            EndpointName               = 'SSBR'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $true
                            MessageForwardingSize      = 2
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.Ensure = 'Absent'
                        $mockTestTargetResourceParameters.EndpointName = 'DefaultEndpointMirror'
                        $mockTestTargetResourceParameters.EndpointType = 'ServiceBroker'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }

            Context 'When the endpoint should be present' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = 'ServiceBroker'
                            Ensure                     = 'Absent'
                            EndpointName               = ''
                            Port                       = ''
                            IpAddress                  = ''
                            Owner                      = ''
                            State                      = $null
                            IsMessageForwardingEnabled = $null
                            MessageForwardingSize      = $null
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                        $mockTestTargetResourceParameters.EndpointType = 'ServiceBroker'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }
        }

        Context 'When endpoint is a <MockEndpointType>' -ForEach @(
            @{
                MockEndpointType = 'DatabaseMirroring'
            }
            @{
                MockEndpointType = 'ServiceBroker'
            }
        ) {
            Context 'When the parameter <MockParameterName> is not in desired state' -ForEach @(
                @{
                    MockParameterName = 'IsMessageForwardingEnabled'
                    MockParameterValue = $true
                }
                @{
                    MockParameterName = 'MessageForwardingSize'
                    MockParameterValue = 2
                }
            ) {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName                 = 'localhost'
                            InstanceName               = 'MSSQLSERVER'
                            EndpointType               = $MockEndpointType
                            Ensure                     = 'Present'
                            EndpointName               = 'SSBR'
                            Port                       = '5022'
                            IpAddress                  = '0.0.0.0'
                            Owner                      = 'sa'
                            State                      = 'Started'
                            IsMessageForwardingEnabled = $false
                            MessageForwardingSize      = 1
                        }
                    }
                }

                It 'Should return $false' {
                    $_.MockEndpointType = $MockEndpointType

                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                        $mockTestTargetResourceParameters.$MockParameterName = $MockParameterValue
                        $mockTestTargetResourceParameters.EndpointType = $MockEndpointType

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }
            }
        }

        Context 'When the parameter <MockParameterName> is not in desired state' -ForEach @(
            @{
                MockParameterName = 'Owner'
                MockParameterValue = 'NewOwner'
            }
            @{
                MockParameterName = 'State'
                MockParameterValue = 'Started'
            }
            @{
                MockParameterName = 'Port'
                MockParameterValue = '5023'
            }
            @{
                MockParameterName = 'IpAddress'
                MockParameterValue = '192.168.10.2'
            }
        ) {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName                 = 'localhost'
                        InstanceName               = 'MSSQLSERVER'
                        EndpointType               = 'DatabaseMirroring'
                        Ensure                     = 'Present'
                        EndpointName               = 'SSBR'
                        Port                       = '5022'
                        IpAddress                  = '0.0.0.0'
                        Owner                      = 'sa'
                        State                      = 'Stopped'
                        IsMessageForwardingEnabled = $false
                        MessageForwardingSize      = 1
                    }
                }
            }

            It 'Should return $false' {
                $_.MockEndpointType = $MockEndpointType

                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.EndpointName = 'SSBR'
                    $mockTestTargetResourceParameters.EndpointType = 'DatabaseMirroring'
                    $mockTestTargetResourceParameters.$MockParameterName = $MockParameterValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }
    }
}

#     Context 'When the system is not in the desired state' {
#         # Make sure the mock does not return the correct endpoint
#         $mockDynamicEndpointName = $mockOtherEndpointName

#         It 'Should return that desired state is absent when wanted desired state is to be Present (using default values)' {
#             $testParameters.Add('Ensure', 'Present')

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         It 'Should return that desired state is absent when wanted desired state is to be Present (setting all parameters)' {
#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Port', $mockEndpointListenerPort)
#             $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
#             $testParameters.Add('Owner', $mockEndpointOwner)

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Make sure the mock do return the correct endpoint
#         $mockDynamicEndpointName = $mockEndpointName

#         It 'Should return that desired state is absent when wanted desired state is to be Absent' {
#             $testParameters.Add('Ensure', 'Absent')

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Make sure the mock do return the correct endpoint, but does not return the correct endpoint listener port
#         $mockDynamicEndpointName = $mockEndpointName
#         $mockDynamicEndpointListenerPort = $mockOtherEndpointListenerPort

#         Context 'When listener port is not in desired state' {
#             It 'Should return that desired state is absent' {
#                 $testParameters.Add('Ensure', 'Present')
#                 $testParameters.Add('Port', $mockEndpointListenerPort)

#                 $result = Test-TargetResource @testParameters
#                 $result | Should -BeFalse

#                 Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             }
#         }

#         Context 'When State is not in desired state' {
#             It 'Should return that desired state is absent' {
#                 $testParameters.Add('Ensure', 'Present')
#                 $testParameters.Add('State', 'Stopped')

#                 $result = Test-TargetResource @testParameters
#                 $result | Should -BeFalse

#                 Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             }
#         }

#         # Make sure the mock do return the correct endpoint listener port
#         $mockDynamicEndpointListenerPort = $mockEndpointListenerPort

#         # Make sure the mock do return the correct endpoint, but does not return the correct endpoint listener IP address
#         $mockDynamicEndpointName = $mockEndpointName
#         $mockDynamicEndpointListenerIpAddress = $mockOtherEndpointListenerIpAddress

#         Context 'When listener IP address is not in desired state' {
#             It 'Should return that desired state is absent' {
#                 $testParameters.Add('Ensure', 'Present')
#                 $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)


#                 $result = Test-TargetResource @testParameters
#                 $result | Should -BeFalse

#                 Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             }
#         }

#         # Make sure the mock do return the correct endpoint listener IP address
#         $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress

#         # Make sure the mock do return the correct endpoint, but does not return the correct endpoint owner
#         $mockDynamicEndpointName = $mockEndpointName
#         $mockDynamicEndpointOwner = $mockOtherEndpointOwner

#         Context 'When listener Owner is not in desired state' {
#             It 'Should return that desired state is absent' {
#                 $testParameters.Add('Ensure', 'Present')
#                 $testParameters.Add('Owner', $mockEndpointOwner)


#                 $result = Test-TargetResource @testParameters
#                 $result | Should -BeFalse

#                 Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             }
#         }

#         # Make sure the mock return the endpoint with ServiceBroker endpoint type
#         $mockDynamicEndpointName = $mockSsbrEndpointName
#         $mockDynamicEndpointType = $mockSsbrEndpointType
#         $mockDynamicEndpointListenerPort = $mockSsbrEndpointListenerPort
#         $mockDynamicEndpointListenerIpAddress = $mockSsbrEndpointListenerIpAddress
#         $mockDynamicEndpointOwner = $mockSsbrEndpointOwner
#         $mockDynamicIsMessageForwardingEnabled = $false
#         $mockDynamicMessageForwardingSize = 1
#         $mockDynamicEndpointState = 'Started'

#         Context 'When ServiceBroker message forwarding is not in desired state' {
#             It 'Should return that desired state is absent' {
#                 $testParameters = $defaultSsbrParameters.Clone()
#                 $testParameters.Add('Ensure', 'Present')
#                 $testParameters.Add('IsMessageForwardingEnabled', $mockSsbrIsMessageForwardingEnabled)

#                 $result = Test-TargetResource @testParameters
#                 $result | Should -BeFalse

#                 Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             }
#         }

#         Context 'When ServiceBroker message forwarding size is not in desired state' {
#             It 'Should return that desired state is absent' {
#                 $testParameters = $defaultSsbrParameters.Clone()
#                 $testParameters.Add('Ensure', 'Present')
#                 $testParameters.Add('MessageForwardingSize', $mockSsbrMessageForwardingSize)


#                 $result = Test-TargetResource @testParameters
#                 $result | Should -BeFalse

#                 Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             }
#         }

#         # Make sure the mock return the endpoint with original endpoint type
#         $mockDynamicEndpointName = $mockEndpointName
#         $mockDynamicEndpointType = $mockEndpointType
#         $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
#         $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress
#         $mockDynamicEndpointOwner = $mockEndpointOwner
#         $mockDynamicIsMessageForwardingEnabled = $null
#         $mockDynamicMessageForwardingSize = $null
#         $mockDynamicEndpointState = 'Started'

#         # Make sure the mock do return the correct endpoint owner
#         $mockDynamicEndpointOwner = $mockEndpointOwner
#     }

#     $testParameters = $defaultParameters.Clone()

#     Context 'When the system is in the desired state' {
#         # Make sure the mock do return the correct endpoint
#         $mockDynamicEndpointName = $mockEndpointName

#         It 'Should return that desired state is present when wanted desired state is to be Present (using default values)' {
#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Make sure the mock does not return the correct endpoint
#         $mockDynamicEndpointName = $mockOtherEndpointName

#         It 'Should return that desired state is present when wanted desired state is to be Absent' {
#             $testParameters.Add('Ensure', 'Absent')

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }
#     }


#     Assert-VerifiableMock
# }

# Describe 'DSC_SqlEndpoint\Set-TargetResource' -Tag 'Set' {
#     BeforeEach {
#         $testParameters = $defaultParameters.Clone()

#         Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
#         Mock -CommandName New-Object -MockWith $mockNewObjectEndPoint -ParameterFilter $mockNewObjectEndPoint_ParameterFilter -Verifiable
#     }

#     Context 'When the system is not in the desired state' {
#         # Make sure the mock do return the correct endpoint
#         $mockDynamicEndpointName = $mockEndpointName

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         # Set what the expected endpoint name should be when Create() method is called.
#         $mockExpectedNameWhenCallingMethod = $mockEndpointName

#         It 'Should call the method Create when desired state is to be Present (using default values)' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Absent'
#                 }
#             } -Verifiable

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeTrue
#             $script:mockMethodStartRan | Should -BeTrue
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         # Set what the expected endpoint name should be when Create() method is called.
#         $mockExpectedNameWhenCallingMethod = $mockEndpointName

#         It 'Should call the method Create when desired state is to be Present (setting all parameters for Mirror endpoint)' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Absent'
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Port', $mockEndpointListenerPort)
#             $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
#             $testParameters.Add('Owner', $mockEndpointOwner)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeTrue
#             $script:mockMethodStartRan | Should -BeTrue
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false


#         $mockExpectedNameWhenCallingMethod = $mockSsbrEndpointName
#         $mockDynamicEndpointName = $mockSsbrEndpointName

#         It 'Should call the method Create when desired state is to be Present (setting parameters for ServiceBroker endpoint)' {
#             #Setting parameters here because of the beforeeach block.
#             $testParameters = $defaultSsbrParameters.Clone()

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Absent'
#                 }
#             } -Verifiable

#             $testParameters.EndpointName = $mockSsbrEndpointName
#             $testParameters.EndpointType = $mockSsbrEndpointType
#             $testParameters.Add('Ensure', 'Present')

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeTrue
#             $script:mockMethodStartRan | Should -BeTrue
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         It 'Should call the method Alter when desired state is to be Present (setting Port parameter for endpoint)' {
#             #Setting parameters here because of the beforeeach block.
#             $testParameters = $defaultSsbrParameters.Clone()

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                 }
#             } -Verifiable

#             $testParameters.EndpointName = $mockSsbrEndpointName
#             $testParameters.EndpointType = $mockSsbrEndpointType
#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Port', $mockSsbrEndpointListenerPort)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         It 'Should call the method Alter when desired state is to be Present (setting IpAddress parameter for endpoint)' {
#             #Setting parameters here because of the beforeeach block.
#             $testParameters = $defaultSsbrParameters.Clone()

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                 }
#             } -Verifiable

#             $testParameters.EndpointName = $mockSsbrEndpointName
#             $testParameters.EndpointType = $mockSsbrEndpointType
#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('IpAddress', $mockSsbrEndpointListenerIpAddress)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         It 'Should call the method Alter when desired state is to be Present (setting Owner parameter for endpoint)' {
#             #Setting parameters here because of the beforeeach block.
#             $testParameters = $defaultSsbrParameters.Clone()

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                 }
#             } -Verifiable
#             $testParameters.EndpointName = $mockSsbrEndpointName
#             $testParameters.EndpointType = $mockSsbrEndpointType
#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Owner', $mockSsbrEndpointOwner)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         It 'Should call the method Alter when desired state is to be Present (setting IsMessageForwardingEnabled parameter for ServiceBroker endpoint)' {
#             #Setting parameters here because of the beforeeach block.
#             $testParameters = $defaultSsbrParameters.Clone()

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     IsMessageForwardingEnabled = $False
#                 }
#             } -Verifiable
#             $testParameters.EndpointName = $mockSsbrEndpointName
#             $testParameters.EndpointType = $mockSsbrEndpointType
#             $testParameters.Add('IsMessageForwardingEnabled', $mockSsbrIsMessageForwardingEnabled)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         It 'Should call the method Alter when desired state is to be Present (setting MessageForwardingSize parameters for ServiceBroker endpoint)' {
#             #Setting parameters here because of the beforeeach block.
#             $testParameters = $defaultSsbrParameters.Clone()

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     IsMessageForwardingEnabled = $true
#                     MessageForwardingSize = 1
#                 }
#             } -Verifiable
#             $testParameters.EndpointName = $mockSsbrEndpointName
#             $testParameters.EndpointType = $mockSsbrEndpointType
#             $testParameters.Add('MessageForwardingSize', $mockSsbrMessageForwardingSize)

#             { Set-TargetResource @testParameters } | Should -Not -Throw

#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         # Set what the expected endpoint name should be when Drop() method is called.
#         $mockExpectedNameWhenCallingMethod = $mockEndpointName
#         $mockDynamicEndpointName = $mockEndpointName

#         It 'Should call the method Drop when desired state is to be Absent' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Absent')

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeTrue

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         # Set what the expected endpoint name should be when Alter() method is called. (Mirror)
#         $mockExpectedNameWhenCallingMethod = $mockEndpointName

#         It 'Should call Alter method when listener port is not in desired state' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     Port = $mockEndpointListenerPort
#                     IpAddress = $mockEndpointListenerIpAddress
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Port', $mockOtherEndpointListenerPort)
#             $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
#             $testParameters.Add('Owner', $mockEndpointOwner)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false


#         # Set what the expected endpoint name should be when Alter() method is called. (ServiceBroker)
#         $mockExpectedNameWhenCallingMethod = $mockSsbrEndpointName
#         $mockDynamicEndpointName = $mockSsbrEndpointName

#         It 'Should call the method Alter when desired state is to be Present (setting all parameters for ServiceBroker endpoint)' {
#             #Setting parameters here because of the beforeeach block.
#             $testParameters = $defaultSsbrParameters.Clone()

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     Port = $mockEndpointListenerPort
#                     IpAddress = $mockEndpointListenerIpAddress
#                     IsMessageForwardingEnabled = $false
#                     MessageForwardingSize = 1
#                 }
#             } -Verifiable

#             $testParameters.EndpointName = $mockSsbrEndpointName
#             $testParameters.EndpointType = $mockSsbrEndpointType
#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Port', $mockEndpointListenerPort)
#             $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
#             $testParameters.Add('Owner', $mockEndpointOwner)
#             $testParameters.Add('IsMessageForwardingEnabled', $mockSsbrIsMessageForwardingEnabled)
#             $testParameters.Add('MessageForwardingSize', $mockSsbrMessageForwardingSize)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false


#         # Set what the expected endpoint name should be when Alter() method is called.
#         $mockExpectedNameWhenCallingMethod = $mockEndpointName
#         $mockDynamicEndpointName = $mockEndpointName

#         It 'Should call Alter method when listener IP address is not in desired state' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     Port = $mockEndpointListenerPort
#                     IpAddress = $mockEndpointListenerIpAddress
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Port', $mockEndpointListenerPort)
#             $testParameters.Add('IpAddress', $mockOtherEndpointListenerIpAddress)
#             $testParameters.Add('Owner', $mockEndpointOwner)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         # Set what the expected endpoint name should be when Alter() method is called.
#         $mockExpectedNameWhenCallingMethod = $mockEndpointName

#         It 'Should call Alter method when Owner is not in desired state' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     Owner = $mockEndpointOwner
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Owner', $mockOtherEndpointOwner)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeTrue
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false
#         $script:mockMethodStopRan = $false
#         $script:mockMethodDisableRan = $false

#         $mockDynamicEndpointState = 'Stopped'

#         It 'Should call Start() method when State is not ''Started''' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     State = 'Stopped'
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('State', 'Started')

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeTrue
#             $script:mockMethodStopRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeFalse
#             $script:mockMethodDisableRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false
#         $script:mockMethodStopRan = $false
#         $script:mockMethodDisableRan = $false

#         $mockDynamicEndpointState = 'Running'

#         It 'Should call Stop() method when State is not ''Stopped''' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     State = 'Running'
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('State', 'Stopped')

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodStopRan | Should -BeTrue
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeFalse
#             $script:mockMethodDisableRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false
#         $script:mockMethodStopRan = $false
#         $script:mockMethodDisableRan = $false

#         $mockDynamicEndpointState = 'Running'

#         It 'Should call Disable() method when State is not ''Disabled''' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     State = 'Running'
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('State', 'Disabled')

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodStopRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeFalse
#             $script:mockMethodDisableRan | Should -BeTrue

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Make sure the mock does not return the correct endpoint
#         $mockDynamicEndpointName = $mockOtherEndpointName

#         Context 'When endpoint is missing when Ensure is set to Present' {
#             It 'Should throw the correct error' {
#                 Mock -CommandName Get-TargetResource -MockWith {
#                     return @{
#                         Ensure = 'Present'
#                     }
#                 } -Verifiable

#                 { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.EndpointNotFound -f $testParameters.EndpointName)
#             }
#         }

#         Context 'When endpoint is missing when Ensure is set to Absent' {
#             It 'Should throw the correct error' {
#                 Mock -CommandName Get-TargetResource -MockWith {
#                     return @{
#                         Ensure = 'Present'
#                     }
#                 } -Verifiable

#                 $testParameters.Add('Ensure', 'Absent')

#                 { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.EndpointNotFound -f $testParameters.EndpointName)
#             }
#         }

#         Context 'When Connect-SQL returns nothing' {
#             It 'Should throw the correct error' {
#                 Mock -CommandName Get-TargetResource -Verifiable
#                 Mock -CommandName Connect-SQL -MockWith {
#                     return $null
#                 }

#                 { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.NotConnectedToInstance -f $testParameters.ServerName, $testParameters.InstanceName)
#             }
#         }
#     }

#     Context 'When the system is in the desired state' {
#         # Make sure the mock do return the correct endpoint
#         $mockDynamicEndpointName = $mockEndpointName
#         $mockDynamicEndpointListenerPort = $mockEndpointListenerPort
#         $mockDynamicEndpointListenerIpAddress = $mockEndpointListenerIpAddress
#         $mockDynamicEndpointOwner = $mockEndpointOwner

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         It 'Should not call any methods when desired state is already Present' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                     Port = $mockEndpointListenerPort
#                     IpAddress = $mockEndpointListenerIpAddress
#                     Owner = $mockEndpointOwner
#                     IsMessageForwardingEnabled = $mockSsbrIsMessageForwardingEnabled
#                     MessageForwardingSize = $mockSsbrMessageForwardingSize
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Present')
#             $testParameters.Add('Port', $mockEndpointListenerPort)
#             $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
#             $testParameters.Add('Owner', $mockEndpointOwner)
#             $testParameters.Add('IsMessageForwardingEnabled', $mockSsbrIsMessageForwardingEnabled)
#             $testParameters.Add('MessageForwardingSize', $mockSsbrMessageForwardingSize)

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }

#         # Make sure the mock does not return the correct endpoint
#         $mockDynamicEndpointName = $mockOtherEndpointName

#         # Set all method call tests variables to $false
#         $script:mockMethodCreateRan = $false
#         $script:mockMethodStartRan = $false
#         $script:mockMethodAlterRan = $false
#         $script:mockMethodDropRan = $false

#         It 'Should not call any methods when desired state is already Absent' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Absent'
#                 }
#             } -Verifiable

#             $testParameters.Add('Ensure', 'Absent')

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodCreateRan | Should -BeFalse
#             $script:mockMethodStartRan | Should -BeFalse
#             $script:mockMethodAlterRan | Should -BeFalse
#             $script:mockMethodDropRan | Should -BeFalse

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#         }
#     }

#     # Make sure the mock do return the correct endpoint
#     $mockDynamicEndpointName = $mockEndpointName
#     $mockExpectedNameWhenCallingMethod = $mockOtherEndpointName

#     Context 'Testing mocks' {
#         Context 'When mocked Create() method is called with the wrong endpoint name' {
#             It 'Should throw the correct error' {
#                 Mock -CommandName Get-TargetResource -MockWith {
#                     return @{
#                         Ensure = 'Absent'
#                     }
#                 } -Verifiable

#                 { Set-TargetResource @testParameters } | Should -Throw 'Exception calling "Create" with "0" argument(s): "Called mocked Create() method on and endpoint with wrong name. Expected ''UnknownEndpoint''. But was ''DefaultEndpointMirror''."'
#             }
#         }

#         Context 'When mocked Drop() method is called with the wrong endpoint name' {
#             It 'Should throw the correct error' {
#                 Mock -CommandName Get-TargetResource -MockWith {
#                     return @{
#                         Ensure = 'Present'
#                     }
#                 } -Verifiable

#                 $testParameters.Add('Ensure', 'Absent')

#                 { Set-TargetResource @testParameters } | Should -Throw 'Exception calling "Drop" with "0" argument(s): "Called mocked Drop() method on and endpoint with wrong name. Expected ''UnknownEndpoint''. But was ''DefaultEndpointMirror''."'
#             }
#         }

#         Context 'When mocked Alter() method is called with the wrong endpoint name' {
#             It 'Should throw the correct error' {
#                 Mock -CommandName Get-TargetResource -MockWith {
#                     return @{
#                         Ensure = 'Present'
#                         Port = $mockEndpointListenerPort
#                         IpAddress = $mockEndpointListenerIpAddress
#                     }
#                 } -Verifiable

#                 $testParameters.Add('Ensure', 'Present')
#                 $testParameters.Add('Port', $mockOtherEndpointListenerPort)
#                 $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
#                 $testParameters.Add('Owner', $mockEndpointOwner)

#                 { Set-TargetResource @testParameters } | Should -Throw 'Exception calling "Alter" with "0" argument(s): "Called mocked Alter() method on and endpoint with wrong name. Expected ''UnknownEndpoint''. But was ''DefaultEndpointMirror''."'
#             }
#         }
#     }

#     Assert-VerifiableMock
# }
