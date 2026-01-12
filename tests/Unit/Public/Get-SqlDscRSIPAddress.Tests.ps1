[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-SqlDscRSIPAddress' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSIPAddress').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting IP addresses successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    IPAddress     = @('0.0.0.0', '192.168.1.1', '::')
                    IPVersion     = @('V4', 'V4', 'V6')
                    IsDhcpEnabled = @($false, $true, $false)
                }
            }
        }

        It 'Should return IP addresses as ReportServerIPAddress objects' {
            $result = $mockCimInstance | Get-SqlDscRSIPAddress

            $result | Should -HaveCount 3
            $result[0].IPAddress | Should -Be '0.0.0.0'
            $result[0].IPVersion | Should -Be 'V4'
            $result[0].IsDhcpEnabled | Should -BeFalse
            $result[1].IPAddress | Should -Be '192.168.1.1'
            $result[1].IPVersion | Should -Be 'V4'
            $result[1].IsDhcpEnabled | Should -BeTrue
            $result[2].IPAddress | Should -Be '::'
            $result[2].IPVersion | Should -Be 'V6'
            $result[2].IsDhcpEnabled | Should -BeFalse

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ListIPAddresses'
            } -Exactly -Times 1
        }
    }

    Context 'When there are no IP addresses' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    IPAddress     = @()
                    IPVersion     = @()
                    IsDhcpEnabled = @()
                }
            }
        }

        It 'Should return an empty result' {
            $result = $mockCimInstance | Get-SqlDscRSIPAddress

            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method ListIPAddresses() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Get-SqlDscRSIPAddress } | Should -Throw -ErrorId 'GSRSIP0001,Get-SqlDscRSIPAddress'
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    IPAddress     = @('0.0.0.0')
                    IPVersion     = @('V4')
                    IsDhcpEnabled = @($false)
                }
            }
        }

        It 'Should get IP addresses' {
            $result = Get-SqlDscRSIPAddress -Configuration $mockCimInstance

            $result | Should -HaveCount 1
            $result[0].IPAddress | Should -Be '0.0.0.0'
            $result[0].IPVersion | Should -Be 'V4'
            $result[0].IsDhcpEnabled | Should -BeFalse

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }
}
