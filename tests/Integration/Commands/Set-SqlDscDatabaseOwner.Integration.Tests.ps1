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

Describe 'Set-SqlDscDatabaseOwner' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Test database names
        $script:testDatabaseName = 'SqlDscTestSetOwner_' + (Get-Random)
        $script:testDatabaseNameForObject = 'SqlDscTestSetOwnerObj_' + (Get-Random)

        # Create test databases
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'

        # Get the current owner to restore later
        $testDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
        $script:originalOwner = $testDb.Owner
    }

    AfterAll {
        # Clean up test databases
        $testDatabasesToRemove = @($script:testDatabaseName, $script:testDatabaseNameForObject)

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

    Context 'When setting database owner using ServerObject parameter set' {
        It 'Should set owner to sa successfully' {
            $null = Set-SqlDscDatabaseOwner -ServerObject $script:serverObject -Name $script:testDatabaseName -OwnerName 'sa' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.Owner | Should -Be 'sa'
        }

        It 'Should set owner to domain account successfully' {
            $ownerName = '{0}\SqlAdmin' -f $script:mockComputerName
            $null = Set-SqlDscDatabaseOwner -ServerObject $script:serverObject -Name $script:testDatabaseName -OwnerName $ownerName -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $updatedDb.Owner | Should -Be $ownerName
        }

        It 'Should be idempotent when owner is already set' {
            $ownerName = 'sa'
            
            # Set owner
            $null = Set-SqlDscDatabaseOwner -ServerObject $script:serverObject -Name $script:testDatabaseName -OwnerName $ownerName -Force -ErrorAction 'Stop'

            # Set same owner again - should not throw
            $null = Set-SqlDscDatabaseOwner -ServerObject $script:serverObject -Name $script:testDatabaseName -OwnerName $ownerName -Force -ErrorAction 'Stop'

            # Verify the value is still correct
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.Owner | Should -Be $ownerName
        }

        It 'Should throw error when trying to set owner of non-existent database' {
            { Set-SqlDscDatabaseOwner -ServerObject $script:serverObject -Name 'NonExistentDatabase' -OwnerName 'sa' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When setting database owner using DatabaseObject parameter set' {
        It 'Should set owner using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'

            $null = Set-SqlDscDatabaseOwner -DatabaseObject $databaseObject -OwnerName 'sa' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.Owner | Should -Be 'sa'
        }

        It 'Should support pipeline input with database object' {
            $ownerName = '{0}\SqlAdmin' -f $script:mockComputerName
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            
            $null = $databaseObject | Set-SqlDscDatabaseOwner -OwnerName $ownerName -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.Owner | Should -Be $ownerName
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection before setting owner' {
            $ownerName = 'sa'
            $null = Set-SqlDscDatabaseOwner -ServerObject $script:serverObject -Name $script:testDatabaseName -OwnerName $ownerName -Refresh -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $updatedDb.Owner | Should -Be $ownerName
        }
    }

    Context 'When using the PassThru parameter' {
        It 'Should return the database object when PassThru is specified' {
            $ownerName = 'sa'
            $result = Set-SqlDscDatabaseOwner -ServerObject $script:serverObject -Name $script:testDatabaseName -OwnerName $ownerName -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be $script:testDatabaseName
            $result.Owner | Should -Be $ownerName
        }
    }
}
