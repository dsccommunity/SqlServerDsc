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
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

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
                { [SqlRSSetup]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default or empty constructor' {
            InModuleScope -ScriptBlock {
                $instance = [SqlRSSetup]::new()
                $instance | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
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
                                InstanceName = 'SSRS'
                            }
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                            return
                        } -PassThru |
                        Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                            return
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlRSSetupInstance.Get()

                    $currentState.InstanceName | Should -Be 'SSRS'
                    $currentState.Timeout | Should -Be 7200
                    $currentState.Action | Should -BeNullOrEmpty
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
                    $currentState.ProductVersion | Should -BeNullOrEmpty
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
                        }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    $currentState = $script:mockSqlRSSetupInstance.Get()

                    $currentState.InstanceName | Should -BeNull
                    $currentState.Installed | Should -BeFalse
                    $currentState.Timeout | Should -Be 7200
                    $currentState.Action | Should -BeNullOrEmpty
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
                    $currentState.ProductVersion | Should -BeNullOrEmpty
                }
            }
        }
    }
}

Describe 'SqlRSSetup\Test()' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockSqlRSSetupInstance = [SqlRSSetup] @{
                InstanceName = 'SSRS'
                Edition      = 'Developer'
                Action       = 'Install'
            }
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
                    }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance.Test() | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance |
                    # Mock method Compare() which is called by the base method Set()
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'Compare' -Value {
                        <#
                            Compare() method shall only return the properties NOT in
                            desired state, in the format of the command Compare-DscParameterState.
                        #>
                        return @(
                            @{
                                Property      = 'Installed'
                                ExpectedValue = $true
                                ActualValue   = $false
                            }
                        )
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'NormalizeProperties' -Value {
                        return
                    }
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $script:mockSqlRSSetupInstance.Test() | Should -BeFalse
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
                    }
            }
        }

        It 'Should not call method Modify()' {
            InModuleScope -ScriptBlock {
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
                            Property      = 'Installed'
                            ExpectedValue = $true
                            ActualValue   = $false
                        }
                    } -PassThru |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'AssertProperties' -Value {
                        return
                    }
            }
        }

        It 'Should call method Modify()' {
            InModuleScope -ScriptBlock {
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
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    } -PassThru
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
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
                } |
                    Add-Member -Force -MemberType 'ScriptMethod' -Name 'GetServerObject' -Value {
                        return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
                    } -PassThru
            }

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return @(
                    [PSCustomObject] @{
                        InstanceName   = 'SSRS'
                        InstallFolder  = 'C:\Program Files\SSRS'
                        ProductVersion = '15.0.2000.5'
                    }
                )
            }
        }

        It 'Should return the correct values' {
            InModuleScope -ScriptBlock {
                $currentState = $script:mockSqlRSSetupInstance.GetCurrentState(
                    @{
                        Name         = 'InstanceName'
                        InstanceName = 'SSRS'
                    }
                )

                $currentState.InstanceName | Should -Be 'SSRS'
                $currentState.ProductVersion | Should -Be '15.0.2000.5'
                $currentState.InstallFolder | Should -Be 'C:\Program Files\SSRS'
            }
        }
    }
}
