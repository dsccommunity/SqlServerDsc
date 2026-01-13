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

Describe 'Get-SqlDscRSIPAddress' {
    <#
        Note: CI environments contain dynamic IP addresses that change per run (e.g., 10.1.0.x, 172.x.x.x).
        We validate the command returns expected addresses and structure without checking for specific
        dynamic IPs. Loopback addresses (127.0.0.1) and IPv4/IPv6 support are consistent across runs.
    #>

    Context 'When getting IP addresses for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        It 'Should return available IP addresses' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSIPAddress -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty

            # Should contain loopback addresses (stable across CI workers)
            $result.IPAddress | Should -Contain '127.0.0.1'

            # Should have IPv4 addresses
            $result.IPVersion | Should -Contain 'V4'

            # Should have at least one additional IP besides loopback
            $result.Count | Should -BeGreaterThan 1
        }
    }

    Context 'When getting IP addresses for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        It 'Should return available IP addresses' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSIPAddress -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty

            # Should contain loopback addresses (stable across CI workers)
            $result.IPAddress | Should -Contain '127.0.0.1'

            # Should have IPv4 addresses
            $result.IPVersion | Should -Contain 'V4'

            # Should have at least one additional IP besides loopback
            $result.Count | Should -BeGreaterThan 1
        }
    }

    Context 'When getting IP addresses for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        It 'Should return available IP addresses' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSIPAddress -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty

            # Should contain loopback addresses (stable across CI workers)
            $result.IPAddress | Should -Contain '127.0.0.1'

            # Should have IPv4 addresses
            $result.IPVersion | Should -Contain 'V4'

            # Should have at least one additional IP besides loopback
            $result.Count | Should -BeGreaterThan 1
        }
    }

    Context 'When getting IP addresses for Power BI Report Server' -Tag @('Integration_PowerBI') {
        It 'Should return available IP addresses' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSIPAddress -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty

            # Should contain loopback addresses (stable across CI workers)
            $result.IPAddress | Should -Contain '127.0.0.1'

            # Should have IPv4 addresses
            $result.IPVersion | Should -Contain 'V4'

            # Should have at least one additional IP besides loopback
            $result.Count | Should -BeGreaterThan 1
        }
    }
}
