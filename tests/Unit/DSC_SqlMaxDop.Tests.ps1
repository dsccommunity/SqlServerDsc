<#
    .SYNOPSIS
        Unit test for DSC_SqlMaxDop DSC resource.
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
    $script:dscResourceName = 'DSC_SqlMaxDop'

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

Describe 'SqlMaxDop\Get-TargetResource' -Tag 'Get' {
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
        Context 'When getting the current state of max degree of parallelism' {
            BeforeAll {
                $mockConnectSQL = {
                    return @(
                        (
                            New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                                Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'MSSQLSERVER' -PassThru -Force |
                                Add-Member -MemberType 'NoteProperty' -Name 'ComputerNamePhysicalNetBIOS' -Value 'localhost' -PassThru -Force |
                                Add-Member -MemberType 'ScriptProperty' -Name 'Configuration' -Value {
                                    return @(
                                        (New-Object -TypeName 'Object' |
                                            Add-Member -MemberType 'ScriptProperty' -Name 'MaxDegreeOfParallelism' -Value {
                                            return @(
                                                (New-Object -TypeName Object |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'DisplayName' -Value 'max degree of parallelism' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'Description' -Value 'maximum degree of parallelism' -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'RunValue' -Value 4 -PassThru |
                                                    Add-Member -MemberType 'NoteProperty' -Name 'ConfigValue' -Value 4 -PassThru -Force)
                                                )
                                            } -PassThru -Force)
                                    )
                                } -PassThru -Force
                        )
                    )
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
                Mock -CommandName Test-ActiveNode -MockWith {
                    return $false
                }
            }

            It 'Should return the correct value for each property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -BeNullOrEmpty
                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.MaxDop | Should -Be 4
                    $result.IsActiveNode | Should -BeFalse
                    $result.ProcessOnlyOnActiveNode | Should -BeNullOrEmpty
                    $result.DynamicAlloc | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When getting the current state of max degree of parallelism' {
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith {
                    return $null
                }

                Mock -CommandName Test-ActiveNode -MockWith {
                    return $false
                }
            }

            It 'Should return the correct value for each property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -BeNullOrEmpty
                    $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $result.MaxDop | Should -BeNullOrEmpty
                    $result.IsActiveNode | Should -BeNullOrEmpty
                    $result.ProcessOnlyOnActiveNode | Should -BeNullOrEmpty
                    $result.DynamicAlloc | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'SqlMaxDop\Test-TargetResource' -Tag 'Test' {
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
        Context 'When max degree of parallelism should not be used' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        MaxDop                  = 0
                        IsActiveNode            = $null
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Ensure = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When max degree of parallelism is set to a specific value' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        MaxDop                  = 4
                        IsActiveNode            = $null
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MaxDop = 4

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When max degree of parallelism is set to a dynamic value' {
            BeforeAll {
                Mock -CommandName Get-SqlDscDynamicMaxDop -MockWith {
                    return 4
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        MaxDop                  = 4
                        IsActiveNode            = $null
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DynamicAlloc =  $true

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When both the parameters DynamicAlloc and MaxDop are set' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        MaxDop                  = 4
                    }
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MaxDop = 4
                    $mockTestTargetResourceParameters.DynamicAlloc =  $true

                    $mockErrorMessage = '{0} (Parameter ''MaxDop'')' -f $script:localizedData.MaxDopParamMustBeNull

                    { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When parameter ProcessOnlyActiveNode is set to $true' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        MaxDop                  = 0
                        IsActiveNode            = $false
                    }
                }
            }

            It 'Should return $true even if it is not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.ProcessOnlyOnActiveNode = $true
                    $mockTestTargetResourceParameters.MaxDop = 4

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When specifying a specific value for max degree of parallelism' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        MaxDop                  = 0
                        IsActiveNode            = $null
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MaxDop = 4

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When specifying that a dynamic value should be used for max degree of parallelism' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        MaxDop                  = 0
                        IsActiveNode            = $null
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DynamicAlloc = $true

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When specifying that max degree of parallelism should not be used' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        MaxDop                  = 4
                        IsActiveNode            = $null
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Ensure = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }
    }
}

Describe 'SqlMaxDop\Set-TargetResource' -Tag 'Set' {
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
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When both the parameters DynamicAlloc and MaxDop are set' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                # Can mock anything for this test since it is not used before it throws
                return 'mocked server object'
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.MaxDop = 4
                $mockSetTargetResourceParameters.DynamicAlloc =  $true

                $mockErrorMessage = '{0} (Parameter ''MaxDop'')' -f $script:localizedData.MaxDopParamMustBeNull

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When setting the max degree of parallelism but the call to the method Alter() fails' {
            BeforeAll {
                $mockConnectSQL = {
                    $mockMaxDegreeOfParallelismObject = New-Object -TypeName Object |
                        Add-Member -MemberType 'NoteProperty' -Name 'DisplayName' -Value 'max degree of parallelism' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'Description' -Value 'maximum degree of parallelism' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'RunValue' -Value 8 -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'ConfigValue' -Value 8 -PassThru -Force

                    $mockConfigurationObject = @(
                        (
                            New-Object -TypeName 'Object' |
                                Add-Member -MemberType 'NoteProperty' -Name 'MaxDegreeOfParallelism' -Value $mockMaxDegreeOfParallelismObject -PassThru -Force
                        )
                    )

                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                        Add-Member -MemberType 'NoteProperty' -Name 'Configuration' -Value $mockConfigurationObject -PassThru |
                        Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                            throw 'Mock Alter Method was called with invalid operation.'
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            It 'Should return the correct value for each property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxDop = 4

                    $mockErrorMessage = $script:localizedData.MaxDopSetError

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*Mock Alter Method was called with invalid operation.*')
                }
            }
        }

        Context 'When max degree of parallelism should not be used' {
            BeforeAll {
                $mockConnectSQL = {
                    $mockMaxDegreeOfParallelismObject = New-Object -TypeName Object |
                        Add-Member -MemberType 'NoteProperty' -Name 'DisplayName' -Value 'max degree of parallelism' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'Description' -Value 'maximum degree of parallelism' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'RunValue' -Value 8 -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'ConfigValue' -Value 8 -PassThru -Force

                    $mockConfigurationObject = @(
                        (
                            New-Object -TypeName 'Object' |
                                Add-Member -MemberType 'NoteProperty' -Name 'MaxDegreeOfParallelism' -Value $mockMaxDegreeOfParallelismObject -PassThru -Force
                        )
                    )

                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                        Add-Member -MemberType 'NoteProperty' -Name 'Configuration' -Value $mockConfigurationObject -PassThru |
                        Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                            if ( $this.Configuration.MaxDegreeOfParallelism.ConfigValue -ne $mockExpectedMaxDopForAlterMethod )
                            {
                                throw "Called mocked Alter() method without setting the right MaxDegreeOfParallelism. Expected '{0}'. But was '{1}'." `
                                    -f $mockExpectedMaxDopForAlterMethod, $this.Configuration.MaxDegreeOfParallelism.ConfigValue
                            }
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            It 'Should return the correct value for each property' {
                $mockExpectedMaxDopForAlterMethod = 0

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Ensure = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }
            }
        }

        Context 'When setting the max degree of parallelism to a specific value' {
            BeforeAll {
                $mockConnectSQL = {
                    $mockMaxDegreeOfParallelismObject = New-Object -TypeName Object |
                        Add-Member -MemberType 'NoteProperty' -Name 'DisplayName' -Value 'max degree of parallelism' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'Description' -Value 'maximum degree of parallelism' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'RunValue' -Value 8 -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'ConfigValue' -Value 8 -PassThru -Force

                    $mockConfigurationObject = @(
                        (
                            New-Object -TypeName 'Object' |
                                Add-Member -MemberType 'NoteProperty' -Name 'MaxDegreeOfParallelism' -Value $mockMaxDegreeOfParallelismObject -PassThru -Force
                        )
                    )

                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                        Add-Member -MemberType 'NoteProperty' -Name 'Configuration' -Value $mockConfigurationObject -PassThru |
                        Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                            if ( $this.Configuration.MaxDegreeOfParallelism.ConfigValue -ne $mockExpectedMaxDopForAlterMethod )
                            {
                                throw "Called mocked Alter() method without setting the right MaxDegreeOfParallelism. Expected '{0}'. But was '{1}'." `
                                    -f $mockExpectedMaxDopForAlterMethod, $this.Configuration.MaxDegreeOfParallelism.ConfigValue
                            }
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            It 'Should return the correct value for each property' {
                $mockExpectedMaxDopForAlterMethod = 4

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxDop = 4

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }
            }
        }

        Context 'When setting the max degree of parallelism to a dynamic value' {
            BeforeAll {
                $mockConnectSQL = {
                    $mockMaxDegreeOfParallelismObject = New-Object -TypeName Object |
                        Add-Member -MemberType 'NoteProperty' -Name 'DisplayName' -Value 'max degree of parallelism' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'Description' -Value 'maximum degree of parallelism' -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'RunValue' -Value 8 -PassThru |
                        Add-Member -MemberType 'NoteProperty' -Name 'ConfigValue' -Value 8 -PassThru -Force

                    $mockConfigurationObject = @(
                        (
                            New-Object -TypeName 'Object' |
                                Add-Member -MemberType 'NoteProperty' -Name 'MaxDegreeOfParallelism' -Value $mockMaxDegreeOfParallelismObject -PassThru -Force
                        )
                    )

                    return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                        Add-Member -MemberType 'NoteProperty' -Name 'Configuration' -Value $mockConfigurationObject -PassThru |
                        Add-Member -MemberType 'ScriptMethod' -Name 'Alter' -Value {
                            if ( $this.Configuration.MaxDegreeOfParallelism.ConfigValue -ne $mockExpectedMaxDopForAlterMethod )
                            {
                                throw "Called mocked Alter() method without setting the right MaxDegreeOfParallelism. Expected '{0}'. But was '{1}'." `
                                    -f $mockExpectedMaxDopForAlterMethod, $this.Configuration.MaxDegreeOfParallelism.ConfigValue
                            }
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

                Mock -CommandName Get-SqlDscDynamicMaxDop -MockWith {
                    return 2
                }
            }

            It 'Should return the correct value for each property' {
                $mockExpectedMaxDopForAlterMethod = 2

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DynamicAlloc = $true

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }
            }
        }
    }
}

Describe 'Get-SqlDscDynamicMaxDop' -Tag 'Helper' {
    Context 'When number of logical processors is 1' {
        Context 'When number of cores are 1' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    return @(
                        (
                            New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value 1 -PassThru |
                                Add-Member -MemberType NoteProperty -Name NumberOfCores -Value 1 -PassThru -Force
                        )
                    )
                } -ParameterFilter {
                    $ClassName -eq 'Win32_Processor'
                } -Verifiable
            }

            It 'Should return the correct value for dynamic max degree of parallelism' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-SqlDscDynamicMaxDop

                    $result | Should -Be 1
                }
            }
        }

        Context 'When number of cores are 4' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    return @(
                        (
                            New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value 1 -PassThru |
                                Add-Member -MemberType NoteProperty -Name NumberOfCores -Value 4 -PassThru -Force
                        )
                    )
                } -ParameterFilter {
                    $ClassName -eq 'Win32_Processor'
                } -Verifiable
            }

            It 'Should return the correct value for dynamic max degree of parallelism' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-SqlDscDynamicMaxDop

                    $result | Should -Be 2
                }
            }
        }
    }

    Context 'When number of cores are in between 2 and 7' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value 2 -PassThru |
                            Add-Member -MemberType NoteProperty -Name NumberOfCores -Value 2 -PassThru -Force
                    )
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value 2 -PassThru |
                            Add-Member -MemberType NoteProperty -Name NumberOfCores -Value 2 -PassThru -Force
                    )
                )
            } -ParameterFilter {
                $ClassName -eq 'Win32_Processor'
            } -Verifiable
        }

        It 'Should return the correct value for dynamic max degree of parallelism' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-SqlDscDynamicMaxDop

                $result | Should -Be 4
            }
        }
    }

    Context 'When number of cores are 8' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value 2 -PassThru |
                            Add-Member -MemberType NoteProperty -Name NumberOfCores -Value 4 -PassThru -Force
                    )
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value 2 -PassThru |
                            Add-Member -MemberType NoteProperty -Name NumberOfCores -Value 4 -PassThru -Force
                    )
                )
            } -ParameterFilter {
                $ClassName -eq 'Win32_Processor'
            } -Verifiable
        }

        It 'Should return the correct value for dynamic max degree of parallelism' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-SqlDscDynamicMaxDop

                $result | Should -Be 8
            }
        }
    }

    Context 'When number of cores higher than 8' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value 2 -PassThru |
                            Add-Member -MemberType NoteProperty -Name NumberOfCores -Value 8 -PassThru -Force
                    )
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value 2 -PassThru |
                            Add-Member -MemberType NoteProperty -Name NumberOfCores -Value 8 -PassThru -Force
                    )
                )
            } -ParameterFilter {
                $ClassName -eq 'Win32_Processor'
            } -Verifiable
        }

        It 'Should return the correct value for dynamic max degree of parallelism' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-SqlDscDynamicMaxDop

                $result | Should -Be 8
            }
        }
    }
}

# try
# {
#     InModuleScope $script:dscResourceName {
#         $mockServerName = 'localhost'
#         $mockInstanceName = 'MSSQLSERVER'
#         $mockMaxDegreeOfParallelism = 4
#         $mockExpectedMaxDopForAlterMethod = 1
#         $mockInvalidOperationForAlterMethod = $false
#         $mockNumberOfLogicalProcessors = 4
#         $mockNumberOfCores = 4
#         $mockProcessOnlyOnActiveNode = $true

#         # Default parameters that are used for the It-blocks
#         $mockDefaultParameters = @{
#             InstanceName = $mockInstanceName
#             ServerName   = $mockServerName
#         }

#         #region Function mocks

#         $mockConnectSQL = {
#             return @(
#                 (
#                     New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server |
#                         Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru -Force |
#                         Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru -Force |
#                         Add-Member -MemberType ScriptProperty -Name Configuration -Value {
#                         return @( ( New-Object -TypeName Object |
#                                     Add-Member -MemberType ScriptProperty -Name MaxDegreeOfParallelism -Value {
#                                     return @( ( New-Object -TypeName Object |
#                                                 Add-Member -MemberType NoteProperty -Name DisplayName -Value 'max degree of parallelism' -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name Description -Value 'maximum degree of parallelism' -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name RunValue -Value $mockMaxDegreeOfParallelism -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name ConfigValue -Value $mockMaxDegreeOfParallelism -PassThru -Force
#                                         ) )
#                                 } -PassThru -Force
#                             ) )
#                     } -PassThru |
#                         Add-Member -MemberType ScriptMethod -Name Alter -Value {
#                         if ( $this.Configuration.MaxDegreeOfParallelism.ConfigValue -ne $mockExpectedMaxDopForAlterMethod )
#                         {
#                             throw "Called mocked Alter() method without setting the right MaxDegreeOfParallelism. Expected '{0}'. But was '{1}'." `
#                                 -f $mockExpectedMaxDopForAlterMethod, $this.Configuration.MaxDegreeOfParallelism.ConfigValue
#                         }
#                         if ($mockInvalidOperationForAlterMethod)
#                         {
#                             throw 'Mock Alter Method was called with invalid operation.'
#                         }
#                     } -PassThru -Force
#                 )
#             )
#         }

#         $mockCimInstance_Win32Processor = {
#             return @(
#                 (
#                     New-Object -TypeName Object |
#                         Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value $mockNumberOfLogicalProcessors -PassThru |
#                         Add-Member -MemberType NoteProperty -Name NumberOfCores -Value $mockNumberOfCores -PassThru -Force
#                 )
#             )
#         }

#         #endregion

#         Describe "DSC_SqlMaxDop\Get-TargetResource" -Tag 'Get' {
#             Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
#             Mock -CommandName Test-ActiveNode -MockWith { return $mockProcessOnlyOnActiveNode } -Verifiable

#             Context 'When the system is either in the desired state or not in the desired state' {
#                 $testParameters = $mockDefaultParameters

#                 $result = Get-TargetResource @testParameters

#                 It 'Should return the current value for MaxDop' {
#                     $result.MaxDop | Should -Be $mockMaxDegreeOfParallelism
#                 }

#                 It 'Should return the same values as passed as parameters' {
#                     $result.ServerName | Should -Be $testParameters.ServerName
#                     $result.InstanceName | Should -Be $testParameters.InstanceName
#                 }

#                 It 'Should return $null for the remaining parameters' {
#                     $result.ProcessOnlyOnActiveNode | Should -BeNullOrEmpty
#                     $result.Ensure | Should -BeNullOrEmpty
#                     $result.DynamicAlloc | Should -BeNullOrEmpty
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should call the mock function Test-ActiveNode' {
#                     Assert-MockCalled -CommandName Test-ActiveNode -Exactly -Times 1 -Scope Context
#                 }
#             }

#             Assert-VerifiableMock
#         }

#         Describe "DSC_SqlMaxDop\Test-TargetResource" -Tag 'Test' {
#             BeforeEach {
#                 Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                 Mock -CommandName Test-ActiveNode -MockWith {
#                     $mockProcessOnlyOnActiveNode
#                 } -Verifiable

#                 Mock -CommandName Get-CimInstance -MockWith $mockCimInstance_Win32Processor -ParameterFilter {
#                     $ClassName -eq 'Win32_Processor'
#                 } -Verifiable

#                 Mock -CommandName Get-CimInstance -MockWith {
#                     throw 'Mocked function Get-CimInstance was called with the wrong set of parameter filters.'
#                 }
#             }

#             Context 'When the system is not in the desired state and DynamicAlloc is set to false' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxDop       = 1
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                 }

#                 It 'Should return the state as false when desired MaxDop is the wrong value' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $false
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-CimInstance' {
#                     Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope Context
#                 }
#             }

#             $mockMaxDegreeOfParallelism = 6

#             Context 'When the system is in the desired state and DynamicAlloc is set to false' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxDop       = 6
#                     DynamicAlloc = $false
#                 }

#                 It 'Should return the state as true when desired MaxDop is the correct value' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $true
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-CimInstance' {
#                     Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 0 -Scope Context
#                 }
#             }

#             $mockMaxDegreeOfParallelism = 4

#             Context 'When the system is in the desired state and DynamicAlloc is set to true' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     DynamicAlloc = $true
#                 }

#                 It 'Should return the state as true when desired MaxDop is present' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $true
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
#                     Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -ParameterFilter {
#                         $ClassName -eq 'Win32_Processor'
#                     } -Scope Context
#                 }
#             }

#             $mockNumberOfCores = 2

#             Context 'When the system is not in the desired state, DynamicAlloc is set to true, NumberOfLogicalProcessors = 4 and NumberOfCores = 2' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     DynamicAlloc = $true
#                 }

#                 It 'Should return the state as false when desired MaxDop is the wrong value' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $false
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
#                     Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -ParameterFilter {
#                         $ClassName -eq 'Win32_Processor'
#                     } -Scope Context
#                 }
#             }

#             $mockNumberOfLogicalProcessors = 1

#             Context 'When the system is not in the desired state, DynamicAlloc is set to true, NumberOfLogicalProcessors = 1 and NumberOfCores = 2' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     DynamicAlloc = $true
#                 }

#                 It 'Should return the state as false when desired MaxDop is the wrong value' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $false
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
#                     Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -ParameterFilter {
#                         $ClassName -eq 'Win32_Processor'
#                     } -Scope Context
#                 }
#             }

#             $mockNumberOfLogicalProcessors = 4
#             $mockNumberOfCores = 8

#             Context 'When the system is not in the desired state, DynamicAlloc is set to true, NumberOfLogicalProcessors = 4 and NumberOfCores = 8' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     DynamicAlloc = $true
#                 }

#                 It 'Should return the state as false when desired MaxDop is the wrong value' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $false
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
#                     Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -ParameterFilter {
#                         $ClassName -eq 'Win32_Processor'
#                     } -Scope Context
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to absent' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     Ensure = 'Absent'
#                 }

#                 It 'Should return the state as false when desired MaxDop is the wrong value' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $false
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             Context 'When the ProcessOnlyOnActiveNode parameter is passed' {
#                 AfterAll {
#                     $mockProcessOnlyOnActiveNode = $true
#                 }

#                 BeforeAll {
#                     $testParameters = $mockDefaultParameters
#                     $testParameters += @{
#                         Ensure                  = 'Absent'
#                         ProcessOnlyOnActiveNode = $true
#                     }

#                     $mockProcessOnlyOnActiveNode = $false
#                 }

#                 It 'Should return $true when ProcessOnlyOnActiveNode is "$true" and the current node is not actively hosting the instance' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $true
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             $mockMaxDegreeOfParallelism = 0

#             Context 'When the system is in the desired state and Ensure is set to absent' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     Ensure = 'Absent'
#                 }

#                 It 'Should return the state as true when desired MaxDop is the correct value' {
#                     $result = Test-TargetResource @testParameters
#                     $result | Should -Be $true
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             Context 'When the MaxDop parameter is not null and DynamicAlloc set to true' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxDop       = 4
#                     DynamicAlloc = $true
#                 }

#                 It 'Should throw the correct error' {
#                     { Test-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxDopParamMustBeNull
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             # This is regression test for issue #576
#             Context 'When the system is in the desired state and ServerName is not set' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters.Remove('ServerName')
#                 $testParameters += @{
#                     Ensure = 'Absent'
#                 }

#                 It 'Should not throw an error' {
#                     { Test-TargetResource @testParameters } | Should -Not -Throw
#                 }
#             }

#             Assert-VerifiableMock
#         }

#         Describe "DSC_SqlMaxDop\Set-TargetResource" -Tag 'Set' {
#             BeforeEach {
#                 Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                 Mock -CommandName Get-CimInstance -MockWith $mockCimInstance_Win32Processor -ParameterFilter {
#                     $ClassName -eq 'Win32_Processor'
#                 } -Verifiable

#                 Mock -CommandName Get-CimInstance -MockWith {
#                     throw 'Mocked function Get-CimInstance was called with the wrong set of parameter filters.'
#                 }
#             }

#             Context 'When the MaxDop parameter is not null and DynamicAlloc set to true' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxDop       = 4
#                     DynamicAlloc = $true
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error' {
#                     { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxDopParamMustBeNull
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             $mockMaxDegreeOfParallelism = 0
#             $mockExpectedMaxDopForAlterMethod = 0

#             Context 'When the Ensure parameter is set to Absent' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     Ensure = 'Absent'
#                 }

#                 It 'Should Not Throw when Ensure parameter is set to Absent' {
#                     { Set-TargetResource @testParameters } | Should -Not -Throw
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             $mockMaxDegreeOfParallelism = 1
#             $mockExpectedMaxDopForAlterMethod = 1

#             Context 'When the desired MaxDop parameter is not set' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxDop       = 1
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                 }

#                 It 'Should Not Throw when MaxDop parameter is not null and DynamicAlloc set to false' {
#                     { Set-TargetResource @testParameters } | Should -Not -Throw
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             $mockMaxDegreeOfParallelism = 2
#             $mockExpectedMaxDopForAlterMethod = 2
#             $mockNumberOfLogicalProcessors = 4
#             $mockNumberOfCores = 2

#             Context 'When the system is not in the desired state and DynamicAlloc is set to true' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     DynamicAlloc = $true
#                     Ensure       = 'Present'
#                 }

#                 It 'Should Not Throw when MaxDop parameter is not null and DynamicAlloc set to false' {
#                     { Set-TargetResource @testParameters } | Should -Not -Throw
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
#                     Assert-MockCalled -CommandName Get-CimInstance -Exactly -Times 1 -ParameterFilter {
#                         $ClassName -eq 'Win32_Processor'
#                     } -Scope Context
#                 }
#             }

#             $mockInvalidOperationForAlterMethod = $true

#             Context 'When the desired MaxDop parameter is not set' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxDop       = 1
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error when Alter() method was called with invalid operation' {
#                     { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxDopSetError
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }
#             }

#             Assert-VerifiableMock
#         }
#     }
# }
# finally
# {
#     Invoke-TestCleanup
# }
