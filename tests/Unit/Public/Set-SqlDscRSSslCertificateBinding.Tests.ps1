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

Describe 'Set-SqlDscRSSslCertificateBinding' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-Binding] <hashtable[]> [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Set-SqlDscRSSslCertificateBinding').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When setting SSL certificate bindings to desired state' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @()
            }

            Mock -CommandName Add-SqlDscRSSslCertificateBinding
            Mock -CommandName Remove-SqlDscRSSslCertificateBinding
        }

        It 'Should add missing SSL certificate binding' {
            $desiredBindings = @(
                @{
                    CertificateHash = 'AABBCCDD'
                    Application = 'ReportServerWebService'
                    IPAddress = '0.0.0.0'
                    Port = 443
                }
            )

            { $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Binding $desiredBindings -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Add-SqlDscRSSslCertificateBinding -Exactly -Times 1
            Should -Invoke -CommandName Remove-SqlDscRSSslCertificateBinding -Exactly -Times 0
        }
    }

    Context 'When removing extra SSL certificate bindings' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @(
                    [PSCustomObject] @{
                        CertificateHash = 'AABBCCDD'
                        Application = 'ReportServerWebService'
                        IPAddress = '0.0.0.0'
                        Port = 443
                    },
                    [PSCustomObject] @{
                        CertificateHash = 'EEFFAABB'
                        Application = 'ReportServerWebApp'
                        IPAddress = '0.0.0.0'
                        Port = 443
                    }
                )
            }

            Mock -CommandName Add-SqlDscRSSslCertificateBinding
            Mock -CommandName Remove-SqlDscRSSslCertificateBinding
        }

        It 'Should remove extra SSL certificate binding' {
            $desiredBindings = @(
                @{
                    CertificateHash = 'AABBCCDD'
                    Application = 'ReportServerWebService'
                    IPAddress = '0.0.0.0'
                    Port = 443
                }
            )

            { $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Binding $desiredBindings -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Add-SqlDscRSSslCertificateBinding -Exactly -Times 0
            Should -Invoke -CommandName Remove-SqlDscRSSslCertificateBinding -Exactly -Times 1
        }
    }

    Context 'When bindings are already in desired state' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @(
                    [PSCustomObject] @{
                        CertificateHash = 'AABBCCDD'
                        Application = 'ReportServerWebService'
                        IPAddress = '0.0.0.0'
                        Port = 443
                    }
                )
            }

            Mock -CommandName Add-SqlDscRSSslCertificateBinding
            Mock -CommandName Remove-SqlDscRSSslCertificateBinding
        }

        It 'Should not add or remove any bindings' {
            $desiredBindings = @(
                @{
                    CertificateHash = 'AABBCCDD'
                    Application = 'ReportServerWebService'
                    IPAddress = '0.0.0.0'
                    Port = 443
                }
            )

            { $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Binding $desiredBindings -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Add-SqlDscRSSslCertificateBinding -Exactly -Times 0
            Should -Invoke -CommandName Remove-SqlDscRSSslCertificateBinding -Exactly -Times 0
        }
    }

    Context 'When using PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @()
            }

            Mock -CommandName Add-SqlDscRSSslCertificateBinding
            Mock -CommandName Remove-SqlDscRSSslCertificateBinding
        }

        It 'Should return the configuration CIM instance' {
            $desiredBindings = @(
                @{
                    CertificateHash = 'AABBCCDD'
                    Application = 'ReportServerWebService'
                    IPAddress = '0.0.0.0'
                    Port = 443
                }
            )

            $result = $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Binding $desiredBindings -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When using Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @()
            }

            Mock -CommandName Add-SqlDscRSSslCertificateBinding
            Mock -CommandName Remove-SqlDscRSSslCertificateBinding
        }

        It 'Should set SSL certificate bindings without confirmation' {
            $desiredBindings = @(
                @{
                    CertificateHash = 'AABBCCDD'
                    Application = 'ReportServerWebService'
                    IPAddress = '0.0.0.0'
                    Port = 443
                }
            )

            { $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Binding $desiredBindings -Force } | Should -Not -Throw

            Should -Invoke -CommandName Add-SqlDscRSSslCertificateBinding -Exactly -Times 1
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @()
            }

            Mock -CommandName Add-SqlDscRSSslCertificateBinding
            Mock -CommandName Remove-SqlDscRSSslCertificateBinding
        }

        It 'Should not add or remove any bindings' {
            $desiredBindings = @(
                @{
                    CertificateHash = 'AABBCCDD'
                    Application = 'ReportServerWebService'
                    IPAddress = '0.0.0.0'
                    Port = 443
                }
            )

            $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Binding $desiredBindings -WhatIf

            Should -Invoke -CommandName Add-SqlDscRSSslCertificateBinding -Exactly -Times 0
            Should -Invoke -CommandName Remove-SqlDscRSSslCertificateBinding -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @()
            }

            Mock -CommandName Add-SqlDscRSSslCertificateBinding
            Mock -CommandName Remove-SqlDscRSSslCertificateBinding
        }

        It 'Should set SSL certificate bindings' {
            $desiredBindings = @(
                @{
                    CertificateHash = 'AABBCCDD'
                    Application = 'ReportServerWebService'
                    IPAddress = '0.0.0.0'
                    Port = 443
                }
            )

            { Set-SqlDscRSSslCertificateBinding -Configuration $mockCimInstance -Binding $desiredBindings -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Get-SqlDscRSSslCertificateBinding -Exactly -Times 1
        }
    }
}
