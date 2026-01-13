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
        over HTTPS on port 443 after SSL/TLS certificate binding. It runs after
        Initialize-SqlDscRS in the SSL/TLS test stage to verify the RS
        configuration is complete and functional with secure connections.

        Uses explicit HTTPS URIs with port 443 to test the configured sites.
#>
Describe 'Post.Certificate.RS' {
    Context 'When validating Power BI Report Server accessibility over HTTPS' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Get the virtual directories
            $script:reportServerVirtualDirectory = $script:configuration.VirtualDirectoryReportServer
            $script:reportsVirtualDirectory = $script:configuration.VirtualDirectoryReportManager

            # Construct HTTPS URIs using port 443
            $computerName = Get-ComputerName

            $script:reportServerUri = "https://$computerName`:443/$script:reportServerVirtualDirectory"
            $script:reportsUri = "https://$computerName`:443/$script:reportsVirtualDirectory"

            Write-Verbose -Message "Testing ReportServer URI: $script:reportServerUri" -Verbose
            Write-Verbose -Message "Testing Reports URI: $script:reportsUri" -Verbose
        }

        It 'Should have an initialized instance' {
            $isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue
        }

        It 'Should have the ReportServer site accessible over HTTPS on port 443' {
            $results = Test-SqlDscRSAccessible -ReportServerUri $script:reportServerUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "ReportServer accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'

            $siteResult = $results | Where-Object -FilterScript { $_.Site -eq 'ReportServer' }

            $siteResult | Should -Not -BeNullOrEmpty -Because 'the ReportServer site should have a result'
            $siteResult.Accessible | Should -BeTrue -Because 'the ReportServer site should be accessible over HTTPS'
            $siteResult.StatusCode | Should -Be 200 -Because 'the ReportServer site should return HTTP 200'
            $siteResult.Uri | Should -Match '^https://' -Because 'the URI should use HTTPS protocol'
            $siteResult.Uri | Should -Match ':443/' -Because 'the URI should use port 443'
        }

        It 'Should have the Reports site accessible over HTTPS on port 443' {
            $results = Test-SqlDscRSAccessible -ReportsUri $script:reportsUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Reports accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'

            $siteResult = $results | Where-Object -FilterScript { $_.Site -eq 'Reports' }

            $siteResult | Should -Not -BeNullOrEmpty -Because 'the Reports site should have a result'
            $siteResult.Accessible | Should -BeTrue -Because 'the Reports site should be accessible over HTTPS'
            $siteResult.StatusCode | Should -Be 200 -Because 'the Reports site should return HTTP 200'
            $siteResult.Uri | Should -Match '^https://' -Because 'the URI should use HTTPS protocol'
            $siteResult.Uri | Should -Match ':443/' -Because 'the URI should use port 443'
        }

        It 'Should have both sites accessible when tested together over HTTPS on port 443' {
            $results = Test-SqlDscRSAccessible -ReportServerUri $script:reportServerUri -ReportsUri $script:reportsUri -Detailed -ErrorAction 'Stop'

            Write-Verbose -Message "Combined accessibility results: $($results | ConvertTo-Json -Compress)" -Verbose

            $results | Should -Not -BeNullOrEmpty -Because 'the command should return site accessibility results'
            $results | Should -HaveCount 2 -Because 'we expect results for both ReportServer and Reports sites'

            foreach ($result in $results)
            {
                $result.Accessible | Should -BeTrue -Because "the '$($result.Site)' site should be accessible over HTTPS"
                $result.StatusCode | Should -Be 200 -Because "the '$($result.Site)' site should return HTTP 200"
                $result.Uri | Should -Match '^https://' -Because "the '$($result.Site)' URI should use HTTPS protocol"
                $result.Uri | Should -Match ':443/' -Because "the '$($result.Site)' URI should use port 443"
            }
        }
    }
}
