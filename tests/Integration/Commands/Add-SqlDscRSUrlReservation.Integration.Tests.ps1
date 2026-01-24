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

Describe 'Add-SqlDscRSUrlReservation' {
    Context 'When adding URL reservation for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Use a unique port for testing to avoid conflicts
            $script:testPort = 18080
            $script:testUrl = "http://+:$script:testPort"
        }

        It 'Should add URL reservation for ReportServerWebService using pipeline' {
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            # Verify the URL was added
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $reservations.UrlString | Should -Contain $script:testUrl
        }

        It 'Should add URL reservation for ReportServerWebApp using pipeline' {
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebApp' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            # Verify the URL was added for ReportServerWebApp
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # Find the index for ReportServerWebApp
            $webAppIndex = [System.Array]::IndexOf($reservations.Application, 'ReportServerWebApp')

            $webAppIndex | Should -BeGreaterOrEqual 0 -Because 'ReportServerWebApp should be in the applications'
            $reservations.UrlString[$webAppIndex] | Should -Be $script:testUrl
        }
    }

    Context 'When adding URL reservation for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Use a unique port for testing to avoid conflicts
            $script:testPort = 18080
            $script:testUrl = "http://+:$script:testPort"
        }

        It 'Should add URL reservation for ReportServerWebService using pipeline' {
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            # Verify the URL was added
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $reservations.UrlString | Should -Contain $script:testUrl
        }

        It 'Should add URL reservation for ReportServerWebApp using pipeline' {
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebApp' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            # Verify the URL was added for ReportServerWebApp
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # Find the index for ReportServerWebApp
            $webAppIndex = [System.Array]::IndexOf($reservations.Application, 'ReportServerWebApp')

            $webAppIndex | Should -BeGreaterOrEqual 0 -Because 'ReportServerWebApp should be in the applications'
            $reservations.UrlString[$webAppIndex] | Should -Be $script:testUrl
        }
    }

    Context 'When adding URL reservation for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Use a unique port for testing to avoid conflicts
            $script:testPort = 18080
            $script:testUrl = "http://+:$script:testPort"
        }

        It 'Should add URL reservation for ReportServerWebService using pipeline' {
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            # Verify the URL was added
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $reservations.UrlString | Should -Contain $script:testUrl
        }

        It 'Should add URL reservation for ReportServerWebApp using pipeline' {
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebApp' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            # Verify the URL was added for ReportServerWebApp
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # Find the index for ReportServerWebApp
            $webAppIndex = [System.Array]::IndexOf($reservations.Application, 'ReportServerWebApp')

            $webAppIndex | Should -BeGreaterOrEqual 0 -Because 'ReportServerWebApp should be in the applications'
            $reservations.UrlString[$webAppIndex] | Should -Be $script:testUrl
        }
    }

    Context 'When adding URL reservation for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Use a unique port for testing to avoid conflicts
            $script:testPort = 18080
            $script:testUrl = "http://+:$script:testPort"
        }

        It 'Should add URL reservation for ReportServerWebService using pipeline' {
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            # Verify the URL was added
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $reservations.UrlString | Should -Contain $script:testUrl
        }

        It 'Should add URL reservation for ReportServerWebApp using pipeline' {
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebApp' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            # Verify the URL was added for ReportServerWebApp
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # Find the index for ReportServerWebApp
            $webAppIndex = [System.Array]::IndexOf($reservations.Application, 'ReportServerWebApp')

            $webAppIndex | Should -BeGreaterOrEqual 0 -Because 'ReportServerWebApp should be in the applications'
            $reservations.UrlString[$webAppIndex] | Should -Be $script:testUrl
        }
    }
}
