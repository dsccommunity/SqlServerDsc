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

Describe 'Request-SqlDscRSDatabaseUpgradeScript' {
    Context 'When requesting database upgrade script for SQL Server 2017 Reporting Services' -Tag @('Integration_SQL2017_RS') {
        It 'Should return database upgrade script or empty result' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            $configuration | Request-SqlDscRSDatabaseUpgradeScript -ErrorAction 'Stop'
        }
    }

    Context 'When requesting database upgrade script for SQL Server 2019 Reporting Services' -Tag @('Integration_SQL2019_RS') {
        It 'Should return database upgrade script or empty result' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            $configuration | Request-SqlDscRSDatabaseUpgradeScript -ErrorAction 'Stop'
        }
    }

    Context 'When requesting database upgrade script for SQL Server 2022 Reporting Services' -Tag @('Integration_SQL2022_RS') {
        It 'Should return database upgrade script or empty result' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            $configuration | Request-SqlDscRSDatabaseUpgradeScript -ErrorAction 'Stop'
        }
    }

    Context 'When requesting database upgrade script for Power BI Report Server' -Tag @('Integration_PowerBI') {
        It 'Should return database upgrade script or empty result' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            $configuration | Request-SqlDscRSDatabaseUpgradeScript -ErrorAction 'Stop'
        }
    }
}
