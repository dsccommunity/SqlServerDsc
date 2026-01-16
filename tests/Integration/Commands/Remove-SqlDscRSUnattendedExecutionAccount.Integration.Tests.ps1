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
        These tests validate removing the unattended execution account.
        Since the unattended execution account may not be configured,
        the tests may succeed or fail depending on the current state.
#>
Describe 'Remove-SqlDscRSUnattendedExecutionAccount' {
    Context 'When removing unattended execution account for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should not throw when removing unattended execution account' {
            $script:configuration | Remove-SqlDscRSUnattendedExecutionAccount -Force -ErrorAction 'Stop'
        }
    }

    Context 'When removing unattended execution account for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should not throw when removing unattended execution account' {
            $script:configuration | Remove-SqlDscRSUnattendedExecutionAccount -Force -ErrorAction 'Stop'
        }
    }

    Context 'When removing unattended execution account for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
        }

        It 'Should not throw when removing unattended execution account' {
            $script:configuration | Remove-SqlDscRSUnattendedExecutionAccount -Force -ErrorAction 'Stop'
        }
    }

    Context 'When removing unattended execution account for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
        }

        It 'Should not throw when removing unattended execution account' {
            $script:configuration | Remove-SqlDscRSUnattendedExecutionAccount -Force -ErrorAction 'Stop'
        }
    }
}
