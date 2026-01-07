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

        Uses explicit URIs instead of relying on URL reservations from the
        configuration CIM instance, as the ListReservedUrls CIM method may
        not return data reliably in all CI scenarios.
#>
Describe 'Post.Initialization.RS' {
    Context 'When validating SQL Server 2017 Reporting Services accessibility' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get actual URL reservations from the configuration
            $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'SilentlyContinue'

            Write-Verbose -Message "URL Reservations: $($script:urlReservations | ConvertTo-Json -Compress -Depth 3)" -Verbose

            # SSRS 2017 and later use fixed virtual directories without instance suffix
            $computerName = Get-ComputerName
            $script:reportServerUri = 'http://{0}/ReportServer' -f $computerName
            $script:reportsUri = 'http://{0}/Reports' -f $computerName
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have accessible ReportServer site' {
            $result = Test-SqlDscRSAccessible -ReportServerUri $script:reportServerUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "ReportServer accessibility result: $($result | ConvertTo-Json -Compress)" -Verbose

            $result | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $result.Accessible | Should -BeTrue -Because 'the ReportServer web service should be accessible'
            $result.StatusCode | Should -Be 200 -Because 'the ReportServer web service should return HTTP 200'
        }

        It 'Should have accessible Reports site' {
            $result = Test-SqlDscRSAccessible -ReportsUri $script:reportsUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Reports accessibility result: $($result | ConvertTo-Json -Compress)" -Verbose

            $result | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $result.Accessible | Should -BeTrue -Because 'the Reports web portal should be accessible'
            $result.StatusCode | Should -Be 200 -Because 'the Reports web portal should return HTTP 200'
        }
    }

    Context 'When validating SQL Server 2019 Reporting Services accessibility' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get actual URL reservations from the configuration
            $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'SilentlyContinue'

            Write-Verbose -Message "URL Reservations: $($script:urlReservations | ConvertTo-Json -Compress -Depth 3)" -Verbose

            # SSRS 2019 uses fixed virtual directories without instance suffix
            $computerName = Get-ComputerName
            $script:reportServerUri = 'http://{0}/ReportServer' -f $computerName
            $script:reportsUri = 'http://{0}/Reports' -f $computerName
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have accessible ReportServer site' {
            $result = Test-SqlDscRSAccessible -ReportServerUri $script:reportServerUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "ReportServer accessibility result: $($result | ConvertTo-Json -Compress)" -Verbose

            $result | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $result.Accessible | Should -BeTrue -Because 'the ReportServer web service should be accessible'
            $result.StatusCode | Should -Be 200 -Because 'the ReportServer web service should return HTTP 200'
        }

        It 'Should have accessible Reports site' {
            $result = Test-SqlDscRSAccessible -ReportsUri $script:reportsUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Reports accessibility result: $($result | ConvertTo-Json -Compress)" -Verbose

            $result | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $result.Accessible | Should -BeTrue -Because 'the Reports web portal should be accessible'
            $result.StatusCode | Should -Be 200 -Because 'the Reports web portal should return HTTP 200'
        }
    }

    Context 'When validating SQL Server 2022 Reporting Services accessibility' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Get actual URL reservations from the configuration
            $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'SilentlyContinue'

            Write-Verbose -Message "URL Reservations: $($script:urlReservations | ConvertTo-Json -Compress -Depth 3)" -Verbose

            # SSRS 2022 uses fixed virtual directories without instance suffix
            $computerName = Get-ComputerName
            $script:reportServerUri = 'http://{0}/ReportServer' -f $computerName
            $script:reportsUri = 'http://{0}/Reports' -f $computerName
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have accessible ReportServer site' {
            $result = Test-SqlDscRSAccessible -ReportServerUri $script:reportServerUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "ReportServer accessibility result: $($result | ConvertTo-Json -Compress)" -Verbose

            $result | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $result.Accessible | Should -BeTrue -Because 'the ReportServer web service should be accessible'
            $result.StatusCode | Should -Be 200 -Because 'the ReportServer web service should return HTTP 200'
        }

        It 'Should have accessible Reports site' {
            $result = Test-SqlDscRSAccessible -ReportsUri $script:reportsUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Reports accessibility result: $($result | ConvertTo-Json -Compress)" -Verbose

            $result | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $result.Accessible | Should -BeTrue -Because 'the Reports web portal should be accessible'
            $result.StatusCode | Should -Be 200 -Because 'the Reports web portal should return HTTP 200'
        }
    }

    Context 'When validating Power BI Report Server accessibility' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Get actual URL reservations from the configuration
            $script:urlReservations = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'SilentlyContinue'

            Write-Verbose -Message "URL Reservations: $($script:urlReservations | ConvertTo-Json -Compress -Depth 3)" -Verbose

            # Power BI Report Server uses fixed virtual directories
            $computerName = Get-ComputerName
            $script:reportServerUri = 'http://{0}/ReportServer' -f $computerName
            $script:reportsUri = 'http://{0}/Reports' -f $computerName
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have accessible ReportServer site' {
            $result = Test-SqlDscRSAccessible -ReportServerUri $script:reportServerUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "ReportServer accessibility result: $($result | ConvertTo-Json -Compress)" -Verbose

            $result | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $result.Accessible | Should -BeTrue -Because 'the ReportServer web service should be accessible'
            $result.StatusCode | Should -Be 200 -Because 'the ReportServer web service should return HTTP 200'
        }

        It 'Should have accessible Reports site' {
            $result = Test-SqlDscRSAccessible -ReportsUri $script:reportsUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Reports accessibility result: $($result | ConvertTo-Json -Compress)" -Verbose

            $result | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $result.Accessible | Should -BeTrue -Because 'the Reports web portal should be accessible'
            $result.StatusCode | Should -Be 200 -Because 'the Reports web portal should return HTTP 200'
        }
    }
}
