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

Describe 'Get-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When connecting to SQL Server instance' {
        Context 'When getting permissions for valid SQL logins' {
            It 'Should return permissions for sa login' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sa'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for sa login using pipeline' {
                $result = $script:serverObject | Get-SqlDscServerPermission -Name 'sa'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }
        }

        Context 'When getting permissions for valid Windows logins' {
            It 'Should return permissions for SqlAdmin Windows login' {
                $windowsLogin = '{0}\SqlAdmin' -f (Get-ComputerName)
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name $windowsLogin

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for NT AUTHORITY\SYSTEM login' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NT AUTHORITY\SYSTEM'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }
        }

        Context 'When getting permissions for valid server roles' {
            It 'Should return permissions for public server role' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'public'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for SqlDscIntegrationTestRole_Persistent server role' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]

                # Verify that the CreateEndpoint permission granted by Grant-SqlDscServerPermission test is present
                $createEndpointPermission = $result | Where-Object { $_.PermissionType.CreateEndpoint -eq $true }
                $createEndpointPermission | Should -Not -BeNullOrEmpty -Because 'CreateEndpoint permission should have been granted by Grant-SqlDscServerPermission integration test'
                $createEndpointPermission.PermissionState | Should -Be 'Grant'
            }
        }

        Context 'When getting permissions for invalid principals' {
            It 'Should throw error for non-existent login with ErrorAction Stop' {
                { Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentLogin123' -ErrorAction 'Stop' } |
                    Should -Throw
            }

            It 'Should return null for non-existent login with ErrorAction SilentlyContinue' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentLogin123' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty
            }

            It 'Should throw error for non-existent server role with ErrorAction Stop' {
                { Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentRole123' -ErrorAction 'Stop' } |
                    Should -Throw
            }

            It 'Should return null for non-existent server role with ErrorAction SilentlyContinue' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentRole123' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When verifying permission properties' {
            BeforeAll {
                # Get permissions for a known principal that should have permissions
                $script:testPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent'
            }

            It 'Should return ServerPermissionInfo objects with PermissionState property' {
                $script:testPermissions | Should -Not -BeNullOrEmpty

                foreach ($permission in $script:testPermissions) {
                    $permission.PermissionState | Should -BeIn @('Grant', 'Deny', 'GrantWithGrant')
                }
            }

            It 'Should return ServerPermissionInfo objects with PermissionType property' {
                $script:testPermissions | Should -Not -BeNullOrEmpty

                foreach ($permission in $script:testPermissions) {
                    $permission.PermissionType | Should -Not -BeNullOrEmpty
                    $permission.PermissionType | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
                }
            }
        }

        Context 'When using PrincipalType parameter' {
            It 'Should return permissions for sa login when PrincipalType is Login' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sa' -PrincipalType 'Login'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for SqlDscIntegrationTestRole_Persistent role when PrincipalType is Role' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent' -PrincipalType 'Role'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for sa login when PrincipalType is both Login and Role' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sa' -PrincipalType 'Login', 'Role'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should throw error when looking for login as role' {
                { Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sa' -PrincipalType 'Role' -ErrorAction 'Stop' } |
                    Should -Throw
            }

            It 'Should throw error when looking for role as login' {
                { Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent' -PrincipalType 'Login' -ErrorAction 'Stop' } |
                    Should -Throw
            }

            It 'Should return null when looking for login as role with SilentlyContinue' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sa' -PrincipalType 'Role' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty
            }

            It 'Should return null when looking for role as login with SilentlyContinue' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent' -PrincipalType 'Login' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When using Login parameter set' {
            It 'Should return permissions for sa login using Login object' {
                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name 'sa'
                $result = Get-SqlDscServerPermission -Login $loginObject

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for sa login using Login object from pipeline' {
                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name 'sa'
                $result = $loginObject | Get-SqlDscServerPermission

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for Windows login using Login object' {
                $windowsLogin = '{0}\SqlAdmin' -f (Get-ComputerName)
                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $windowsLogin
                $result = Get-SqlDscServerPermission -Login $loginObject

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for multiple logins using pipeline' {
                $loginObjects = @(
                    Get-SqlDscLogin -ServerObject $script:serverObject -Name 'sa'
                    Get-SqlDscLogin -ServerObject $script:serverObject -Name 'NT AUTHORITY\SYSTEM'
                )
                $result = $loginObjects | Get-SqlDscServerPermission

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
                $result.Count | Should -BeGreaterThan 1
            }
        }

        Context 'When using ServerRole parameter set' {
            It 'Should return permissions for SqlDscIntegrationTestRole_Persistent role using ServerRole object' {
                $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent'
                $result = Get-SqlDscServerPermission -ServerRole $roleObject

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for SqlDscIntegrationTestRole_Persistent role using ServerRole object from pipeline' {
                $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent'
                $result = $roleObject | Get-SqlDscServerPermission

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for public role using ServerRole object' {
                $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name 'public'
                $result = Get-SqlDscServerPermission -ServerRole $roleObject

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for multiple server roles using pipeline' {
                $roleObjects = @(
                    Get-SqlDscRole -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent'
                    Get-SqlDscRole -ServerObject $script:serverObject -Name 'public'
                )
                $result = $roleObjects | Get-SqlDscServerPermission

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
                $result.Count | Should -BeGreaterThan 1
            }
        }

        Context 'When comparing parameter sets' {
            It 'Should return same permissions for sa login using different parameter sets' {
                # Get permissions using ByName parameter set
                $resultByName = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sa'

                # Get permissions using Login parameter set
                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name 'sa'
                $resultByLogin = Get-SqlDscServerPermission -Login $loginObject

                # Compare results
                $resultByName.Count | Should -Be $resultByLogin.Count

                # Compare each permission (assuming they are returned in the same order)
                for ($i = 0; $i -lt $resultByName.Count; $i++) {
                    $resultByName[$i].PermissionState | Should -Be $resultByLogin[$i].PermissionState
                    # Note: Permission type comparison is complex due to object structure
                }
            }

            It 'Should return same permissions for SqlDscIntegrationTestRole_Persistent role using different parameter sets' {
                # Get permissions using ByName parameter set
                $resultByName = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent'

                # Get permissions using ServerRole parameter set
                $roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name 'SqlDscIntegrationTestRole_Persistent'
                $resultByRole = Get-SqlDscServerPermission -ServerRole $roleObject

                # Compare results
                $resultByName.Count | Should -Be $resultByRole.Count

                # Compare each permission (assuming they are returned in the same order)
                for ($i = 0; $i -lt $resultByName.Count; $i++) {
                    $resultByName[$i].PermissionState | Should -Be $resultByRole[$i].PermissionState
                    # Note: Permission type comparison is complex due to object structure
                }
            }
        }
    }
}
