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

Describe 'Set-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Test database names
        $script:testDatabaseName = 'SqlDscTestSetDatabase_' + (Get-Random)
        $script:testDatabaseNameForObject = 'SqlDscTestSetDatabaseObj_' + (Get-Random)

        # Create test databases
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Force -ErrorAction 'Stop'
        $null = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -Force -ErrorAction 'Stop'
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

    Context 'When setting database properties using ServerObject parameter set' {
        It 'Should set recovery model successfully' {
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.RecoveryModel | Should -Be 'Simple'
        }

        It 'Should set compatibility level successfully' {
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -CompatibilityLevel 'Version150' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.CompatibilityLevel | Should -Be 'Version150'
        }

        It 'Should set AutoClose successfully' {
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -AutoClose $true -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.AutoClose | Should -Be $true

            # Reset to default
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -AutoClose $false -Force -ErrorAction 'Stop'
        }

        It 'Should set AutoShrink successfully' {
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -AutoShrink $true -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.AutoShrink | Should -Be $true

            # Reset to default
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -AutoShrink $false -Force -ErrorAction 'Stop'
        }

        It 'Should set PageVerify successfully' {
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -PageVerify 'TornPageDetection' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.PageVerify | Should -Be 'TornPageDetection'

            # Reset to default
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -PageVerify 'Checksum' -Force -ErrorAction 'Stop'
        }

        It 'Should set multiple properties successfully' {
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Full' -AutoClose $false -AutoShrink $false -PageVerify 'Checksum' -Force -ErrorAction 'Stop'

            # Verify the changes
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'Full'
            $updatedDb.AutoClose | Should -Be $false
            $updatedDb.AutoShrink | Should -Be $false
            $updatedDb.PageVerify | Should -Be 'Checksum'
        }

        It 'Should be idempotent when property is already set' {
            # Set property
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'

            # Set same property again - should not throw
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'

            # Verify the value is still correct
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName
            $updatedDb.RecoveryModel | Should -Be 'Simple'
        }

        It 'Should throw error when trying to set properties of non-existent database' {
            { Set-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -RecoveryModel 'Simple' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When setting database properties using DatabaseObject parameter set' {
        It 'Should set recovery model using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'

            $null = Set-SqlDscDatabase -DatabaseObject $databaseObject -RecoveryModel 'Simple' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'Simple'
        }

        It 'Should set AutoClose using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'

            $null = Set-SqlDscDatabase -DatabaseObject $databaseObject -AutoClose $true -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.AutoClose | Should -Be $true

            # Reset to default
            $null = Set-SqlDscDatabase -DatabaseObject $databaseObject -AutoClose $false -Force -ErrorAction 'Stop'
        }

        It 'Should set multiple properties using database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'

            $null = Set-SqlDscDatabase -DatabaseObject $databaseObject -RecoveryModel 'Full' -PageVerify 'TornPageDetection' -Force -ErrorAction 'Stop'

            # Verify the changes
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'Full'
            $updatedDb.PageVerify | Should -Be 'TornPageDetection'
        }

        It 'Should support pipeline input with database object' {
            $databaseObject = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $null = $databaseObject | Set-SqlDscDatabase -RecoveryModel 'BulkLogged' -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseNameForObject -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'BulkLogged'
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection before setting properties' {
            $null = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'BulkLogged' -Refresh -Force -ErrorAction 'Stop'

            # Verify the change
            $updatedDb = Get-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -ErrorAction 'Stop'
            $updatedDb.RecoveryModel | Should -Be 'BulkLogged'
        }
    }

    Context 'When using the PassThru parameter' {
        It 'Should return the database object when PassThru is specified' {
            $result = Set-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -RecoveryModel 'Simple' -PassThru -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
            $result.Name | Should -Be $script:testDatabaseName
            $result.RecoveryModel | Should -Be 'Simple'
        }
    }
}
