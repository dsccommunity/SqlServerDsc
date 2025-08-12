[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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

Describe 'Get-SqlDscServerPermission' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:instanceName = 'DSCSQLTEST'
        $script:computerName = Get-ComputerName
    }

    AfterAll {
        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When connecting to SQL Server instance' {
        BeforeAll {
            $sqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
            $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

            $script:sqlAdminCredential = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)

            $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:instanceName -Credential $script:sqlAdminCredential
        }

        AfterAll {
            Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
        }

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
                $windowsLogin = '{0}\SqlAdmin' -f $script:computerName
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
            It 'Should return permissions for sysadmin server role' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sysadmin'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for public server role' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'public'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for serveradmin server role' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'serveradmin'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }

            It 'Should return permissions for securityadmin server role' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'securityadmin'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo]
            }
        }

        Context 'When getting permissions for invalid principals' {
            It 'Should throw error for non-existent login with ErrorAction Stop' {
                { Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentLogin123' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "*does not exist*"
            }

            It 'Should return null for non-existent login with ErrorAction SilentlyContinue' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentLogin123' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty
            }

            It 'Should throw error for non-existent server role with ErrorAction Stop' {
                { Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentRole123' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage "*does not exist*"
            }

            It 'Should return null for non-existent server role with ErrorAction SilentlyContinue' {
                $result = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentRole123' -ErrorAction 'SilentlyContinue'

                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When verifying permission properties' {
            BeforeAll {
                # Get permissions for a known principal that should have permissions
                $script:testPermissions = Get-SqlDscServerPermission -ServerObject $script:serverObject -Name 'sysadmin'
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
    }
}
