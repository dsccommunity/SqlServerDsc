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
        This test file recreates all URL reservations after the service account
        has been changed. URL reservations are tied to the Windows service account
        and must be recreated after changing the account to use the new account's
        security context.

        This test runs after Post.ServiceAccountChange.RS to ensure the service
        account has been verified before recreating URL reservations.
#>
Describe 'Post.UrlReservationRecreate.RS' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
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

        $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

        # Get URL reservations before recreating
        $script:urlReservationsBefore = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

        Write-Verbose -Message "Instance: $script:instanceName, URL Reservations before: Application=$($script:urlReservationsBefore.Application -join ',') UrlString=$($script:urlReservationsBefore.UrlString -join ',')" -Verbose
    }

    Context 'When recreating URL reservations after service account change' {
        It 'Should have URL reservations to recreate' {
            $script:urlReservationsBefore | Should -Not -BeNullOrEmpty
            $script:urlReservationsBefore.Application | Should -Not -BeNullOrEmpty -Because 'URL reservations should have applications configured'
            $script:urlReservationsBefore.UrlString | Should -Not -BeNullOrEmpty -Because 'URL reservations should have URL strings configured'
        }

        It 'Should recreate all URL reservations without throwing' {
            $null = $script:configuration | Set-SqlDscRSUrlReservation -RecreateExisting -Force -ErrorAction 'Stop'
        }

        It 'Should have the same URL reservations after recreating' {
            $urlReservationsAfter = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            Write-Verbose -Message "URL Reservations after: Application=$($urlReservationsAfter.Application -join ',') UrlString=$($urlReservationsAfter.UrlString -join ',')" -Verbose

            $urlReservationsAfter.Application.Count | Should -Be $script:urlReservationsBefore.Application.Count -Because 'the number of URL reservations should remain the same'

            # Verify each application and URL combination exists
            for ($i = 0; $i -lt $script:urlReservationsBefore.Application.Count; $i++)
            {
                $expectedApplication = $script:urlReservationsBefore.Application[$i]
                $expectedUrl = $script:urlReservationsBefore.UrlString[$i]

                # Find matching reservation in after list
                $found = $false

                for ($j = 0; $j -lt $urlReservationsAfter.Application.Count; $j++)
                {
                    if ($urlReservationsAfter.Application[$j] -eq $expectedApplication -and $urlReservationsAfter.UrlString[$j] -eq $expectedUrl)
                    {
                        $found = $true

                        break
                    }
                }

                $found | Should -BeTrue -Because "URL reservation '$expectedUrl' for application '$expectedApplication' should exist after recreation"
            }
        }

        It 'Should have all configured sites accessible after URL reservation recreation' {
            $results = $script:configuration | Test-SqlDscRSAccessible -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            # Verify we got results for the expected applications
            $expectedApplications = $script:urlReservationsBefore.Application | Select-Object -Unique

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $results | Should -HaveCount $expectedApplications.Count -Because "we expect results for each unique application ($($expectedApplications -join ', '))"

            foreach ($application in $expectedApplications)
            {
                $siteResult = $results | Where-Object -FilterScript { $_.Site -eq $application }

                $siteResult | Should -Not -BeNullOrEmpty -Because "the '$application' site should have a result"
                $siteResult.Accessible | Should -BeTrue -Because "the '$application' site should be accessible after URL reservation recreation"
                $siteResult.StatusCode | Should -Be 200 -Because "the '$application' site should return HTTP 200 after URL reservation recreation"
            }
        }
    }
}
