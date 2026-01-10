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

Describe 'Set-SqlDscDatabaseDefault' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Test database names
        $script:testDatabaseName = 'SqlDscTestSetDatabaseDefault_' + (Get-Random)

        # Create test database for the integration tests
        $script:testDatabaseObject = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force

        # Create additional filegroup for testing (needed for setting default filegroup)
        $script:testFileGroupName = 'TestFileGroup_' + (Get-Random)
        $script:serverObject.Databases[$script:testDatabaseName].Query("ALTER DATABASE [$script:testDatabaseName] ADD FILEGROUP [$script:testFileGroupName]")

        # Add a file to the filegroup so it can be set as default
        $script:testFileName = 'TestFile_' + (Get-Random)
        # Resolve instance default data path in a version-agnostic way
        $dataRoot = $script:serverObject.Settings.DefaultFile
        if (-not $dataRoot) { $dataRoot = $script:serverObject.Information.MasterDBPath }
        $script:testFilePath = Join-Path -Path $dataRoot -ChildPath "$script:testFileName.ndf"
        $script:serverObject.Databases[$script:testDatabaseName].Query("ALTER DATABASE [$script:testDatabaseName] ADD FILE (NAME = '$script:testFileName', FILENAME = '$script:testFilePath') TO FILEGROUP [$script:testFileGroupName]")
    }

    AfterAll {
        # Disconnect from the database engine.
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When using the DatabaseObject parameter' {
        It 'Should set the default filegroup without throwing an error' {
            $null = Set-SqlDscDatabaseDefault -DatabaseObject $script:testDatabaseObject -DefaultFileGroup $script:testFileGroupName -Force

            # Verify the change was applied
            $script:testDatabaseObject.Refresh()
            $script:testDatabaseObject.DefaultFileGroup | Should -Be $script:testFileGroupName
        }

        It 'Should reset the default filegroup back to PRIMARY' {
            $null = Set-SqlDscDatabaseDefault -DatabaseObject $script:testDatabaseObject -DefaultFileGroup 'PRIMARY' -Force

            # Verify the change was applied
            $script:testDatabaseObject.Refresh()
            $script:testDatabaseObject.DefaultFileGroup | Should -Be 'PRIMARY'
        }
    }

    Context 'When using the ServerObject parameter' {
        It 'Should set the default filegroup using server object and database name' {
            $null = Set-SqlDscDatabaseDefault -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup $script:testFileGroupName -Force

            # Verify the change was applied by refreshing the database object
            $script:testDatabaseObject.Refresh()
            $script:testDatabaseObject.DefaultFileGroup | Should -Be $script:testFileGroupName
        }

        It 'Should return the database object when PassThru is specified' {
            $result = Set-SqlDscDatabaseDefault -ServerObject $script:serverObject -Name $script:testDatabaseName -DefaultFileGroup 'PRIMARY' -PassThru -Force

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testDatabaseName
            $result.DefaultFileGroup | Should -Be 'PRIMARY'
        }
    }

    Context 'When the command fails' {
        It 'Should throw an error when trying to set a non-existent filegroup as default' {
            { Set-SqlDscDatabaseDefault -DatabaseObject $script:testDatabaseObject -DefaultFileGroup 'NonExistentFileGroup' -Force } | Should -Throw
        }

        It 'Should throw an error when database is not found' {
            { Set-SqlDscDatabaseDefault -ServerObject $script:serverObject -Name 'NonExistentDatabase' -DefaultFileGroup 'PRIMARY' -Force } | Should -Throw
        }
    }

    Context 'After all tests are completed' {
        It 'Should clean up the test database' {
            $null = Remove-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force
        }
    }
}
