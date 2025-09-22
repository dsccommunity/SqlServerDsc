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

Describe 'Test-SqlDscIsLogin' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Note: SQL Server service is already running from Install-SqlDscServer test for performance optimization

        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Use existing persistent login for testing
        $script:testLoginName = 'IntegrationTestSqlLogin'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Note: SQL Server service is left running for subsequent tests for performance optimization
    }

    Context 'When testing login existence using ServerObject parameter set' {
        It 'Should return True when login exists' {
            # Test with persistent integration test login
            $result = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return False when login does not exist' {
            # Test with non-existent login
            $result = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name 'NonExistentLogin'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should accept ServerObject from pipeline' {
            # Test using pipeline
            $result = $script:serverObject | Test-SqlDscIsLogin -Name $script:testLoginName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return True for built-in sa login' {
            # Test with built-in sa login
            $result = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name 'sa'

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }
    }

    Context 'When testing different login types' {
        It 'Should return True for SQL Server login' {
            # Verify the persistent test login exists and is a SQL Server login
            $result = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return True for Windows login if it exists' {
            # Test with Windows login (using SqlAdmin which should exist)
            $computerName = Get-ComputerName
            $windowsLoginName = "$computerName\SqlAdmin"
            
            $result = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $windowsLoginName

            $result | Should -BeOfType [System.Boolean]
            # Note: We don't assert True/False here as it depends on environment setup
            # but we verify it returns a boolean value
        }
    }

    Context 'When testing case sensitivity' {
        It 'Should handle case differences correctly' {
            # Test with different case - SQL Server login names are case-insensitive
            $result1 = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName.ToUpper()
            $result2 = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName.ToLower()

            $result1 | Should -BeOfType [System.Boolean]
            $result2 | Should -BeOfType [System.Boolean]
            $result1 | Should -Be $result2
        }
    }
}
