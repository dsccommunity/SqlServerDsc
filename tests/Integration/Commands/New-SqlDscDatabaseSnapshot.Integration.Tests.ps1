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

Describe 'New-SqlDscDatabaseSnapshot' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Source database names - using the persistent database created by New-SqlDscDatabase integration tests
        $script:persistentSourceDatabase = 'SqlDscIntegrationTestDatabase_Persistent'

        # Snapshot names
        $script:testSnapshotName = 'SqlDscTestSnapshot_' + (Get-Random)
        $script:testSnapshotNameWithFileGroup = 'SqlDscTestSnapshotFG_' + (Get-Random)
        $script:testSnapshotNameFromDbObject = 'SqlDscTestSnapshotDbObj_' + (Get-Random)

        # Verify the persistent database exists before proceeding
        $sourceDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:persistentSourceDatabase -ErrorAction 'SilentlyContinue'

        if (-not $sourceDb)
        {
            throw "The source database '$script:persistentSourceDatabase' does not exist. Please ensure New-SqlDscDatabase integration tests have run successfully."
        }
    }

    AfterAll {
        # Clean up test snapshots
        $testSnapshotsToRemove = @(
            $script:testSnapshotName,
            $script:testSnapshotNameWithFileGroup,
            $script:testSnapshotNameFromDbObject
        )

        foreach ($snapshotName in $testSnapshotsToRemove)
        {
            $existingSnapshot = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $snapshotName -ErrorAction 'SilentlyContinue'

            if ($existingSnapshot)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingSnapshot -Force -ErrorAction 'Stop'
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When creating a database snapshot using ServerObject parameter set' {
        It 'Should create a database snapshot successfully with minimal parameters' {
            $result = New-SqlDscDatabaseSnapshot -ServerObject $script:serverObject -Name $script:testSnapshotName -DatabaseName $script:persistentSourceDatabase -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testSnapshotName
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.DatabaseSnapshotBaseName | Should -Be $script:persistentSourceDatabase

            # Verify the snapshot exists
            $createdSnapshot = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testSnapshotName -Refresh -ErrorAction 'Stop'
            $createdSnapshot | Should -Not -BeNullOrEmpty
            $createdSnapshot.DatabaseSnapshotBaseName | Should -Be $script:persistentSourceDatabase
        }

        It 'Should throw error when trying to create a snapshot that already exists' {
            { New-SqlDscDatabaseSnapshot -ServerObject $script:serverObject -Name $script:testSnapshotName -DatabaseName $script:persistentSourceDatabase -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When creating a database snapshot using DatabaseObject parameter set' {
        BeforeAll {
            # Get the source database object
            $script:sourceDatabaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:persistentSourceDatabase -ErrorAction 'Stop'
        }

        It 'Should create a database snapshot from DatabaseObject successfully' {
            $result = New-SqlDscDatabaseSnapshot -DatabaseObject $script:sourceDatabaseObject -Name $script:testSnapshotNameFromDbObject -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testSnapshotNameFromDbObject
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.DatabaseSnapshotBaseName | Should -Be $script:persistentSourceDatabase

            # Verify the snapshot exists
            $createdSnapshot = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testSnapshotNameFromDbObject -Refresh -ErrorAction 'Stop'
            $createdSnapshot | Should -Not -BeNullOrEmpty
            $createdSnapshot.DatabaseSnapshotBaseName | Should -Be $script:persistentSourceDatabase
        }
    }

    Context 'When creating a database snapshot with custom file groups' {
        BeforeAll {
            # Get the default data directory from the server
            $script:dataDirectory = $script:serverObject.Settings.DefaultFile

            if (-not $script:dataDirectory)
            {
                $script:dataDirectory = $script:serverObject.Information.MasterDBPath
            }

            # Ensure the directory exists
            if (-not (Test-Path -Path $script:dataDirectory))
            {
                $null = New-Item -Path $script:dataDirectory -ItemType Directory -Force
            }

            # Get the source database for file group creation
            $script:sourceDatabaseForFG = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:persistentSourceDatabase -ErrorAction 'Stop'
        }

        It 'Should create a database snapshot with custom sparse file location' {
            # Get the logical name of the source database's primary file
            $sourceDatabase = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:persistentSourceDatabase -ErrorAction 'Stop'
            $sourceLogicalFileName = $sourceDatabase.FileGroups['PRIMARY'].Files[0].Name

            # Create PRIMARY filegroup with sparse file using -AsSpec
            # IMPORTANT: Must use the same logical name as the source database file
            $sparseFilePath = Join-Path -Path $script:dataDirectory -ChildPath ($script:testSnapshotNameWithFileGroup + '_Sparse.ss')
            $dataFileSpec = New-SqlDscDataFile -Name $sourceLogicalFileName -FileName $sparseFilePath -AsSpec
            $primaryFileGroupSpec = New-SqlDscFileGroup -Name 'PRIMARY' -Files @($dataFileSpec) -AsSpec

            # Create snapshot with custom file group
            $result = New-SqlDscDatabaseSnapshot -ServerObject $script:serverObject -Name $script:testSnapshotNameWithFileGroup -DatabaseName $script:persistentSourceDatabase -FileGroup @($primaryFileGroupSpec) -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testSnapshotNameWithFileGroup
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.DatabaseSnapshotBaseName | Should -Be $script:persistentSourceDatabase

            # Verify the snapshot exists with correct file configuration
            $createdSnapshot = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testSnapshotNameWithFileGroup -Refresh -ErrorAction 'Stop'
            $createdSnapshot | Should -Not -BeNullOrEmpty
            $createdSnapshot.DatabaseSnapshotBaseName | Should -Be $script:persistentSourceDatabase

            # Verify the sparse file was created with the correct path
            $createdSnapshot.FileGroups['PRIMARY'] | Should -Not -BeNullOrEmpty
            $createdSnapshot.FileGroups['PRIMARY'].Files.Count | Should -BeGreaterThan 0
            $createdSnapshot.FileGroups['PRIMARY'].Files[0].FileName | Should -Be $sparseFilePath
        }
    }

    Context 'When using the Refresh parameter' {
        BeforeAll {
            $script:refreshTestSnapshotName = 'SqlDscTestSnapshotRefresh_' + (Get-Random)
        }

        AfterAll {
            # Clean up the refresh test snapshot
            $snapshotToRemove = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:refreshTestSnapshotName -ErrorAction 'SilentlyContinue'
            if ($snapshotToRemove)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $snapshotToRemove -Force -ErrorAction 'Stop'
            }
        }

        It 'Should refresh the database collection before creating snapshot' {
            $result = New-SqlDscDatabaseSnapshot -ServerObject $script:serverObject -Name $script:refreshTestSnapshotName -DatabaseName $script:persistentSourceDatabase -Refresh -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:refreshTestSnapshotName
            $result.DatabaseSnapshotBaseName | Should -Be $script:persistentSourceDatabase
        }
    }
}
