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
}

<#
    .NOTES
        This test file validates that Reporting Services sites are accessible
        after initialization. It runs after Initialize-SqlDscRS to verify
        the RS configuration is complete and functional.

        Uses URL reservations from the configuration CIM instance via the
        Configuration parameter set of Test-SqlDscRSAccessible.
#>
Describe 'Post.Initialization.RS' {
    Context 'When validating SQL Server 2017 Reporting Services accessibility' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get expected URL reservations
            $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            Write-Verbose -Message "URL Reservations: Application=$($script:urlReservations.Application -join ',') UrlString=$($script:urlReservations.UrlString -join ',')" -Verbose
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have URL reservations configured' {
            $script:urlReservations | Should -Not -BeNullOrEmpty
            $script:urlReservations.Application | Should -Not -BeNullOrEmpty -Because 'URL reservations should have applications configured'
            $script:urlReservations.UrlString | Should -Not -BeNullOrEmpty -Because 'URL reservations should have URL strings configured'
        }

        It 'Should have all configured sites accessible' {
            $results = $script:configuration | Test-SqlDscRSAccessible -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            # Verify we got results for the expected applications
            $expectedApplications = $script:urlReservations.Application | Select-Object -Unique

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $results | Should -HaveCount $expectedApplications.Count -Because "we expect results for each unique application ($($expectedApplications -join ', '))"

            foreach ($application in $expectedApplications)
            {
                $siteResult = $results | Where-Object -FilterScript { $_.Site -eq $application }

                $siteResult | Should -Not -BeNullOrEmpty -Because "the '$application' site should have a result"
                $siteResult.Accessible | Should -BeTrue -Because "the '$application' site should be accessible"
                $siteResult.StatusCode | Should -Be 200 -Because "the '$application' site should return HTTP 200"
            }
        }
    }

    Context 'When validating SQL Server 2019 Reporting Services accessibility' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get expected URL reservations
            $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            Write-Verbose -Message "URL Reservations: Application=$($script:urlReservations.Application -join ',') UrlString=$($script:urlReservations.UrlString -join ',')" -Verbose
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have URL reservations configured' {
            $script:urlReservations | Should -Not -BeNullOrEmpty
            $script:urlReservations.Application | Should -Not -BeNullOrEmpty -Because 'URL reservations should have applications configured'
            $script:urlReservations.UrlString | Should -Not -BeNullOrEmpty -Because 'URL reservations should have URL strings configured'
        }

        It 'Should have all configured sites accessible' {
            $results = $script:configuration | Test-SqlDscRSAccessible -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            # Verify we got results for the expected applications
            $expectedApplications = $script:urlReservations.Application | Select-Object -Unique

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $results | Should -HaveCount $expectedApplications.Count -Because "we expect results for each unique application ($($expectedApplications -join ', '))"

            foreach ($application in $expectedApplications)
            {
                $siteResult = $results | Where-Object -FilterScript { $_.Site -eq $application }

                $siteResult | Should -Not -BeNullOrEmpty -Because "the '$application' site should have a result"
                $siteResult.Accessible | Should -BeTrue -Because "the '$application' site should be accessible"
                $siteResult.StatusCode | Should -Be 200 -Because "the '$application' site should return HTTP 200"
            }
        }
    }

    Context 'When validating SQL Server 2022 Reporting Services accessibility' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get expected URL reservations
            $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            Write-Verbose -Message "URL Reservations: Application=$($script:urlReservations.Application -join ',') UrlString=$($script:urlReservations.UrlString -join ',')" -Verbose
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have URL reservations configured' {
            $script:urlReservations | Should -Not -BeNullOrEmpty
            $script:urlReservations.Application | Should -Not -BeNullOrEmpty -Because 'URL reservations should have applications configured'
            $script:urlReservations.UrlString | Should -Not -BeNullOrEmpty -Because 'URL reservations should have URL strings configured'
        }

        It 'Should have all configured sites accessible' {
            $results = $script:configuration | Test-SqlDscRSAccessible -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            # Verify we got results for the expected applications
            $expectedApplications = $script:urlReservations.Application | Select-Object -Unique

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $results | Should -HaveCount $expectedApplications.Count -Because "we expect results for each unique application ($($expectedApplications -join ', '))"

            foreach ($application in $expectedApplications)
            {
                $siteResult = $results | Where-Object -FilterScript { $_.Site -eq $application }

                $siteResult | Should -Not -BeNullOrEmpty -Because "the '$application' site should have a result"
                $siteResult.Accessible | Should -BeTrue -Because "the '$application' site should be accessible"
                $siteResult.StatusCode | Should -Be 200 -Because "the '$application' site should return HTTP 200"
            }
        }
    }

    Context 'When validating Power BI Report Server accessibility' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Get expected URL reservations
            $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            Write-Verbose -Message "URL Reservations: Application=$($script:urlReservations.Application -join ',') UrlString=$($script:urlReservations.UrlString -join ',')" -Verbose
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have URL reservations configured' {
            $script:urlReservations | Should -Not -BeNullOrEmpty
            $script:urlReservations.Application | Should -Not -BeNullOrEmpty -Because 'URL reservations should have applications configured'
            $script:urlReservations.UrlString | Should -Not -BeNullOrEmpty -Because 'URL reservations should have URL strings configured'
        }

        It 'Should have all configured sites accessible' {
            $results = $script:configuration | Test-SqlDscRSAccessible -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            # Verify we got results for the expected applications
            $expectedApplications = $script:urlReservations.Application | Select-Object -Unique

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $results | Should -HaveCount $expectedApplications.Count -Because "we expect results for each unique application ($($expectedApplications -join ', '))"

            foreach ($application in $expectedApplications)
            {
                $siteResult = $results | Where-Object -FilterScript { $_.Site -eq $application }

                $siteResult | Should -Not -BeNullOrEmpty -Because "the '$application' site should have a result"
                $siteResult.Accessible | Should -BeTrue -Because "the '$application' site should be accessible"
                $siteResult.StatusCode | Should -Be 200 -Because "the '$application' site should return HTTP 200"
            }
        }
    }
}
