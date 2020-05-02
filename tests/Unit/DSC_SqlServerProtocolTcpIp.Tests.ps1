$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlServerProtocolTcpIp'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

# Begin Testing

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        Set-StrictMode -Version 1.0

        Describe 'SqlServerProtocolTcpIp\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $mockInstanceName = 'DSCTEST'

                Mock -CommandName Import-SQLPSModule
            }

            Context 'When the system is not in the desired state' {
                Context 'When the SQL Server instance does not exist' {
                    BeforeAll {
                        Mock -CommandName Get-ServerProtocolObject -MockWith {
                            return $null
                        }

                        $getTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            <#
                                Intentionally using lower-case to test so that
                                the correct casing is returned.
                            #>
                            IpAddressGroup = 'ipall'
                        }
                    }

                    It 'Should return the correct values' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                        $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                        # IP address group should always be returned with the correct casing.
                        $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IPAll'
                        $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                        $getTargetResourceResult.SuppressRestart | Should -BeFalse
                        $getTargetResourceResult.RestartTimeout | Should -Be 120
                        $getTargetResourceResult.Enabled | Should -BeFalse
                        $getTargetResourceResult.IPAddress | Should -BeNullOrEmpty
                        $getTargetResourceResult.UseTcpDynamicPort | Should -BeFalse
                        $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty
                        $getTargetResourceResult.IsActive | Should -BeFalse
                        $getTargetResourceResult.AddressFamily | Should -BeNullOrEmpty
                        $getTargetResourceResult.TcpDynamicPort | Should -BeNullOrEmpty
                    }
                }

                Context 'When the IP address group is missing' {
                    BeforeAll {
                        Mock -CommandName Write-Warning
                        Mock -CommandName Get-ServerProtocolObject -MockWith {
                            return @{
                                IPAddresses = @(
                                    [PSCustomObject] @{
                                        Name = 'IPAll'
                                    }
                                    [PSCustomObject] @{
                                        Name = 'IP1'
                                    }
                                )
                            }
                        }

                        $getTargetResourceParameters = @{
                            InstanceName   = $mockInstanceName
                            IpAddressGroup = 'IP2'
                        }
                    }

                    It 'Should return the correct values' {
                        { Get-TargetResource @getTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Write-Warning
                    }
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the IP address group is IPAll' {
                    Context 'When the IP address group is using dynamic port' {
                        BeforeAll {
                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return @{
                                    IPAddresses = @{
                                        Name  = 'IPAll'
                                        IPAll = @{
                                            IPAddressProperties = @{
                                                TcpPort = @{
                                                    Value = ''
                                                }
                                                TcpDynamicPorts = @{
                                                    Value = '0'
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            $getTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IPAll'
                            }
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                            $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                            $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IPAll'
                            $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                            $getTargetResourceResult.SuppressRestart | Should -BeFalse
                            $getTargetResourceResult.RestartTimeout | Should -Be 120
                            $getTargetResourceResult.Enabled | Should -BeFalse
                            $getTargetResourceResult.IPAddress | Should -BeNullOrEmpty
                            $getTargetResourceResult.UseTcpDynamicPort | Should -BeTrue
                            $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty
                            $getTargetResourceResult.IsActive | Should -BeFalse
                            $getTargetResourceResult.AddressFamily | Should -BeNullOrEmpty
                            $getTargetResourceResult.TcpDynamicPort | Should -BeExactly '0'
                        }
                    }

                    Context 'When the IP address group is using static TCP ports' {
                        BeforeAll {
                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return @{
                                    IPAddresses = @{
                                        Name  = 'IPAll'
                                        IPAll = @{
                                            IPAddressProperties = @{
                                                TcpPort = @{
                                                    Value = '1433,1500,1501'
                                                }
                                                TcpDynamicPorts = @{
                                                    Value = ''
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            $getTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IPAll'
                            }
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                            $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                            $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IPAll'
                            $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                            $getTargetResourceResult.SuppressRestart | Should -BeFalse
                            $getTargetResourceResult.RestartTimeout | Should -Be 120
                            $getTargetResourceResult.Enabled | Should -BeFalse
                            $getTargetResourceResult.IPAddress | Should -BeNullOrEmpty
                            $getTargetResourceResult.UseTcpDynamicPort | Should -BeFalse
                            $getTargetResourceResult.TcpPort | Should -BeExactly '1433,1500,1501'
                            $getTargetResourceResult.IsActive | Should -BeFalse
                            $getTargetResourceResult.AddressFamily | Should -BeNullOrEmpty
                            $getTargetResourceResult.TcpDynamicPort | Should -BeNullOrEmpty
                        }
                    }
                }

                Context 'When the IP address group is IPx (where x is an available group number)' {
                    Context 'When the IP address group is using dynamic port' {
                        BeforeAll {
                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return @{
                                    IPAddresses = @{
                                        Name  = 'IP1'
                                        IP1 = @{
                                            IPAddress = @{
                                                AddressFamily = 'InterNetworkV6'
                                                IPAddressToString = 'fe80::7894:a6b6:59dd:c8ff%9'
                                            }
                                            IPAddressProperties = @{
                                                TcpPort = @{
                                                    Value = ''
                                                }
                                                TcpDynamicPorts = @{
                                                    Value = '0'
                                                }
                                                Enabled = @{
                                                    Value = $true
                                                }
                                                Active = @{
                                                    Value = $true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            $getTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IP1'
                            }
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                            $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                            $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IP1'
                            $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                            $getTargetResourceResult.SuppressRestart | Should -BeFalse
                            $getTargetResourceResult.RestartTimeout | Should -Be 120
                            $getTargetResourceResult.Enabled | Should -BeTrue
                            $getTargetResourceResult.IPAddress | Should -Be 'fe80::7894:a6b6:59dd:c8ff%9'
                            $getTargetResourceResult.UseTcpDynamicPort | Should -BeTrue
                            $getTargetResourceResult.TcpPort | Should -BeNullOrEmpty
                            $getTargetResourceResult.IsActive | Should -BeTrue
                            $getTargetResourceResult.AddressFamily | Should -Be 'InterNetworkV6'
                            $getTargetResourceResult.TcpDynamicPort | Should -BeExactly '0'
                        }
                    }

                    Context 'When the IP address group is using static TCP ports' {
                        BeforeAll {
                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return @{
                                    IPAddresses = @{
                                        Name  = 'IP1'
                                        IP1 = @{
                                            IPAddress = @{
                                                AddressFamily = 'InterNetworkV6'
                                                IPAddressToString = 'fe80::7894:a6b6:59dd:c8ff%9'
                                            }
                                            IPAddressProperties = @{
                                                TcpPort = @{
                                                    Value = '1433,1500,1501'
                                                }
                                                TcpDynamicPorts = @{
                                                    Value = ''
                                                }
                                                Enabled = @{
                                                    Value = $true
                                                }
                                                Active = @{
                                                    Value = $true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            $getTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IP1'
                            }
                        }

                        It 'Should return the correct values' {
                            $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters

                            $getTargetResourceResult.InstanceName | Should -Be $mockInstanceName
                            $getTargetResourceResult.IpAddressGroup | Should -BeExactly 'IP1'
                            $getTargetResourceResult.ServerName | Should -Be $env:COMPUTERNAME
                            $getTargetResourceResult.SuppressRestart | Should -BeFalse
                            $getTargetResourceResult.RestartTimeout | Should -Be 120
                            $getTargetResourceResult.Enabled | Should -BeTrue
                            $getTargetResourceResult.IPAddress | Should -Be 'fe80::7894:a6b6:59dd:c8ff%9'
                            $getTargetResourceResult.UseTcpDynamicPort | Should -BeFalse
                            $getTargetResourceResult.TcpPort | Should -BeExactly '1433,1500,1501'
                            $getTargetResourceResult.IsActive | Should -BeTrue
                            $getTargetResourceResult.AddressFamily | Should -Be 'InterNetworkV6'
                            $getTargetResourceResult.TcpDynamicPort | Should -BeNullOrEmpty
                        }
                    }
                }
            }
        }

        Describe 'SqlServerProtocolTcpIp\Test-TargetResource' -Tag 'Test' {
            BeforeAll {
                $testTargetResourceParameters = @{
                    InstanceName   = 'DSCTEST'
                    IpAddressGroup = 'IPAll'
                }
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Enabled'
                                InDesiredState = $true
                            }
                        )
                    }
                }

                It 'Should return $true' {
                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeTrue

                    Assert-MockCalled -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                ParameterName  = 'Enabled'
                                InDesiredState = $false
                            }
                        )
                    }
                }

                It 'Should return $false' {
                    $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
                    $testTargetResourceResult | Should -BeFalse

                    Assert-MockCalled -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe 'SqlServerProtocolTcpIp\Compare-TargetResourceState' -Tag 'Compare' {
            BeforeAll {
                $mockInstanceName = 'DSCTEST'
            }

            Context 'When passing wrong set of parameters' {
                It 'Should throw the an exception when passing both UseTcpDynamicPort and TcpPort' {
                    $testTargetResourceParameters = @{
                        InstanceName   = $mockInstanceName
                        IpAddressGroup = 'IPAll'
                        UseTcpDynamicPort = $true
                        TcpPort        = '1433'
                    }

                    { Compare-ResourcePropertyState @testTargetResourceParameters } | Should -Throw
                }
            }

            Context 'When the system is in the desired state' {
                Context 'When the IP address group is IPAll' {
                    Context 'When the IP address group is using dynamic port' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IPAll'
                                    Enabled            = $false
                                    IPAddress          = $null
                                    UseTcpDynamicPort  = $true
                                    TcpPort            = $null
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName      = $mockInstanceName
                                IpAddressGroup    = 'IPAll'
                                UseTcpDynamicPort = $true
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'UseTcpDynamicPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeTrue
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the IP address group is using static TCP ports' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IPAll'
                                    Enabled            = $false
                                    IPAddress          = $null
                                    UseTcpDynamicPort  = $false
                                    TcpPort            = '1433'
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IPAll'
                                TcpPort        = '1433'
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be '1433'
                            $comparedReturnValue.Actual | Should -Be '1433'
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the IP address group is IPx (where x is an available group number)' {
                    Context 'When the IP address group is using dynamic port' {
                        BeforeAll {
                            $mockIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IP1'
                                    Enabled            = $true
                                    IPAddress          = $mockIpAddress
                                    UseTcpDynamicPort  = $true
                                    TcpPort            = $null
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName      = $mockInstanceName
                                IpAddressGroup    = 'IP1'
                                UseTcpDynamicPort = $true
                                Enabled           = $true
                                IPAddress         = $mockIpAddress
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 3

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'UseTcpDynamicPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeTrue
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeTrue
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be $mockIpAddress
                            $comparedReturnValue.Actual | Should -Be $mockIpAddress
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the IP address group is using static TCP ports' {
                        BeforeAll {
                            $mockIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IP1'
                                    Enabled            = $true
                                    IPAddress          = $mockIpAddress
                                    UseTcpDynamicPort  = $false
                                    TcpPort            = '1433'
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IP1'
                                TcpPort        = '1433'
                                Enabled        = $true
                                IPAddress      = $mockIpAddress
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 3

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be '1433'
                            $comparedReturnValue.Actual | Should -Be '1433'
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeTrue
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be $mockIpAddress
                            $comparedReturnValue.Actual | Should -Be $mockIpAddress
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the IP address group is IPAll' {
                    Context 'When the IP address group should be using dynamic port' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IPAll'
                                    Enabled            = $false
                                    IPAddress          = $null
                                    UseTcpDynamicPort  = $false
                                    TcpPort            = '1433'
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName      = $mockInstanceName
                                IpAddressGroup    = 'IPAll'
                                UseTcpDynamicPort = $true
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'UseTcpDynamicPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeFalse
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the IP address group should be using static TCP ports' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IPAll'
                                    Enabled            = $false
                                    IPAddress          = $null
                                    UseTcpDynamicPort  = $true
                                    TcpPort            = $null
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IPAll'
                                TcpPort        = '1433'
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be '1433'
                            $comparedReturnValue.Actual | Should -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the IP address group is IPx (where x is an available group number)' {
                    Context 'When the IP address group should be using dynamic port' {
                        BeforeAll {
                            $mockIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IP1'
                                    Enabled            = $true
                                    IPAddress          = $mockIpAddress
                                    UseTcpDynamicPort  = $false
                                    TcpPort            = '1433'
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName      = $mockInstanceName
                                IpAddressGroup    = 'IP1'
                                UseTcpDynamicPort = $true
                                Enabled           = $true
                                IPAddress         = $mockIpAddress
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 3

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'UseTcpDynamicPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeFalse
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeTrue
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be $mockIpAddress
                            $comparedReturnValue.Actual | Should -Be $mockIpAddress
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the IP address group should be using static TCP ports' {
                        BeforeAll {
                            $mockIpAddress = 'fe80::7894:a6b6:59dd:c8ff%9'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IP1'
                                    Enabled            = $true
                                    IPAddress          = $mockIpAddress
                                    UseTcpDynamicPort  = $true
                                    TcpPort            = $null
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IP1'
                                TcpPort        = '1433'
                                Enabled        = $true
                                IPAddress      = $mockIpAddress
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 3

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be '1433'
                            $comparedReturnValue.Actual | Should -BeNullOrEmpty
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeTrue
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be $mockIpAddress
                            $comparedReturnValue.Actual | Should -Be $mockIpAddress
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the IP address group has the wrong IP adress' {
                        BeforeAll {
                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IP1'
                                    Enabled            = $true
                                    IPAddress          = '10.0.0.1'
                                    UseTcpDynamicPort  = $false
                                    TcpPort            = '1433'
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IP1'
                                TcpPort        = '1433'
                                Enabled        = $true
                                IPAddress      = 'fe80::7894:a6b6:59dd:c8ff%9'
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 3

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'TcpPort' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be '1433'
                            $comparedReturnValue.Actual | Should -Be '1433'
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeTrue
                            $comparedReturnValue.InDesiredState | Should -BeTrue

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'IPAddress' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -Be 'fe80::7894:a6b6:59dd:c8ff%9'
                            $comparedReturnValue.Actual | Should -Be '10.0.0.1'
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When the IP address group has the wrong state for Enabled' {
                        BeforeAll {
                            $mockIpAddress = '10.0.0.1'

                            Mock -CommandName Get-TargetResource -MockWith {
                                return @{
                                    InstanceName       = $mockInstanceName
                                    IpAddressGroup     = 'IP1'
                                    Enabled            = $false
                                    IPAddress          = $mockIpAddress
                                    UseTcpDynamicPort  = $false
                                    TcpPort            = '1433'
                                }
                            }

                            $compareTargetResourceParameters = @{
                                InstanceName   = $mockInstanceName
                                IpAddressGroup = 'IP1'
                                Enabled        = $true
                            }
                        }

                        It 'Should return the correct metadata for each protocol property' {
                            $compareTargetResourceStateResult = Compare-TargetResourceState @compareTargetResourceParameters
                            $compareTargetResourceStateResult | Should -HaveCount 1

                            $comparedReturnValue = $compareTargetResourceStateResult.Where( { $_.ParameterName -eq 'Enabled' })
                            $comparedReturnValue | Should -Not -BeNullOrEmpty
                            $comparedReturnValue.Expected | Should -BeTrue
                            $comparedReturnValue.Actual | Should -BeFalse
                            $comparedReturnValue.InDesiredState | Should -BeFalse

                            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                        }
                    }
                }
            }
        }

        Describe 'SqlServerProtocolTcpIp\Set-TargetResource' -Tag 'Set' {
            BeforeAll {
                $mockInstanceName = 'DSCTEST'
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    Mock -CommandName Compare-TargetResourceState -MockWith {
                        return @(
                            @{
                                InDesiredState = $true
                            }
                        )
                    }

                    $setTargetResourceParameters = @{
                        InstanceName = $mockInstanceName
                        ProtocolName = 'SharedMemory'
                        Enabled      = $true
                    }
                }

                It 'Should return $true' {
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Compare-TargetResourceState -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When the desired protocol is TCP/IP' {
                    Context 'When enabling and setting all the protocol properties' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                    @{
                                        ParameterName = 'ListenOnAllIpAddresses'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                    @{
                                        ParameterName = 'KeepAlive'
                                        Actual = 30000
                                        Expected = 50000
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName           = $mockInstanceName
                                ProtocolName           = 'TcpIp'
                                ListenOnAllIpAddresses = $true
                                KeepAlive              = 50000
                                Enabled                = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When enabling the protocol and leaving the rest of the properties to their default value' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'TcpIp'
                                Enabled      = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When disabling the protocol and leaving the rest of the properties to their default value' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $true
                                        Expected = $false
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $true -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'TcpIp'
                                Enabled      = $false
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When setting the individual protocol properties regardless if the protocol is enabled or disabled' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'ListenOnAllIpAddresses'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                    @{
                                        ParameterName = 'KeepAlive'
                                        Actual = 30000
                                        Expected = 50000
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName           = $mockInstanceName
                                ProtocolName           = 'TcpIp'
                                ListenOnAllIpAddresses = $true
                                KeepAlive              = 50000
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and _not_ restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                        }
                    }

                    Context 'When suppressing the restart' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Write-Warning
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            ListenOnAllIPs = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value $false -PassThru -Force
                                            KeepAlive = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value 30000 -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName    = $mockInstanceName
                                ProtocolName    = 'TcpIp'
                                Enabled         = $true
                                SuppressRestart = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should not restart the SQL Server service but instead write a warning message' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When the desired protocol is Named Pipes' {
                    Context 'When enabling and setting all the protocol properties' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                    @{
                                        ParameterName = 'PipeName'
                                        Actual = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'
                                        Expected = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            PipeName = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'NamedPipes'
                                PipeName     = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                                Enabled      = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When enabling the protocol and leaving the rest of the properties to their default value' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'Enabled'
                                        Actual = $false
                                        Expected = $true
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            PipeName = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'NamedPipes'
                                Enabled      = $true
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 1 -Scope It
                        }
                    }

                    Context 'When setting the individual protocol properties regardless if the protocol is enabled or disabled' {
                        BeforeAll {
                            Mock -CommandName Restart-SqlService
                            Mock -CommandName Compare-TargetResourceState -MockWith {
                                return @(
                                    @{
                                        ParameterName = 'PipeName'
                                        Actual = '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query'
                                        Expected = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                                        InDesiredState = $false
                                    }
                                )
                            }

                            Mock -CommandName Get-ServerProtocolObject -MockWith {
                                return New-Object -TypeName PSObject |
                                    Add-Member -MemberType NoteProperty -Name 'IsEnabled' -Value $false -PassThru |
                                    Add-Member -MemberType ScriptProperty -Name 'ProtocolProperties' -Value {
                                        return @{
                                            PipeName = New-Object -TypeName PSObject |
                                                Add-Member -MemberType NoteProperty -Name 'Value' -Value '\\.\pipe\$$\TESTCLU01A\MSSQL$SQL2014\sql\query' -PassThru -Force
                                        }
                                    } -PassThru |
                                    Add-Member -MemberType ScriptMethod -Name 'Alter' -Value {
                                        # This is used to verify so that method Alter() is actually called or not.
                                        $script:wasMethodAlterCalled = $true
                                    } -PassThru -Force
                            }

                            $setTargetResourceParameters = @{
                                InstanceName = $mockInstanceName
                                ProtocolName = 'NamedPipes'
                                PipeName     = '\\.\pipe\$$\CLU01A\MSSQL$SQL2014\sql\query'
                            }
                        }

                        BeforeEach {
                            $script:wasMethodAlterCalled = $false
                        }

                        It 'Should set the desired values and _not_ restart the SQL Server service' {
                            { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

                            $script:wasMethodAlterCalled | Should -BeTrue

                            Assert-MockCalled -CommandName Restart-SqlService -Exactly -Times 0 -Scope It
                        }
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
