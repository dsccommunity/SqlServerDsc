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

Describe 'Test-SqlDscBackupFile' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
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
        $script:testDatabaseName = 'SqlDscTestBackupFileDb_' + (Get-Random)

        # Create a test database and backup for verification tests
        $script:testDatabase = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Full' -Force -ErrorAction 'Stop'

        # Create a backup file to test against
        $script:testBackupFile = Join-Path -Path $script:backupDirectory -ChildPath ($script:testDatabaseName + '_TestVerify.bak')
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

    Context 'When verifying a valid backup file' {
        It 'Should return true for a valid backup file' {
            $result = Test-SqlDscBackupFile -ServerObject $script:serverObject -BackupFile $script:testBackupFile

            $result | Should -BeTrue
        }

        It 'Should return true when using pipeline' {
            $result = $script:serverObject | Test-SqlDscBackupFile -BackupFile $script:testBackupFile

            $result | Should -BeTrue
        }

        It 'Should return true when specifying FileNumber' {
            $result = Test-SqlDscBackupFile -ServerObject $script:serverObject -BackupFile $script:testBackupFile -FileNumber 1

            $result | Should -BeTrue
        }
    }

    Context 'When verifying an invalid backup file' {
        BeforeAll {
            # Create an invalid backup file (just a text file)
            $script:invalidBackupFile = Join-Path -Path $script:backupDirectory -ChildPath 'InvalidBackup.bak'
            'This is not a valid backup file' | Out-File -FilePath $script:invalidBackupFile -Force
        }

        AfterAll {
            if (Test-Path -Path $script:invalidBackupFile)
            {
                Remove-Item -Path $script:invalidBackupFile -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should throw an error for an invalid backup file' {
            { Test-SqlDscBackupFile -ServerObject $script:serverObject -BackupFile $script:invalidBackupFile } | Should -Throw -ErrorId 'TSBF0004,Test-SqlDscBackupFile'
        }
    }

    Context 'When verifying a non-existent backup file' {
        It 'Should throw an error for a non-existent backup file' {
            $nonExistentFile = Join-Path -Path $script:backupDirectory -ChildPath 'NonExistentBackup_12345.bak'

            { Test-SqlDscBackupFile -ServerObject $script:serverObject -BackupFile $nonExistentFile } | Should -Throw -ErrorId 'TSBF0004,Test-SqlDscBackupFile'
        }
    }

    Context 'When SqlVerify throws an exception' {
        It 'Should throw a localized error for an invalid path' {
            # Use an invalid path that will cause SQL Server to throw an exception
            $invalidPath = 'Z:\NonExistentDrive\InvalidPath\Backup.bak'

            { Test-SqlDscBackupFile -ServerObject $script:serverObject -BackupFile $invalidPath } | Should -Throw
        }
    }
}
