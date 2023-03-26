<#
    .SYNOPSIS
        Unit test for DSC_SqlAlias DSC resource.
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
    $script:dscResourceName = 'DSC_SqlAlias'

    $env:SqlServerDscCI = $true

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName

    # Inject a stub in the module scope to support testing cross-plattform
    InModuleScope -ScriptBlock {
        function script:Get-CimInstance
        {
            param
            (
                $ClassName
            )
        }
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlAlias\Get-TargetResource' {
    BeforeAll {
        $mockRegistryPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
        $mockRegistryPathWow6432Node = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                Name = 'MyAlias'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When <OSArchitecture> node is using TCP' -ForEach @(
            @{
                OSArchitecture = '64-bit'
            }
            @{
                OSArchitecture = '32-bit'
            }
        ) {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value $OSArchitecture -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }
            }

            Context 'When the alias that using a specific TCP port already exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return @{
                            'MyAlias' = 'DBMSSOCN,SqlNode.company.local,1433'
                        }
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return @{
                            'MyAlias' = 'DBMSSOCN,SqlNode.company.local,1433'
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -Be 'SqlNode.company.local'
                        $result.Protocol | Should -Be 'TCP'
                        $result.TcpPort | Should -BeExactly 1433
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias that using a specific TCP port does not exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockGetTargetResourceParameters.Name = 'UnknownAlias'

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -BeNullOrEmpty
                        $result.Protocol | Should -Be ''
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias that using dynamic TCP port already exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return @{
                            'MyAlias' = 'DBMSSOCN,SqlNode.company.local'
                        }
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return @{
                            'MyAlias' = 'DBMSSOCN,SqlNode.company.local'
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -Be 'SqlNode.company.local'
                        $result.Protocol | Should -Be 'TCP'
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $true
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias that using dynamic TCP port does not exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockGetTargetResourceParameters.Name = 'UnknownAlias'

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -BeNullOrEmpty
                        $result.Protocol | Should -Be ''
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }
        }

        Context 'When <OSArchitecture> node is using Named Pipes' -ForEach @(
            @{
                OSArchitecture = '64-bit'
            }
            @{
                OSArchitecture = '32-bit'
            }
        ) {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value $OSArchitecture -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }
            }

            Context 'When the alias that using a specific TCP port already exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return @{
                            'MyAlias' = 'DBNMPNTW,\\SqlNode\PIPE\sql\query'
                        }
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return @{
                            'MyAlias' = 'DBNMPNTW,\\SqlNode\PIPE\sql\query'
                        }
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Present'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -BeNullOrEmpty
                        $result.Protocol | Should -Be 'NP'
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be '\\SqlNode\PIPE\sql\query'
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias does not exist' {
                BeforeAll {
                    # Mocking for protocol TCP
                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                        return $null
                    }
                }

                It 'Should return the correct values' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockGetTargetResourceParameters.Name = 'UnknownAlias'

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.ServerName | Should -BeNullOrEmpty
                        $result.Protocol | Should -Be ''
                        $result.TcpPort | Should -BeExactly 0
                        $result.UseDynamicTcpPort | Should -Be $false
                        $result.PipeName | Should -Be ''
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }
        }

        Context 'When the registry key under Wow6432Node differ from the one at the regular path' {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value '64-bit' -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }

                # Mocking for protocol TCP
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                    return @{
                        'MyAlias' = 'DBNMPNTW,\\SqlNode\PIPE\sql\query'
                    }
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                    return $null
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.ServerName | Should -BeNullOrEmpty
                    $result.Protocol | Should -Be ''
                    $result.TcpPort | Should -BeExactly 0
                    $result.UseDynamicTcpPort | Should -Be $false
                    $result.PipeName | Should -Be ''
                }
            }

            It 'Should call the correct mocks' {
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'win32_OperatingSystem'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq $mockRegistryPath
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq $mockRegistryPathWow6432Node
                } -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When the registry key exist but does not have any value' {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value '64-bit' -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }

                # Mocking for protocol TCP
                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPath } -MockWith {
                    return @{
                        'MyAlias' = ''
                    }
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter { $Path -eq $mockRegistryPathWow6432Node } -MockWith {
                    return @{
                        'MyAlias' = ''
                    }
                }
            }

            It 'Should return the correct values' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                    $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                    $result.ServerName | Should -BeNullOrEmpty
                    $result.Protocol | Should -Be ''
                    $result.TcpPort | Should -BeExactly 0
                    $result.UseDynamicTcpPort | Should -Be $false
                    $result.PipeName | Should -Be ''
                }
            }

            It 'Should call the correct mocks' {
                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'win32_OperatingSystem'
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq $mockRegistryPath
                } -Exactly -Times 1 -Scope Context

                Should -Invoke -CommandName Get-ItemProperty -ParameterFilter {
                    $Path -eq $mockRegistryPathWow6432Node
                } -Exactly -Times 1 -Scope Context
            }
        }
    }
}

Describe 'SqlAlias\Test-TargetResource' {
    BeforeAll {
        $mockRegistryPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
        $mockRegistryPathWow6432Node = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                Name = 'MyAlias'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When node is using TCP' {
            Context 'When the alias that using a specific TCP port already exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'TCP'
                            TcpPort           = 1433
                            UseDynamicTcpPort = $false
                            PipeName          = ''
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'TCP'
                        $script:mockTestTargetResourceParameters.TcpPort = 1433
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias that using dynamic TCP port already exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'TCP'
                            TcpPort           = 0
                            UseDynamicTcpPort = $true
                            PipeName          = ''
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'TCP'
                        $script:mockTestTargetResourceParameters.UseDynamicTcpPort = $true
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias should not exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Absent'
                            Name              = 'MyAlias'
                            ServerName        = ''
                            Protocol          = ''
                            TcpPort           = 0
                            UseDynamicTcpPort = $false
                            PipeName          = ''
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Ensure = 'Absent'
                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }
        }

        Context 'When node is using Named Pipes' {
            Context 'When the alias already exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'NP'
                            TcpPort           = 0
                            UseDynamicTcpPort = $false
                            PipeName          = '\\SqlNode.company.local\PIPE\sql\query'
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'NP'
                        $script:mockTestTargetResourceParameters.UseDynamicTcpPort = $false
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeTrue
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When alias should not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure            = 'Present'
                        Name              = 'MyAlias'
                        ServerName        = 'SqlNode.company.local'
                        Protocol          = 'TCP'
                        TcpPort           = 1433
                        UseDynamicTcpPort = $false
                        PipeName          = ''
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockTestTargetResourceParameters.Ensure = 'Absent'
                    $script:mockTestTargetResourceParameters.Name = 'MyAlias'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }

            It 'Should call the correct mocks' {
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When node should be using TCP' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure            = 'Absent'
                        Name              = 'MyAlias'
                        ServerName        = ''
                        Protocol          = ''
                        TcpPort           = 0
                        UseDynamicTcpPort = $false
                        PipeName          = ''
                    }
                }
            }

            Context 'When the alias that using a specific TCP port does not exist' {
                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'TCP'
                        $script:mockTestTargetResourceParameters.TcpPort = 1433
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias that using dynamic TCP port does not exist' {
                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'TCP'
                        $script:mockTestTargetResourceParameters.UseDynamicTcpPort = $true
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias exist but has wrong port number' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'TCP'
                            TcpPort           = 1433
                            UseDynamicTcpPort = $false
                            PipeName          = ''
                        }
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'TCP'
                        $script:mockTestTargetResourceParameters.TcpPort = 1500
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias already exist but does not use dynamic TCP port' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'TCP'
                            TcpPort           = 1433
                            UseDynamicTcpPort = $false
                            PipeName          = ''
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'TCP'
                        $script:mockTestTargetResourceParameters.UseDynamicTcpPort = $true
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias already exist but does not use static TCP port' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'TCP'
                            TcpPort           = 0
                            UseDynamicTcpPort = $true
                            PipeName          = ''
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'TCP'
                        $script:mockTestTargetResourceParameters.TcpPort = '1433'
                        $script:mockTestTargetResourceParameters.UseDynamicTcpPort = $false
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias already exist but does not use TCP protocol' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'NP'
                            TcpPort           = 0
                            UseDynamicTcpPort = $false
                            PipeName          = '\\SqlNode.company.local\PIPE\sql\query'
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'TCP'
                        $script:mockTestTargetResourceParameters.TcpPort = '1433'
                        $script:mockTestTargetResourceParameters.UseDynamicTcpPort = $false
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }
        }

        Context 'When node should be using Named Pipes' {
            Context 'When the alias does not exist' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Absent'
                            Name              = 'MyAlias'
                            ServerName        = ''
                            Protocol          = ''
                            TcpPort           = 0
                            UseDynamicTcpPort = $false
                            PipeName          = ''
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'NP'
                        $script:mockTestTargetResourceParameters.UseDynamicTcpPort = $false
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias already exist but has wrong server name' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'NP'
                            TcpPort           = 0
                            UseDynamicTcpPort = $false
                            PipeName          = '\\SqlNode.company.local\PIPE\sql\query'
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'NP'
                        $script:mockTestTargetResourceParameters.ServerName = 'NewSqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the alias already exist but does not use Named Pipes protocol' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Ensure            = 'Present'
                            Name              = 'MyAlias'
                            ServerName        = 'SqlNode.company.local'
                            Protocol          = 'TCP'
                            TcpPort           = 1433
                            UseDynamicTcpPort = $false
                            PipeName          = ''
                        }
                    }
                }

                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockTestTargetResourceParameters.Name = 'MyAlias'
                        $script:mockTestTargetResourceParameters.Protocol = 'NP'
                        $script:mockTestTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        $result = Test-TargetResource @mockTestTargetResourceParameters

                        $result | Should -BeFalse
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope Context
                }
            }
        }
    }
}

Describe 'SqlAlias\Set-TargetResource' {
    BeforeAll {
        $mockRegistryPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
        $mockRegistryPathWow6432Node = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                Name = 'MyAlias'
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
            Mock -CommandName New-Item
            Mock -CommandName Set-ItemProperty
            Mock -CommandName Remove-ItemProperty
            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        Context 'When <OSArchitecture> node is using TCP' -ForEach @(
            @{
                OSArchitecture = '64-bit'
            }
            @{
                OSArchitecture = '32-bit'
            }
        ) {
            BeforeAll {
                # Mocking OSArchitecture
                Mock -CommandName Get-CimInstance -MockWith {
                    return New-Object -TypeName 'Object' |
                        Add-Member -MemberType NoteProperty -Name 'OSArchitecture' -Value $OSArchitecture -PassThru -Force
                } -ParameterFilter { $ClassName -eq 'win32_OperatingSystem' }
            }

            Context 'When the alias should use static TCP port' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters.Name = 'MyAlias'
                        $script:mockSetTargetResourceParameters.Protocol = 'TCP'
                        $script:mockSetTargetResourceParameters.TcpPort = 1433
                        $script:mockSetTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Remove-ItemProperty -Exactly -Times 0 -Scope Context

                    Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias should use dynamic TCP port' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters.Name = 'MyAlias'
                        $script:mockSetTargetResourceParameters.Protocol = 'TCP'
                        $script:mockSetTargetResourceParameters.UseDynamicTcpPort = $true
                        $script:mockSetTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Remove-ItemProperty -Exactly -Times 0 -Scope Context

                    Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias should use Named Pipes' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters.Name = 'MyAlias'
                        $script:mockSetTargetResourceParameters.Protocol = 'NP'
                        $script:mockSetTargetResourceParameters.ServerName = 'SqlNode.company.local'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context

                    Should -Invoke -CommandName Remove-ItemProperty -Exactly -Times 0 -Scope Context

                    Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 1 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 1 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context
                    }
                }
            }

            Context 'When the alias should not exist' {
                BeforeAll {
                    # Override the mock above that return $false.
                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }
                }

                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters.Ensure = 'Absent'
                        $script:mockSetTargetResourceParameters.Name = 'MyAlias'

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }
                }

                It 'Should call the correct mocks' {
                    Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                        $ClassName -eq 'win32_OperatingSystem'
                    } -Exactly -Times 1 -Scope Context


                    Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                        $Path -eq $mockRegistryPath
                    } -Exactly -Times 0 -Scope Context

                    if ($OSArchitecture -eq '64-bit')
                    {
                        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context

                        Should -Invoke -CommandName Remove-ItemProperty -Exactly -Times 2 -Scope Context
                    }
                    else
                    {
                        Should -Invoke -CommandName Set-ItemProperty -ParameterFilter {
                            $Path -eq $mockRegistryPathWow6432Node
                        } -Exactly -Times 0 -Scope Context

                        Should -Invoke -CommandName Remove-ItemProperty -Exactly -Times 1 -Scope Context
                    }
                }
            }
        }
    }
}
