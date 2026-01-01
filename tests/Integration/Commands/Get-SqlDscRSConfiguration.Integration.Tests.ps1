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

Describe 'Get-SqlDscRSConfiguration' {
    Context 'When getting the configuration CIM instance for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        It 'Should return the configuration CIM instance for SSRS instance' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.SecureConnectionLevel | Should -BeIn @(0, 1, 2)
            $result | Should -BeOfType 'Microsoft.Management.Infrastructure.CimInstance'
        }
    }

    Context 'When getting the configuration CIM instance for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        It 'Should return the configuration CIM instance for SSRS instance' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.SecureConnectionLevel | Should -BeIn @(0, 1, 2)
            $result | Should -BeOfType 'Microsoft.Management.Infrastructure.CimInstance'
        }
    }

    Context 'When getting the configuration CIM instance for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        It 'Should return the configuration CIM instance for SSRS instance' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'SSRS'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.SecureConnectionLevel | Should -BeIn @(0, 1, 2)
            $result | Should -BeOfType 'Microsoft.Management.Infrastructure.CimInstance'
        }
    }

    Context 'When getting the configuration CIM instance for Power BI Report Server' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        It 'Should return the configuration CIM instance for PBIRS instance' {
            $result = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'
            $result.SecureConnectionLevel | Should -BeIn @(0, 1, 2)
            $result | Should -BeOfType 'Microsoft.Management.Infrastructure.CimInstance'
        }
    }

    Context 'When getting configuration with explicit version' -Tag @('Integration_SQL2019_RS') {
        It 'Should return the configuration CIM instance when version is specified' {
            # Get version from setup configuration
            $setupConfig = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'
            $version = ([System.Version] $setupConfig.CurrentVersion).Major

            $result = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -Version $version

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }
}
