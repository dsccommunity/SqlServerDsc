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

Describe 'Get-SqlDscRSUrlReservation' {
    Context 'When getting URL reservations for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return URL reservations using pipeline' {
            $result = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return URL reservations using Configuration parameter' {
            $result = Get-SqlDscRSUrlReservation -Configuration $script:configuration -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return result with expected properties' {
            $result = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # The result should be a CIM method result with URL reservation properties
            $result | Should -Not -BeNullOrEmpty
            $result.HRESULT | Should -Be 0
            $result.Application | Should -Not -BeNullOrEmpty
            $result.UrlString | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When getting URL reservations for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return URL reservations using pipeline' {
            $result = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return URL reservations using Configuration parameter' {
            $result = Get-SqlDscRSUrlReservation -Configuration $script:configuration -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return result with expected properties' {
            $result = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # The result should be a CIM method result with URL reservation properties
            $result | Should -Not -BeNullOrEmpty
            $result.HRESULT | Should -Be 0
            $result.Application | Should -Not -BeNullOrEmpty
            $result.UrlString | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When getting URL reservations for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should return URL reservations using pipeline' {
            $result = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return URL reservations using Configuration parameter' {
            $result = Get-SqlDscRSUrlReservation -Configuration $script:configuration -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return result with expected properties' {
            $result = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # The result should be a CIM method result with URL reservation properties
            $result | Should -Not -BeNullOrEmpty
            $result.HRESULT | Should -Be 0
            $result.Application | Should -Not -BeNullOrEmpty
            $result.UrlString | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When getting URL reservations for Power BI Report Server' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
        }

        It 'Should return URL reservations using pipeline' {
            $result = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return URL reservations using Configuration parameter' {
            $result = Get-SqlDscRSUrlReservation -Configuration $script:configuration -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return result with expected properties' {
            $result = $script:configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # The result should be a CIM method result with URL reservation properties
            $result | Should -Not -BeNullOrEmpty
            $result.HRESULT | Should -Be 0
            $result.Application | Should -Not -BeNullOrEmpty
            $result.UrlString | Should -Not -BeNullOrEmpty
        }
    }
}
