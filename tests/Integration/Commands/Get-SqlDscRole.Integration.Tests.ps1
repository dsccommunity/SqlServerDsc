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

Describe 'Get-SqlDscRole' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Shared test role names created by New-SqlDscRole integration tests
        $script:sharedTestRoleForIntegrationTests = 'SharedTestRole_ForIntegrationTests'
        $script:persistentTestRole = 'SqlDscIntegrationTestRole_Persistent'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When getting all SQL Server roles' {
        It 'Should return an array of ServerRole objects' {
            $result = Get-SqlDscRole -ServerObject $script:serverObject

            <#
                Casting to array to ensure we get the count on Windows PowerShell
                when there is only one role.
            #>
            @($result).Count | Should -BeGreaterOrEqual 1
            @($result)[0] | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
        }

        It 'Should return system roles including sysadmin' {
            $result = Get-SqlDscRole -ServerObject $script:serverObject

            $result.Name | Should -Contain 'sysadmin'
        }
    }

    Context 'When getting a specific SQL Server role' {
        It 'Should return the specified role when it exists (system role)' {
            $result = Get-SqlDscRole -ServerObject $script:serverObject -Name 'sysadmin'

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be 'sysadmin'
            $result.IsFixedRole | Should -BeTrue
        }

        It 'Should return the specified role when it exists (shared test role)' {
            $result = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:sharedTestRoleForIntegrationTests

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:sharedTestRoleForIntegrationTests
            $result.IsFixedRole | Should -BeFalse
        }

        It 'Should return the specified role when it exists (persistent test role)' {
            $result = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:persistentTestRole

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:persistentTestRole
            $result.Owner | Should -Be 'sa'
            $result.IsFixedRole | Should -BeFalse
        }

        It 'Should throw an error when the role does not exist' {
            { Get-SqlDscRole -ServerObject $script:serverObject -Name 'NonExistentRole' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage 'Server role ''NonExistentRole'' was not found.'
        }

        It 'Should return null when the role does not exist and error action is SilentlyContinue' {
            $result = Get-SqlDscRole -ServerObject $script:serverObject -Name 'NonExistentRole' -ErrorAction 'SilentlyContinue'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should return the same results with and without Refresh' {
            $resultWithoutRefresh = Get-SqlDscRole -ServerObject $script:serverObject
            $resultWithRefresh = Get-SqlDscRole -ServerObject $script:serverObject -Refresh

            @($resultWithoutRefresh).Count | Should -Be @($resultWithRefresh).Count
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            $result = $script:serverObject | Get-SqlDscRole -Name $script:sharedTestRoleForIntegrationTests

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:sharedTestRoleForIntegrationTests
        }
    }
}
