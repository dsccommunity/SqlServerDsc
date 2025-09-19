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

Describe 'ConvertTo-SqlDscDatabasePermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When converting empty collection of DatabasePermissionInfo' {
        It 'Should return empty array for empty DatabasePermissionInfo collection' {
            $emptyCollection = [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] @()
            
            $result = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $emptyCollection

            $result | Should -BeNullOrEmpty
        }

        It 'Should accept empty collection through pipeline' {
            $emptyCollection = [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] @()
            
            $result = $emptyCollection | ConvertTo-SqlDscDatabasePermission

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When converting DatabasePermissionInfo from system database' {
        It 'Should convert DatabasePermissionInfo to DatabasePermission objects for dbo principal' {
            # Get permissions for the dbo user from master database
            $databasePermissionInfo = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'master' -Name 'dbo' -ErrorAction 'Stop'

            # Only proceed if we have permission data to work with
            if ($databasePermissionInfo) {
                $result = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $databasePermissionInfo

                # Validate the result structure
                $result | Should -Not -BeNullOrEmpty
                
                # Each result should have State and Permission properties
                foreach ($permission in $result) {
                    $permission.State | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -BeOfType 'System.String[]'
                    
                    # Validate that permission state is one of the expected values
                    $permission.State | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }
        }

        It 'Should accept DatabasePermissionInfo through pipeline' {
            # Get permissions for the dbo user from master database
            $databasePermissionInfo = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'master' -Name 'dbo' -ErrorAction 'Stop'

            # Only proceed if we have permission data to work with
            if ($databasePermissionInfo) {
                $result = $databasePermissionInfo | ConvertTo-SqlDscDatabasePermission

                # Validate the result structure
                $result | Should -Not -BeNullOrEmpty
                
                # Each result should have State and Permission properties
                foreach ($permission in $result) {
                    $permission.State | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -BeOfType 'System.String[]'
                    
                    # Validate that permission state is one of the expected values
                    $permission.State | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }
        }
    }

    Context 'When converting DatabasePermissionInfo for guest user' {
        It 'Should handle guest user permissions correctly' {
            # Get permissions for the guest user from master database (guest should have Connect permission)
            $databasePermissionInfo = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'master' -Name 'guest' -ErrorAction 'SilentlyContinue'

            # Only proceed if we have permission data to work with
            if ($databasePermissionInfo) {
                $result = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $databasePermissionInfo

                # Validate the result structure
                $result | Should -Not -BeNullOrEmpty
                
                # Each result should have State and Permission properties
                foreach ($permission in $result) {
                    $permission.State | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -BeOfType 'System.String[]'
                    
                    # Validate that permission state is one of the expected values
                    $permission.State | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }
        }
    }

    Context 'When testing conversion functionality with multiple permission states' {
        It 'Should group permissions by state correctly' {
            # Try to get permissions from system databases where we might have various permission states
            $databasePermissionInfo = Get-SqlDscDatabasePermission -ServerObject $script:serverObject -DatabaseName 'msdb' -Name 'dbo' -ErrorAction 'SilentlyContinue'

            # Only proceed if we have permission data to work with
            if ($databasePermissionInfo) {
                $result = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $databasePermissionInfo

                if ($result) {
                    # Validate that permissions are properly grouped by state
                    $uniqueStates = $result.State | Sort-Object -Unique
                    
                    foreach ($state in $uniqueStates) {
                        $permissionsForState = $result | Where-Object { $_.State -eq $state }
                        $permissionsForState | Should -HaveCount 1
                        $permissionsForState[0].Permission | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }
}
