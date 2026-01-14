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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $script:computerName = Get-ComputerName

    <#
        Get the self-signed certificate created by Add-SqlDscRSSslCertificateBinding
        integration tests. This test assumes the Add-SqlDscRSSslCertificateBinding
        tests have run first and created the certificate.
    #>
    $script:testCertificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' |
        Where-Object -FilterScript {
            $_.FriendlyName -eq 'SqlServerDsc SSL Integration Test Certificate' -and
            $_.Subject -eq "CN=$script:computerName"
        } |
        Select-Object -First 1

    if (-not $script:testCertificate)
    {
        throw 'Test certificate not found. Ensure Add-SqlDscRSSslCertificateBinding integration tests have run first to create the certificate.'
    }

    $script:testCertificateHash = $script:testCertificate.Thumbprint
    $script:testIPAddress = '0.0.0.0'
    $script:testPort = 443

    Write-Verbose -Message ('Using self-signed certificate ''{0}'' with thumbprint ''{1}''.' -f $script:testCertificate.Subject, $script:testCertificateHash) -Verbose
}

Describe 'Get-SqlDscRSSslCertificateBinding' {
    Context 'When getting SSL certificate bindings for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return SSL certificate bindings' {
            $result = $script:configuration | Get-SqlDscRSSslCertificateBinding -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return the binding for the test certificate' {
            $result = $script:configuration | Get-SqlDscRSSslCertificateBinding -ErrorAction 'Stop'

            $binding = $result | Where-Object -FilterScript {
                $_.CertificateHash -eq $script:testCertificateHash -and
                $_.Port -eq $script:testPort
            }

            $binding | Should -Not -BeNullOrEmpty
            $binding.Application | Should -Be 'ReportServerWebService'
            $binding.IPAddress | Should -Be $script:testIPAddress
        }
    }

    Context 'When getting SSL certificate bindings for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return SSL certificate bindings' {
            $result = $script:configuration | Get-SqlDscRSSslCertificateBinding -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return the binding for the test certificate' {
            $result = $script:configuration | Get-SqlDscRSSslCertificateBinding -ErrorAction 'Stop'

            $binding = $result | Where-Object -FilterScript {
                $_.CertificateHash -eq $script:testCertificateHash -and
                $_.Port -eq $script:testPort
            }

            $binding | Should -Not -BeNullOrEmpty
            $binding.Application | Should -Be 'ReportServerWebService'
            $binding.IPAddress | Should -Be $script:testIPAddress
        }
    }

    Context 'When getting SSL certificate bindings for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return SSL certificate bindings' {
            $result = $script:configuration | Get-SqlDscRSSslCertificateBinding -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return the binding for the test certificate' {
            $result = $script:configuration | Get-SqlDscRSSslCertificateBinding -ErrorAction 'Stop'

            $binding = $result | Where-Object -FilterScript {
                $_.CertificateHash -eq $script:testCertificateHash -and
                $_.Port -eq $script:testPort
            }

            $binding | Should -Not -BeNullOrEmpty
            $binding.Application | Should -Be 'ReportServerWebService'
            $binding.IPAddress | Should -Be $script:testIPAddress
        }
    }

    Context 'When getting SSL certificate bindings for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
        }

        It 'Should return SSL certificate bindings' {
            $result = $script:configuration | Get-SqlDscRSSslCertificateBinding -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return the binding for the test certificate' {
            $result = $script:configuration | Get-SqlDscRSSslCertificateBinding -ErrorAction 'Stop'

            $binding = $result | Where-Object -FilterScript {
                $_.CertificateHash -eq $script:testCertificateHash -and
                $_.Port -eq $script:testPort
            }

            $binding | Should -Not -BeNullOrEmpty
            $binding.Application | Should -Be 'ReportServerWebService'
            $binding.IPAddress | Should -Be $script:testIPAddress
        }
    }
}
