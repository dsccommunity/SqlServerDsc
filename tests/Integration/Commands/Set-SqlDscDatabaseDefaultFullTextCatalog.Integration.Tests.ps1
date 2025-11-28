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

Describe 'Set-SqlDscDatabaseDefaultFullTextCatalog' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Test database names
        $script:testDatabaseName = 'SqlDscTestSetFTCatalog_' + (Get-Random)

        # Create test database for the integration tests
        $script:testDatabaseObject = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'

        # Create full-text catalogs for testing
        $script:testCatalogName1 = 'TestFTCatalog1_' + (Get-Random)
        $script:testCatalogName2 = 'TestFTCatalog2_' + (Get-Random)

        # Create full-text catalogs using T-SQL
        $null = $script:testDatabaseObject.ExecuteNonQuery("CREATE FULLTEXT CATALOG [$script:testCatalogName1]")
        $null = $script:testDatabaseObject.ExecuteNonQuery("CREATE FULLTEXT CATALOG [$script:testCatalogName2]")

        # Refresh database object to get the newly created catalogs
        $script:testDatabaseObject.Refresh()

        # Store the original default full-text catalog to restore later
        $script:originalDefaultCatalog = $script:testDatabaseObject.DefaultFullTextCatalog
        Write-Verbose -Message "Original default full-text catalog of database '$($script:testDatabaseName)' is '$($script:originalDefaultCatalog)'." -Verbose
    }

    AfterAll {
        # Clean up test database (this will also remove the full-text catalogs)
        $existingDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'SilentlyContinue'

        if ($existingDb)
        {
            $null = Remove-SqlDscDatabase -DatabaseObject $existingDb -Force -ErrorAction 'Stop'
        }

        # Disconnect from the database engine
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -ErrorAction 'Stop'
    }

    Context 'When setting default full-text catalog using ServerObject parameter set' {
        It 'Should set default catalog successfully' {
            $resultDb = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $script:serverObject -Name $script:testDatabaseName -CatalogName $script:testCatalogName1 -Force -PassThru -ErrorAction 'Stop'
            $resultDb.DefaultFullTextCatalog | Should -Be $script:testCatalogName1

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFullTextCatalog | Should -Be $script:testCatalogName1
        }

        It 'Should change to a different catalog' {
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $script:serverObject -Name $script:testDatabaseName -CatalogName $script:testCatalogName2 -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFullTextCatalog | Should -Be $script:testCatalogName2
        }

        It 'Should be idempotent when catalog is already set' {
            # Set catalog
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $script:serverObject -Name $script:testDatabaseName -CatalogName $script:testCatalogName1 -Force -ErrorAction 'Stop'

            # Set same catalog again - should not throw
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $script:serverObject -Name $script:testDatabaseName -CatalogName $script:testCatalogName1 -Force -ErrorAction 'Stop'

            # Verify the value is still correct
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFullTextCatalog | Should -Be $script:testCatalogName1
        }

        It 'Should throw error when trying to set catalog of non-existent database' {
            { Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $script:serverObject -Name 'NonExistentDatabase' -CatalogName $script:testCatalogName1 -Force -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should throw error when trying to set non-existent catalog' {
            { Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $script:serverObject -Name $script:testDatabaseName -CatalogName 'NonExistentCatalog' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When setting default full-text catalog using DatabaseObject parameter set' {
        It 'Should set catalog using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'

            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -DatabaseObject $databaseObject -CatalogName $script:testCatalogName2 -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFullTextCatalog | Should -Be $script:testCatalogName2
        }

        It 'Should support pipeline input with database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'

            $null = $databaseObject | Set-SqlDscDatabaseDefaultFullTextCatalog -CatalogName $script:testCatalogName1 -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFullTextCatalog | Should -Be $script:testCatalogName1
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection before setting catalog' {
            $null = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $script:serverObject -Name $script:testDatabaseName -CatalogName $script:testCatalogName2 -Refresh -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh -ErrorAction 'Stop'
            $updatedDb.DefaultFullTextCatalog | Should -Be $script:testCatalogName2
        }
    }

    Context 'When using the PassThru parameter' {
        It 'Should return the database object when PassThru is specified' {
            $result = Set-SqlDscDatabaseDefaultFullTextCatalog -ServerObject $script:serverObject -Name $script:testDatabaseName -CatalogName $script:testCatalogName1 -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be $script:testDatabaseName
            $result.DefaultFullTextCatalog | Should -Be $script:testCatalogName1
        }
    }
}
