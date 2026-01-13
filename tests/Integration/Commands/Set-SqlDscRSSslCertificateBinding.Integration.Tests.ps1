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

    <#
        Use the same certificate and binding parameters as Add-SqlDscRSSslCertificateBinding
        integration tests. This test sets the binding after Remove-SqlDscRSSslCertificateBinding
        has removed it.
    #>
    $script:testCertificateFriendlyName = 'SqlServerDsc SSL Integration Test Certificate'
    $script:testIPAddress = '0.0.0.0'
    $script:testPort = 8443
}

<#
    .NOTES
        This test validates that Set-SqlDscRSSslCertificateBinding works correctly.
        It uses the same certificate created by Add-SqlDscRSSslCertificateBinding
        and sets the binding after Remove-SqlDscRSSslCertificateBinding has removed it.
#>
Describe 'Set-SqlDscRSSslCertificateBinding' {
    Context 'When setting SSL certificate binding for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get the test certificate that was created by Add-SqlDscRSSslCertificateBinding tests
            $script:testCertificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' |
                Where-Object -FilterScript { $_.FriendlyName -eq $script:testCertificateFriendlyName } |
                Select-Object -First 1

            $script:testCertificateHash = $script:testCertificate.Thumbprint
        }

        It 'Should set SSL certificate binding' -Skip:(-not $script:testCertificateHash) {
            { $script:configuration | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return configuration when using PassThru' -Skip:(-not $script:testCertificateHash) {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $config | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When setting SSL certificate binding for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            $script:testCertificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' |
                Where-Object -FilterScript { $_.FriendlyName -eq $script:testCertificateFriendlyName } |
                Select-Object -First 1

            $script:testCertificateHash = $script:testCertificate.Thumbprint
        }

        It 'Should set SSL certificate binding' -Skip:(-not $script:testCertificateHash) {
            { $script:configuration | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return configuration when using PassThru' -Skip:(-not $script:testCertificateHash) {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $config | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When setting SSL certificate binding for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            $script:testCertificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' |
                Where-Object -FilterScript { $_.FriendlyName -eq $script:testCertificateFriendlyName } |
                Select-Object -First 1

            $script:testCertificateHash = $script:testCertificate.Thumbprint
        }

        It 'Should set SSL certificate binding' -Skip:(-not $script:testCertificateHash) {
            { $script:configuration | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return configuration when using PassThru' -Skip:(-not $script:testCertificateHash) {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $config | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When setting SSL certificate binding for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            $script:testCertificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' |
                Where-Object -FilterScript { $_.FriendlyName -eq $script:testCertificateFriendlyName } |
                Select-Object -First 1

            $script:testCertificateHash = $script:testCertificate.Thumbprint
        }

        It 'Should set SSL certificate binding' -Skip:(-not $script:testCertificateHash) {
            { $script:configuration | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return configuration when using PassThru' -Skip:(-not $script:testCertificateHash) {
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $result = $config | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'
        }
    }
}
