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

Describe 'Test-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Note: SQL Server service is already running from Install-SqlDscServer test for performance optimization

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -ErrorAction 'Stop'

        # Note: SQL Server service is left running for subsequent tests for performance optimization
    }

    Context 'When testing database presence' {
        It 'Should return true when system database exists and Ensure is Present' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Present' -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when non-existent database is tested with Ensure Present' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Ensure 'Present' -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should return false when system database exists and Ensure is Absent' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Absent' -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should return true when non-existent database is tested with Ensure Absent' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Ensure 'Absent' -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }

    Context 'When testing database properties' {
        It 'Should return true when testing master database with correct recovery model' {
            # Master database typically has Simple recovery model
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Present' -RecoveryModel 'Simple' -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when testing master database with incorrect recovery model' {
            # Master database typically has Simple recovery model, so Full should return false
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Present' -RecoveryModel 'Full' -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection and test database presence' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Present' -Refresh -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }
}
