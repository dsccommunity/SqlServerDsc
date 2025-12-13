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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Test-SqlDscIsInstalledInstance' {
    Context 'When testing for any SQL Server instance' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI') {
        It 'Should not throw an exception' {
            { Test-SqlDscIsInstalledInstance -ErrorAction 'Stop' } | Should -Not -Throw
        }

        It 'Should return a boolean value' {
            $result = Test-SqlDscIsInstalledInstance

            $result | Should -BeOfType ([System.Boolean])
        }

        It 'Should return $true when at least one instance exists' {
            $result = Test-SqlDscIsInstalledInstance

            $result | Should -BeTrue
        }
    }

    Context 'When testing for a specific SQL Server instance by name' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI') {
        # cSpell: ignore PBIRS DSCSQLTEST
        It 'Should return $true when the specified instance exists (PBIRS)' -Tag @('Integration_PowerBI') {
            $result = Test-SqlDscIsInstalledInstance -InstanceName 'PBIRS'

            $result | Should -BeTrue
        }

        It 'Should return $true when the specified instance exists (DSCSQLTEST)' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
            $result = Test-SqlDscIsInstalledInstance -InstanceName 'DSCSQLTEST'

            $result | Should -BeTrue
        }

        It 'Should return $false when the instance does not exist' {
            $result = Test-SqlDscIsInstalledInstance -InstanceName 'NonExistentInstance'

            $result | Should -BeFalse
        }
    }

    Context 'When filtering by service type' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI') {
        It 'Should return $true when ReportingServices instances exist' -Tag @('Integration_PowerBI') {
            $result = Test-SqlDscIsInstalledInstance -ServiceType 'ReportingServices'

            $result | Should -BeTrue
        }

        It 'Should return $true when DatabaseEngine instances exist' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
            $result = Test-SqlDscIsInstalledInstance -ServiceType 'DatabaseEngine'

            $result | Should -BeTrue
        }

        It 'Should return a boolean when filtering by multiple service types' {
            $result = Test-SqlDscIsInstalledInstance -ServiceType @('DatabaseEngine', 'AnalysisServices')

            $result | Should -BeOfType ([System.Boolean])
        }
    }

    Context 'When using both instance name and service type parameters' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI') {
        It 'Should return $true when instance name and service type match (PBIRS)' -Tag @('Integration_PowerBI') {
            $result = Test-SqlDscIsInstalledInstance -InstanceName 'PBIRS' -ServiceType 'ReportingServices'

            $result | Should -BeTrue
        }

        It 'Should return $true when instance name and service type match (DSCSQLTEST)' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
            $result = Test-SqlDscIsInstalledInstance -InstanceName 'DSCSQLTEST' -ServiceType 'DatabaseEngine'

            $result | Should -BeTrue
        }

        It 'Should return $false when instance name exists but service type does not match (PBIRS)' -Tag @('Integration_PowerBI') {
            $result = Test-SqlDscIsInstalledInstance -InstanceName 'PBIRS' -ServiceType 'DatabaseEngine'

            $result | Should -BeFalse
        }
    }
}
