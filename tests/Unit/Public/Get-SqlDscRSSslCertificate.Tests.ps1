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

Describe 'Get-SqlDscRSSslCertificate' {
    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters = '[-Configuration] <Object> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSSslCertificate').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When getting SSL certificates successfully' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    CertName        = @('Certificate1', 'Certificate2')
                    HostName        = @('server1.domain.com', 'server2.domain.com')
                    CertificateHash = @('AABBCCDD', 'EEFFAABB')
                    Length          = 2
                }
            }
        }

        It 'Should return SSL certificates with correct properties' {
            $result = $mockCimInstance | Get-SqlDscRSSslCertificate

            $result | Should -HaveCount 2
            $result[0].CertificateName | Should -Be 'Certificate1'
            $result[0].HostName | Should -Be 'server1.domain.com'
            $result[0].CertificateHash | Should -Be 'AABBCCDD'
            $result[1].CertificateName | Should -Be 'Certificate2'
            $result[1].HostName | Should -Be 'server2.domain.com'
            $result[1].CertificateHash | Should -Be 'EEFFAABB'

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ListSSLCertificates' -and
                $null -eq $Arguments
            } -Exactly -Times 1
        }
    }

    Context 'When there are no SSL certificates' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    CertName        = @()
                    HostName        = @()
                    CertificateHash = @()
                    Length          = 0
                }
            }
        }

        It 'Should return an empty result' {
            $result = $mockCimInstance | Get-SqlDscRSSslCertificate

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
                throw 'Method ListSSLCertificates() failed with an error.'
            }
        }

        It 'Should throw a terminating error' {
            { $mockCimInstance | Get-SqlDscRSSslCertificate } | Should -Throw -ErrorId 'GSRSSC0001,Get-SqlDscRSSslCertificate'
        }
    }

    Context 'When passing configuration as parameter' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'SSRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    CertName        = @('Certificate1')
                    HostName        = @('server1.domain.com')
                    CertificateHash = @('AABBCCDD')
                    Length          = 1
                }
            }
        }

        It 'Should get SSL certificates' {
            $result = Get-SqlDscRSSslCertificate -Configuration $mockCimInstance

            $result | Should -HaveCount 1

            Should -Invoke -CommandName Invoke-RsCimMethod -Exactly -Times 1
        }
    }

    Context 'When getting SSL certificates for Power BI Report Server' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName = 'PBIRS'
            }

            Mock -CommandName Invoke-RsCimMethod -MockWith {
                return @{
                    CertName        = @('PBIRS Certificate')
                    HostName        = @('pbirs.domain.com')
                    CertificateHash = @('11223344')
                    Length          = 1
                }
            }
        }

        It 'Should return SSL certificates without passing Lcid argument' {
            $result = $mockCimInstance | Get-SqlDscRSSslCertificate

            $result | Should -HaveCount 1
            $result[0].CertificateName | Should -Be 'PBIRS Certificate'
            $result[0].HostName | Should -Be 'pbirs.domain.com'
            $result[0].CertificateHash | Should -Be '11223344'

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ListSSLCertificates' -and
                $null -eq $Arguments
            } -Exactly -Times 1
        }
    }
}
