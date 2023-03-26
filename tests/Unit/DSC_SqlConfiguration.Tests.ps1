<#
    .SYNOPSIS
        Unit test for DSC_SqlConfiguration DSC resource.
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
    $script:dscResourceName = 'DSC_SqlConfiguration'

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlConfiguration\Get-TargetResource' {
    BeforeAll {
        Mock -CommandName Connect-SQL -MockWith {
            return New-Object -TypeName PSObject -Property @{
                Configuration = @{
                    Properties = @(
                        @{
                            DisplayName = 'user connections'
                            ConfigValue = 500
                        }
                    )
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        It 'Should return the same values as passed' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters = @{
                    ServerName     = 'CLU01'
                    InstanceName   = 'ClusteredInstance'
                    OptionName     = 'user connections'
                    OptionValue    = 500
                    RestartService = $false
                    RestartTimeout = 120
                }

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                $result.OptionName | Should -Be $mockGetTargetResourceParameters.OptionName
                $result.OptionValue | Should -Be $mockGetTargetResourceParameters.OptionValue
                $result.RestartService | Should -Be $mockGetTargetResourceParameters.RestartService
                $result.RestartTimeout | Should -Be $mockGetTargetResourceParameters.RestartTimeout
            }
        }

        It 'Should call Connect-SQL mock when getting the current state' {
            Should -Invoke -CommandName Connect-SQL -Scope Context -Times 1
        }
    }

    Context 'When an invalid option name is supplied' {
        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters = @{
                    ServerName     = 'CLU01'
                    InstanceName   = 'MSSQLSERVER'
                    OptionName     = 'Does Not Exist'
                    OptionValue    = 1
                    RestartService = $false
                    RestartTimeout = 120
                }

                $errorMessage = ($script:localizedData.ConfigurationOptionNotFound -f $mockGetTargetResourceParameters.OptionName) + " (Parameter 'OptionName')"

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage $errorMessage
            }
        }
    }
}

Describe 'SqlConfiguration\Test-TargetResource' {
    BeforeAll {
        Mock -CommandName Get-TargetResource -MockWith {
            return @{
                ServerName     = 'CLU01'
                InstanceName   = 'ClusteredInstance'
                OptionName     = 'user connections'
                OptionValue    = 500
                RestartService = $false
                RestartTimeout = 120
            }
        }
    }

    Context 'When the system is in the desired state' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters = @{
                    ServerName     = 'CLU01'
                    InstanceName   = 'ClusteredInstance'
                    OptionName     = 'user connections'
                    OptionValue    = 500
                    RestartService = $false
                    RestartTimeout = 120
                }

                $result = Test-TargetResource @mockTestTargetResourceParameters

                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-TargetResource -Scope It -Times 1
        }
    }

    Context 'When the system is not in the desired state' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters = @{
                    ServerName     = 'CLU01'
                    InstanceName   = 'ClusteredInstance'
                    OptionName     = 'user connections'
                    OptionValue    = 400
                    RestartService = $false
                    RestartTimeout = 120
                }

                $result = Test-TargetResource @mockTestTargetResourceParameters

                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-TargetResource -Scope It -Times 1
        }
    }
}

Describe 'SqlConfiguration\Set-TargetResource' {
    Context 'When the system is not in the desired state' {
        Context 'When setting option ''<OptionName>'' which has property IsDynamic set to <IsDynamic>' -ForEach @(
            @{
                OptionName = 'user connections'
                IsDynamic = $false
            }
            @{
                OptionName = 'show advanced options'
                IsDynamic = $true
            }
        ) {
            BeforeAll {
                Mock -CommandName Restart-SqlService
                Mock -CommandName Write-Warning
                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object -TypeName PSObject -Property @{
                        Configuration = @{
                            Properties = @(
                                @{
                                    DisplayName = $OptionName
                                    ConfigValue = 0
                                    IsDynamic   = $IsDynamic
                                }
                            )
                        }
                    }

                    # Add the Alter method.
                    $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {
                        InModuleScope -ScriptBlock {
                            $script:mockAlterMethodCallCount += 1
                        }
                    }

                    return $mock
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    # Reset method call count before each It-block.
                    $script:mockAlterMethodCallCount = 0
                }
            }

            It 'Should call the correct mocks and mocked methods for setting <OptionName>' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        ServerName     = 'CLU01'
                        InstanceName   = 'ClusteredInstance'
                        OptionName     = $OptionName
                        OptionValue    = 1
                        RestartService = $false
                        RestartTimeout = 120
                    }

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $script:mockAlterMethodCallCount | Should -Be 1
                }

                Should -Invoke -CommandName Restart-SqlService -Exactly -Times 0 -Scope It

                if ($IsDynamic)
                {
                    Should -Invoke -CommandName Write-Warning -Exactly -Times 0 -Scope It
                }
                else
                {
                    Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Scope It
                }
            }

            Context 'When passing RestartService set to $true' {
                It 'Should call the correct mocks and mocked methods for setting <OptionName>' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockSetTargetResourceParameters = @{
                            ServerName     = 'CLU01'
                            InstanceName   = 'ClusteredInstance'
                            OptionName     = $OptionName
                            OptionValue    = 1
                            RestartService = $true
                            RestartTimeout = 120
                        }

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    if ($IsDynamic)
                    {
                        Should -Invoke -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName Write-Warning -Exactly -Times 0 -Scope It
                    }
                    else
                    {
                        Should -Invoke -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName Write-Warning -Exactly -Times 0 -Scope It
                    }
                }
            }
        }

        Context 'When an invalid option is passed' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    $mock = New-Object -TypeName PSObject -Property @{
                        Configuration = @{
                            Properties = @(
                                @{
                                    DisplayName = 'user connections'
                                    ConfigValue = 0
                                    IsDynamic   = $false
                                }
                            )
                        }
                    }

                    # Add the Alter method.
                    $mock.Configuration | Add-Member -MemberType ScriptMethod -Name Alter -Value {}

                    return $mock
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters = @{
                        ServerName     = 'CLU01'
                        InstanceName   = 'ClusteredInstance'
                        OptionName     = 'InvalidOptionName'
                        OptionValue    = 1
                        RestartService = $true
                        RestartTimeout = 120
                    }

                    $errorMessage = ($script:localizedData.ConfigurationOptionNotFound -f 'InvalidOptionName') + " (Parameter 'OptionName')"

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage $errorMessage
                }
            }
        }
    }
}
