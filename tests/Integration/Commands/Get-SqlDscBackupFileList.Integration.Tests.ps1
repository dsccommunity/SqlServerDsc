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

Describe 'Get-SqlDscBackupFileList' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Get the SQL Server default backup directory
        $script:backupDirectory = $script:serverObject.Settings.BackupDirectory

        # Test database name
        $script:testDatabaseName = 'SqlDscGetFileListDb_' + (Get-Random)

        # Create a test database and backup for file list tests
        $script:testDatabase = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Full' -Force -ErrorAction 'Stop'

        # Create a backup file to read file list from
        $script:testBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_FileList.bak')
        $null = Backup-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -BackupFile $script:testBackupFile -Force -ErrorAction 'Stop'
    }

    AfterAll {
        # Clean up test database
        $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'SilentlyContinue'

        if ($existingDb)
        {
            $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'Stop'
        }

        # Clean up backup files
        if (Test-Path -Path $script:testBackupFile)
        {
            Remove-Item -Path $script:testBackupFile -Force -ErrorAction 'SilentlyContinue'
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When reading file list from a valid backup file' {
        It 'Should return file list with correct properties' {
            $result = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:testBackupFile

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterOrEqual 2 # At least data and log file

            # Verify first file has expected properties
            $result[0].LogicalName | Should -Not -BeNullOrEmpty
            $result[0].PhysicalName | Should -Not -BeNullOrEmpty
            $result[0].Type | Should -BeIn @('D', 'L')
        }

        It 'Should return BackupFileSpec objects' {
            $result = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:testBackupFile

            $result[0].GetType().Name | Should -Be 'BackupFileSpec'
        }

        It 'Should return data file with type D' {
            $result = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:testBackupFile

            $dataFile = $result | Where-Object -FilterScript { $_.Type -eq 'D' }
            $dataFile | Should -Not -BeNullOrEmpty
            $dataFile.PhysicalName | Should -Match '\.mdf$'
        }

        It 'Should return log file with type L' {
            $result = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:testBackupFile

            $logFile = $result | Where-Object -FilterScript { $_.Type -eq 'L' }
            $logFile | Should -Not -BeNullOrEmpty
            $logFile.PhysicalName | Should -Match '\.ldf$'
        }

        It 'Should work with pipeline input' {
            $result = $script:serverObject | Get-SqlDscBackupFileList -BackupFile $script:testBackupFile

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterOrEqual 2
        }

        It 'Should work with FileNumber parameter' {
            $result = Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:testBackupFile -FileNumber 1

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When reading file list from an invalid backup file' {
        BeforeAll {
            # Create an invalid backup file (just a text file)
            $script:invalidBackupFile = Join-Path -Path $script:backupDirectory -ChildPath 'InvalidBackupForFileList.bak'
            'This is not a valid backup file' | Out-File -FilePath $script:invalidBackupFile -Force
        }

        AfterAll {
            if (Test-Path -Path $script:invalidBackupFile)
            {
                Remove-Item -Path $script:invalidBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should throw an error for an invalid backup file' {
            { Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $script:invalidBackupFile } | Should -Throw -ErrorId 'GSBFL0002,Get-SqlDscBackupFileList'
        }
    }

    Context 'When reading file list from a non-existent backup file' {
        It 'Should throw an error for a non-existent backup file' {
            $nonExistentFile = Join-Path -Path $script:backupDirectory -ChildPath 'NonExistentBackupForFileList_12345.bak'

            { Get-SqlDscBackupFileList -ServerObject $script:serverObject -BackupFile $nonExistentFile } | Should -Throw -ErrorId 'GSBFL0002,Get-SqlDscBackupFileList'
        }
    }
}
