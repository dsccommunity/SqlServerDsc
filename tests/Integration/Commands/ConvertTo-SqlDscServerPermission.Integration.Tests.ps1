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

Describe 'ConvertTo-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When converting empty collection of ServerPermissionInfo' {
        It 'Should return empty array for empty ServerPermissionInfo collection' {
            $emptyCollection = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

            $result = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $emptyCollection

            $result | Should -BeNullOrEmpty
        }

        It 'Should accept empty collection through pipeline' {
            $emptyCollection = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

            $result = $emptyCollection | ConvertTo-SqlDscServerPermission

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When converting ServerPermissionInfo from SQL Server' {
        It 'Should convert ServerPermissionInfo to ServerPermission objects for sa principal' {
            # Get permissions for the sa login
            $serverPermissionInfo = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sa' -ErrorAction 'Stop'

            # Only proceed if we have permission data to work with
            if ($serverPermissionInfo) {
                $result = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $serverPermissionInfo

                # Validate the result structure
                $result | Should -Not -BeNullOrEmpty

                # Each result should have State and Permission properties
                foreach ($permission in $result) {
                    $permission.State | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -Not -BeNullOrEmpty

                    # Validate that permission state is one of the expected values
                    $permission.State | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }
        }

        It 'Should accept ServerPermissionInfo through pipeline' {
            # Get permissions for the sa login
            $serverPermissionInfo = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sa' -ErrorAction 'Stop'

            # Only proceed if we have permission data to work with
            if ($serverPermissionInfo) {
                $result = $serverPermissionInfo | ConvertTo-SqlDscServerPermission

                # Validate the result structure
                $result | Should -Not -BeNullOrEmpty

                # Each result should have State and Permission properties
                foreach ($permission in $result) {
                    $permission.State | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -Not -BeNullOrEmpty

                    # Validate that permission state is one of the expected values
                    $permission.State | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }
        }
    }

    Context 'When converting ServerPermissionInfo for system logins' {
        It 'Should handle NT AUTHORITY\SYSTEM permissions correctly' {
            # Get permissions for NT AUTHORITY\SYSTEM
            $serverPermissionInfo = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NT AUTHORITY\SYSTEM' -ErrorAction 'SilentlyContinue'

            # Only proceed if we have permission data to work with
            if ($serverPermissionInfo) {
                $result = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $serverPermissionInfo

                # Validate the result structure
                $result | Should -Not -BeNullOrEmpty

                # Each result should have State and Permission properties
                foreach ($permission in $result) {
                    $permission.State | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -Not -BeNullOrEmpty

                    # Validate that permission state is one of the expected values
                    $permission.State | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }
        }
    }

    Context 'When converting ServerPermissionInfo for server roles' {
        It 'Should handle public server role permissions correctly' {
            # Get permissions for the public server role
            $serverPermissionInfo = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'public' -ErrorAction 'Stop'

            # Only proceed if we have permission data to work with
            if ($serverPermissionInfo) {
                $result = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $serverPermissionInfo

                # Validate the result structure
                $result | Should -Not -BeNullOrEmpty

                # Each result should have State and Permission properties
                foreach ($permission in $result) {
                    $permission.State | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -Not -BeNullOrEmpty

                    # Validate that permission state is one of the expected values
                    $permission.State | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }
        }

        It 'Should handle SqlDscIntegrationTestRole_Persistent server role permissions correctly' {
            # Get permissions for the SqlDscIntegrationTestRole_Persistent server role
            $serverPermissionInfo = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent' -ErrorAction 'Stop'

            # Only proceed if we have permission data to work with
            if ($serverPermissionInfo) {
                $result = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $serverPermissionInfo

                # Validate the result structure
                $result | Should -Not -BeNullOrEmpty

                # Each result should have State and Permission properties
                foreach ($permission in $result) {
                    $permission.State | Should -Not -BeNullOrEmpty
                    $permission.Permission | Should -Not -BeNullOrEmpty

                    # Validate that permission state is one of the expected values
                    $permission.State | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }

                # Verify that the CreateEndpoint permission granted by Grant-SqlDscServerPermission test is present
                $grantPermission = $result | Where-Object { $_.State -eq 'Grant' }
                if ($grantPermission) {
                    $grantPermission.Permission | Should -Contain 'CreateEndpoint' -Because 'CreateEndpoint permission should have been granted by Grant-SqlDscServerPermission integration test'
                }
            }
        }
    }

    Context 'When testing conversion functionality with multiple permission states' {
        It 'Should group permissions by state correctly' {
            # Get permissions from a principal that might have various permission states
            $serverPermissionInfo = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent' -ErrorAction 'SilentlyContinue'

            # Only proceed if we have permission data to work with
            if ($serverPermissionInfo) {
                $result = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $serverPermissionInfo

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
