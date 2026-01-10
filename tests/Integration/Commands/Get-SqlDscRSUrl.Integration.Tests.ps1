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

Describe 'Get-SqlDscRSUrl' {
    Context 'When getting Report Server URLs for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS') {
        BeforeAll {
            $script:setupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return Report Server URLs using pipeline' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return Report Server URLs using SetupConfiguration parameter' {
            $result = Get-SqlDscRSUrl -SetupConfiguration $script:setupConfiguration -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return ReportServerUri objects with expected properties' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result[0].PSObject.Properties.Name | Should -Contain 'InstanceName'
            $result[0].PSObject.Properties.Name | Should -Contain 'ApplicationName'
            $result[0].PSObject.Properties.Name | Should -Contain 'Uri'
        }

        It 'Should return URLs for the correct instance' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $result | ForEach-Object -Process {
                $_.InstanceName | Should -Be 'SSRS'
            }
        }

        It 'Should return URLs for ReportServerWebService application' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $webServiceUrls = $result | Where-Object -FilterScript {
                $_.ApplicationName -eq 'ReportServerWebService'
            }

            $webServiceUrls | Should -Not -BeNullOrEmpty -Because 'ReportServerWebService should have URLs configured'
            $webServiceUrls[0].Uri | Should -Match '^https?://' -Because 'URL should be a valid HTTP or HTTPS URL'
        }

        It 'Should return URLs for ReportServerWebApp application' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $webAppUrls = $result | Where-Object -FilterScript {
                $_.ApplicationName -eq 'ReportServerWebApp'
            }

            $webAppUrls | Should -Not -BeNullOrEmpty -Because 'ReportServerWebApp should have URLs configured'
            $webAppUrls[0].Uri | Should -Match '^https?://' -Because 'URL should be a valid HTTP or HTTPS URL'
        }
    }

    Context 'When getting Report Server URLs for Power BI Report Server' -Tag @('Integration_PBIRS') {
        BeforeAll {
            $script:setupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
        }

        It 'Should return Report Server URLs using pipeline' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return Report Server URLs using SetupConfiguration parameter' {
            $result = Get-SqlDscRSUrl -SetupConfiguration $script:setupConfiguration -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return ReportServerUri objects with expected properties' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result[0].PSObject.Properties.Name | Should -Contain 'InstanceName'
            $result[0].PSObject.Properties.Name | Should -Contain 'ApplicationName'
            $result[0].PSObject.Properties.Name | Should -Contain 'Uri'
        }

        It 'Should return URLs for the correct instance' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $result | ForEach-Object -Process {
                $_.InstanceName | Should -Be 'PBIRS'
            }
        }

        It 'Should return URLs for ReportServerWebService application' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $webServiceUrls = $result | Where-Object -FilterScript {
                $_.ApplicationName -eq 'ReportServerWebService'
            }

            $webServiceUrls | Should -Not -BeNullOrEmpty -Because 'ReportServerWebService should have URLs configured'
            $webServiceUrls[0].Uri | Should -Match '^https?://' -Because 'URL should be a valid HTTP or HTTPS URL'
        }

        It 'Should return URLs for ReportServerWebApp application' {
            $result = $script:setupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $webAppUrls = $result | Where-Object -FilterScript {
                $_.ApplicationName -eq 'ReportServerWebApp'
            }

            $webAppUrls | Should -Not -BeNullOrEmpty -Because 'ReportServerWebApp should have URLs configured'
            $webAppUrls[0].Uri | Should -Match '^https?://' -Because 'URL should be a valid HTTP or HTTPS URL'
        }
    }

    Context 'When getting Report Server URLs for all instances' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS') {
        It 'Should return URLs for all instances via pipeline' {
            $result = Get-SqlDscRSSetupConfiguration | Get-SqlDscRSUrl -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }
    }
}
