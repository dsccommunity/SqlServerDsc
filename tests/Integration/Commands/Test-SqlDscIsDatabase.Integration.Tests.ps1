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

Describe 'Test-SqlDscIsDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Use existing persistent database for testing
        $script:testDatabaseName = 'SqlDscIntegrationTestDatabase_Persistent'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When testing database existence using ServerObject parameter set' {
        It 'Should return True when database exists' {
            # Test with persistent integration test database
            $result = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return False when database does not exist' {
            # Test with non-existent database
            $result = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should accept ServerObject from pipeline' {
            # Test using pipeline
            $result = $script:serverObject | Test-SqlDscIsDatabase -Name $script:testDatabaseName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return True for system database master' {
            # Test with built-in master database
            $result = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name 'master'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return True for system database msdb' {
            # Test with built-in msdb database
            $result = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name 'msdb'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return True for system database model' {
            # Test with built-in model database
            $result = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name 'model'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return True for system database tempdb' {
            # Test with built-in tempdb database
            $result = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name 'tempdb'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }
    }

    Context 'When testing case sensitivity' {
        It 'Should handle case differences correctly' {
            # Test with different case - SQL Server database names are case-insensitive by default
            $result1 = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName.ToUpper()
            $result2 = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName.ToLower()

            $result1 | Should -BeOfType [System.Boolean]
            $result2 | Should -BeOfType [System.Boolean]
            $result1 | Should -Be $result2
        }
    }

    Context 'When using Refresh parameter' {
        It 'Should return correct result when using Refresh switch' {
            # Test with Refresh parameter
            $result = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Refresh

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return False for non-existent database when using Refresh switch' {
            # Test with Refresh parameter for non-existent database
            $result = Test-SqlDscIsDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Refresh

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }
    }
}
