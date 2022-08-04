<#
    .SYNOPSIS
        Unit test for DSC_SqlAudit DSC resource.
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
                # Redirect all streams to $null, except the error stream (stream 2)
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
    $script:dscResourceName = 'DSC_SqlServerAudit'

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

Describe 'SqlAudit\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name = 'FileAudit'
                # TODO: Remove this
                Verbose = $true
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the audit is present' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @(
                        (
                            New-Object -TypeName Object |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Audits' -Value {
                                    return @{
                                        # TODO: get the correct values for this.
                                        'FileAudit' = New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'FileAudit' -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'DestinationType' -Value 'File' -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'FilePath' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'Filter' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'MaximumFiles' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'MaximumFileSize' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'MaximumFileSizeUnit' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'MaximumRolloverFiles' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'OnFailure' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'QueueDelay' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'ReserveDiskSpace' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'Enabled' -Value $true -PassThru -Force
                                    }
                                } -PassThru -Force
                        )
                    )
                }
            }

            It 'Should call the mock function Connect-SQL' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the desired state as present' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Present'
                    $result.Enabled | Should -BeTrue
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                }
            }

            It 'Should return the correct value for the rest of the properties' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    # TODO: get the correct values for this.
                    $result.DestinationType | Should -Be 'File'
                    $result.FilePath | Should -BeNullOrEmpty
                    $result.Filter | Should -BeNullOrEmpty
                    $result.MaximumFiles | Should -BeNullOrEmpty
                    $result.MaximumFileSize | Should -BeNullOrEmpty
                    $result.MaximumFileSizeUnit | Should -BeNullOrEmpty
                    $result.MaximumRolloverFiles | Should -BeNullOrEmpty
                    $result.OnFailure | Should -BeNullOrEmpty
                    $result.QueueDelay | Should -BeNullOrEmpty
                    $result.ReserveDiskSpace | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When the audit is absent' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    return @(
                        (
                            New-Object -TypeName Object |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Audits' -Value {
                                    return @{
                                        'FileAudit' = New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'FileAudit' -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'DestinationType' -Value 'File' -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'FilePath' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'Filter' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'MaximumFiles' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'MaximumFileSize' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'MaximumFileSizeUnit' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'MaximumRolloverFiles' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'OnFailure' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'QueueDelay' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'ReserveDiskSpace' -Value $null -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'Enabled' -Value $true -PassThru -Force
                                    }
                                } -PassThru -Force
                        )
                    )
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters.Name = 'UnknownName'
                }
            }

            It 'Should call the mock function Connect-SQL' {
                InModuleScope -ScriptBlock {
                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }

            It 'Should return the desired state as present' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                    $result.Enabled | Should -BeFalse
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                }
            }

            It 'Should return the correct value for the rest of the properties' {
                InModuleScope -ScriptBlock {
                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    # TODO: get the correct values for this.
                    $result.DestinationType | Should -BeNullOrEmpty
                    $result.FilePath | Should -BeNullOrEmpty
                    $result.Filter | Should -BeNullOrEmpty
                    $result.MaximumFiles | Should -BeNullOrEmpty
                    $result.MaximumFileSize | Should -BeNullOrEmpty
                    $result.MaximumFileSizeUnit | Should -BeNullOrEmpty
                    $result.MaximumRolloverFiles | Should -BeNullOrEmpty
                    $result.OnFailure | Should -BeNullOrEmpty
                    $result.QueueDelay | Should -BeNullOrEmpty
                    $result.ReserveDiskSpace | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'SqlAudit\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name = 'FileAudit'
                # TODO: Remove this
                Verbose = $true
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the audit is present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure               = 'Present'
                        Name                 = 'FileAudit'
                        ServerName           = 'localhost'
                        InstanceName         = 'MSSQLSERVER'
                        DestinationType      = 'File'
                        FilePath             = $null
                        Filter               = $null
                        MaximumFiles         = $null
                        MaximumFileSize      = $null
                        MaximumFileSizeUnit  = $null
                        MaximumRolloverFiles = $null
                        OnFailure            = $null
                        QueueDelay           = $null
                        ReserveDiskSpace     = $null
                        Enabled              = $false
                    }
                }
            }

            It 'Should return the property <MockPropertyName> as in desired state' -ForEach @(
                # TODO: add all properties
                @{
                    MockPropertyName = 'DestinationType'
                    MockExpectedValue = 'File'
                }
            ) {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $mockTestTargetResourceParameters.$MockPropertyName = $MockExpectedValue

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When the audit is absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure               = 'Absent'
                        Name                 = 'FileAudit'
                        ServerName           = 'localhost'
                        InstanceName         = 'MSSQLSERVER'
                        DestinationType      = $null
                        FilePath             = $null
                        Filter               = $null
                        MaximumFiles         = $null
                        MaximumFileSize      = $null
                        MaximumFileSizeUnit  = $null
                        MaximumRolloverFiles = $null
                        OnFailure            = $null
                        QueueDelay           = $null
                        ReserveDiskSpace     = $null
                        Enabled              = $false
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockTestTargetResourceParameters.Ensure = 'Absent'
                }
            }

            It 'Should return the property <MockPropertyName> as in desired state' {
                InModuleScope -ScriptBlock {
                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }
    }
}

    # $mockServerName = 'SERVER01'
    # $mockInstanceName = 'INSTANCE'
    # $mockAuditName = 'FileAudit'

    # $mockAuditObject = New-Object -TypeName Object |
    #     Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAuditName -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'DestinationType' -Value 'File' -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'FilePath' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'Filter' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'MaximumFiles' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'MaximumFileSize' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'MaximumFileSizeUnit' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'MaximumRolloverFiles' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'OnFailure' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'QueueDelay' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'ReserveDiskSpace' -Value $null -PassThru |
    #     Add-Member -MemberType NoteProperty -Name 'Enabled' -Value $true -PassThru -Force

    # $mockConnectSql = {
    #     return New-Object -TypeName Object |
    #         Add-Member -MemberType ScriptProperty -Name 'Audits' -Value {
    #             return @(
    #                 @{
    #                     $mockAuditName =  $mockAuditObject
    #                 }
    #             )
    #         } -PassThru -Force
    # }

    # $defaultParameters = @{
    #     InstanceName = $mockInstanceName
    #     ServerName = $mockServerName
    #     Name = $mockAuditName
    #     Verbose = $true
    # }

    #     BeforeAll {
    #         Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
    #     }

    #     Context 'When the system is not in the desired state' {
    #         BeforeEach {
    #             $testParameters = $defaultParameters.Clone()
    #             $testParameters.Name = 'UnknownAudit'
    #         }

    #         It 'Should call the mock function Connect-SQL' {
    #             { Get-TargetResource @testParameters } | Should -Not -Throw

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         It 'Should return the desired state as absent' {
    #             $result = Get-TargetResource @testParameters

    #             $result.Ensure | Should -Be 'Absent'
    #             $result.Enabled | Should -BeFalse
    #         }

    #         It 'Should return the same values as passed as parameters' {
    #             $result = Get-TargetResource @testParameters

    #             $result.Name | Should -Be $testParameters.Name
    #             $result.ServerName | Should -Be $testParameters.ServerName
    #             $result.InstanceName | Should -Be $testParameters.InstanceName
    #         }

    #         It 'Should return $null for the rest of the properties' {
    #             $result = Get-TargetResource @testParameters

    #             $result.DestinationType | Should -BeNullOrEmpty
    #             $result.FilePath | Should -BeNullOrEmpty
    #             $result.Filter | Should -BeNullOrEmpty
    #             $result.MaximumFiles | Should -BeNullOrEmpty
    #             $result.MaximumFileSize | Should -BeNullOrEmpty
    #             $result.MaximumFileSizeUnit | Should -BeNullOrEmpty
    #             $result.MaximumRolloverFiles | Should -BeNullOrEmpty
    #             $result.OnFailure | Should -BeNullOrEmpty
    #             $result.QueueDelay | Should BeNullOrEmpty
    #             $result.ReserveDiskSpace | Should -BeNullOrEmpty
    #         }
    #     }

    #     Context 'When the system is in the desired state' {
    #         BeforeEach {
    #             $testParameters = $defaultParameters.Clone()
    #         }


    #     }
    # }

    # Describe 'DSC_SqlServerAudit\Test-TargetResource' -Tag 'Test' {
    #     BeforeEach {
    #         $testParameters = $defaultParameters.Clone()

    #         Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
    #     }

    #     Context 'When the system is not in the desired state' {
    #         # Make sure the mock does not return the correct endpoint
    #         $mockDynamicEndpointName = $mockOtherEndpointName

    #         It 'Should return that desired state is absent when wanted desired state is to be Present (using default values)' {
    #             $testParameters.Add('Ensure', 'Present')

    #             $result = Test-TargetResource @testParameters
    #             $result | Should -Be $false

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         It 'Should return that desired state is absent when wanted desired state is to be Present (setting all parameters)' {
    #             $testParameters.Add('Ensure', 'Present')
    #             $testParameters.Add('Port', $mockEndpointListenerPort)
    #             $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
    #             $testParameters.Add('Owner', $mockEndpointOwner)

    #             $result = Test-TargetResource @testParameters
    #             $result | Should -Be $false

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         # Make sure the mock do return the correct endpoint
    #         $mockDynamicEndpointName = $mockEndpointName

    #         It 'Should return that desired state is absent when wanted desired state is to be Absent' {
    #             $testParameters.Add('Ensure', 'Absent')

    #             $result = Test-TargetResource @testParameters
    #             $result | Should -Be $false

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
    #                 $result | Should -Be $false

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
    #                 $result | Should -Be $false

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
    #                 $result | Should -Be $false

    #                 Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #             }
    #         }

    #         # Make sure the mock do return the correct endpoint owner
    #         $mockDynamicEndpointOwner = $mockEndpointOwner
    #     }

    #     Context 'When the system is in the desired state' {
    #         # Make sure the mock do return the correct endpoint
    #         $mockDynamicEndpointName = $mockEndpointName

    #         It 'Should return that desired state is present when wanted desired state is to be Present (using default values)' {
    #             $result = Test-TargetResource @testParameters
    #             $result | Should -Be $true

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         # Make sure the mock does not return the correct endpoint
    #         $mockDynamicEndpointName = $mockOtherEndpointName

    #         It 'Should return that desired state is present when wanted desired state is to be Absent' {
    #             $testParameters.Add('Ensure', 'Absent')

    #             $result = Test-TargetResource @testParameters
    #             $result | Should -Be $true

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }
    #     }

    #     Assert-VerifiableMock
    # }

    # Describe 'DSC_SqlServerAudit\Set-TargetResource' -Tag 'Set' {
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
    #             $script:mockMethodCreateRan | Should -Be $true
    #             $script:mockMethodStartRan | Should -Be $true
    #             $script:mockMethodAlterRan | Should -Be $false
    #             $script:mockMethodDropRan | Should -Be $false

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         # Set all method call tests variables to $false
    #         $script:mockMethodCreateRan = $false
    #         $script:mockMethodStartRan = $false
    #         $script:mockMethodAlterRan = $false
    #         $script:mockMethodDropRan = $false

    #         # Set what the expected endpoint name should be when Create() method is called.
    #         $mockExpectedNameWhenCallingMethod = $mockEndpointName

    #         It 'Should call the method Create when desired state is to be Present (setting all parameters)' {
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
    #             $script:mockMethodCreateRan | Should -Be $true
    #             $script:mockMethodStartRan | Should -Be $true
    #             $script:mockMethodAlterRan | Should -Be $false
    #             $script:mockMethodDropRan | Should -Be $false

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         # Set all method call tests variables to $false
    #         $script:mockMethodCreateRan = $false
    #         $script:mockMethodStartRan = $false
    #         $script:mockMethodAlterRan = $false
    #         $script:mockMethodDropRan = $false

    #         # Set what the expected endpoint name should be when Drop() method is called.
    #         $mockExpectedNameWhenCallingMethod = $mockEndpointName

    #         It 'Should call the method Drop when desired state is to be Absent' {
    #             Mock -CommandName Get-TargetResource -MockWith {
    #                 return @{
    #                     Ensure = 'Present'
    #                 }
    #             } -Verifiable

    #             $testParameters.Add('Ensure', 'Absent')

    #             { Set-TargetResource @testParameters } | Should -Not -Throw
    #             $script:mockMethodCreateRan | Should -Be $false
    #             $script:mockMethodStartRan | Should -Be $false
    #             $script:mockMethodAlterRan | Should -Be $false
    #             $script:mockMethodDropRan | Should -Be $true

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         # Set all method call tests variables to $false
    #         $script:mockMethodCreateRan = $false
    #         $script:mockMethodStartRan = $false
    #         $script:mockMethodAlterRan = $false
    #         $script:mockMethodDropRan = $false

    #         # Set what the expected endpoint name should be when Alter() method is called.
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
    #             $script:mockMethodCreateRan | Should -Be $false
    #             $script:mockMethodStartRan | Should -Be $false
    #             $script:mockMethodAlterRan | Should -Be $true
    #             $script:mockMethodDropRan | Should -Be $false

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         # Set all method call tests variables to $false
    #         $script:mockMethodCreateRan = $false
    #         $script:mockMethodStartRan = $false
    #         $script:mockMethodAlterRan = $false
    #         $script:mockMethodDropRan = $false

    #         # Set what the expected endpoint name should be when Alter() method is called.
    #         $mockExpectedNameWhenCallingMethod = $mockEndpointName

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
    #             $script:mockMethodCreateRan | Should -Be $false
    #             $script:mockMethodStartRan | Should -Be $false
    #             $script:mockMethodAlterRan | Should -Be $true
    #             $script:mockMethodDropRan | Should -Be $false

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
    #                     Port = $mockEndpointListenerPort
    #                     IpAddress = $mockEndpointListenerIpAddress
    #                 }
    #             } -Verifiable

    #             $testParameters.Add('Ensure', 'Present')
    #             $testParameters.Add('Port', $mockEndpointListenerPort)
    #             $testParameters.Add('IpAddress', $mockEndpointListenerIpAddress)
    #             $testParameters.Add('Owner', $mockOtherEndpointOwner)

    #             { Set-TargetResource @testParameters } | Should -Not -Throw
    #             $script:mockMethodCreateRan | Should -Be $false
    #             $script:mockMethodStartRan | Should -Be $false
    #             $script:mockMethodAlterRan | Should -Be $true
    #             $script:mockMethodDropRan | Should -Be $false

    #             Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
    #         }

    #         # Make sure the mock does not return the correct endpoint
    #         $mockDynamicEndpointName = $mockOtherEndpointName

    #         Context 'When endpoint is missing when Ensure is set to Present' {
    #             It 'Should throw the correct error' {
    #                 Mock -CommandName Get-TargetResource -MockWith {
    #                     return @{
    #                         Ensure = 'Present'
    #                         Port = $mockEndpointListenerPort
    #                         IpAddress = $mockEndpointListenerIpAddress
    #                         Owner = $mockEndpointOwner
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
    #                         Port = $mockEndpointListenerPort
    #                         IpAddress = $mockEndpointListenerIpAddress
    #                         Owner = $mockEndpointOwner
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


    #     Assert-VerifiableMock
    # }
#}
