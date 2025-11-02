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

Describe 'New-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Test database names
        $script:testDatabaseName = 'SqlDscTestDatabase_' + (Get-Random)
        $script:testDatabaseNameWithProperties = 'SqlDscTestDatabaseWithProps_' + (Get-Random)
    }

    AfterAll {
        # Clean up test databases
        $testDatabasesToRemove = @($script:testDatabaseName, $script:testDatabaseNameWithProperties)

        foreach ($dbName in $testDatabasesToRemove)
        {
            $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $dbName -ErrorAction 'SilentlyContinue'

            if ($existingDb)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'Stop'
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When creating a new database' {
        It 'Should create a database successfully with minimal parameters' {
            $result = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testDatabaseName
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'

            # Verify the database exists
            $createdDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $createdDb | Should -Not -BeNullOrEmpty
        }

        It 'Should create a database with specified properties' {
            $result = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameWithProperties -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testDatabaseNameWithProperties
            $result.RecoveryModel | Should -Be 'Simple'

            # Verify the database exists with correct properties
            $createdDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameWithProperties -ErrorAction 'Stop'
            $createdDb | Should -Not -BeNullOrEmpty
            $createdDb.RecoveryModel | Should -Be 'Simple'
        }

        It 'Should throw error when trying to create a database that already exists' {
            { New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When using the Refresh parameter' {
        BeforeEach {
            $script:refreshTestDbName = $null
        }

        AfterEach {
            # Clean up the refresh test database if it was created
            if ($script:refreshTestDbName)
            {
                $dbToRemove = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:refreshTestDbName -ErrorAction 'SilentlyContinue'
                if ($dbToRemove)
                {
                    $null = Remove-SqlDscDatabase -DatabaseObject $dbToRemove -Force -ErrorAction 'Stop'
                }
            }
        }

        It 'Should refresh the database collection before creating' {
            $script:refreshTestDbName = 'SqlDscTestRefresh_' + (Get-Random)

            $result = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:refreshTestDbName -Refresh -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:refreshTestDbName
        }
    }

    Context 'When creating a persistent database for other integration tests' {
        BeforeAll {
            $script:persistentTestDatabase = 'SqlDscIntegrationTestDatabase_Persistent'
        }

        It 'Should create a persistent database that remains on the instance' {
            # Create persistent database with Simple recovery model that will remain on the instance
            $result = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:persistentTestDatabase -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:persistentTestDatabase
            $result.RecoveryModel | Should -Be 'Simple'
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'

            # Verify the database exists
            $verifyDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:persistentTestDatabase -Refresh -ErrorAction 'Stop'

            $verifyDb | Should -Not -BeNullOrEmpty
            $verifyDb.Name | Should -Be $script:persistentTestDatabase
            $verifyDb.RecoveryModel | Should -Be 'Simple'
        }

        It 'Should throw error when trying to create the persistent database that already exists' {
            # Try to re-create the persistent database which should already exist
            { New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:persistentTestDatabase -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When creating a database with file groups' {
        BeforeAll {
            $script:testDatabaseWithFileGroups = 'SqlDscTestDbFileGroups_' + (Get-Random)

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
        }

        AfterAll {
            # Clean up test database
            $dbToRemove = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseWithFileGroups -ErrorAction 'SilentlyContinue'
            if ($dbToRemove)
            {
                $null = Remove-SqlDscDatabase -DatabaseObject $dbToRemove -Force -ErrorAction 'Stop'
            }
        }

        It 'Should create a database with custom file groups and data files' {
            # Create PRIMARY filegroup with data file
            $primaryFileGroup = New-SqlDscFileGroup -Name 'PRIMARY'
            $primaryFilePath = Join-Path -Path $script:dataDirectory -ChildPath ($script:testDatabaseWithFileGroups + '_Primary.mdf')
            $null = New-SqlDscDataFile -FileGroup $primaryFileGroup -Name ($script:testDatabaseWithFileGroups + '_Primary') -FileName $primaryFilePath -Force

            # Create a secondary filegroup with data file
            $secondaryFileGroup = New-SqlDscFileGroup -Name 'SecondaryFG'
            $secondaryFilePath = Join-Path -Path $script:dataDirectory -ChildPath ($script:testDatabaseWithFileGroups + '_Secondary.ndf')
            $null = New-SqlDscDataFile -FileGroup $secondaryFileGroup -Name ($script:testDatabaseWithFileGroups + '_Secondary') -FileName $secondaryFilePath -Force

            # Create database with file groups
            $result = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseWithFileGroups -FileGroup @($primaryFileGroup, $secondaryFileGroup) -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testDatabaseWithFileGroups
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'

            # Verify the database exists with correct file groups
            $createdDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseWithFileGroups -Refresh -ErrorAction 'Stop'
            $createdDb | Should -Not -BeNullOrEmpty

            # Verify PRIMARY filegroup exists
            $createdDb.FileGroups['PRIMARY'] | Should -Not -BeNullOrEmpty
            $createdDb.FileGroups['PRIMARY'].Files.Count | Should -Be 1
            $createdDb.FileGroups['PRIMARY'].Files[0].Name | Should -Be ($script:testDatabaseWithFileGroups + '_Primary')

            # Verify secondary filegroup exists
            $createdDb.FileGroups['SecondaryFG'] | Should -Not -BeNullOrEmpty
            $createdDb.FileGroups['SecondaryFG'].Files.Count | Should -Be 1
            $createdDb.FileGroups['SecondaryFG'].Files[0].Name | Should -Be ($script:testDatabaseWithFileGroups + '_Secondary')
        }
    }
}
