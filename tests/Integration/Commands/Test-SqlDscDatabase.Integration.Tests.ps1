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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName
}

Describe 'Test-SqlDscDatabase' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When testing database presence' {
        It 'Should return true when system database exists and Ensure is Present' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Present'

            $result | Should -BeTrue
        }

        It 'Should return false when non-existent database is tested with Ensure Present' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Ensure 'Present'

            $result | Should -BeFalse
        }

        It 'Should return false when system database exists and Ensure is Absent' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Absent'

            $result | Should -BeFalse
        }

        It 'Should return true when non-existent database is tested with Ensure Absent' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -Ensure 'Absent'

            $result | Should -BeTrue
        }
    }

    Context 'When testing database properties' {
        It 'Should return true when testing master database with correct recovery model' {
            # Master database typically has Simple recovery model
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Present' -RecoveryModel 'Simple'

            $result | Should -BeTrue
        }

        It 'Should return false when testing master database with incorrect recovery model' {
            # Master database typically has Simple recovery model, so Full should return false
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Present' -RecoveryModel 'Full'

            $result | Should -BeFalse
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection and test database presence' {
            $result = Test-SqlDscDatabase -ServerObject $script:serverObject -Name 'master' -Ensure 'Present' -Refresh

            $result | Should -BeTrue
        }
    }
}