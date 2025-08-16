<#
    .SYNOPSIS
        Unit test for SqlRSSetup DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlRSSetup' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { [SqlRSSetup]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlRSSetup]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlRSSetup]::new()
                $instance.GetType().Name | Should -Be 'SqlRSSetup'
            }
        }
    }
}

Describe 'SqlRSSetup\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        Context 'When the instance is installed' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Edition      = 'Developer'
                        Action       = 'Install'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockSqlRSSetupInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                InstanceName   = 'SSRS'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockSqlRSSetupInstance.Get()

                    $currentState.InstanceName | Should -Be 'SSRS'
                    $currentState.Timeout | Should -Be 7200
                    # Returns 0, that means no value was set by GetCurrentState() from the enum InstallAction
                    $currentState.Action | Should -Be 0
                    $currentState.AcceptLicensingTerms | Should -BeFalse
                    $currentState.MediaPath | Should -BeNullOrEmpty
                    $currentState.ProductKey | Should -BeNullOrEmpty
                    $currentState.EditionUpgrade | Should -BeNullOrEmpty
                    $currentState.Edition | Should -BeNullOrEmpty
                    $currentState.LogPath | Should -BeNullOrEmpty
                    $currentState.InstallFolder | Should -BeNullOrEmpty
                    $currentState.SuppressRestart | Should -BeFalse
                    $currentState.ForceRestart | Should -BeFalse
                    $currentState.VersionUpgrade | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the instance is not installed' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Edition      = 'Developer'
                        Action       = 'Install'
                    }

                    <#
                        This mocks the method GetCurrentState().

                        Method Get() will call the base method Get() which will
                        call back to the derived class method GetCurrentState()
                        to get the result to return from the derived method Get().
                    #>
                    $script:mockSqlRSSetupInstance |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetCurrentState' -Value {
                            return [System.Collections.Hashtable] @{
                                InstanceName = $null
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $currentState = $script:mockSqlRSSetupInstance.Get()

                    $currentState.InstanceName | Should -BeNull
                    $currentState.Installed | Should -BeFalse
                    $currentState.Timeout | Should -Be 7200
                    # Returns 0, that means no value was set by GetCurrentState() from the enum InstallAction
                    $currentState.Action | Should -Be 0
                    $currentState.AcceptLicensingTerms | Should -BeFalse
                    $currentState.MediaPath | Should -BeNullOrEmpty
                    $currentState.ProductKey | Should -BeNullOrEmpty
                    $currentState.EditionUpgrade | Should -BeNullOrEmpty
                    $currentState.Edition | Should -BeNullOrEmpty
                    $currentState.LogPath | Should -BeNullOrEmpty
                    $currentState.InstallFolder | Should -BeNullOrEmpty
                    $currentState.SuppressRestart | Should -BeFalse
                    $currentState.ForceRestart | Should -BeFalse
                    $currentState.VersionUpgrade | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'SqlRSSetup\Test()' -Tag 'Test' {
    Context 'When the system is in the desired state' {
        Context 'When the parameter action is set to Install' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Edition      = 'Developer'
                        Action       = 'Install'
                    } |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return $null
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSqlRSSetupInstance.Test() | Should -BeTrue
                }
            }
        }

        Context 'When the parameter action is set to Uninstall' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Edition      = 'Developer'
                        Action       = 'Uninstall'
                    } |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            <#
                                Compare() method shall only return the properties NOT in
                                desired state, in the format of the command Compare-DscParameterState.
                            #>
                            return @(
                                @{
                                    Property      = 'InstanceName'
                                    ExpectedValue = 'SSRS'
                                    ActualValue   = $null
                                }
                            )
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSqlRSSetupInstance.Test() | Should -BeTrue
                }
            }
        }

        Context 'When the parameter action is set to Repair' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Edition      = 'Developer'
                        Action       = 'Repair'
                    } |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            <#
                                Compare() method shall only return the properties NOT in
                                desired state, in the format of the command Compare-DscParameterState.
                            #>
                            return @(
                                @{
                                    Property      = 'InstanceName'
                                    ExpectedValue = 'SSRS'
                                    ActualValue   = $null
                                }
                            )
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSqlRSSetupInstance.Test() | Should -BeTrue
                }
            }
        }

        Context 'When the parameter action is set to Install and VersionUpgrade is set to $true' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName   = 'SSRS'
                        Edition        = 'Developer'
                        Action         = 'Install'
                        VersionUpgrade = $true
                        MediaPath      = $TestDrive
                    } |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return $null
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-FileProductVersion -MockWith {
                    return [System.Version] '9.9.99'
                }

                Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                    return [System.Collections.Hashtable] @{
                        InstanceName   = 'SSRS'
                        ProductVersion = '9.9.99'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSqlRSSetupInstance.Test() | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the parameter action is set to Install' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Edition      = 'Developer'
                        Action       = 'Install'
                    } |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            <#
                                Compare() method shall only return the properties NOT in
                                desired state, in the format of the command Compare-DscParameterState.
                            #>
                            return @(
                                @{
                                    Property      = 'InstanceName'
                                    ExpectedValue = 'SSRS'
                                    ActualValue   = $null
                                }
                            )
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSqlRSSetupInstance.Test() | Should -BeFalse
                }
            }
        }

        Context 'When the parameter action is set to Uninstall' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Edition      = 'Developer'
                        Action       = 'Uninstall'
                    } |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return $null
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSqlRSSetupInstance.Test() | Should -BeFalse
                }
            }
        }

        Context 'When the parameter action is set to Repair' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Edition      = 'Developer'
                        Action       = 'Repair'
                    } |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return $null
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSqlRSSetupInstance.Test() | Should -BeFalse
                }
            }
        }

        Context 'When the parameter action is set to Install and VersionUpgrade is set to $true' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName   = 'SSRS'
                        Edition        = 'Developer'
                        Action         = 'Install'
                        VersionUpgrade = $true
                        MediaPath      = $TestDrive
                    } |
                        # Mock method Compare() which is called by the base method Set()
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                            return $null
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        } -PassThru
                }

                Mock -CommandName Get-FileProductVersion -MockWith {
                    return [System.Version] '9.9.99'
                }

                Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                    return [System.Collections.Hashtable] @{
                        InstanceName   = 'SSRS'
                        ProductVersion = '5.5.0'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSqlRSSetupInstance.Test() | Should -BeFalse
                }
            }
        }
    }
}

Describe 'SqlRSSetup\Set()' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                InstanceName = 'SSRS'
                Edition      = 'Developer'
                Action       = 'Install'
            } |
                # Mock method Modify which is called by the base method Set().
                Add-Member -Force -MemberType 'ScriptMethod' -Name 'Modify' -Value {
                    $script:mockMethodModifyCallCount += 1
                } -PassThru
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:mockMethodModifyCallCount = 0
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return $null
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                        return
                    } -PassThru
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockSqlRSSetupInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 0
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        return @{
                            Property      = 'InstanceName'
                            ExpectedValue = 'SSRS'
                            ActualValue   = $null
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    } -PassThru
            }
        }

        It 'Should call method Modify()' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockSqlRSSetupInstance.Set()

                $script:mockMethodModifyCallCount | Should -Be 1
            }
        }
    }
}

Describe 'SqlRSSetup\GetCurrentState()' -Tag 'GetCurrentState' {
    Context 'When current state is missing SSRS instance' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                    InstanceName = 'SSRS'
                }
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $currentState = $script:mockSqlRSSetupInstance.GetCurrentState(
                    @{
                        Name         = 'InstanceName'
                        InstanceName = 'SSRS'
                    }
                )

                $currentState.InstanceName | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When current state have an SSRS instance' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                    InstanceName = 'SSRS'
                }
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @(
                    [PSCustomObject] @{
                        InstanceName   = 'SSRS'
                        InstallFolder  = 'C:\Program Files\SSRS'
                    }
                )
            }
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $currentState = $script:mockSqlRSSetupInstance.GetCurrentState(
                    @{
                        Name         = 'InstanceName'
                        InstanceName = 'SSRS'
                    }
                )

                $currentState.InstanceName | Should -Be 'SSRS'
                $currentState.InstallFolder | Should -Be 'C:\Program Files\SSRS'
            }
        }
    }
}

Describe 'SqlRSSetup\Modify()' -Tag 'Modify' {
    Context 'When action is Install' {
        Context 'When current state is missing SSRS instance' {
            Context 'When the install command is successful' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'SSRS'
                            Action       = 'Install'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Install-SqlDscReportingService -MockWith {
                        return 0
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'SSRS'
                            }
                        )

                        Should -Invoke -CommandName 'Install-SqlDscReportingService' -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the install command returns exit code 3010' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'SSRS'
                            Action       = 'Install'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Install-SqlDscReportingService -MockWith {
                        return 3010
                    }

                    Mock -CommandName Set-DscMachineRebootRequired
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'SSRS'
                            }
                        )

                        Should -Invoke -CommandName 'Install-SqlDscReportingService' -Exactly -Times 1 -Scope It
                        Should -Invoke -CommandName 'Set-DscMachineRebootRequired' -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When current state is missing PBIRS instance' {
            Context 'When the install command is successful' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'PBIRS'
                            Action       = 'Install'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Install-SqlDscBIReportServer -MockWith {
                        return 0
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'PBIRS'
                            }
                        )

                        Should -Invoke -CommandName 'Install-SqlDscBIReportServer' -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the install command returns exit code 3010' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'PBIRS'
                            Action       = 'Install'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Install-SqlDscBIReportServer -MockWith {
                        return 3010
                    }

                    Mock -CommandName Set-DscMachineRebootRequired
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'PBIRS'
                            }
                        )

                        Should -Invoke -CommandName 'Install-SqlDscBIReportServer' -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName 'Set-DscMachineRebootRequired' -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }

    Context 'When action is Uninstall' {
        Context 'When current state is missing SSRS instance' {
            Context 'When the uninstall command is successful' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'SSRS'
                            Action       = 'Uninstall'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Uninstall-SqlDscReportingService -MockWith {
                        return 0
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'SSRS'
                            }
                        )

                        Should -Invoke -CommandName 'Uninstall-SqlDscReportingService' -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the uninstall command returns exit code 3010' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'SSRS'
                            Action       = 'Uninstall'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Uninstall-SqlDscReportingService -MockWith {
                        return 3010
                    }

                    Mock -CommandName Set-DscMachineRebootRequired
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'SSRS'
                            }
                        )

                        Should -Invoke -CommandName 'Uninstall-SqlDscReportingService' -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName 'Set-DscMachineRebootRequired' -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When current state is missing PBIRS instance' {
            Context 'When the uninstall command is successful' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'PBIRS'
                            Action       = 'Uninstall'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Uninstall-SqlDscBIReportServer -MockWith {
                        return 0
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'PBIRS'
                            }
                        )

                        Should -Invoke -CommandName 'Uninstall-SqlDscBIReportServer' -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the uninstall command returns exit code 3010' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'PBIRS'
                            Action       = 'Uninstall'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Uninstall-SqlDscBIReportServer -MockWith {
                        return 3010
                    }

                    Mock -CommandName Set-DscMachineRebootRequired
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'PBIRS'
                            }
                        )

                        Should -Invoke -CommandName 'Uninstall-SqlDscBIReportServer' -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName 'Set-DscMachineRebootRequired' -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }

    Context 'When action is Repair' {
        Context 'When current state is missing SSRS instance' {
            Context 'When the repair command is successful' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'SSRS'
                            Action       = 'Repair'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Repair-SqlDscReportingService -MockWith {
                        return 0
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'SSRS'
                            }
                        )

                        Should -Invoke -CommandName 'Repair-SqlDscReportingService' -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the repair command returns exit code 3010' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'SSRS'
                            Action       = 'Repair'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Repair-SqlDscReportingService -MockWith {
                        return 3010
                    }

                    Mock -CommandName Set-DscMachineRebootRequired
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'SSRS'
                            }
                        )

                        Should -Invoke -CommandName 'Repair-SqlDscReportingService' -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName 'Set-DscMachineRebootRequired' -Exactly -Times 1 -Scope It
                    }
                }
            }
        }

        Context 'When current state is missing PBIRS instance' {
            Context 'When the repair command is successful' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'PBIRS'
                            Action       = 'Repair'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Repair-SqlDscBIReportServer -MockWith {
                        return 0
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'PBIRS'
                            }
                        )

                        Should -Invoke -CommandName 'Repair-SqlDscBIReportServer' -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the repair command returns exit code 3010' {
                BeforeAll {
                    InModuleScope -ScriptBlock {
                        $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                            InstanceName = 'PBIRS'
                            Action       = 'Repair'
                            MediaPath    = $TestDrive
                        }
                    }

                    Mock -CommandName Repair-SqlDscBIReportServer -MockWith {
                        return 3010
                    }

                    Mock -CommandName Set-DscMachineRebootRequired
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSqlRSSetupInstance.Modify(
                            @{
                                Name         = 'InstanceName'
                                InstanceName = 'PBIRS'
                            }
                        )

                        Should -Invoke -CommandName 'Repair-SqlDscBIReportServer' -Exactly -Times 1 -Scope It

                        Should -Invoke -CommandName 'Set-DscMachineRebootRequired' -Exactly -Times 1 -Scope It
                    }
                }
            }
        }
    }
}

Describe 'SqlRSSetup\AssertProperties()' -Tag 'AssertProperties' {
    Context 'When the passing invalid instance name' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                    InstanceName = 'INSTANCE'
                    Action       = 'Install'
                    MediaPath    = $TestDrive
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockExpectedErrorMessage = ($script:mockSqlRSSetupInstance.localizedData.InstanceName_Invalid -f 'INSTANCE') + ' (Parameter ''InstanceName'')'

                {
                    $script:mockSqlRSSetupInstance.AssertProperties(
                        @{
                            InstanceName = 'INSTANCE'
                            Action       = 'Install'
                            MediaPath    = $TestDrive
                        }
                    )
                } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
            }
        }
    }

    Context 'When the parameter Action is set to ''Install''' {
        Context 'When not passing parameter AcceptLicensingTerms' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Action       = 'Install'
                        MediaPath    = $TestDrive
                    }
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.AcceptLicensingTerms_Required
                        ArgumentName = 'AcceptLicensingTerms'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName = 'SSRS'
                                Action       = 'Install'

                                MediaPath    = $TestDrive
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }

        Context 'When passing parameter AcceptLicensingTerms with the value $false' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName         = 'SSRS'
                        Action               = 'Install'
                        MediaPath            = $TestDrive
                        AcceptLicensingTerms = $false
                    }
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.AcceptLicensingTerms_Required
                        ArgumentName = 'AcceptLicensingTerms'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName         = 'SSRS'
                                Action               = 'Install'
                                MediaPath            = $TestDrive
                                AcceptLicensingTerms = $false
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }

        Context 'When not passing either parameter ProductKey or Edition' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName         = 'SSRS'
                        Action               = 'Install'
                        MediaPath            = Join-Path -Path $TestDrive -ChildPath 'setup.exe'
                        AcceptLicensingTerms = $true
                    }
                }

                Set-Content -Path (Join-Path -Path $TestDrive -ChildPath 'setup.exe') -Value 'This is the mocked setup executable file.'
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.EditionOrProductKeyMissing
                        ArgumentName = 'Edition, ProductKey'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName         = 'SSRS'
                                Action               = 'Install'
                                MediaPath            = Join-Path -Path $TestDrive -ChildPath 'setup.exe'
                                AcceptLicensingTerms = $true
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }

        Context 'When passing InstallFolder with invalid path' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName         = 'SSRS'
                        Action               = 'Install'
                        MediaPath            = Join-Path -Path $TestDrive -ChildPath 'setup.exe'
                        AcceptLicensingTerms = $true
                        Edition              = 'Developer'
                        InstallFolder        = $TestDrive | Join-Path -ChildPath 'MissingParent' | Join-Path -ChildPath 'SSRS'
                    }
                }

                Set-Content -Path (Join-Path -Path $TestDrive -ChildPath 'setup.exe') -Value 'This is the mocked setup executable file.'
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.InstallFolder_ParentMissing -f ($TestDrive | Join-Path -ChildPath 'MissingParent')
                        ArgumentName = 'InstallFolder'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName         = 'SSRS'
                                Action               = 'Install'
                                MediaPath            = Join-Path -Path $TestDrive -ChildPath 'setup.exe'
                                AcceptLicensingTerms = $true
                                Edition              = 'Developer'
                                InstallFolder        = $TestDrive | Join-Path -ChildPath 'MissingParent' | Join-Path -ChildPath 'SSRS'
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }
    }

    Context 'When the parameter Action is set to ''Repair''' {
        Context 'When not passing parameter AcceptLicensingTerms' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName = 'SSRS'
                        Action       = 'Repair'
                        MediaPath    = $TestDrive
                    }
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.AcceptLicensingTerms_Required
                        ArgumentName = 'AcceptLicensingTerms'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName = 'SSRS'
                                Action       = 'Repair'
                                MediaPath    = $TestDrive
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }

        Context 'When passing parameter AcceptLicensingTerms with the value $false' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName         = 'SSRS'
                        Action               = 'Repair'
                        MediaPath            = $TestDrive
                        AcceptLicensingTerms = $false
                    }
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.AcceptLicensingTerms_Required
                        ArgumentName = 'AcceptLicensingTerms'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName         = 'SSRS'
                                Action               = 'Repair'
                                MediaPath            = $TestDrive
                                AcceptLicensingTerms = $false
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }

        Context 'When not passing parameter EditionUpgrade, but not either parameter ProductKey or Edition' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName         = 'SSRS'
                        Action               = 'Repair'
                        MediaPath            = Join-Path -Path $TestDrive -ChildPath 'setup.exe'
                        AcceptLicensingTerms = $true
                        EditionUpgrade       = $true
                    }
                }

                Set-Content -Path (Join-Path -Path $TestDrive -ChildPath 'setup.exe') -Value 'This is the mocked setup executable file.'
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.EditionUpgrade_RequiresKeyOrEdition
                        ArgumentName = 'EditionUpgrade'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName         = 'SSRS'
                                Action               = 'Repair'
                                MediaPath            = Join-Path -Path $TestDrive -ChildPath 'setup.exe'
                                AcceptLicensingTerms = $true
                                EditionUpgrade       = $true
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }
    }

    Context 'When the passing both parameters Edition and ProductKey' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                    InstanceName         = 'SSRS'
                    Action               = 'Install'
                    MediaPath            = $TestDrive
                    AcceptLicensingTerms = $true
                    Edition              = 'Developer'
                    ProductKey           = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                {
                    $script:mockSqlRSSetupInstance.AssertProperties(
                        @{
                            InstanceName         = 'SSRS'
                            Action               = 'Install'
                            MediaPath            = $TestDrive
                            AcceptLicensingTerms = $true
                            Edition              = 'Developer'
                            ProductKey           = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
                        }
                    )
                } | Should -Throw -ExpectedMessage '*DRC0010*'
            }
        }
    }

    Context 'When the passing invalid path for parameter MediaPath' {
        Context 'When the path does not exist' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName         = 'SSRS'
                        Action               = 'Install'
                        MediaPath            = Join-Path -Path $TestDrive -ChildPath 'InvalidFile.exe'
                        AcceptLicensingTerms = $true
                        Edition              = 'Developer'
                    }
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.MediaPath_Invalid -f (Join-Path -Path $TestDrive -ChildPath 'InvalidFile.exe')
                        ArgumentName = 'MediaPath'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName         = 'SSRS'
                                Action               = 'Install'
                                MediaPath            = Join-Path -Path $TestDrive -ChildPath 'InvalidFile.exe'
                                AcceptLicensingTerms = $true
                                Edition              = 'Developer'
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }

        Context 'When the path exist but does not reference an executable with extension .exe' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                        InstanceName         = 'SSRS'
                        Action               = 'Install'
                        MediaPath            = Join-Path -Path $TestDrive -ChildPath 'InvalidFile.txt'
                        AcceptLicensingTerms = $true
                        Edition              = 'Developer'
                    }
                }

                # Create a file in $TestDrive that does not have extension .exe
                Set-Content -Path (Join-Path -Path $TestDrive -ChildPath 'InvalidFile.txt') -Value 'This is a test file.'
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getInvalidArgumentRecordParameters = @{
                        Message     = $script:mockSqlRSSetupInstance.localizedData.MediaPath_DoesNotHaveRequiredExtension -f (Join-Path -Path $TestDrive -ChildPath 'InvalidFile.txt')
                        ArgumentName = 'MediaPath'
                    }

                    $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                    {
                        $script:mockSqlRSSetupInstance.AssertProperties(
                            @{
                                InstanceName         = 'SSRS'
                                Action               = 'Install'
                                MediaPath            = Join-Path -Path $TestDrive -ChildPath 'InvalidFile.txt'
                                AcceptLicensingTerms = $true
                                Edition              = 'Developer'
                            }
                        )
                    } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
                }
            }
        }
    }

    Context 'When passing LogPath with invalid path' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                    InstanceName         = 'SSRS'
                    Action               = 'Install'
                    MediaPath            = Join-Path -Path $TestDrive -ChildPath 'setup.exe'
                    AcceptLicensingTerms = $true
                    Edition              = 'Developer'
                    LogPath              = $TestDrive | Join-Path -ChildPath 'MissingParent' | Join-Path -ChildPath 'Logs'
                }
            }

            Set-Content -Path (Join-Path -Path $TestDrive -ChildPath 'setup.exe') -Value 'This is the mocked setup executable file.'
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getInvalidArgumentRecordParameters = @{
                    Message     = $script:mockSqlRSSetupInstance.localizedData.LogPath_ParentMissing -f (Join-Path -Path $TestDrive -ChildPath 'MissingParent')
                    ArgumentName = 'LogPath'
                }

                $mockExpectedErrorMessage = Get-InvalidArgumentRecord @getInvalidArgumentRecordParameters

                {
                    $script:mockSqlRSSetupInstance.AssertProperties(
                        @{
                            InstanceName         = 'SSRS'
                            Action               = 'Install'
                            MediaPath            = Join-Path -Path $TestDrive -ChildPath 'setup.exe'
                            AcceptLicensingTerms = $true
                            Edition              = 'Developer'
                            LogPath              = $TestDrive | Join-Path -ChildPath 'MissingParent' | Join-Path -ChildPath 'Logs'
                        }
                    )
                } | Should -Throw -ExpectedMessage $mockExpectedErrorMessage
            }
        }
    }
}

Describe 'SqlRSSetup\NormalizeProperties()' -Tag 'NormalizeProperties' {
    Context 'When the passing all path parameters' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                    InstanceName         = 'SSRS'
                    Action               = 'Install'
                    AcceptLicensingTerms = $true
                    Edition              = 'Developer'
                    MediaPath            = $TestDrive
                    LogPath              = $TestDrive | Join-Path -ChildPath 'Logs'
                    InstallFolder        = $TestDrive | Join-Path -ChildPath 'SSRS'
                }
            }

            Mock -CommandName Format-Path
        }

        It 'Should call the expected mock' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockSqlRSSetupInstance.NormalizeProperties(
                    @{
                        InstanceName         = 'SSRS'
                        Action               = 'Install'
                        AcceptLicensingTerms = $true
                        Edition              = 'Developer'
                        MediaPath            = $TestDrive
                        LogPath              = $TestDrive | Join-Path -ChildPath 'Logs'
                        InstallFolder        = $TestDrive | Join-Path -ChildPath 'SSRS'
                    }
                )

                Should -Invoke -CommandName 'Format-Path' -Exactly -Times 3 -Scope It
            }
        }
    }

    Context 'When the passing one path parameter' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                    InstanceName         = 'SSRS'
                    Action               = 'Install'
                    AcceptLicensingTerms = $true
                    Edition              = 'Developer'
                    LogPath              = $TestDrive | Join-Path -ChildPath 'Logs'
                }
            }

            Mock -CommandName Format-Path
        }

        It 'Should call the expected mock' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockSqlRSSetupInstance.NormalizeProperties(
                    @{
                        InstanceName         = 'SSRS'
                        Action               = 'Install'
                        AcceptLicensingTerms = $true
                        Edition              = 'Developer'
                        LogPath              = $TestDrive | Join-Path -ChildPath 'Logs'
                    }
                )

                Should -Invoke -CommandName 'Format-Path' -Exactly -Times 1 -Scope It
            }
        }
    }
}
