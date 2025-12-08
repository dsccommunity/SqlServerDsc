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

Describe 'Backup-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Get the SQL Server default backup directory
        $script:backupDirectory = $script:serverObject.Settings.BackupDirectory

        # Test database name
        $script:testDatabaseName = 'SqlDscBackupTestDatabase_' + (Get-Random)

        # Create a test database
        $script:testDatabase = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Full' -Force -ErrorAction 'Stop'
    }

    AfterAll {
        # Clean up test database
        $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'SilentlyContinue'

        if ($existingDb)
        {
            $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'Stop'
        }

        # Clean up backup files
        $backupFilesToRemove = Get-ChildItem -Path $script:backupDirectory -Filter 'SqlDscBackupTestDatabase_*.bak' -ErrorAction 'SilentlyContinue'
        $backupFilesToRemove += Get-ChildItem -Path $script:backupDirectory -Filter 'SqlDscBackupTestDatabase_*.trn' -ErrorAction 'SilentlyContinue'

        foreach ($file in $backupFilesToRemove)
        {
            Remove-Item -Path $file.FullName -Force -ErrorAction 'SilentlyContinue'
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When performing a full backup using ServerObject and Name' {
        BeforeAll {
            $script:fullBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_Full.bak')
        }

        AfterAll {
            if (Test-Path -Path $script:fullBackupFile)
            {
                Remove-Item -Path $script:fullBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should perform a full backup successfully' {
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:fullBackupFile -Force -ErrorAction 'Stop'

            # Verify the backup file was created
            Test-Path -Path $script:fullBackupFile | Should -BeTrue
        }
    }

    Context 'When performing a full backup using DatabaseObject' {
        BeforeAll {
            $script:fullBackupFileFromObject = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_FullFromObject.bak')

            # Refresh the database object
            $script:testDatabase = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
        }

        AfterAll {
            if (Test-Path -Path $script:fullBackupFileFromObject)
            {
                Remove-Item -Path $script:fullBackupFileFromObject -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should perform a full backup successfully using database object' {
            $null = $script:testDatabase | Backup-SqlDscDatabase -BackupFile $script:fullBackupFileFromObject -Force -ErrorAction 'Stop'

            # Verify the backup file was created
            Test-Path -Path $script:fullBackupFileFromObject | Should -BeTrue
        }
    }

    Context 'When performing a copy-only backup' {
        BeforeAll {
            $script:copyOnlyBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_CopyOnly.bak')
        }

        AfterAll {
            if (Test-Path -Path $script:copyOnlyBackupFile)
            {
                Remove-Item -Path $script:copyOnlyBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should perform a copy-only backup successfully' {
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:copyOnlyBackupFile -CopyOnly -Force -ErrorAction 'Stop'

            # Verify the backup file was created
            Test-Path -Path $script:copyOnlyBackupFile | Should -BeTrue
        }
    }

    Context 'When performing a differential backup' {
        BeforeAll {
            # First, create a full backup as a baseline
            $script:baseFullBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_BaseFull.bak')
            $script:diffBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_Diff.bak')

            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:baseFullBackupFile -Force
        }

        AfterAll {
            if (Test-Path -Path $script:baseFullBackupFile)
            {
                Remove-Item -Path $script:baseFullBackupFile -Force -ErrorAction 'SilentlyContinue'
            }

            if (Test-Path -Path $script:diffBackupFile)
            {
                Remove-Item -Path $script:diffBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should perform a differential backup successfully' {
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:diffBackupFile -BackupType 'Differential' -Force -ErrorAction 'Stop'

            # Verify the backup file was created
            Test-Path -Path $script:diffBackupFile | Should -BeTrue
        }
    }

    Context 'When performing a transaction log backup' {
        BeforeAll {
            # First, create a full backup as a baseline (required before log backup)
            $script:baseFullBackupForLog = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_BaseFullForLog.bak')
            $script:logBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_Log.trn')

            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:baseFullBackupForLog -Force
        }

        AfterAll {
            if (Test-Path -Path $script:baseFullBackupForLog)
            {
                Remove-Item -Path $script:baseFullBackupForLog -Force -ErrorAction 'SilentlyContinue'
            }

            if (Test-Path -Path $script:logBackupFile)
            {
                Remove-Item -Path $script:logBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should perform a transaction log backup successfully' {
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:logBackupFile -BackupType 'Log' -Force -ErrorAction 'Stop'

            # Verify the backup file was created
            Test-Path -Path $script:logBackupFile | Should -BeTrue
        }
    }

    Context 'When performing a compressed backup with checksum' {
        BeforeAll {
            $script:compressedBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_Compressed.bak')
        }

        AfterAll {
            if (Test-Path -Path $script:compressedBackupFile)
            {
                Remove-Item -Path $script:compressedBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should perform a compressed backup with checksum successfully' {
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:compressedBackupFile -Compress -Checksum -Force -ErrorAction 'Stop'

            # Verify the backup file was created
            Test-Path -Path $script:compressedBackupFile | Should -BeTrue
        }
    }

    Context 'When performing a backup with description and retention' {
        BeforeAll {
            $script:backupWithDescFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_WithDesc.bak')
        }

        AfterAll {
            if (Test-Path -Path $script:backupWithDescFile)
            {
                Remove-Item -Path $script:backupWithDescFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should perform a backup with description and retention days successfully' {
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:backupWithDescFile -Description 'Integration test backup' -RetainDays 7 -Force -ErrorAction 'Stop'

            # Verify the backup file was created
            Test-Path -Path $script:backupWithDescFile | Should -BeTrue
        }
    }

    Context 'When trying to backup a non-existent database' {
        It 'Should throw an error when database does not exist' {
            $nonExistentDbName = 'NonExistentDatabase_' + (Get-Random)
            $backupFile = Join-Path -Path $script:backupDirectory -ChildPath ($nonExistentDbName + '.bak')

            { Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $nonExistentDbName -BackupFile $backupFile -Force } | Should -Throw -ErrorId 'BSDD0001,Backup-SqlDscDatabase'
        }
    }

    Context 'When trying to perform a log backup on a Simple recovery model database' {
        BeforeAll {
            $script:simpleDbName = 'SqlDscSimpleRecoveryDb_' + (Get-Random)
            $script:simpleDb = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:simpleDbName -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'
        }

        AfterAll {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:simpleDbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'Stop'
            }
        }

        It 'Should throw an error when trying to perform a log backup on Simple recovery model database' {
            $logBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:simpleDbName + '.trn')

            { Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:simpleDbName -BackupFile $logBackupFile -BackupType 'Log' -Force } | Should -Throw -ErrorId 'BSDD0002,Backup-SqlDscDatabase'
        }
    }

    Context 'When performing a backup with Initialize to overwrite existing backup' {
        BeforeAll {
            $script:initializeBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_Initialize.bak')

            # Create initial backup
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:initializeBackupFile -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if (Test-Path -Path $script:initializeBackupFile)
            {
                Remove-Item -Path $script:initializeBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should overwrite existing backup file when Initialize is specified' {
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:initializeBackupFile -Initialize -Force -ErrorAction 'Stop'

            Test-Path -Path $script:initializeBackupFile | Should -BeTrue
        }
    }

    Context 'When performing a backup with Refresh parameter' {
        BeforeAll {
            $script:refreshBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_Refresh.bak')
        }

        AfterAll {
            if (Test-Path -Path $script:refreshBackupFile)
            {
                Remove-Item -Path $script:refreshBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should perform a backup successfully with Refresh parameter' {
            $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:refreshBackupFile -Refresh -Force -ErrorAction 'Stop'

            Test-Path -Path $script:refreshBackupFile | Should -BeTrue
        }
    }
}
