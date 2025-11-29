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

Describe 'Set-SqlDscDatabaseDefaultFileGroup' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Test database names
        $script:testDatabaseName = 'SqlDscTestSetDefaultFG_' + (Get-Random)
        $script:testDatabaseNameForObject = 'SqlDscTestSetDefaultFGObj_' + (Get-Random)
        $script:testDatabaseNameForFileStream = 'SqlDscTestSetDefaultFSFG_' + (Get-Random)

        # Create test databases with filegroups
        $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'master' -Query @"
CREATE DATABASE [$($script:testDatabaseName)]
GO
USE [$($script:testDatabaseName)]
GO
-- Create a secondary filegroup
ALTER DATABASE [$($script:testDatabaseName)]
ADD FILEGROUP [UserDataFileGroup]
GO
-- Add a file to the filegroup
ALTER DATABASE [$($script:testDatabaseName)]
ADD FILE (
    NAME = N'UserData1',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.DSCSQLTEST\MSSQL\DATA\UserData1.ndf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
) TO FILEGROUP [UserDataFileGroup]
GO
-- Create another filegroup
ALTER DATABASE [$($script:testDatabaseName)]
ADD FILEGROUP [SecondaryFileGroup]
GO
-- Add a file to the second filegroup
ALTER DATABASE [$($script:testDatabaseName)]
ADD FILE (
    NAME = N'SecondaryData1',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.DSCSQLTEST\MSSQL\DATA\SecondaryData1.ndf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
) TO FILEGROUP [SecondaryFileGroup]
GO
"@ -ErrorAction 'Stop'

        # Create second test database
        $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'master' -Query @"
CREATE DATABASE [$($script:testDatabaseNameForObject)]
GO
USE [$($script:testDatabaseNameForObject)]
GO
-- Create a secondary filegroup
ALTER DATABASE [$($script:testDatabaseNameForObject)]
ADD FILEGROUP [ObjectTestFileGroup]
GO
-- Add a file to the filegroup
ALTER DATABASE [$($script:testDatabaseNameForObject)]
ADD FILE (
    NAME = N'ObjectTest1',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.DSCSQLTEST\MSSQL\DATA\ObjectTest1.ndf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
) TO FILEGROUP [ObjectTestFileGroup]
GO
"@ -ErrorAction 'Stop'

        # Create third test database for FILESTREAM testing (if FILESTREAM is enabled)
        try
        {
            $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -DatabaseName 'master' -Query @"
CREATE DATABASE [$($script:testDatabaseNameForFileStream)]
GO
USE [$($script:testDatabaseNameForFileStream)]
GO
-- Create a FILESTREAM filegroup
ALTER DATABASE [$($script:testDatabaseNameForFileStream)]
ADD FILEGROUP [FileStreamFileGroup] CONTAINS FILESTREAM
GO
-- Add a file to the FILESTREAM filegroup
ALTER DATABASE [$($script:testDatabaseNameForFileStream)]
ADD FILE (
    NAME = N'FileStreamData1',
    FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.DSCSQLTEST\MSSQL\DATA\FileStreamData1'
) TO FILEGROUP [FileStreamFileGroup]
GO
"@ -ErrorAction 'Stop'

            $script:fileStreamSupported = $true
        }
        catch
        {
            Write-Verbose -Message "FILESTREAM is not enabled on this instance. Skipping FILESTREAM tests." -Verbose
            $script:fileStreamSupported = $false
        }

        # Get the current default filegroup to restore later
        $testDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
        $script:originalDefaultFileGroup = $testDb.DefaultFileGroup
        Write-Verbose -Message "Original default filegroup of database '$($script:testDatabaseName)' is '$($script:originalDefaultFileGroup)'." -Verbose
    }

    AfterAll {
        # Clean up test databases
        $testDatabasesToRemove = @($script:testDatabaseName, $script:testDatabaseNameForObject)

        if ($script:fileStreamSupported)
        {
            $testDatabasesToRemove += $script:testDatabaseNameForFileStream
        }

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

    Context 'When setting default filegroup using ServerObject parameter set' {
        It 'Should set default filegroup to UserDataFileGroup successfully' {
            $resultDb = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup 'UserDataFileGroup' -Force -PassThru -ErrorAction 'Stop'
            $resultDb.DefaultFileGroup | Should -Be 'UserDataFileGroup'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileGroup | Should -Be 'UserDataFileGroup'
        }

        It 'Should set default filegroup to SecondaryFileGroup successfully' {
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup 'SecondaryFileGroup' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileGroup | Should -Be 'SecondaryFileGroup'
        }

        It 'Should be idempotent when default filegroup is already set' {
            $fileGroupName = 'UserDataFileGroup'

            # Set default filegroup
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup $fileGroupName -Force -ErrorAction 'Stop'

            # Set same default filegroup again - should not throw
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup $fileGroupName -Force -ErrorAction 'Stop'

            # Verify the value is still correct
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileGroup | Should -Be $fileGroupName
        }

        It 'Should throw error when trying to set default filegroup of non-existent database' {
            { Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name 'NonExistentDatabase' -DefaultFileGroup 'UserDataFileGroup' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should throw error when trying to set non-existent filegroup as default' {
            { Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup 'NonExistentFileGroup' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When setting default filegroup using DatabaseObject parameter set' {
        It 'Should set default filegroup using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'

            $null = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $databaseObject -DefaultFileGroup 'ObjectTestFileGroup' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileGroup | Should -Be 'ObjectTestFileGroup'
        }

        It 'Should support pipeline input with database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'

            $null = $databaseObject | Set-SqlDscDatabaseDefaultFileGroup -DefaultFileGroup 'PRIMARY' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileGroup | Should -Be 'PRIMARY'
        }

        It 'Should revert default filegroup back to PRIMARY' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'

            $null = Set-SqlDscDatabaseDefaultFileGroup -DatabaseObject $databaseObject -DefaultFileGroup 'PRIMARY' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileGroup | Should -Be 'PRIMARY'
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection before setting default filegroup' {
            $fileGroupName = 'UserDataFileGroup'
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup $fileGroupName -Refresh -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileGroup | Should -Be $fileGroupName
        }
    }

    Context 'When using the PassThru parameter' {
        It 'Should return the database object when PassThru is specified' {
            $fileGroupName = 'SecondaryFileGroup'
            $result = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup $fileGroupName -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be $script:testDatabaseName
            $result.DefaultFileGroup | Should -Be $fileGroupName
        }
    }

    Context 'When setting default FILESTREAM filegroup' -Skip:(-not $script:fileStreamSupported) {
        It 'Should set default FILESTREAM filegroup successfully' {
            $resultDb = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseNameForFileStream -DefaultFileStreamFileGroup 'FileStreamFileGroup' -Force -PassThru -ErrorAction 'Stop'
            $resultDb.DefaultFileStreamFileGroup | Should -Be 'FileStreamFileGroup'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForFileStream -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileStreamFileGroup | Should -Be 'FileStreamFileGroup'
        }

        It 'Should be idempotent when default FILESTREAM filegroup is already set' {
            $fileGroupName = 'FileStreamFileGroup'

            # Set default FILESTREAM filegroup
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseNameForFileStream -DefaultFileStreamFileGroup $fileGroupName -Force -ErrorAction 'Stop'

            # Set same default FILESTREAM filegroup again - should not throw
            $null = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseNameForFileStream -DefaultFileStreamFileGroup $fileGroupName -Force -ErrorAction 'Stop'

            # Verify the value is still correct
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForFileStream -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFileStreamFileGroup | Should -Be $fileGroupName
        }

        It 'Should return the database object when PassThru is specified for FILESTREAM filegroup' {
            $fileGroupName = 'FileStreamFileGroup'
            $result = Set-SqlDscDatabaseDefaultFileGroup -ServerObject $script:serverObject -Name $script:testDatabaseNameForFileStream -DefaultFileStreamFileGroup $fileGroupName -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be $script:testDatabaseNameForFileStream
            $result.DefaultFileStreamFileGroup | Should -Be $fileGroupName
        }
    }
}
