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

Describe 'Remove-SqlDscRSUrlReservation' {
    Context 'When removing URL reservation for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

            # Use a unique port for testing to avoid conflicts
            $script:testPort = 18081
            $script:testUrl = "http://+:$script:testPort"

            # Add a test URL reservation to remove
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'
        }

        AfterAll {
            # Clean up: ensure the test URL reservation is removed
            try
            {
                $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
                $config | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'SilentlyContinue'
            }
            catch
            {
                # Ignore errors during cleanup
            }
        }

        It 'Should remove URL reservation using pipeline' {
            { $script:configuration | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify the URL was removed
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $reservations.UrlReservations | Should -Not -Contain $script:testUrl
        }

        It 'Should return configuration when using PassThru' {
            # First add the test URL back
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $result = $config | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When removing URL reservation for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

            # Use a unique port for testing to avoid conflicts
            $script:testPort = 18081
            $script:testUrl = "http://+:$script:testPort"

            # Add a test URL reservation to remove
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'
        }

        AfterAll {
            # Clean up: ensure the test URL reservation is removed
            try
            {
                $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
                $config | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'SilentlyContinue'
            }
            catch
            {
                # Ignore errors during cleanup
            }
        }

        It 'Should remove URL reservation using pipeline' {
            { $script:configuration | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify the URL was removed
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $reservations.UrlReservations | Should -Not -Contain $script:testUrl
        }

        It 'Should return configuration when using PassThru' {
            # First add the test URL back
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $result = $config | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When removing URL reservation for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

            # Use a unique port for testing to avoid conflicts
            $script:testPort = 18081
            $script:testUrl = "http://+:$script:testPort"

            # Add a test URL reservation to remove
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'
        }

        AfterAll {
            # Clean up: ensure the test URL reservation is removed
            try
            {
                $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
                $config | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'SilentlyContinue'
            }
            catch
            {
                # Ignore errors during cleanup
            }
        }

        It 'Should remove URL reservation using pipeline' {
            { $script:configuration | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify the URL was removed
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $reservations.UrlReservations | Should -Not -Contain $script:testUrl
        }

        It 'Should return configuration when using PassThru' {
            # First add the test URL back
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $result = $config | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When removing URL reservation for Power BI Report Server' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'

            # Use a unique port for testing to avoid conflicts
            $script:testPort = 18081
            $script:testUrl = "http://+:$script:testPort"

            # Add a test URL reservation to remove
            $script:configuration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'
        }

        AfterAll {
            # Clean up: ensure the test URL reservation is removed
            try
            {
                $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
                $config | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'SilentlyContinue'
            }
            catch
            {
                # Ignore errors during cleanup
            }
        }

        It 'Should remove URL reservation for PBIRS using pipeline' {
            { $script:configuration | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify the URL was removed
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $reservations.UrlReservations | Should -Not -Contain $script:testUrl
        }

        It 'Should return configuration when using PassThru' {
            # First add the test URL back
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $config | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -ErrorAction 'Stop'

            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $result = $config | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'
        }
    }
}
