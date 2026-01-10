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

Describe 'Enable-SqlDscDatabaseSnapshotIsolation' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Test database names
        $script:testDatabaseName = 'SqlDscTestSnapshotIsolation_' + (Get-Random)
        $script:testDatabaseNameForObject = 'SqlDscTestSnapshotIsolationObj_' + (Get-Random)

        # Create test databases
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

        # Get the current snapshot isolation state to restore later
        $testDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
        $script:originalSnapshotIsolationState = $testDb.SnapshotIsolationState
        Write-Verbose -Message "Original snapshot isolation state of database '$($script:testDatabaseName)' is '$($script:originalSnapshotIsolationState)'." -Verbose
    }

    AfterAll {
        # Clean up test databases
        $testDatabasesToRemove = @($script:testDatabaseName, $script:testDatabaseNameForObject)

        foreach ($dbName in $testDatabasesToRemove)
        {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $dbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'Stop'
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -ErrorAction 'Stop'
    }

    Context 'When enabling snapshot isolation using ServerObject parameter set' {
        It 'Should enable snapshot isolation successfully' {
            # First ensure it's disabled
            $null = Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            $resultDb = Enable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -PassThru -ErrorAction 'Stop'
            $resultDb.SnapshotIsolationState | Should -Be 'Enabled'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.SnapshotIsolationState | Should -Be 'Enabled'
        }

        It 'Should be idempotent when snapshot isolation is already enabled' {
            # Enable snapshot isolation
            $null = Enable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Enable again - should not throw
            $null = Enable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            # Verify the value is still correct
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.SnapshotIsolationState | Should -Be 'Enabled'
        }

        It 'Should throw error when trying to enable snapshot isolation on non-existent database' {
            { Enable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When enabling snapshot isolation using DatabaseObject parameter set' {
        It 'Should enable snapshot isolation using database object' {
            # First ensure it's disabled
            $null = Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'

            $null = Enable-SqlDscDatabaseSnapshotIsolation -DatabaseObject $databaseObject -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $updatedDb.SnapshotIsolationState | Should -Be 'Enabled'
        }

        It 'Should support pipeline input with database object' {
            # First ensure it's disabled
            $null = Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'

            $null = $databaseObject | Enable-SqlDscDatabaseSnapshotIsolation -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $updatedDb.SnapshotIsolationState | Should -Be 'Enabled'
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection before enabling snapshot isolation' {
            # First ensure it's disabled
            $null = Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            $null = Enable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.SnapshotIsolationState | Should -Be 'Enabled'
        }
    }

    Context 'When using the PassThru parameter' {
        It 'Should return the database object when PassThru is specified' {
            # First ensure it's disabled
            $null = Disable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            $resultDb = Enable-SqlDscDatabaseSnapshotIsolation -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -PassThru -ErrorAction 'Stop'

            $resultDb | Should -Not -BeNullOrEmpty
            $resultDb.Name | Should -Be $script:testDatabaseName
            $resultDb.SnapshotIsolationState | Should -Be 'Enabled'
        }
    }
}
