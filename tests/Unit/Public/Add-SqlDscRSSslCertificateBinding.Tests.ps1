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

Describe 'Add-SqlDscRSSslCertificateBinding' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [-CertificateHash] <string> [-Application] <string> [[-IPAddress] <string>] [[-Port] <int>] [[-Lcid] <int>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Add-SqlDscRSSslCertificateBinding').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When adding SSL certificate binding successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should add SSL certificate binding without errors' {
            { $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'CreateSSLCertificateBinding' -and
                $Arguments.CertificateHash -eq 'AABBCCDD' -and
                $Arguments.Application -eq 'ReportServerWebService' -and
                $Arguments.IPAddress -eq '0.0.0.0' -and
                $Arguments.Port -eq 443 -and
                $Arguments.Lcid -eq 1033
            } -Exactly -Times 1
        }

        It 'Should not return anything by default' {
            $result = $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Confirm:$false

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When adding SSL certificate binding with custom parameters' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should use custom IP address and port' {
            { $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -IPAddress '192.168.1.1' -Port 8443 -Lcid 1031 -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.IPAddress -eq '192.168.1.1' -and
                $Arguments.Port -eq 8443 -and
                $Arguments.Lcid -eq 1031
            } -Exactly -Times 1
        }
    }

    Context 'When adding SSL certificate binding with PassThru' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should return the configuration CIM instance' {
            $result = $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When adding SSL certificate binding with Force' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should add SSL certificate binding without confirmation' {
            { $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Force } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When CIM method fails' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                throw 'Method CreateSSLCertificateBinding() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Confirm:$false } | Should -Throw -ErrorId 'ASRSSB0001,Add-SqlDscRSSslCertificateBinding'
        }
    }

    Context 'When using WhatIf' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should not call Invoke-RsCimMethod' {
            $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -WhatIf

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 0
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should add SSL certificate binding' {
            { Add-SqlDscRSSslCertificateBinding -Configuration $mockCimInstance -CertificateHash 'AABBCCDD' -Application 'ReportServerWebService' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When using different application types' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod
        }

        It 'Should accept ReportServerWebApp application' {
            { $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportServerWebApp' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.Application -eq 'ReportServerWebApp'
            } -Exactly -Times 1
        }

        It 'Should accept ReportManager application' {
            { $mockCimInstance | Add-SqlDscRSSslCertificateBinding -CertificateHash 'AABBCCDD' -Application 'ReportManager' -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $Arguments.Application -eq 'ReportManager'
            } -Exactly -Times 1
        }
    }
}
