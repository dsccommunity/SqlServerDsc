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
        These tests verify that the service account can be retrieved for Reporting
        Services instances. The tests run after Set-SqlDscRSServiceAccount has
        changed the service account to svc-RS, so we verify that account is set.
#>
Describe 'Get-SqlDscRSServiceAccount' {
    Context 'When getting service account for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $computerName = Get-ComputerName
            $script:expectedServiceAccount = '{0}\svc-RS' -f $computerName
        }

        It 'Should return the expected service account' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $result | Should -BeExactly $script:expectedServiceAccount
        }
    }

    Context 'When getting service account for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $computerName = Get-ComputerName
            $script:expectedServiceAccount = '{0}\svc-RS' -f $computerName
        }

        It 'Should return the expected service account' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $result | Should -BeExactly $script:expectedServiceAccount
        }
    }

    Context 'When getting service account for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $computerName = Get-ComputerName
            $script:expectedServiceAccount = '{0}\svc-RS' -f $computerName
        }

        It 'Should return the expected service account' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $result | Should -BeExactly $script:expectedServiceAccount
        }
    }

    Context 'When getting service account for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $computerName = Get-ComputerName
            $script:expectedServiceAccount = '{0}\svc-RS' -f $computerName
        }

        It 'Should return the expected service account' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $result | Should -BeExactly $script:expectedServiceAccount
        }
    }
}
