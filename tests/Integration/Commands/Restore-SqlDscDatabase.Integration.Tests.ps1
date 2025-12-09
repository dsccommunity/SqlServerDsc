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
        $script:mockComputerName = Get-ComputerName

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
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restoreDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database successfully with simple file relocation' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:restoreDbName -BackupFile $script:fullBackupFile -DataFilePath $script:dataDirectory -LogFilePath $script:logDirectory -Force -ErrorAction 'Stop'

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

            # Create the database first
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:replaceDbName -BackupFile $script:fullBackupFile -DataFilePath $script:dataDirectory -LogFilePath $script:logDirectory -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:replaceDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should replace existing database successfully' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:replaceDbName -BackupFile $script:fullBackupFile -DataFilePath $script:dataDirectory -LogFilePath $script:logDirectory -ReplaceDatabase -Force -ErrorAction 'Stop'

            # Verify the database still exists
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:replaceDbName -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When performing a restore with NoRecovery' {
        BeforeAll {
            $script:noRecoveryDbName = 'SqlDscRestoreNoRecovery_' + (Get-Random)
            $script:createdDatabases += $script:noRecoveryDbName
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:noRecoveryDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database in restoring state with NoRecovery' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:noRecoveryDbName -BackupFile $script:fullBackupFile -DataFilePath $script:dataDirectory -LogFilePath $script:logDirectory -NoRecovery -Force -ErrorAction 'Stop'

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

            # Get the file list from the backup
            $fileList = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:fullBackupFile

            # Create RelocateFile objects
            $script:relocateFiles = @()

            foreach ($file in $fileList)
            {
                $originalFileName = [System.IO.Path]::GetFileName($file.PhysicalName)
                $newFileName = $script:relocateDbName + '_' + $originalFileName

                if ($file.Type -eq 'L')
                {
                    $newPath = Join-Path -Path $script:logDirectory -ChildPath $newFileName
                }
                else
                {
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
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:relocateDbName -ErrorAction 'SilentlyContinue'
            $restoredDb | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When performing a restore with PassThru' {
        BeforeAll {
            $script:passThruDbName = 'SqlDscRestorePassThru_' + (Get-Random)
            $script:createdDatabases += $script:passThruDbName
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:passThruDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return database object when PassThru is specified' {
            $result = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:passThruDbName -BackupFile $script:fullBackupFile -DataFilePath $script:dataDirectory -LogFilePath $script:logDirectory -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:passThruDbName
        }
    }

    Context 'When performing a restore with Checksum option' {
        BeforeAll {
            $script:checksumDbName = 'SqlDscRestoreChecksum_' + (Get-Random)
            $script:createdDatabases += $script:checksumDbName
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:checksumDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore database with checksum verification' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:checksumDbName -BackupFile $script:fullBackupFile -DataFilePath $script:dataDirectory -LogFilePath $script:logDirectory -Checksum -Force -ErrorAction 'Stop'

            # Verify the database was restored
            $restoredDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:checksumDbName -ErrorAction 'SilentlyContinue'
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
            { Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:existingDbName -BackupFile $script:fullBackupFile -DataFilePath $script:dataDirectory -LogFilePath $script:logDirectory -Force } | Should -Throw -ErrorId 'RSDD0001,Restore-SqlDscDatabase'
        }
    }

    Context 'When using NoRecovery and Standby together' {
        It 'Should throw error when both NoRecovery and Standby are specified' {
            $standbyFile = Join-Path -Path $script:backupDirectory -ChildPath 'standby.ldf'

            { Restore-SqlDscDatabase -ServerObject $script:serverObject -Name 'TestDb' -BackupFile $script:fullBackupFile -NoRecovery -Standby $standbyFile -Force } | Should -Throw -ErrorId 'RSDD0006,Restore-SqlDscDatabase'
        }
    }

    Context 'When performing a restore sequence (Full + Differential + Log)' {
        BeforeAll {
            $script:sequenceDbName = 'SqlDscRestoreSequence_' + (Get-Random)
            $script:createdDatabases += $script:sequenceDbName
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sequenceDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should restore full backup with NoRecovery' {
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sequenceDbName -BackupFile $script:fullBackupFile -DataFilePath $script:dataDirectory -LogFilePath $script:logDirectory -NoRecovery -Force -ErrorAction 'Stop'

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
            $null = Restore-SqlDscDatabase -ServerObject $script:serverObject -Name $script:sequenceDbName -BackupFile $script:logBackupFile -RestoreType 'Log' -Force -ErrorAction 'Stop'

            $script:serverObject.Databases.Refresh()
            $restoredDb = $script:serverObject.Databases[$script:sequenceDbName]
            $restoredDb | Should -Not -BeNullOrEmpty
            $restoredDb.Status | Should -Be 'Normal'
        }
    }
}
