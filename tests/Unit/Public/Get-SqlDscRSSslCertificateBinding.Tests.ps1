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

Describe 'Get-SqlDscRSSslCertificateBinding' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSSslCertificateBinding').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting SSL certificate bindings successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Application = @('ReportServerWebService', 'ReportServerWebApp')
                    CertificateHash = @('AABBCCDD', 'EEFFAABB')
                    IPAddress = @('0.0.0.0', '0.0.0.0')
                    Port = @(443, 443)
                    Lcid = @(1033, 1033)
                }
            }
        }

        It 'Should return SSL certificate bindings' {
            $result = $mockCimInstance | Get-SqlDscRSSslCertificateBinding

            $result | Should -HaveCount 2
            $result[0].Application | Should -Be 'ReportServerWebService'
            $result[0].CertificateHash | Should -Be 'AABBCCDD'
            $result[1].Application | Should -Be 'ReportServerWebApp'
            $result[1].CertificateHash | Should -Be 'EEFFAABB'

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ListSSLCertificateBindings' -and
                $Arguments.Lcid -eq 1033
            } -Exactly -Times 1
        }
    }

    Context 'When there are no SSL certificate bindings' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Application = @()
                    CertificateHash = @()
                    IPAddress = @()
                    Port = @()
                    Lcid = @()
                }
            }
        }

        It 'Should return an empty result' {
            $result = $mockCimInstance | Get-SqlDscRSSslCertificateBinding

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
                throw 'Method ListSSLCertificateBindings() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Get-SqlDscRSSslCertificateBinding } | Should -Throw -ErrorId 'GSRSSB0001,Get-SqlDscRSSslCertificateBinding'
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    Application = @('ReportServerWebService')
                    CertificateHash = @('AABBCCDD')
                    IPAddress = @('0.0.0.0')
                    Port = @(443)
                    Lcid = @(1033)
                }
            }
        }

        It 'Should get SSL certificate bindings' {
            $result = Get-SqlDscRSSslCertificateBinding -Configuration $mockCimInstance

            $result | Should -HaveCount 1

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }
}
