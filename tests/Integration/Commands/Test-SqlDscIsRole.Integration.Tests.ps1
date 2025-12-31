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

Describe 'Test-SqlDscIsRole' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
        $mockSqlAdministratorCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockSqlAdministratorUserName, $mockSqlAdministratorPassword

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $mockSqlAdministratorCredential -ErrorAction 'Stop'

        # Shared test roles created by New-SqlDscRole integration tests
        $script:sharedTestRoleForIntegrationTests = 'SharedTestRole_ForIntegrationTests'
        $script:persistentTestRole = 'SqlDscIntegrationTestRole_Persistent'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When testing for existing system roles' {
        It 'Should return true for built-in sysadmin role' {
            $result = Test-SqlDscIsRole -ServerObject $script:serverObject -Name 'sysadmin' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should return true for built-in serveradmin role' {
            $result = Test-SqlDscIsRole -ServerObject $script:serverObject -Name 'serveradmin' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should return true for built-in securityadmin role' {
            $result = Test-SqlDscIsRole -ServerObject $script:serverObject -Name 'securityadmin' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }

    Context 'When testing for existing user-created roles' {
        It 'Should return true for shared test role created by New-SqlDscRole integration test' {
            # This role should be created by New-SqlDscRole integration tests
            $result = Test-SqlDscIsRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForIntegrationTests -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should return true for persistent test role created by New-SqlDscRole integration test' {
            # This role should be created by New-SqlDscRole integration tests
            $result = Test-SqlDscIsRole -ServerObject $script:serverObject -Name $script:persistentTestRole -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }

    Context 'When testing for non-existing roles' {
        It 'Should return false for non-existing role' {
            $result = Test-SqlDscIsRole -ServerObject $script:serverObject -Name 'NonExistentRole' -ErrorAction 'Stop'
            $result | Should -BeFalse
        }

        It 'Should return false for role with special characters that does not exist' {
            $result = Test-SqlDscIsRole -ServerObject $script:serverObject -Name 'Role$WithSpecial@Characters' -ErrorAction 'Stop'
            $result | Should -BeFalse
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline for existing role' {
            $result = $script:serverObject | Test-SqlDscIsRole -Name 'sysadmin' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should accept ServerObject from pipeline for non-existing role' {
            $result = $script:serverObject | Test-SqlDscIsRole -Name 'NonExistentRole' -ErrorAction 'Stop'
            $result | Should -BeFalse
        }
    }
}
