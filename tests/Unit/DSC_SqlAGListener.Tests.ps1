<#
    .SYNOPSIS
        Unit test for DSC_SqlAGListener DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
# Suppressing this rule because tests are mocking passwords in clear text.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 3)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscResourceName = 'DSC_SqlAGListener'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

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

# $mockDynamicAvailabilityGroup = 'AG01'
# $mockDynamicListenerName = 'AGListener'
# $mockDynamicPortNumber = 5031
# $mockDynamicIsDhcp = $true
# $script:mockMethodDropRan = $false

# $mockConnectSql = {
#     return New-Object -TypeName Object |
#         Add-Member -MemberType ScriptProperty -Name AvailabilityGroups -Value {
#         return @(
#             @{
#                 $mockDynamicAvailabilityGroup = New-Object -TypeName Object |
#                     Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListeners -Value {
#                     @(
#                         @{
#                             $mockDynamicListenerName = New-Object -TypeName Object |
#                                 Add-Member -MemberType NoteProperty -Name PortNumber -Value $mockDynamicPortNumber -PassThru |
#                                 Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListenerIPAddresses -Value {
#                                 return @(
#                                     # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
#                                     (New-Object -TypeName Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
#                                             Add-Member -MemberType NoteProperty -Name IsDHCP -Value $mockDynamicIsDhcp -PassThru |
#                                             Add-Member -MemberType NoteProperty -Name IPAddress -Value '192.168.0.1' -PassThru |
#                                             Add-Member -MemberType NoteProperty -Name SubnetMask -Value '255.255.255.0' -PassThru
#                                     )
#                                 )
#                             } -PassThru |
#                                 Add-Member -MemberType ScriptMethod -Name Drop -Value {
#                                 $script:mockMethodDropRan = $true
#                             } -PassThru -Force
#                         }
#                     )
#                 } -PassThru -Force
#             }
#         )
#     } -PassThru -Force
# }

Describe 'SqlAGListener\Get-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName      = 'MSSQLSERVER'
                ServerName        = 'localhost'
                Name              = 'AGListener'
                AvailabilityGroup = 'AG01'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }


    Context 'When the system is in the desired state' {
        Context 'When the listener is absent' {
            BeforeAll {
                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener
            }

            It 'Should return the desired state as absent' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.AvailabilityGroup | Should -Be $mockGetTargetResourceParameters.AvailabilityGroup
                }
            }

            It 'Should not return any IP addresses' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IpAddress | Should -BeNullOrEmpty
                }
            }

            It 'Should not return port' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Port | Should -Be 0
                }
            }

            It 'Should return that DHCP is not used' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.DHCP | Should -BeFalse
                }
            }

            It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }

        Context 'When listener is present and not using DHCP' {
            BeforeAll {
                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    return @{
                        PortNumber = 5031
                        AvailabilityGroupListenerIPAddresses = @{
                            IsDHCP  = $false
                            IPAddress = '192.168.0.1'
                            SubnetMask = '255.255.255.0'
                        }
                    }
                }
            }

            It 'Should return the desired state as present' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.AvailabilityGroup | Should -Be $mockGetTargetResourceParameters.AvailabilityGroup
                }
            }

            It 'Should return correct IP address' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IpAddress | Should -Be '192.168.0.1/255.255.255.0'
                }
            }

            It 'Should return correct port' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Port | Should -Be 5031
                }
            }

            It 'Should return that DHCP is not used' {
                $mockDynamicIsDhcp = $false

                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.DHCP | Should -BeFalse
                }
            }

            It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }

        Context 'When listener is present and using DHCP' {
            BeforeAll {
                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    return @{
                        PortNumber = 5031
                        AvailabilityGroupListenerIPAddresses = @{
                            IsDHCP  = $true
                            IPAddress = '192.168.0.1'
                            SubnetMask = '255.255.255.0'
                        }
                    }
                }
            }

            It 'Should return the desired state as present' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.AvailabilityGroup | Should -Be $mockGetTargetResourceParameters.AvailabilityGroup
                }
            }

            It 'Should return correct IP address' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IpAddress | Should -Be '192.168.0.1/255.255.255.0'
                }
            }

            It 'Should return correct port' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Port | Should -Be 5031
                }
            }

            It 'Should return that DHCP is not used' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.DHCP | Should -BeTrue
                }
            }

            It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }

        Context 'When listener does not have subnet mask' {
            BeforeAll {
                Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
                    return @{
                        PortNumber = 5031
                        AvailabilityGroupListenerIPAddresses = @{
                            IsDHCP  = $false
                            IPAddress = '192.168.0.1'
                            SubnetMask = ''
                        }
                    }
                }
            }

            It 'Should return the desired state as present' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.AvailabilityGroup | Should -Be $mockGetTargetResourceParameters.AvailabilityGroup
                }
            }

            It 'Should return correct IP address' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IpAddress | Should -Be '192.168.0.1'
                }
            }

            It 'Should return correct port' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Port | Should -Be 5031
                }
            }

            It 'Should return that DHCP is not used' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.DHCP | Should -BeFalse
                }
            }

            It 'Should call the mock function Get-SQLAlwaysOnAvailabilityGroupListener' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
            }
        }
    }
}

# Describe 'SqlAGListener\Test-TargetResource' {
#     BeforeEach {
#         $testParameters = $defaultParameters.Clone()
#     }

#     Context 'When the system is not in the desired state (for static IP)' {
#         It 'Should return that desired state is absent when wanted desired state is to be Present' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $false

#             Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
#             # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType NoteProperty -Name PortNumber -Value 5030 -PassThru |
#                 Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListenerIPAddresses -Value {
#                 return @(
#                     # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
#                     (New-Object -TypeName Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
#                             Add-Member -MemberType NoteProperty -Name IsDHCP -Value $false -PassThru |
#                             Add-Member -MemberType NoteProperty -Name IPAddress -Value '192.168.0.1' -PassThru |
#                             Add-Member -MemberType NoteProperty -Name SubnetMask -Value '255.255.255.0' -PassThru
#                     )
#                 )
#             } -PassThru -Force
#         }

#         It 'Should return that desired state is absent when wanted desired state is to be Absent' {
#             $testParameters['Ensure'] = 'Absent'

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         It 'Should return that desired state is absent when IP address is different' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $false

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         It 'Should return that desired state is absent when DHCP is absent but should be present' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $true

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         It 'Should return that desired state is absent when DHCP is the only set parameter' {
#             $testParameters['DHCP'] = $true

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
#             # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType NoteProperty -Name PortNumber -Value 5555 -PassThru |
#                 Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListenerIPAddresses -Value {
#                 return @(
#                     # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
#                     (New-Object -TypeName Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
#                             Add-Member -MemberType NoteProperty -Name IsDHCP -Value $false -PassThru |
#                             Add-Member -MemberType NoteProperty -Name IPAddress -Value '192.168.0.1' -PassThru |
#                             Add-Member -MemberType NoteProperty -Name SubnetMask -Value '255.255.255.0' -PassThru
#                     )
#                 )
#             } -PassThru -Force
#         }

#         It 'Should return that desired state is absent when port is different' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $false

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When the system is not in the desired state (for DHCP)' {
#         Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
#             # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType NoteProperty -Name PortNumber -Value 5030 -PassThru |
#                 Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListenerIPAddresses -Value {
#                 return @(
#                     # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
#                     (New-Object -TypeName Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
#                             Add-Member -MemberType NoteProperty -Name IsDHCP -Value $true -PassThru |
#                             Add-Member -MemberType NoteProperty -Name IPAddress -Value '192.168.0.1' -PassThru |
#                             Add-Member -MemberType NoteProperty -Name SubnetMask -Value '255.255.255.0' -PassThru
#                     )
#                 )
#             } -PassThru -Force
#         }

#         It 'Should return that desired state is absent when DHCP is present but should be absent' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.100/255.255.255.0'
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $false

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         It 'Should return that desired state is absent when IP address is the only set parameter' {
#             $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
#             # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType NoteProperty -Name PortNumber -Value 5555 -PassThru |
#                 Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListenerIPAddresses -Value {
#                 return @(
#                     # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
#                     (New-Object -TypeName Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
#                             Add-Member -MemberType NoteProperty -Name IsDHCP -Value $true -PassThru |
#                             Add-Member -MemberType NoteProperty -Name IPAddress -Value '192.168.0.1' -PassThru |
#                             Add-Member -MemberType NoteProperty -Name SubnetMask -Value '255.255.255.0' -PassThru
#                     )
#                 )
#             } -PassThru -Force
#         }

#         It 'Should return that desired state is absent when port is the only set parameter' {
#             $testParameters['Port'] = 5030

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeFalse

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When the system is in the desired state (for static IP)' {
#         It 'Should return that desired state is present when wanted desired state is to be Absent' {
#             $testParameters['Ensure'] = 'Absent'
#             $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $false

#             Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
#             # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType NoteProperty -Name PortNumber -Value 5030 -PassThru |
#                 Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListenerIPAddresses -Value {
#                 return @(
#                     # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
#                     (New-Object -TypeName Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
#                             Add-Member -MemberType NoteProperty -Name IsDHCP -Value $false -PassThru |
#                             Add-Member -MemberType NoteProperty -Name IPAddress -Value '192.168.0.1' -PassThru |
#                             Add-Member -MemberType NoteProperty -Name SubnetMask -Value '255.255.255.0' -PassThru
#                     ),
#                     # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
#                     (New-Object -TypeName Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
#                             Add-Member -MemberType NoteProperty -Name IsDHCP -Value $false -PassThru |
#                             Add-Member -MemberType NoteProperty -Name IPAddress -Value 'f00::ba12' -PassThru
#                     )
#                 )
#             } -PassThru -Force
#         }

#         It 'Should return that desired state is present when wanted desired state is to be Present, without DHCP' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = @('192.168.0.1/255.255.255.0', 'f00::ba12')
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $false

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         It 'Should return that desired state is present when IP address is the only set parameter' {
#             $testParameters['IpAddress'] = @('192.168.0.1/255.255.255.0', 'f00::ba12')

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         It 'Should return that desired state is present when port is the only set parameter' {
#             $testParameters['Port'] = 5030

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When the system is in the desired state (for DHCP)' {
#         Mock -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -MockWith {
#             # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListener
#             return New-Object -TypeName Object |
#                 Add-Member -MemberType NoteProperty -Name PortNumber -Value 5030 -PassThru |
#                 Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListenerIPAddresses -Value {
#                 return @(
#                     # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
#                     (New-Object -TypeName Object |    # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
#                             Add-Member -MemberType NoteProperty -Name IsDHCP -Value $true -PassThru |
#                             Add-Member -MemberType NoteProperty -Name IPAddress -Value '192.168.0.1' -PassThru |
#                             Add-Member -MemberType NoteProperty -Name SubnetMask -Value '255.255.255.0' -PassThru
#                     )
#                 )
#             } -PassThru -Force
#         }

#         It 'Should return that desired state is present when wanted desired state is to be Present, with DHCP' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $true

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }

#         It 'Should return that desired state is present when DHCP is the only set parameter' {
#             $testParameters['DHCP'] = $true

#             $result = Test-TargetResource @testParameters
#             $result | Should -BeTrue

#             Should -Invoke -CommandName Get-SQLAlwaysOnAvailabilityGroupListener -Exactly -Times 1 -Scope It
#         }
#     }

#     Context 'When Get-TargetResource returns $null' {
#         It 'Should throw the correct error' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return $null
#             }

#             { Test-TargetResource @testParameters } | Should -Throw $script:localizedData.UnexpectedErrorFromGet
#         }
#     }

#     Assert-VerifiableMock
# }

# Describe 'SqlAGListener\Set-TargetResource' {
#     BeforeEach {
#         $testParameters = $defaultParameters.Clone()

#         Mock -CommandName Connect-SQL -MockWith $mockConnectSql
#         Mock -CommandName New-SqlAvailabilityGroupListener
#         Mock -CommandName Set-SqlAvailabilityGroupListener
#         Mock -CommandName Add-SqlAvailabilityGroupListenerStaticIp
#     }

#     Context 'When the system is not in the desired state' {
#         $mockDynamicListenerName = 'UnknownListener'

#         It 'Should call the cmdlet New-SqlAvailabilityGroupListener when system is not in desired state, when using Static IP' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.10.45/255.255.252.0'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $false

#             { Set-TargetResource @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicListenerName = 'UnknownListener'

#         It 'Should call the cmdlet New-SqlAvailabilityGroupListener when system is not in desired state, when using DHCP and specific DhcpSubnet' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.10.1/255.255.252.0'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $true

#             { Set-TargetResource @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicListenerName = 'UnknownListener'

#         It 'Should call the cmdlet New-SqlAvailabilityGroupListener when system is not in desired state, when using DHCP and server default DhcpSubnet' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $true

#             { Set-TargetResource @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicIsDhcp = $false
#         $mockDynamicListenerName = 'AGListener'
#         $mockDynamicPortNumber = 5031

#         It 'Should throw when trying to change an existing IP address' {
#             $testParameters['IpAddress'] = '10.0.0.1/255.255.252.0'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $false

#             { Set-TargetResource @testParameters } | Should -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicIsDhcp = $false
#         $mockDynamicListenerName = 'AGListener'
#         $mockDynamicPortNumber = 5031

#         It 'Should throw when trying to change from static IP to DHCP' {
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $true

#             { Set-TargetResource @testParameters } | Should -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicIsDhcp = $false
#         $mockDynamicListenerName = 'AGListener'
#         $mockDynamicPortNumber = 5031

#         It 'Should call the cmdlet Add-SqlAvailabilityGroupListenerStaticIp, when adding another IP address, and system is not in desired state' {
#             $testParameters['IpAddress'] = @('192.168.0.1/255.255.255.0', '10.0.0.1/255.255.252.0')
#             $testParameters['Port'] = 5030
#             $testParameters['DHCP'] = $false

#             { Set-TargetResource @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 1 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 1 -Scope It
#         }

#         $mockDynamicIsDhcp = $false
#         $mockDynamicListenerName = 'AGListener'
#         $mockDynamicPortNumber = 5031

#         It 'Should not call the any cmdlet *-SqlAvailability* when system is in desired state' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $false

#             { Set-TargetResource @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicListenerName = 'AGListener'
#         $script:mockMethodDropRan = $false # This is set to $true when Drop() method is called. make sure we start the test with $false.

#         It 'Should not call the any cmdlet *-SqlAvailability* or the the Drop() method when system is in desired state and ensure is set to ''Absent''' {
#             $testParameters['Ensure'] = 'Absent'

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodDropRan | Should -BeTrue # Should have made one call to the Drop() method.

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicAvailabilityGroup = 'UnknownAG'
#         $mockDynamicListenerName = 'UnknownListener'

#         It 'Should throw the correct error when availability group is not found and Ensure is set to ''Present''' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $false

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Absent'
#                 }
#             }

#             { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.AvailabilityGroupNotFound -f $testParameters.AvailabilityGroup, $testParameters.InstanceName)
#         }

#         It 'Should throw the correct error when availability group is not found and Ensure is set to ''Absent''' {
#             $testParameters['Ensure'] = 'Absent'

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure = 'Present'
#                 }
#             }

#             { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.AvailabilityGroupNotFound -f $testParameters.AvailabilityGroup, $testParameters.InstanceName)
#         }

#         $mockDynamicAvailabilityGroup = 'AG01'
#         $mockDynamicListenerName = 'UnknownListener'

#         It 'Should throw the correct error when listener is not found and Ensure is set to ''Absent''' {
#             $testParameters['Ensure'] = 'Absent'

#             { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.AvailabilityGroupListenerNotFound -f $testParameters.AvailabilityGroup, $testParameters.InstanceName)
#         }

#         It 'Should throw the correct error when listener is not found and Ensure is set to ''Present''' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $false

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure            = 'Present'
#                     Name              = 'UnknownListener'
#                     AvailabilityGroup = 'AG01'
#                     IpAddress         = '192.168.0.1/255.255.255.0'
#                     Port              = 5031
#                     DHCP              = $false
#                 }
#             }

#             { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.AvailabilityGroupListenerNotFound -f $testParameters.AvailabilityGroup, $testParameters.InstanceName)
#         }

#         $mockDynamicAvailabilityGroup = 'UnknownAG'
#         $mockDynamicListenerName = 'UnknownListener'

#         It 'Should throw the correct error when availability group is not found and Ensure is set to ''Present''' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5031
#             $testParameters['DHCP'] = $false

#             Mock -CommandName Get-TargetResource -MockWith {
#                 return @{
#                     Ensure            = 'Present'
#                     Name              = 'UnknownListener'
#                     AvailabilityGroup = 'UnknownAG'
#                     IpAddress         = '192.168.0.1/255.255.255.0'
#                     Port              = 5031
#                     DHCP              = $false
#                 }
#             }

#             { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.AvailabilityGroupNotFound -f $testParameters.AvailabilityGroup, $testParameters.InstanceName)
#         }
#     }

#     Context 'When the system is in the desired state' {
#         $mockDynamicIsDhcp = $false
#         $mockDynamicListenerName = 'AGListener'
#         $mockDynamicPortNumber = 5031

#         It 'Should not call the any cmdlet *-SqlAvailability* when system is in desired state' {
#             $testParameters['Ensure'] = 'Present'
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5031

#             { Set-TargetResource @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicIsDhcp = $false
#         $mockDynamicListenerName = 'AGListener'
#         $mockDynamicPortNumber = 5031

#         It 'Should not call the any cmdlet *-SqlAvailability* when system is in desired state (without ensure parameter)' {
#             $testParameters['IpAddress'] = '192.168.0.1/255.255.255.0'
#             $testParameters['Port'] = 5031

#             { Set-TargetResource @testParameters } | Should -Not -Throw

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It
#         }

#         $mockDynamicListenerName = 'UnknownListener'
#         $script:mockMethodDropRan = $false # This is set to $true when Drop() method is called. make sure we start the test with $false.

#         It 'Should not call the any cmdlet *-SqlAvailability* or the the Drop() method when system is in desired state and ensure is set to ''Absent''' {
#             $testParameters['Ensure'] = 'Absent'

#             { Set-TargetResource @testParameters } | Should -Not -Throw
#             $script:mockMethodDropRan | Should -BeFalse # Should not have called Drop() method.

#             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
#             Should -Invoke -CommandName New-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Set-SqlAvailabilityGroupListener -Exactly -Times 0 -Scope It
#             Should -Invoke -CommandName Add-SqlAvailabilityGroupListenerStaticIp -Exactly -Times 0 -Scope It

#         }
#     }

#     Context 'When Get-TargetResource returns $null' {
#         It 'Should throw the correct error' {
#             Mock -CommandName Get-TargetResource -MockWith {
#                 return $null
#             }

#             { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.UnexpectedErrorFromGet
#         }
#     }

#     Assert-VerifiableMock
# }

Describe 'SqlAGListener\Get-SQLAlwaysOnAvailabilityGroupListener' {
    BeforeAll {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name AvailabilityGroups -Value {
                return @(
                    @{
                        'AG01' = New-Object -TypeName Object |
                            Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListeners -Value {
                            @(
                                @{
                                    'AGListener' = New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name PortNumber -Value 5031 -PassThru |
                                        Add-Member -MemberType ScriptProperty -Name AvailabilityGroupListenerIPAddresses -Value {
                                            return @(
                                                # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddressCollection
                                                (New-Object -TypeName Object | # TypeName: Microsoft.SqlServer.Management.Smo.AvailabilityGroupListenerIPAddress
                                                        Add-Member -MemberType NoteProperty -Name IsDHCP -Value $true -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name IPAddress -Value '192.168.0.1' -PassThru |
                                                        Add-Member -MemberType NoteProperty -Name SubnetMask -Value '255.255.255.0' -PassThru
                                                )
                                            )
                                        } -PassThru -Force
                                }
                            )
                        } -PassThru -Force
                    }
                )
            } -PassThru -Force
        }
    }

    Context 'When the Availability Group exist' {
        It 'Should return the correct values for each property' {
            InModuleScope -ScriptBlock {
                $mockGetSQLAlwaysOnAvailabilityGroupListenerParameters = @{
                    Name              = 'AGListener'
                    AvailabilityGroup = 'AG01'
                    InstanceName      = 'MSSQLSERVER'
                    ServerName        = 'localhost'
                }

                $result = Get-SQLAlwaysOnAvailabilityGroupListener @mockGetSQLAlwaysOnAvailabilityGroupListenerParameters

                $result.PortNumber | Should -Be 5031
                $result.AvailabilityGroupListenerIPAddresses.IsDHCP | Should -BeTrue
                $result.AvailabilityGroupListenerIPAddresses.IPAddress | Should -Be '192.168.0.1'
                $result.AvailabilityGroupListenerIPAddresses.SubnetMask | Should -Be '255.255.255.0'
            }
        }
    }

    Context 'When the Availability Group Listener does not exist' {
        It 'Should return the correct values for each property' {
            InModuleScope -ScriptBlock {
                $mockGetSQLAlwaysOnAvailabilityGroupListenerParameters = @{
                    Name              = 'UnknownListener'
                    AvailabilityGroup = 'AG01'
                    InstanceName      = 'MSSQLSERVER'
                    ServerName        = 'localhost'
                }

                $result = Get-SQLAlwaysOnAvailabilityGroupListener @mockGetSQLAlwaysOnAvailabilityGroupListenerParameters

                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the Availability Group does not exist' {
        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                $mockGetSQLAlwaysOnAvailabilityGroupListenerParameters = @{
                    Name              = 'AGListener'
                    AvailabilityGroup = 'UnknownAG'
                    InstanceName      = 'MSSQLSERVER'
                    ServerName        = 'localhost'
                }

                $mockErrorMessage = $script:localizedData.AvailabilityGroupNotFound -f 'UnknownAG', 'MSSQLSERVER'

                { $result = Get-SQLAlwaysOnAvailabilityGroupListener @mockGetSQLAlwaysOnAvailabilityGroupListenerParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}
