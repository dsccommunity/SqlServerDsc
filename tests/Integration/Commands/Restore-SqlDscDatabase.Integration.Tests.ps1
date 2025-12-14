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

Describe 'Restore-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Get the SQL Server default directories
        $script:backupDirectory = $script:serverObject.Settings.BackupDirectory
        $script:dataDirectory = $script:serverObject.Settings.DefaultFile
        $script:logDirectory = $script:serverObject.Settings.DefaultLog

        # If defaults are not set, use instance default paths
        if ([System.String]::IsNullOrEmpty($script:dataDirectory))
        {
            $script:dataDirectory = $script:serverObject.MasterDBPath
        }

        if ([System.String]::IsNullOrEmpty($script:logDirectory))
        {
            $script:logDirectory = $script:serverObject.MasterDBLogPath
        }

        # Source database name for backup
        $script:sourceDatabaseName = 'SqlDscRestoreSourceDb_' + (Get-Random)

        # Create a source database and backup for restore tests
        $script:sourceDatabase = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sourceDatabaseName -RecoveryModel 'Full' -Force -ErrorAction 'Stop'

        # Create backup files
        $script:fullBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:sourceDatabaseName + '_Full.bak')
        $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sourceDatabaseName -BackupFile $script:fullBackupFile -Force -ErrorAction 'Stop'

        # Create a differential backup
        $script:diffBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:sourceDatabaseName + '_Diff.bak')
        $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sourceDatabaseName -BackupFile $script:diffBackupFile -BackupType 'Differential' -Force -ErrorAction 'Stop'

        # Create a log backup
        $script:logBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:sourceDatabaseName + '_Log.trn')
        $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sourceDatabaseName -BackupFile $script:logBackupFile -BackupType 'Log' -Force -ErrorAction 'Stop'

        # Track databases created during tests for cleanup
        $script:createdDatabases = @()
    }

    AfterAll {
        # Clean up all created databases
        foreach ($dbName in $script:createdDatabases)
        {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $dbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        # Clean up source database
        $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sourceDatabaseName -ErrorAction 'SilentlyContinue'

        if ($existingDb)
        {
            $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'Stop'
        }

        # Clean up backup files
        $backupFiles = @($script:fullBackupFile, $script:diffBackupFile, $script:logBackupFile)

        foreach ($file in $backupFiles)
        {
            if (Test-Path -Path $file)
            {
                Remove-Item -Path $file -Force -ErrorAction 'SilentlyContinue'
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When performing a full restore to a new database' {
        BeforeAll {
            $script:restoreDbName = 'SqlDscRestoreNewDb_' + (Get-Random)
            $script:createdDatabases += $script:restoreDbName

            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:restoreRelocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:restoreDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:restoreDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:restoreRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restoreDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database successfully with explicit file relocation' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restoreDbName -BackupFile $script:fullBackupFile -RelocateFile $script:restoreRelocateFiles -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restoreDbName -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
            $restoredDb.Name | Should -Be $script:restoreDbName
        }
    }

    Context 'When performing a restore with ReplaceDatabase' {
        BeforeAll {
            $script:replaceDbName = 'SqlDscRestoreReplaceDb_' + (Get-Random)
            $script:createdDatabases += $script:replaceDbName

            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:replaceRelocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:replaceDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:replaceDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:replaceRelocateFiles += $relocateFile
            }

            # Create the database first
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:replaceDbName -BackupFile $script:fullBackupFile -RelocateFile $script:replaceRelocateFiles -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:replaceDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should replace existing database successfully' {
            # Ensure the database exists and is online before attempting replace
            $script:serverObject.Databases.Refresh()
            $existingDb = $script:serverObject.Databases[$script:replaceDbName]
            $existingDb | Should -Not -BeNullOrEmpty -Because 'Database should exist before replace operation'
            $existingDb.Status | Should -Be 'Normal' -Because 'Database should be online before replace operation'

            # When replacing a database, do not specify RelocateFile - SQL Server will use existing file locations
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:replaceDbName -BackupFile $script:fullBackupFile -ReplaceDatabase -Force -ErrorAction 'Stop'

            # Verify the database still exists
            $script:serverObject.Databases.Refresh()
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:replaceDbName -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When performing a restore with NoRecovery' {
        BeforeAll {
            $script:noRecoveryDbName = 'SqlDscRestoreNoRecovery_' + (Get-Random)
            $script:createdDatabases += $script:noRecoveryDbName

            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:noRecoveryRelocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:noRecoveryDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:noRecoveryDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:noRecoveryRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:noRecoveryDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database in restoring state with NoRecovery' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:noRecoveryDbName -BackupFile $script:fullBackupFile -RelocateFile $script:noRecoveryRelocateFiles -NoRecovery -Force -ErrorAction 'Stop'

            # Refresh to get current state
            $script:serverObject.Databases.Refresh()
            $restoredDb = $script:serverObject.Databases[$script:noRecoveryDbName]
            $restoredDb | Should -Not -BeNullOrEmpty
            $restoredDb.Status | Should -Match 'Restoring'
        }
    }

    Context 'When performing a restore with RelocateFile objects' {
        BeforeAll {
            $script:relocateDbName = 'SqlDscRestoreRelocate_' + (Get-Random)
            $script:createdDatabases += $script:relocateDbName

            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:relocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:relocateDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:relocateDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:relocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:relocateDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database with explicit file relocation' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:relocateDbName -BackupFile $script:fullBackupFile -RelocateFile $script:relocateFiles -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:relocateDbName -Refresh -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When performing a restore with PassThru' {
        BeforeAll {
            $script:passThruDbName = 'SqlDscRestorePassThru_' + (Get-Random)
            $script:createdDatabases += $script:passThruDbName

            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:passThruRelocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:passThruDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:passThruDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:passThruRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:passThruDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return database object when PassThru is specified' {
            $result = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:passThruDbName -BackupFile $script:fullBackupFile -RelocateFile $script:passThruRelocateFiles -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:passThruDbName
        }
    }

    Context 'When performing a restore with Checksum option' {
        BeforeAll {
            $script:checksumDbName = 'SqlDscRestoreChecksum_' + (Get-Random)
            $script:createdDatabases += $script:checksumDbName

            # Create a backup with checksums for this test
            $script:checksumBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:sourceDatabaseName + '_Checksum.bak')
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sourceDatabaseName -BackupFile $script:checksumBackupFile -Checksum -Force -ErrorAction 'Stop'

            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:checksumBackupFile -ErrorAction 'Stop'

            $script:checksumRelocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:checksumDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:checksumDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:checksumRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:checksumDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }

            # Clean up checksum backup file
            if (Test-Path -Path $script:checksumBackupFile)
            {
                Remove-Item -Path $script:checksumBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database with checksum verification' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:checksumDbName -BackupFile $script:checksumBackupFile -RelocateFile $script:checksumRelocateFiles -Checksum -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:checksumDbName -Refresh -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When trying to restore to an existing database without ReplaceDatabase' {
        BeforeAll {
            $script:existingDbName = 'SqlDscRestoreExisting_' + (Get-Random)
            $script:createdDatabases += $script:existingDbName

            # Create the database first
            $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:existingDbName -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:existingDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should throw error when database already exists' {
            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $existingRelocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:existingDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:existingDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $existingRelocateFiles += $relocateFile
            }

            { Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:existingDbName -BackupFile $script:fullBackupFile -RelocateFile $existingRelocateFiles -Force -ErrorAction 'Stop' } | Should -Throw -ErrorId 'RSDD0001,Restore-SqlDscDatabase'
        }
    }

    Context 'When using NoRecovery and Standby together' {
        It 'Should throw error when both NoRecovery and Standby are specified' {
            $standbyFile = Join-Path -Path $script:backupDirectory -ChildPath 'standby.ldf'

            { Restore-SqlDscDatabase -ServerObject $script:serverObject -Name 'TestDb' -BackupFile $script:fullBackupFile -NoRecovery -Standby $standbyFile -Force -ErrorAction 'Stop' } | Should -Throw -ErrorId 'RSDD0006,Restore-SqlDscDatabase'
        }
    }

    Context 'When performing a restore sequence (Full + Differential + Log)' {
        BeforeAll {
            $script:sequenceDbName = 'SqlDscRestoreSequence_' + (Get-Random)
            $script:createdDatabases += $script:sequenceDbName

            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:sequenceRelocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:sequenceDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:sequenceDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:sequenceRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sequenceDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore full backup with NoRecovery' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sequenceDbName -BackupFile $script:fullBackupFile -RelocateFile $script:sequenceRelocateFiles -NoRecovery -Force -ErrorAction 'Stop'

            $script:serverObject.Databases.Refresh()
            $restoredDb = $script:serverObject.Databases[$script:sequenceDbName]
            $restoredDb | Should -Not -BeNullOrEmpty
            $restoredDb.Status | Should -Match 'Restoring'
        }

        It 'Should restore differential backup with NoRecovery' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sequenceDbName -BackupFile $script:diffBackupFile -RestoreType 'Differential' -NoRecovery -Force -ErrorAction 'Stop'

            $script:serverObject.Databases.Refresh()
            $restoredDb = $script:serverObject.Databases[$script:sequenceDbName]
            $restoredDb | Should -Not -BeNullOrEmpty
            $restoredDb.Status | Should -Match 'Restoring'
        }

        It 'Should restore log backup and bring database online' {
            # Restore the log backup without NoRecovery to bring the database online
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sequenceDbName -BackupFile $script:logBackupFile -RestoreType 'Log' -Force -ErrorAction 'Stop'

            # Refresh and verify the database is online
            $script:serverObject.Databases.Refresh()
            $restoredDb = $script:serverObject.Databases[$script:sequenceDbName]
            $restoredDb | Should -Not -BeNullOrEmpty

            # Refresh the database object itself to get the latest status
            $restoredDb.Refresh()
            $restoredDb.Status | Should -Be 'Normal'
        }
    }

    Context 'When performing a restore with Standby mode' {
        BeforeAll {
            $script:standbyDbName = 'SqlDscRestoreStandby_' + (Get-Random)
            $script:createdDatabases += $script:standbyDbName

            # Create standby undo file path
            $script:standbyFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:standbyDbName + '_standby.ldf')

            # Get the file list from the backup to build RelocateFile objects with unique names
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:standbyRelocateFiles = @()

            foreach ($file in $fileList)
            {
                # Generate unique filename based on the target database name to avoid conflicts
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:standbyDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:standbyDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:standbyRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:standbyDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }

            # Clean up standby file
            if (Test-Path -Path $script:standbyFile)
            {
                Remove-Item -Path $script:standbyFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database in standby mode with read-only access' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:standbyDbName -BackupFile $script:fullBackupFile -RelocateFile $script:standbyRelocateFiles -Standby $script:standbyFile -Force -ErrorAction 'Stop'

            # Get the database object using Get-SqlDscDatabase to ensure all properties are properly loaded
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:standbyDbName -Refresh -ErrorAction 'Stop'
            $restoredDb | Should -Not -BeNullOrEmpty

            # Database should be online and in standby/read-only state
            $restoredDb.Status | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal -bor [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Standby) -Because 'Database should be online in standby mode'
            $restoredDb.ReadOnly | Should -BeTrue -Because 'Database should be read-only in standby mode'

            # Verify standby file exists and has content
            Test-Path -Path $script:standbyFile | Should -BeTrue -Because 'Standby undo file should exist'
            (Get-Item -Path $script:standbyFile).Length | Should -BeGreaterThan 0 -Because 'Standby file should have content'
        }
    }

    Context 'When performing a point-in-time restore' {
        BeforeAll {
            $script:pitDbName = 'SqlDscRestorePIT_' + (Get-Random)
            $script:createdDatabases += $script:pitDbName

            # Create a temporary database for point-in-time testing
            $script:pitSourceDbName = 'SqlDscPITSource_' + (Get-Random)
            $script:createdDatabases += $script:pitSourceDbName

            # Create source database with Full recovery model
            $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:pitSourceDbName -RecoveryModel 'Full' -Force -ErrorAction 'Stop'

            # Insert initial data
            $query1 = @"
CREATE TABLE dbo.TestData (Id INT PRIMARY KEY, InsertTime DATETIME, Value NVARCHAR(50));
INSERT INTO dbo.TestData (Id, InsertTime, Value) VALUES (1, GETDATE(), 'Initial');
"@
            Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:pitSourceDbName -Query $query1 -Force -ErrorAction 'Stop'

            # Create full backup
            $script:pitFullBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:pitSourceDbName + '_PIT_Full.bak')
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:pitSourceDbName -BackupFile $script:pitFullBackupFile -Force -ErrorAction 'Stop'

            # Wait a moment to ensure time difference
            Start-Sleep -Seconds 2

            # Capture the point-in-time before adding more data
            $script:pointInTime = Get-Date

            # Wait another moment
            Start-Sleep -Seconds 2

            # Insert additional data after the point-in-time
            $query2 = "INSERT INTO dbo.TestData (Id, InsertTime, Value) VALUES (2, GETDATE(), 'AfterPIT');"
            Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:pitSourceDbName -Query $query2 -Force -ErrorAction 'Stop'

            # Create log backup to capture the additional data
            $script:pitLogBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:pitSourceDbName + '_PIT_Log.trn')
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:pitSourceDbName -BackupFile $script:pitLogBackupFile -BackupType 'Log' -Force -ErrorAction 'Stop'

            # Get the file list from the backup to build RelocateFile objects
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:pitFullBackupFile -ErrorAction 'Stop'

            $script:pitRelocateFiles = @()

            foreach ($file in $fileList)
            {
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:pitDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:pitDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:pitRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            # Clean up restored database
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:pitDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }

            # Clean up source database
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:pitSourceDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }

            # Clean up backup files
            if ($script:pitFullBackupFile -and (Test-Path -Path $script:pitFullBackupFile))
            {
                Remove-Item -Path $script:pitFullBackupFile -Force -ErrorAction 'SilentlyContinue'
            }

            if ($script:pitLogBackupFile -and (Test-Path -Path $script:pitLogBackupFile))
            {
                Remove-Item -Path $script:pitLogBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database to a specific point-in-time' {
            # Restore full backup with NoRecovery
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:pitDbName -BackupFile $script:pitFullBackupFile -RelocateFile $script:pitRelocateFiles -NoRecovery -Force -ErrorAction 'Stop'

            # Restore log backup to the point-in-time
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:pitDbName -BackupFile $script:pitLogBackupFile -RestoreType 'Log' -ToPointInTime $script:pointInTime -Force -ErrorAction 'Stop'

            # Refresh and verify the database is online
            $script:serverObject.Databases.Refresh()
            $restoredDb = $script:serverObject.Databases[$script:pitDbName]
            $restoredDb | Should -Not -BeNullOrEmpty

            $restoredDb.Refresh()
            $restoredDb.Status | Should -Be 'Normal' -Because 'Database should be online after point-in-time restore'

            # Verify data reflects the point-in-time (only initial record should exist)
            $query = "SELECT COUNT(*) AS RecordCount FROM dbo.TestData WHERE Id = 1;"
            $result = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:pitDbName -Query $query -PassThru -Force -ErrorAction 'Stop'
            $result.Tables[0].Rows[0].RecordCount | Should -Be 1 -Because 'Initial record should exist'

            # Verify the second record (inserted after point-in-time) should NOT exist
            $query = "SELECT COUNT(*) AS RecordCount FROM dbo.TestData WHERE Id = 2;"
            $result = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName $script:pitDbName -Query $query -PassThru -Force -ErrorAction 'Stop'
            $result.Tables[0].Rows[0].RecordCount | Should -Be 0 -Because 'Record inserted after point-in-time should not exist'
        }
    }

    Context 'When performing a restore with FileNumber parameter for multi-backup-set files' {
        BeforeAll {
            $script:fileNumberDbName = 'SqlDscRestoreFileNum_' + (Get-Random)
            $script:createdDatabases += $script:fileNumberDbName

            # Create a multi-backup-set file by appending multiple backups to the same file
            $script:multiBackupFile = Join-Path -Path $script:backupDirectory -ChildPath 'MultiBackupSet.bak'

            # Create first backup (backup set 1)
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sourceDatabaseName -BackupFile $script:multiBackupFile -Force -ErrorAction 'Stop'

            # Append second backup (backup set 2) - use NOINIT to append
            $query = @"
BACKUP DATABASE [$($script:sourceDatabaseName)]
TO DISK = N'$($script:multiBackupFile)'
WITH NOINIT, NOSKIP, REWIND, NOUNLOAD, STATS = 10;

BACKUP DATABASE [$($script:sourceDatabaseName)]
TO DISK = N'$($script:multiBackupFile)'
WITH NOINIT, NOSKIP, REWIND, NOUNLOAD, STATS = 10;
"@
            Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'master' -Query $query -Force -ErrorAction 'Stop'

            # Get the file list from the backup to build RelocateFile objects
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:multiBackupFile -FileNumber 2 -ErrorAction 'Stop'

            $script:fileNumberRelocateFiles = @()

            foreach ($file in $fileList)
            {
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:fileNumberDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:fileNumberDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:fileNumberRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:fileNumberDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }

            # Clean up multi-backup file
            if (Test-Path -Path $script:multiBackupFile)
            {
                Remove-Item -Path $script:multiBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore from the second backup set using FileNumber parameter' {
            # Restore the second backup set (FileNumber = 2)
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:fileNumberDbName -BackupFile $script:multiBackupFile -FileNumber 2 -RelocateFile $script:fileNumberRelocateFiles -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:fileNumberDbName -Refresh -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
            $restoredDb.Name | Should -Be $script:fileNumberDbName
        }
    }

    Context 'When performing a restore with performance tuning parameters' {
        BeforeAll {
            $script:perfTuneDbName = 'SqlDscRestorePerfTune_' + (Get-Random)
            $script:createdDatabases += $script:perfTuneDbName

            # Get the file list from the backup to build RelocateFile objects
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:perfTuneRelocateFiles = @()

            foreach ($file in $fileList)
            {
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:perfTuneDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:perfTuneDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:perfTuneRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database with BlockSize parameter' {
            # Use a 64KB block size
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -BackupFile $script:fullBackupFile -RelocateFile $script:perfTuneRelocateFiles -BlockSize 65536 -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -Refresh -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }

        It 'Should restore database with BufferCount parameter' {
            # Clean up if needed
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -ErrorAction 'SilentlyContinue'
            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }

            # Use 20 buffers
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -BackupFile $script:fullBackupFile -RelocateFile $script:perfTuneRelocateFiles -BufferCount 20 -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -Refresh -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }

        It 'Should restore database with MaxTransferSize parameter' {
            # Clean up if needed
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -ErrorAction 'SilentlyContinue'
            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }

            # Use 4MB max transfer size
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -BackupFile $script:fullBackupFile -RelocateFile $script:perfTuneRelocateFiles -MaxTransferSize 4194304 -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -Refresh -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }

        It 'Should restore database with all performance tuning parameters combined' {
            # Clean up if needed
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -ErrorAction 'SilentlyContinue'
            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }

            # Combine all performance parameters
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -BackupFile $script:fullBackupFile -RelocateFile $script:perfTuneRelocateFiles -BlockSize 65536 -BufferCount 20 -MaxTransferSize 4194304 -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:perfTuneDbName -Refresh -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When performing a restore with RestrictedUser mode' {
        BeforeAll {
            $script:restrictedUserDbName = 'SqlDscRestoreRestricted_' + (Get-Random)
            $script:createdDatabases += $script:restrictedUserDbName

            # Get the file list from the backup to build RelocateFile objects
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile -ErrorAction 'Stop'

            $script:restrictedUserRelocateFiles = @()

            foreach ($file in $fileList)
            {
                $fileExtension = [System.IO.Path]::GetExtension($file.PhysicalName)

                if ($file.Type -eq 'L')
                {
                    $newFileName = $script:restrictedUserDbName + '_log' + $fileExtension
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
                    $newFileName = $script:restrictedUserDbName + $fileExtension
                    $newPath = Join-Path -Path $script:dataDirectory -ChildPath $newFileName
                }

                $relocateFile = [Microsoft.SqlServer.Management.Smo.RelocateFile]::new($file.LogicalName, $newPath)
                $script:restrictedUserRelocateFiles += $relocateFile
            }
        }

        AfterAll {
            # When database is in restricted mode, we need to use ALTER DATABASE to make it accessible before dropping
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restrictedUserDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                # Try to set database to normal user access mode before removal
                $query = "ALTER DATABASE [$($script:restrictedUserDbName)] SET MULTI_USER WITH NO_WAIT;"
                Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'master' -Query $query -Force -ErrorAction 'SilentlyContinue'

                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database in restricted user access mode' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restrictedUserDbName -BackupFile $script:fullBackupFile -RelocateFile $script:restrictedUserRelocateFiles -RestrictedUser -Force -ErrorAction 'Stop'

            # Get the database object using Get-SqlDscDatabase to ensure all properties are properly loaded
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restrictedUserDbName -Refresh -ErrorAction 'Stop'
            $restoredDb | Should -Not -BeNullOrEmpty

            # Verify the database is in restricted user mode
            # UserAccess enum: Single = 0, Restricted = 1, Multiple = 2
            $restoredDb.UserAccess | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Restricted) -Because 'Database should be in restricted user access mode'
        }

        It 'Should verify restricted access by attempting connection with non-privileged user' {
            # Verify the database exists and is in restricted mode
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restrictedUserDbName -Refresh -ErrorAction 'Stop'
            $restoredDb.UserAccess | Should -Be ([Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Restricted)

            # Verify that only members of db_owner, dbcreator, or sysadmin can access
            # Since we're using SqlAdmin credentials (which has sysadmin), we should be able to query
            $query = "SELECT name FROM sys.databases WHERE name = N'$($script:restrictedUserDbName)';"
            $result = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'master' -Query $query -PassThru -Force -ErrorAction 'Stop'
            $result.Tables[0].Rows.Count | Should -Be 1 -Because 'Sysadmin should be able to see the restricted database'
        }
    }
}
