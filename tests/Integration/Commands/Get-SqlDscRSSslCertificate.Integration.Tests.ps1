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

    Write-Verbose -Message ('Using self-signed certificate ''{0}'' with thumbprint ''{1}''.' -f $script:testCertificate.Subject, $script:testCertificateHash) -Verbose
}

Describe 'Get-SqlDscRSSslCertificate' {
    Context 'When getting SSL certificates for SQL Server 2017 Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return available SSL certificates' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return certificates with correct properties' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result[0].PSObject.Properties.Name | Should -Contain 'CertificateName'
            $result[0].PSObject.Properties.Name | Should -Contain 'HostName'
            $result[0].PSObject.Properties.Name | Should -Contain 'CertificateHash'
        }

        It 'Should return the test certificate that was bound' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result.CertificateHash | Should -Contain $script:testCertificateHash
        }

        It 'Should return correct properties for the test certificate' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $testCert = $result | Where-Object -FilterScript {
                $_.CertificateHash -eq $script:testCertificateHash
            }

            $testCert | Should -Not -BeNullOrEmpty
            $testCert.CertificateName | Should -Be $script:testCertificate.FriendlyName
            $testCert.HostName | Should -Be $script:computerName
        }
    }

    Context 'When getting SSL certificates for SQL Server 2019 Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return available SSL certificates' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return certificates with correct properties' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result[0].PSObject.Properties.Name | Should -Contain 'CertificateName'
            $result[0].PSObject.Properties.Name | Should -Contain 'HostName'
            $result[0].PSObject.Properties.Name | Should -Contain 'CertificateHash'
        }

        It 'Should return the test certificate that was bound' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result.CertificateHash | Should -Contain $script:testCertificateHash
        }

        It 'Should return correct properties for the test certificate' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $testCert = $result | Where-Object -FilterScript {
                $_.CertificateHash -eq $script:testCertificateHash
            }

            $testCert | Should -Not -BeNullOrEmpty
            $testCert.CertificateName | Should -Be $script:testCertificate.FriendlyName
            $testCert.HostName | Should -Be $script:computerName
        }
    }

    Context 'When getting SSL certificates for SQL Server 2022 Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return available SSL certificates' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return certificates with correct properties' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result[0].PSObject.Properties.Name | Should -Contain 'CertificateName'
            $result[0].PSObject.Properties.Name | Should -Contain 'HostName'
            $result[0].PSObject.Properties.Name | Should -Contain 'CertificateHash'
        }

        It 'Should return the test certificate that was bound' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result.CertificateHash | Should -Contain $script:testCertificateHash
        }

        It 'Should return correct properties for the test certificate' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $testCert = $result | Where-Object -FilterScript {
                $_.CertificateHash -eq $script:testCertificateHash
            }

            $testCert | Should -Not -BeNullOrEmpty
            $testCert.CertificateName | Should -Be $script:testCertificate.FriendlyName
            $testCert.HostName | Should -Be $script:computerName
        }
    }

    Context 'When getting SSL certificates for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
        }

        It 'Should return available SSL certificates' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return certificates with correct properties' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result[0].PSObject.Properties.Name | Should -Contain 'CertificateName'
            $result[0].PSObject.Properties.Name | Should -Contain 'HostName'
            $result[0].PSObject.Properties.Name | Should -Contain 'CertificateHash'
        }

        It 'Should return the test certificate that was bound' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $result.CertificateHash | Should -Contain $script:testCertificateHash
        }

        It 'Should return correct properties for the test certificate' {
            $result = $script:configuration | Get-SqlDscRSSslCertificate -ErrorAction 'Stop'

            $testCert = $result | Where-Object -FilterScript {
                $_.CertificateHash -eq $script:testCertificateHash
            }

            $testCert | Should -Not -BeNullOrEmpty
            $testCert.CertificateName | Should -Be $script:testCertificate.FriendlyName
            $testCert.HostName | Should -Be $script:computerName
        }
    }
}
