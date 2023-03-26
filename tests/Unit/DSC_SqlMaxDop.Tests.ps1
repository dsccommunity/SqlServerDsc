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
    $script:dscResourceName = 'DSC_SqlMaxDop'

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
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
                Mock -CommandName Get-SqlDscDynamicMaxDop -MockWith {
                    return 4
                }

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
                            InModuleScope -ScriptBlock {
                                $script:mockMethodAlterWasRun += 1
                            }

                            throw 'Mock Alter Method was called with invalid operation.'
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockMethodAlterWasRun = 0
                }
            }

            It 'Should return the correct value for each property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxDop = 4

                    $mockErrorMessage = $script:localizedData.MaxDopSetError

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*Mock Alter Method was called with invalid operation.*')

                    $mockMethodAlterWasRun | Should -Be 1
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
                            InModuleScope -ScriptBlock {
                                $script:mockMethodAlterWasRun += 1
                            }

                            if ( $this.Configuration.MaxDegreeOfParallelism.ConfigValue -ne $mockExpectedMaxDopForAlterMethod )
                            {
                                throw "Called mocked Alter() method without setting the right MaxDegreeOfParallelism. Expected '{0}'. But was '{1}'." `
                                    -f $mockExpectedMaxDopForAlterMethod, $this.Configuration.MaxDegreeOfParallelism.ConfigValue
                            }
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockMethodAlterWasRun = 0
                }
            }

            It 'Should return the correct value for each property' {
                $mockExpectedMaxDopForAlterMethod = 0

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Ensure = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
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
                            InModuleScope -ScriptBlock {
                                $script:mockMethodAlterWasRun += 1
                            }

                            if ( $this.Configuration.MaxDegreeOfParallelism.ConfigValue -ne $mockExpectedMaxDopForAlterMethod )
                            {
                                throw "Called mocked Alter() method without setting the right MaxDegreeOfParallelism. Expected '{0}'. But was '{1}'." `
                                    -f $mockExpectedMaxDopForAlterMethod, $this.Configuration.MaxDegreeOfParallelism.ConfigValue
                            }
                        } -PassThru -Force
                }

                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockMethodAlterWasRun = 0
                }
            }

            It 'Should return the correct value for each property' {
                $mockExpectedMaxDopForAlterMethod = 4

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxDop = 4

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
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
                            InModuleScope -ScriptBlock {
                                $script:mockMethodAlterWasRun += 1
                            }

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

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:mockMethodAlterWasRun = 0
                }
            }

            It 'Should return the correct value for each property' {
                $mockExpectedMaxDopForAlterMethod = 2

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DynamicAlloc = $true

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
                }
            }
        }
    }
}

Describe 'Get-SqlDscDynamicMaxDop' -Tag 'Helper' {
    BeforeAll {
        # Inject a stub in the module scope to support testing cross-plattform
        InModuleScope -ScriptBlock {
            function script:Get-CimInstance {
                param
                (
                    $ClassName
                )
            }
        }
    }

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
