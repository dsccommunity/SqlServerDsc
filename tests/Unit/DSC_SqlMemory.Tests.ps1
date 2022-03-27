<#
    .SYNOPSIS
        Unit test for DSC_SqlMemory DSC resource.
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
    $script:dscResourceName = 'DSC_SqlMemory'

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
        BeforeAll {
            $mockConnectSQL = {
                $mockMinServerMemoryObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name DisplayName -Value 'min server memory (MB)' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Description -Value 'Minimum size of server memory (MB)' -PassThru |
                    Add-Member -MemberType NoteProperty -Name RunValue -Value 2048 -PassThru |
                    Add-Member -MemberType NoteProperty -Name ConfigValue -Value 2048 -PassThru -Force

                $mockMaxServerMemoryObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name DisplayName -Value 'max server memory (MB)' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Description -Value 'Maximum size of server memory (MB)' -PassThru |
                    Add-Member -MemberType NoteProperty -Name RunValue -Value 10300 -PassThru |
                    Add-Member -MemberType NoteProperty -Name ConfigValue -Value 10300 -PassThru -Force

                $mockServerConfigurationObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'MinServerMemory' -Value $mockMinServerMemoryObject -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'MaxServerMemory' -Value $mockMaxServerMemoryObject -PassThru -Force

                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType NoteProperty -Name 'Configuration' -Value $mockServerConfigurationObject -PassThru -Force
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

                $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                $result.MinMemory | Should -Be 2048
                $result.MaxMemory | Should -Be 10300
                $result.IsActiveNode | Should -BeFalse
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

    Context 'When specifying the wrong combination of parameters' {
        Context 'When specifying dynamic value together with a specific value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DynamicAlloc = $true
                    $mockTestTargetResourceParameters.MaxMemory = $true

                    $mockErrorMessage = '{0} (Parameter ''MaxMemory'')' -f $script:localizedData.MaxMemoryParamMustBeNull

                     { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying dynamic value together with a percentage value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DynamicAlloc = $true
                    $mockTestTargetResourceParameters.MaxMemoryPercent = 50

                    $mockErrorMessage = '{0} (Parameter ''MaxMemoryPercent'')' -f $script:localizedData.MaxMemoryPercentParamMustBeNull

                     { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying specific value together with a percentage value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MaxMemory = 8192
                    $mockTestTargetResourceParameters.MaxMemoryPercent = 50

                    $mockErrorMessage = '{0} (Parameter ''MaxMemoryPercent'')' -f $script:localizedData.MaxMemoryPercentParamMustBeNull

                     { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying specific value together with a percentage value for minimum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MinMemory = 8192
                    $mockTestTargetResourceParameters.MinMemoryPercent = 50

                    $mockErrorMessage = '{0} (Parameter ''MinMemoryPercent'')' -f $script:localizedData.MinMemoryPercentParamMustBeNull

                     { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying $null as the specific value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MaxMemory = $null

                    $mockErrorMessage = '{0} (Parameter ''MaxMemory'')' -f $script:localizedData.MaxMemoryParamMustNotBeNull

                     { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying 0 (zero) as the specific value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MaxMemory = 0

                    $mockErrorMessage = '{0} (Parameter ''MaxMemory'')' -f $script:localizedData.MaxMemoryParamMustNotBeNull

                     { Test-TargetResource @mockTestTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When no specific values for maximum and minimum memory should be set (use default values)' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 0
                        MaxMemory    = 2147483647
                        IsActiveNode = $true
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

        Context 'When specifying a specific value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 10300
                        IsActiveNode = $true
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MaxMemory = 10300

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When specifying a specific value for minimum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 10300
                        IsActiveNode = $true
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MinMemory = 2048

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When specifying to percentage value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscPercentMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    #$mockTestTargetResourceParameters.DynamicAlloc = $true
                    $mockTestTargetResourceParameters.MaxMemoryPercent = 50

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When specifying to percentage value for minimum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 8192
                        MaxMemory    = 10300
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscPercentMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MinMemoryPercent = 50

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When specifying to use a dynamic value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192 # MB
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.DynamicAlloc = $true

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When no specific values for maximum and minimum memory should be set (use default values)' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 1036
                        IsActiveNode = $true
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

        Context 'When specifying a specific value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 10300
                        IsActiveNode = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MaxMemory = 15000

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When specifying a specific value for minimum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 10300
                        IsActiveNode = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MinMemory = 4096

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When specifying to percentage value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscPercentMemory -MockWith {
                    return 16384 # MB
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    #$mockTestTargetResourceParameters.DynamicAlloc = $true
                    $mockTestTargetResourceParameters.MaxMemoryPercent = 50

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When specifying to percentage value for minimum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 8192
                        MaxMemory    = 10300
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscPercentMemory -MockWith {
                    return 16385 # MB
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.MinMemoryPercent = 50

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When specifying to use a dynamic value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $true
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 16384 # MB
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

        Context 'When the node is not the active node and parameter ProcessOnlyOnActiveNode is set to True' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        MinMemory    = 2048
                        MaxMemory    = 8192
                        IsActiveNode = $false
                    }
                }

                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 16384 # MB
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.ProcessOnlyOnActiveNode = $true
                    $mockTestTargetResourceParameters.DynamicAlloc = $true

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
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

    Context 'When specifying the wrong combination of parameters' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                # Can return any value since the content is never used.
                return 'Anything'
            }
        }

        Context 'When specifying dynamic value together with a specific value for maximum memory' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DynamicAlloc = $true
                    $mockSetTargetResourceParameters.MaxMemory = $true

                    $mockErrorMessage = '{0} (Parameter ''MaxMemory'')' -f $script:localizedData.MaxMemoryParamMustBeNull

                     { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying dynamic value together with a percentage value for maximum memory' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DynamicAlloc = $true
                    $mockSetTargetResourceParameters.MaxMemoryPercent = 50

                    $mockErrorMessage = '{0} (Parameter ''MaxMemoryPercent'')' -f $script:localizedData.MaxMemoryPercentParamMustBeNull

                     { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying specific value together with a percentage value for maximum memory' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxMemory = 8192
                    $mockSetTargetResourceParameters.MaxMemoryPercent = 50

                    $mockErrorMessage = '{0} (Parameter ''MaxMemoryPercent'')' -f $script:localizedData.MaxMemoryPercentParamMustBeNull

                     { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying specific value together with a percentage value for minimum memory' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MinMemory = 8192
                    $mockSetTargetResourceParameters.MinMemoryPercent = 50

                    $mockErrorMessage = '{0} (Parameter ''MinMemoryPercent'')' -f $script:localizedData.MinMemoryPercentParamMustBeNull

                     { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying $null as the specific value for maximum memory' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxMemory = $null

                    $mockErrorMessage = '{0} (Parameter ''MaxMemory'')' -f $script:localizedData.MaxMemoryParamMustNotBeNull

                     { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }

        Context 'When specifying 0 (zero) as the specific value for maximum memory' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxMemory = 0

                    $mockErrorMessage = '{0} (Parameter ''MaxMemory'')' -f $script:localizedData.MaxMemoryParamMustNotBeNull

                     { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            $mockConnectSQL = {
                $mockMinServerMemoryObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name DisplayName -Value 'min server memory (MB)' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Description -Value 'Minimum size of server memory (MB)' -PassThru |
                    Add-Member -MemberType NoteProperty -Name RunValue -Value 2048 -PassThru |
                    Add-Member -MemberType NoteProperty -Name ConfigValue -Value 2048 -PassThru -Force

                $mockMaxServerMemoryObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name DisplayName -Value 'max server memory (MB)' -PassThru |
                    Add-Member -MemberType NoteProperty -Name Description -Value 'Maximum size of server memory (MB)' -PassThru |
                    Add-Member -MemberType NoteProperty -Name RunValue -Value 10300 -PassThru |
                    Add-Member -MemberType NoteProperty -Name ConfigValue -Value 10300 -PassThru -Force

                $mockServerConfigurationObject = New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'MinServerMemory' -Value $mockMinServerMemoryObject -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'MaxServerMemory' -Value $mockMaxServerMemoryObject -PassThru -Force

                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType NoteProperty -Name 'Configuration' -Value $mockServerConfigurationObject -PassThru -Force |
                    Add-Member -MemberType ScriptMethod -Name Alter -Value {
                        InModuleScope -ScriptBlock {
                            $script:mockMethodAlterWasRun += 1
                        }

                        if ($script:mockInvalidOperationAlterMethod)
                        {
                            throw 'Mock InvalidOperationException'
                        }

                        if ( $this.Configuration.MinServerMemory.ConfigValue -ne $mockExpectedMinMemoryForAlterMethod )
                        {
                            throw "Called mocked Alter() method without setting the right minimum server memory. Expected '{0}'. But was '{1}'." -f $mockExpectedMinMemoryForAlterMethod, $this.Configuration.MinServerMemory.ConfigValue
                        }

                        if ( $this.Configuration.MaxServerMemory.ConfigValue -ne $mockExpectedMaxMemoryForAlterMethod )
                        {
                            throw "Called mocked Alter() method without setting the right maximum server memory. Expected '{0}'. But was '{1}'." -f $mockExpectedMaxMemoryForAlterMethod, $this.Configuration.MaxServerMemory.ConfigValue
                        }
                    } -PassThru -Force
            }


            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL
            Mock -CommandName Test-ActiveNode -MockWith {
                return $false
            }

        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodAlterWasRun = 0
            }
        }

        Context 'When no specific values for maximum and minimum memory should be set (use default values)' {
            It 'Should not throw and call the correct mocked method' {
                $mockExpectedMaxMemoryForAlterMethod = 2147483647
                $mockExpectedMinMemoryForAlterMethod = 0

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Ensure = 'Absent'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
                }
            }
        }

        Context 'When setting a specific value for maximum memory' {
            It 'Should not throw and call the correct mocked method' {
                $mockExpectedMaxMemoryForAlterMethod = 15000
                $mockExpectedMinMemoryForAlterMethod = 2048

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxMemory = 15000

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
                }
            }
        }

        Context 'When setting a specific value for minimum memory' {
            It 'Should not throw and call the correct mocked method' {
                $mockExpectedMaxMemoryForAlterMethod = 10300
                $mockExpectedMinMemoryForAlterMethod = 4096

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MinMemory = 4096

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
                }
            }
        }

        Context 'When setting a percentage value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-SqlDscPercentMemory -MockWith {
                    return 8192
                }
            }

            It 'Should not throw and call the correct mocked method' {
                $mockExpectedMaxMemoryForAlterMethod = 8192
                $mockExpectedMinMemoryForAlterMethod = 2048

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxMemoryPercent = 50

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
                }
            }
        }

        Context 'When setting a percentage value for minimum memory' {
            BeforeAll {
                Mock -CommandName Get-SqlDscPercentMemory -MockWith {
                    return 8192
                }
            }

            It 'Should not throw and call the correct mocked method' {
                $mockExpectedMaxMemoryForAlterMethod = 10300
                $mockExpectedMinMemoryForAlterMethod = 8192

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MinMemoryPercent = 50

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
                }
            }
        }

        Context 'When setting a dynamic value for maximum memory' {
            BeforeAll {
                Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
                    return 8192
                }
            }

            It 'Should not throw and call the correct mocked method' {
                $mockExpectedMaxMemoryForAlterMethod = 8192
                $mockExpectedMinMemoryForAlterMethod = 2048

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.DynamicAlloc = $true

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    $mockMethodAlterWasRun | Should -Be 1
                }
            }
        }

        Context 'When setting a value and method Alter() fails' {
            It 'Should not throw and call the correct mocked method' {
                $script:mockInvalidOperationAlterMethod = $true

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.MaxMemory = 15000

                    $mockErrorMessage = '*{0}*Mock InvalidOperationException*' -f ($script:localizedData.AlterServerMemoryFailed -f 'localhost', 'MSSQLSERVER')

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage $mockErrorMessage

                    $mockMethodAlterWasRun | Should -Be 1
                }

                $script:mockInvalidOperationAlterMethod = $false
            }
        }
    }
}

Describe 'SqlMemory\Get-SqlDscDynamicMaxMemory' -Tag 'Helper' {
    Context 'When the physical memory should be calculated' {
        Context 'When number of cores is 2' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    return  [PSCustomObject]@{
                        NumberOfCores = 2
                    }
                } -ParameterFilter {
                    $ClassName -eq 'Win32_Processor'
                }
            }

            Context 'When OS Architecture is <MockOSArchitecture>' -ForEach @(
                @{
                    MockOSArchitecture = '64-bit'
                }
                @{
                    MockOSArchitecture = '32-bit'
                }
                @{
                    MockOSArchitecture = 'IA64-bit'
                }

            ) {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return [PSCustomObject]@{
                            OSArchitecture = $MockOSArchitecture
                        }
                    } -ParameterFilter {
                        $ClassName -eq 'Win32_OperatingSystem'
                    }
                }

                Context 'When physical memory is less than 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 20426260480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-SqlDscDynamicMaxMemory

                            $result | Should -Be 14560
                        }
                    }
                }

                Context 'When physical memory is equal to 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 21474836480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-SqlDscDynamicMaxMemory

                            $result | Should -Be 16896
                        }
                    }
                }

                Context 'When physical memory is more than 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 31960596480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-SqlDscDynamicMaxMemory

                            $result | Should -Be 25646
                        }
                    }
                }
            }
        }

        Context 'When number of cores is 4' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    return  [PSCustomObject]@{
                        NumberOfCores = 4
                    }
                } -ParameterFilter {
                    $ClassName -eq 'Win32_Processor'
                }
            }

            Context 'When OS Architecture is 64-bit' {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return [PSCustomObject]@{
                            OSArchitecture = '64-bit'
                        }
                    } -ParameterFilter {
                        $ClassName -eq 'Win32_OperatingSystem'
                    }
                }

                Context 'When physical memory is more than 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 31960596480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        $result = Get-SqlDscDynamicMaxMemory

                        $result | Should -Be 25134
                    }
                }
            }

            Context 'When OS Architecture is 32-bit' {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return [PSCustomObject]@{
                            OSArchitecture = '32-bit'
                        }
                    } -ParameterFilter {
                        $ClassName -eq 'Win32_OperatingSystem'
                    }
                }

                Context 'When physical memory is more than 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 31960596480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        $result = Get-SqlDscDynamicMaxMemory

                        $result | Should -Be 25390
                    }
                }
            }

            Context 'When OS Architecture is IA64-bit' {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return [PSCustomObject]@{
                            OSArchitecture = 'IA64-bit'
                        }
                    } -ParameterFilter {
                        $ClassName -eq 'Win32_OperatingSystem'
                    }
                }

                Context 'When physical memory is more than 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 31960596480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        $result = Get-SqlDscDynamicMaxMemory

                        $result | Should -Be 24622
                    }
                }
            }
        }

        Context 'When number of cores is 6' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    return  [PSCustomObject]@{
                        NumberOfCores = 6
                    }
                } -ParameterFilter {
                    $ClassName -eq 'Win32_Processor'
                }
            }

            Context 'When OS Architecture is 64-bit' {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return [PSCustomObject]@{
                            OSArchitecture = '64-bit'
                        }
                    } -ParameterFilter {
                        $ClassName -eq 'Win32_OperatingSystem'
                    }
                }

                Context 'When physical memory is more than 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 31960596480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        $result = Get-SqlDscDynamicMaxMemory

                        $result | Should -Be 24078
                    }
                }
            }

            Context 'When OS Architecture is 32-bit' {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return [PSCustomObject]@{
                            OSArchitecture = '32-bit'
                        }
                    } -ParameterFilter {
                        $ClassName -eq 'Win32_OperatingSystem'
                    }
                }

                Context 'When physical memory is more than 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 31960596480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        $result = Get-SqlDscDynamicMaxMemory

                        $result | Should -Be 24350
                    }
                }
            }

            Context 'When OS Architecture is IA64-bit' {
                BeforeAll {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return [PSCustomObject]@{
                            OSArchitecture = 'IA64-bit'
                        }
                    } -ParameterFilter {
                        $ClassName -eq 'Win32_OperatingSystem'
                    }
                }

                Context 'When physical memory is more than 20480MB' {
                    BeforeAll {
                        Mock -CommandName Get-CimInstance -MockWith {
                            return New-Object -TypeName PSObject -Property @{
                                TotalPhysicalMemory = 31960596480
                            }
                        } -ParameterFilter {
                            $ClassName -eq 'Win32_ComputerSystem'
                        }
                    }

                    It 'Should return the correct max memory (in megabytes) value' {
                        $result = Get-SqlDscDynamicMaxMemory

                        $result | Should -Be 23534
                    }
                }
            }
        }
    }

    Context 'When the physical memory fails to be calculated' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                throw 'mocked unknown error'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.ErrorGetDynamicMaxMemory

                { Get-SqlDscDynamicMaxMemory } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }
    }
}

Describe 'SqlMemory\Get-SqlDscPercentMemory' -Tag 'Helper' {
    Context 'When the physical memory should be calculated' {
        Context 'When physical memory is equal to 20480MB' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        TotalPhysicalMemory = 21474836480
                    }
                } -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                }
            }

            It 'Should return the correct memory (in megabytes) value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-SqlDscPercentMemory -PercentMemory 80

                    $result | Should -Be 16384
                }
            }
        }

        Context 'When physical memory is equal to 1218.4MB' {
            BeforeAll {
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        TotalPhysicalMemory = 1596981248
                    }
                } -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                }
            }

            It 'Should return the correct rounded memory (in megabytes) value' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-SqlDscPercentMemory -PercentMemory 50

                    $result | Should -Be 762
                }
            }
        }
    }

    Context 'When percentage of physical memory fails to be calculated' {
        BeforeAll {
            Mock -CommandName Get-CimInstance -MockWith {
                throw 'mocked unknown error'
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.ErrorGetPercentMemory

                { Get-SqlDscPercentMemory -PercentMemory 80 } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }
    }
}


# try
# {
#     InModuleScope $script:dscResourceName {
#         $mockServerName = 'localhost'
#         $mockInstanceName = 'MSSQLSERVER'
#         $mockMinServerMemory = 2048
#         $mockMaxServerMemory = 10300
#         $mockPhysicalMemoryCapacity = 8589934592
#         $mockExpectedMinMemoryForAlterMethod = 0
#         $mockExpectedMaxMemoryForAlterMethod = 2147483647
#         $mockTestActiveNode = $true

#         # Default parameters that are used for the It-blocks
#         $mockDefaultParameters = @{
#             InstanceName = $mockInstanceName
#             ServerName   = $mockServerName
#             Verbose = $true
#         }

#         #region Function mocks

#         $mockConnectSQL = {
#             return @(
#                 (
#                     # New-Object -TypeName Object |
#                     New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server |
#                         Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockInstanceName -PassThru -Force |
#                         Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockServerName -PassThru -Force |
#                         Add-Member -MemberType ScriptProperty -Name Configuration -Value {
#                         return @( ( New-Object -TypeName Object |
#                                     Add-Member -MemberType ScriptProperty -Name MinServerMemory -Value {
#                                     return @( ( New-Object -TypeName Object |
#                                                 Add-Member -MemberType NoteProperty -Name DisplayName -Value 'min server memory (MB)' -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name Description -Value 'Minimum size of server memory (MB)' -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name RunValue -Value $mockMinServerMemory -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name ConfigValue -Value $mockMinServerMemory -PassThru -Force
#                                         ) )
#                                 } -PassThru |
#                                     Add-Member -MemberType ScriptProperty -Name MaxServerMemory -Value {
#                                     return @( ( New-Object -TypeName Object |
#                                                 Add-Member -MemberType NoteProperty -Name DisplayName -Value 'max server memory (MB)' -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name Description -Value 'Maximum size of server memory (MB)' -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name RunValue -Value $mockMaxServerMemory -PassThru |
#                                                 Add-Member -MemberType NoteProperty -Name ConfigValue -Value $mockMaxServerMemory -PassThru -Force
#                                         ) )
#                                 } -PassThru -Force
#                             ) )
#                     } -PassThru -Force |
#                         Add-Member -MemberType ScriptMethod -Name Alter -Value {
#                         if ( $this.Configuration.MinServerMemory.ConfigValue -ne $mockExpectedMinMemoryForAlterMethod )
#                         {
#                             throw "Called mocked Alter() method without setting the right minimum server memory. Expected '{0}'. But was '{1}'." -f $mockExpectedMinMemoryForAlterMethod, $this.Configuration.MinServerMemory.ConfigValue
#                         }
#                         if ( $this.Configuration.MaxServerMemory.ConfigValue -ne $mockExpectedMaxMemoryForAlterMethod )
#                         {
#                             throw "Called mocked Alter() method without setting the right maximum server memory. Expected '{0}'. But was '{1}'." -f $mockExpectedMaxMemoryForAlterMethod, $this.Configuration.MaxServerMemory.ConfigValue
#                         }
#                     } -PassThru -Force
#                 )
#             )
#         }

#         #endregion

#         Describe "DSC_SqlMemory\Get-TargetResource" -Tag 'Get' {
#             Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
#             Mock -CommandName Test-ActiveNode -MockWith { return $mockTestActiveNode } -Verifiable

#             Context 'When the system is either in the desired state or not in the desired state' {
#                 $testParameters = $mockDefaultParameters

#                 $result = Get-TargetResource @testParameters

#                 It 'Should return the current value for MinMemory' {
#                     $result.MinMemory | Should -Be 2048
#                 }

#                 It 'Should return the current value for MaxMemory' {
#                     $result.MaxMemory | Should -Be 10300
#                 }

#                 It 'Should return the same values as passed as parameters' {
#                     $result.ServerName | Should -Be $testParameters.ServerName
#                     $result.InstanceName | Should -Be $testParameters.InstanceName
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


#         Describe "DSC_SqlMemory\Set-TargetResource" -Tag 'Set' {
#             $mockMinServerMemory = 0
#             $mockMaxServerMemory = 2147483647

#             Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
#             Mock -CommandName Get-SqlDscDynamicMaxMemory -MockWith {
#                 return 16384 # MB
#             }
#             Mock -CommandName Get-SqlDscPercentMemory -MockWith {
#                 return 16384 # MB
#             }

#             Context 'When the MaxMemory parameter is not null and DynamicAlloc is set to true' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxMemory    = 8192
#                     DynamicAlloc = $true
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error' {
#                     { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxMemoryParamMustBeNull
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
#                 }
#             }

#             Context 'When the MaxMemoryPercent parameter is not null and DynamicAlloc is set to true' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxMemoryPercent = 80
#                     DynamicAlloc = $true
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error' {
#                     { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxMemoryPercentParamMustBeNull
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscPercentMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscPercentMemory -Exactly -Times 0 -Scope Context
#                 }
#             }

#             Context 'When the MaxMemoryPercent and MaxMemory parameters are not null and DynamicAlloc is set to false' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxMemory = 8192
#                     MaxMemoryPercent = 80
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error' {
#                     { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxMemoryPercentParamMustBeNull
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscPercentMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscPercentMemory -Exactly -Times 0 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
#                 }
#             }

#             Context 'When the MinMemoryPercent and MinMemory parameters are not null and MaxMemory is not null' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MinMemory = 1024
#                     MinMemoryPercent = 80
#                     MaxMemory = 8192
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error' {
#                     { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MinMemoryPercentParamMustBeNull
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscPercentMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscPercentMemory -Exactly -Times 0 -Scope Context
#                 }
#             }

#             Context 'When the parameters MaxMemory and MaxMemoryPercent are null and DynamicAlloc is set to false' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error' {
#                     { Set-TargetResource @testParameters } | Should -Throw $script:localizedData.MaxMemoryParamMustNotBeNull
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscPercentMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscPercentMemory -Exactly -Times 0 -Scope Context
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Absent' {
#                 $mockExpectedMinMemoryForAlterMethod = 0
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     Ensure = 'Absent'
#                 }

#                 It 'Should set the MinMemory and MaxMemory to the default values' {
#                     { Set-TargetResource @testParameters } | Should -Not -Throw
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Present, and DynamicAlloc is set to false' {
#                 $mockMinServerMemory = 1024
#                 $mockMaxServerMemory = 8192

#                 Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

#                 $mockExpectedMinMemoryForAlterMethod = 1024
#                 $mockExpectedMaxMemoryForAlterMethod = 8192
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxMemory    = 8192
#                     MinMemory    = 1024
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                 }

#                 It 'Should set the MinMemory and MaxMemory to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to false' {
#                     { Set-TargetResource @testParameters } | Should -Not -Throw
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
#                 }
#             }

#             Context 'When the system is not in the desired state and Ensure is set to Present, Max/MinMemoryPercent specified and DynamicAlloc is set to false' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                     MaxMemoryPercent = 80
#                     MinMemoryPercent = 80
#                 }

#                 It 'Should set the MaxMemoryPercent and MinMemoryPercent to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to false' {
#                     { Set-TargetResource @testParameters } | Should -Not -Throw
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should call the mock function Get-SqlDscPercentMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscPercentMemory -Exactly -Times 2 -Scope Context
#                 }
#             }

#             Context 'When the system (OS IA64-bit) is not in the desired state and Ensure is set to Present, and DynamicAlloc is set to true' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     DynamicAlloc = $true
#                     Ensure       = 'Present'
#                     MinMemory    = 2048
#                 }

#                 It 'Should set the MaxMemory to the correct values when Ensure parameter is set to Present and DynamicAlloc is set to true' {
#                     { Set-TargetResource @testParameters } | Should -Not -Throw
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should call the mock function Get-SqlDscDynamicMaxMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 1 -Scope Context
#                 }
#             }

#             Mock -CommandName Connect-SQL -MockWith {
#                 $mockSqlServerObject = [PSCustomObject]@{
#                     InstanceName                = $mockInstanceName
#                     ComputerNamePhysicalNetBIOS = $mockServerName
#                     Configuration               = @{
#                         MinServerMemory = @{
#                             DisplayName = 'min server memory (MB)'
#                             Description = 'Minimum size of server memory (MB)'
#                             RunValue    = 0
#                             ConfigValue = 0
#                         }
#                         MaxServerMemory = @{
#                             DisplayName = 'max server memory (MB)'
#                             Description = 'Maximum size of server memory (MB)'
#                             RunValue    = 10300
#                             ConfigValue = 10300
#                         }
#                     }
#                 }

#                 # Add the Alter method
#                 $mockSqlServerObject | Add-Member -MemberType ScriptMethod -Name Alter -Value {
#                     throw 'Mock Alter Method was called with invalid operation.'
#                 }

#                 $mockSqlServerObject
#             } -Verifiable

#             Context 'When the desired MinMemory and MaxMemory fails to be set' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxMemory    = 8192
#                     MinMemory    = 1024
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error' {
#                     { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.AlterServerMemoryFailed -f $env:COMPUTERNAME, $mockInstanceName)
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
#                 }
#             }

#             Context 'When the desired MinMemoryPercent and MaxMemoryPercent fails to be set' {
#                 $testParameters = $mockDefaultParameters
#                 $testParameters += @{
#                     MaxMemoryPercent    = 80
#                     MinMemoryPercent    = 80
#                     DynamicAlloc = $false
#                     Ensure       = 'Present'
#                 }

#                 It 'Should throw the correct error' {
#                     { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.AlterServerMemoryFailed -f $env:COMPUTERNAME, $mockInstanceName)
#                 }

#                 It 'Should call the mock function Connect-SQL' {
#                     Assert-MockCalled -CommandName Connect-SQL -Exactly -Times 1 -Scope Context
#                 }

#                 It 'Should not call the mock function Get-SqlDscDynamicMaxMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscDynamicMaxMemory -Exactly -Times 0 -Scope Context
#                 }

#                 It 'Should call the mock function Get-SqlDscPercentMemory' {
#                     Assert-MockCalled -CommandName Get-SqlDscPercentMemory -Exactly -Times 2 -Scope Context
#                 }
#             }

#             Assert-VerifiableMock
#         }


# }
# finally
# {
#     Invoke-TestCleanup
# }
