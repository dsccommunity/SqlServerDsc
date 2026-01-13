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

    Import-Module -Name 'PSPKI' -ErrorAction 'Stop'

    $script:computerName = Get-ComputerName

    <#
        Create a self-signed certificate for SSL binding tests.
        Using PSPKI module's New-SelfSignedCertificateEx for compatibility.
    #>
    $newSelfSignedCertificateExParameters = @{
        Subject            = "CN=$script:computerName"
        EKU                = 'Server Authentication'
        KeyUsage           = 'DigitalSignature, KeyEncipherment, DataEncipherment'
        SAN                = "dns:$script:computerName"
        FriendlyName       = 'SqlServerDsc SSL Integration Test Certificate'
        Exportable         = $true
        KeyLength          = 2048
        ProviderName       = 'Microsoft Software Key Storage Provider'
        AlgorithmName      = 'RSA'
        SignatureAlgorithm = 'SHA256'
        StoreLocation      = 'LocalMachine'
        StoreName          = 'My'
    }

    $script:testCertificate = New-SelfSignedCertificateEx @newSelfSignedCertificateExParameters

    Write-Verbose -Message ('Created self-signed certificate ''{0}'' with thumbprint ''{1}''.' -f $script:testCertificate.Subject, $script:testCertificate.Thumbprint) -Verbose

    # Add the certificate to Trusted Root Certification Authorities to avoid browser warnings
    $script:certificatePath = Join-Path -Path $env:TEMP -ChildPath 'SqlServerDscSslIntegrationTest.cer'

    Export-Certificate -Cert $script:testCertificate -FilePath $script:certificatePath -ErrorAction 'Stop'

    $null = Import-Certificate -FilePath $script:certificatePath -CertStoreLocation 'Cert:\LocalMachine\Root' -ErrorAction 'Stop'

    Write-Verbose -Message ('Added certificate to Trusted Root Certification Authorities.') -Verbose

    $script:testCertificateHash = $script:testCertificate.Thumbprint
    $script:testIPAddress = '0.0.0.0'
    $script:testPort = 8443
}

<#
    .NOTES
        These tests use a self-signed certificate created in BeforeAll.
        The certificate is not removed after tests to allow inspection.
#>
Describe 'Add-SqlDscRSSslCertificateBinding' {
    Context 'When adding SSL certificate binding for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should add SSL certificate binding' {
            { $script:configuration | Add-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }

    Context 'When adding SSL certificate binding for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should add SSL certificate binding' {
            { $script:configuration | Add-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }

    Context 'When adding SSL certificate binding for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should add SSL certificate binding' {
            { $script:configuration | Add-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }

    Context 'When adding SSL certificate binding for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
        }

        It 'Should add SSL certificate binding' {
            { $script:configuration | Add-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash $script:testCertificateHash -IPAddress $script:testIPAddress -Port $script:testPort -Force -ErrorAction 'Stop' } | Should -Not -Throw
        }
    }
}
