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

Describe 'Test-SqlDscRSInitialized' {
    Context 'When testing if SQL Server Reporting Services is initialized' -Tag @('Integration_SQL2017_RS') {
        It 'Should return initialization status' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'
            $result | Should -BeOfType [System.Boolean]
        }
    }

    Context 'When testing if SQL Server Reporting Services is initialized' -Tag @('Integration_SQL2019_RS') {
        It 'Should return initialization status' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'
            $result | Should -BeOfType [System.Boolean]
        }
    }

    Context 'When testing if SQL Server Reporting Services is initialized' -Tag @('Integration_SQL2022_RS') {
        It 'Should return initialization status' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'
            $result | Should -BeOfType [System.Boolean]
        }
    }

    Context 'When testing if Power BI Report Server is initialized' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        It 'Should return initialization status' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $result = $configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'
            $result | Should -BeOfType [System.Boolean]
        }
    }
}
