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
    BeforeAll {
        Mock -CommandName Get-OperatingSystem -MockWith {
            return [PSCustomObject] @{
                OSLanguage = 1033
            }
        }
    }

    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-Application] <string> [-CertificateHash] <string> [[-IPAddress] <string>] [[-Port] <int>] [[-Lcid] <int>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
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

    Context 'When setting SSL certificate binding and no binding exists' {
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

        It 'Should add the SSL certificate binding' {
            $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'AABBCCDD' -Confirm:$false

            Should -Invoke -CommandName Add-SqlDscRSSslCertificateBinding -Exactly -Times 1
            Should -Invoke -CommandName Remove-SqlDscRSSslCertificateBinding -Exactly -Times 0
        }
    }

    Context 'When setting SSL certificate binding and different binding exists' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @(
                    [PSCustomObject] @{
                        CertificateHash = 'oldcerthash'
                        Application = 'ReportServerWebService'
                        IPAddress = '0.0.0.0'
                        Port = 443
                    }
                )
            }

            Mock -CommandName Add-SqlDscRSSslCertificateBinding
            Mock -CommandName Remove-SqlDscRSSslCertificateBinding
        }

        It 'Should remove existing and add new SSL certificate binding' {
            $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'AABBCCDD' -Confirm:$false

            Should -Invoke -CommandName Remove-SqlDscRSSslCertificateBinding -Exactly -Times 1
            Should -Invoke -CommandName Add-SqlDscRSSslCertificateBinding -Exactly -Times 1
        }
    }

    Context 'When binding is already in desired state' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Get-SqlDscRSSslCertificateBinding -MockWith {
                return @(
                    [PSCustomObject] @{
                        CertificateHash = 'aabbccdd'
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
            $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'AABBCCDD' -Confirm:$false

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
            $result = $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'AABBCCDD' -PassThru -Confirm:$false

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

        It 'Should set SSL certificate binding without confirmation' {
            $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'AABBCCDD' -Force

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
            $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'AABBCCDD' -WhatIf

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

        It 'Should set SSL certificate binding' {
            Set-SqlDscRSSslCertificateBinding -Configuration $mockCimInstance -Application 'ReportServerWebService' -CertificateHash 'AABBCCDD' -Confirm:$false

            Should -Invoke -CommandName Get-SqlDscRSSslCertificateBinding -Exactly -Times 1
        }
    }

    Context 'When using custom IP address and port' {
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

        It 'Should use custom IP address and port' {
            $mockCimInstance | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'AABBCCDD' -IPAddress '192.168.1.1' -Port 8443 -Confirm:$false

            Should -Invoke -CommandName Add-SqlDscRSSslCertificateBinding -ParameterFilter {
                $IPAddress -eq '192.168.1.1' -and $Port -eq 8443
            } -Exactly -Times 1
        }
    }
}
