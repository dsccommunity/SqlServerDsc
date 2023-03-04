<#
    .SYNOPSIS
        Unit test for DSC_SqlAlwaysOnService DSC resource.
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
    $script:dscResourceName = 'DSC_SqlAlwaysOnService'

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

Describe 'SqlAlwaysOnService\Get-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                ServerName   = 'Server01'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When using a <MockTitleText>' -ForEach @(
            @{
                MockTitleText = 'default instance'
                MockInstanceName = 'MSSQLSERVER'
            }
            @{
                MockTitleText = 'named instance'
                MockInstanceName = 'NamedInstance'
            }
        ) {
            Context 'When HADR should be disabled' {
                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName PSObject -Property @{
                            IsHadrEnabled = $false
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters['Ensure'] = 'Absent'
                        $script:mockGetTargetResourceParameters['InstanceName'] = $MockInstanceName
                    }
                }

                It 'Should return that HADR is disabled' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }

                    Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    }
                }

                It 'Should return the correct values for other properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be $mockGetTargetResourceParameters.Ensure
                        $result.RestartTimeout | Should -Not -BeNullOrEmpty
                    }
                }
            }

            Context 'When HADR should be enabled' {
                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName PSObject -Property @{
                            IsHadrEnabled = $true
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters['Ensure'] = 'Present'
                        $script:mockGetTargetResourceParameters['InstanceName'] = $MockInstanceName
                    }
                }

                It 'Should return that HADR is disabled' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                    }

                    Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    }
                }

                It 'Should return the correct values for other properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be $mockGetTargetResourceParameters.Ensure
                        $result.RestartTimeout | Should -Not -BeNullOrEmpty
                    }
                }
            }

            # This it regression test for issue #519.
            Context 'When Server.IsHadrEnabled returns $null' {
                BeforeAll {
                    Mock -CommandName Connect-SQL -MockWith {
                        return New-Object -TypeName PSObject -Property @{
                            IsHadrEnabled = $null
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters['Ensure'] = 'Present'
                        $script:mockGetTargetResourceParameters['InstanceName'] = $MockInstanceName
                    }
                }

                It 'Should not fail with an error message' {
                    # Regression test for issue #519
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw 'Index operation failed; the array index evaluated to null'
                    }

                    Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }

                It 'Should return that HADR is disabled' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        # Get the current state
                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }

                    Should -Invoke -CommandName Connect-SQL -Scope It -Times 1 -Exactly
                }
            }
        }
    }
}

Describe 'SqlAlwaysOnService\Test-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                ServerName   = 'Server01'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When using a <MockTitleText>' -ForEach @(
            @{
                MockTitleText = 'default instance'
                MockInstanceName = 'MSSQLSERVER'
            }
            @{
                MockTitleText = 'named instance'
                MockInstanceName = 'NamedInstance'
            }
        ) {
            Context 'When HADR is already disabled' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName   = $MockInstanceName
                            Ensure         = 'Absent'
                            ServerName     = 'Server01'
                            RestartTimeout = 120
                        }
                    }
                }

                It 'Should return that HADR is disabled' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters['Ensure'] = 'Absent'
                        $script:mockTestTargetResourceParameters['InstanceName'] = $MockInstanceName

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Scope It -Times 1 -Exactly
                }
            }

            Context 'When HADR is already enabled' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName   = $MockInstanceName
                            Ensure         = 'Present'
                            ServerName     = 'Server01'
                            RestartTimeout = 120
                        }
                    }
                }

                It 'Should return that HADR is enabled' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters['Ensure'] = 'Present'
                        $script:mockTestTargetResourceParameters['InstanceName'] = $MockInstanceName

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }

                    Should -Invoke -CommandName Get-TargetResource -Scope It -Times 1 -Exactly
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When using a <MockTitleText>' -ForEach @(
            @{
                MockTitleText = 'default instance'
                MockInstanceName = 'MSSQLSERVER'
            }
            @{
                MockTitleText = 'named instance'
                MockInstanceName = 'NamedInstance'
            }
        ) {
            Context 'When HADR should be disabled' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName   = $MockInstanceName
                            Ensure         = 'Present'
                            ServerName     = 'Server01'
                            RestartTimeout = 120
                        }
                    }
                }

                It 'Should return that HADR is disabled' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters['Ensure'] = 'Absent'
                        $script:mockTestTargetResourceParameters['InstanceName'] = $MockInstanceName

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Scope It -Times 1 -Exactly
                }
            }

            Context 'When HADR should be enabled' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            InstanceName   = $MockInstanceName
                            Ensure         = 'Absent'
                            ServerName     = 'Server01'
                            RestartTimeout = 120
                        }
                    }
                }

                It 'Should return that HADR is enabled' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters['Ensure'] = 'Present'
                        $script:mockTestTargetResourceParameters['InstanceName'] = $MockInstanceName

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }

                    Should -Invoke -CommandName Get-TargetResource -Scope It -Times 1 -Exactly
                }
            }
        }
    }
}

Describe 'SqlAlwaysOnService\Set-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                ServerName   = 'Server01'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Import-SqlDscPreferredModule
            Mock -CommandName Restart-SqlService
        }

        Context 'When using a <MockTitleText>' -ForEach @(
            @{
                MockTitleText = 'default instance'
                MockInstanceName = 'MSSQLSERVER'
            }
            @{
                MockTitleText = 'named instance'
                MockInstanceName = 'NamedInstance'
            }
        ) {
            Context 'When HADR should be disabled' {
                BeforeAll {
                    Mock -CommandName Disable-SqlAlwaysOn
                    Mock -CommandName Test-TargetResource -MockWith {
                        return $true
                    }
                }

                It 'Should call the correct mocks to disable HADR' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters['Ensure'] = 'Absent'
                        $script:mockSetTargetResourceParameters['InstanceName'] = $MockInstanceName

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Import-SqlDscPreferredModule -Scope It -Times 1 -Exactly
                    Should -Invoke -CommandName Disable-SqlAlwaysOn -Scope It -Times 1 -Exactly
                    Should -Invoke -CommandName Restart-SqlService -Scope It -Times 1 -Exactly
                }
            }

            Context 'When HADR should be enabled' {
                BeforeAll {
                    Mock -CommandName Enable-SqlAlwaysOn
                    Mock -CommandName Test-TargetResource -MockWith {
                        return $true
                    }
                }

                It 'Should call the correct mocks to enable HADR' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters['Ensure'] = 'Present'
                        $script:mockSetTargetResourceParameters['InstanceName'] = $MockInstanceName

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Import-SqlDscPreferredModule -Scope It -Times 1 -Exactly
                    Should -Invoke -CommandName Enable-SqlAlwaysOn -Scope It -Times 1 -Exactly
                    Should -Invoke -CommandName Restart-SqlService -Scope It -Times 1 -Exactly
                }
            }

            Context 'When failing to change HADR' {
                BeforeAll {
                    Mock -CommandName Enable-SqlAlwaysOn
                    Mock -CommandName Test-TargetResource -MockWith {
                        return $false
                    }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters['Ensure'] = 'Present'
                        $script:mockSetTargetResourceParameters['InstanceName'] = $MockInstanceName

                        $mockErrorMessage = $script:localizedData.AlterAlwaysOnServiceFailed -f @(
                            'enabled',
                            $script:mockSetTargetResourceParameters.ServerName,
                            $script:mockSetTargetResourceParameters.InstanceName
                        )

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                    }
                }
            }
        }
    }
}
