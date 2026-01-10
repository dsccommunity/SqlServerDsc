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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../TestHelpers/CommonTestHelper.psm1')

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

<#
    .NOTES
        This test file validates that Reporting Services sites are accessible
        after the service account has been changed. It runs after the
        Set-SqlDscRSServiceAccount and Get-SqlDscRSServiceAccount tests to
        verify the RS configuration remains functional after a service account
        change.

        Uses URL reservations from the configuration CIM instance via the
        Configuration parameter set of Test-SqlDscRSAccessible.
#>

<#
    TODO: The following integration tests are skipped on SQL Server 2017 due to
          encryption key validation failures. These tests are linked and all fail
          with similar errors related to "rsCannotValidateEncryptedData" and
          "Keyset does not exist".

          Failing tests on SQL Server 2017:
          - Remove-SqlDscRSEncryptionKey.Integration.Tests.ps1
          - New-SqlDscRSEncryptionKey.Integration.Tests.ps1
          - Post.Reinitialize.RS.Integration.Tests.ps1
          - Post.ServiceAccountChange.RS.Integration.Tests.ps1

          Error: "The report server was unable to validate the integrity of encrypted
          data in the database. (rsCannotValidateEncryptedData);Keyset does not exist
          (Exception from HRESULT: 0x80090016)"

          Re-add tag 'Integration_SQL2017_RS' when fixed.
#>
Describe 'Post.ServiceAccountChange.RS' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
    BeforeAll {
        if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_PowerBI')
        {
            $script:instanceName = 'PBIRS'
        }
        else
        {
            # Default to SSRS for SQL2017_RS, SQL2019_RS, SQL2022_RS
            $script:instanceName = 'SSRS'
        }

        $computerName = Get-ComputerName
        $script:expectedServiceAccount = '{0}\svc-RS' -f $computerName

        $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

        # Get expected URL reservations
        $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

        Write-Verbose -Message "Instance: $script:instanceName, URL Reservations: Application=$($script:urlReservations.Application -join ',') UrlString=$($script:urlReservations.UrlString -join ',')" -Verbose
    }

    Context 'When validating Reporting Services accessibility after service account change' {
        It 'Should have the expected service account set' {
            $currentServiceAccount = $script:configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $currentServiceAccount | Should -BeExactly $script:expectedServiceAccount -Because 'the service account should have been changed by Set-SqlDscRSServiceAccount tests'
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue -Because 'the instance should remain initialized after service account change'
        }

        It 'Should have URL reservations configured' {
            $script:urlReservations | Should -Not -BeNullOrEmpty
            $script:urlReservations.Application | Should -Not -BeNullOrEmpty -Because 'URL reservations should have applications configured'
            $script:urlReservations.UrlString | Should -Not -BeNullOrEmpty -Because 'URL reservations should have URL strings configured'
        }

        It 'Should have all configured sites accessible after service account change' {
            $results = $script:configuration | Test-SqlDscRSAccessible -Detailed -TimeoutSeconds 240 -RetryIntervalSeconds 10 -ErrorAction 'Stop' -Verbose

            Write-Verbose -Message "Accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            # Verify we got results for the expected applications
            $expectedApplications = $script:urlReservations.Application | Select-Object -Unique

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $results | Should -HaveCount $expectedApplications.Count -Because "we expect results for each unique application ($($expectedApplications -join ', '))"

            foreach ($application in $expectedApplications)
            {
                $siteResult = $results | Where-Object -FilterScript { $_.Site -eq $application }

                $siteResult | Should -Not -BeNullOrEmpty -Because "the '$application' site should have a result"
                $siteResult.Accessible | Should -BeTrue -Because "the '$application' site should be accessible after service account change"
                $siteResult.StatusCode | Should -Be 200 -Because "the '$application' site should return HTTP 200 after service account change"
            }
        }
    }
}
