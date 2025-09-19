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

Describe 'ConvertFrom-SqlDscDatabasePermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'

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

    Context 'When converting DatabasePermission objects' {
        Context 'When converting a single permission Grant state' {
            It 'Should return a DatabasePermissionSet with correct permissions set' {
                $databasePermission = & (Get-Module -Name $script:moduleName) {
                    [DatabasePermission] @{
                        State      = 'Grant'
                        Permission = @('Connect', 'Select')
                    }
                }

                $result = ConvertFrom-SqlDscDatabasePermission -Permission $databasePermission -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
                $result.Connect | Should -BeTrue
                $result.Select | Should -BeTrue
                $result.Update | Should -BeFalse
                $result.Insert | Should -BeFalse
                $result.Delete | Should -BeFalse
            }
        }

        Context 'When converting multiple permissions' {
            It 'Should return a DatabasePermissionSet with all specified permissions set' {
                $databasePermission = & (Get-Module -Name $script:moduleName) {
                    [DatabasePermission] @{
                        State      = 'Grant'
                        Permission = @('Connect', 'Select', 'Update', 'Insert')
                    }
                }

                $result = ConvertFrom-SqlDscDatabasePermission -Permission $databasePermission -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
                $result.Connect | Should -BeTrue
                $result.Select | Should -BeTrue
                $result.Update | Should -BeTrue
                $result.Insert | Should -BeTrue
                $result.Delete | Should -BeFalse
                $result.Alter | Should -BeFalse
            }
        }

        Context 'When converting permission with GrantWithGrant state' {
            It 'Should return a DatabasePermissionSet with correct permissions set regardless of state' {
                $databasePermission = & (Get-Module -Name $script:moduleName) {
                    [DatabasePermission] @{
                        State      = 'GrantWithGrant'
                        Permission = @('Alter', 'CreateTable')
                    }
                }

                $result = ConvertFrom-SqlDscDatabasePermission -Permission $databasePermission -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
                $result.Alter | Should -BeTrue
                $result.CreateTable | Should -BeTrue
                $result.Connect | Should -BeFalse
                $result.Select | Should -BeFalse
            }
        }

        Context 'When converting permission with Deny state' {
            It 'Should return a DatabasePermissionSet with correct permissions set regardless of state' {
                $databasePermission = & (Get-Module -Name $script:moduleName) {
                    [DatabasePermission] @{
                        State      = 'Deny'
                        Permission = @('Delete', 'Execute')
                    }
                }

                $result = ConvertFrom-SqlDscDatabasePermission -Permission $databasePermission -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
                $result.Delete | Should -BeTrue
                $result.Execute | Should -BeTrue
                $result.Connect | Should -BeFalse
                $result.Select | Should -BeFalse
            }
        }

        Context 'When using pipeline input' {
            It 'Should accept DatabasePermission objects from the pipeline' {
                $databasePermission = & (Get-Module -Name $script:moduleName) {
                    [DatabasePermission] @{
                        State      = 'Grant'
                        Permission = @('Connect', 'ViewDefinition')
                    }
                }

                $result = $databasePermission | ConvertFrom-SqlDscDatabasePermission -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
                $result.Connect | Should -BeTrue
                $result.ViewDefinition | Should -BeTrue
                $result.Select | Should -BeFalse
            }
        }

        Context 'When processing multiple DatabasePermission objects through pipeline' {
            It 'Should process each permission object and combine them into single DatabasePermissionSet object' {
                $databasePermissions = & (Get-Module -Name $script:moduleName) {
                    @(
                        [DatabasePermission] @{
                            State      = 'Grant'
                            Permission = @('Connect')
                        },
                        [DatabasePermission] @{
                            State      = 'Grant'
                            Permission = @('Select', 'Update')
                        }
                    )
                }

                $result = $databasePermissions | ConvertFrom-SqlDscDatabasePermission -ErrorAction 'Stop'

                # The command combines all permissions into a single DatabasePermissionSet
                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]

                # All permissions from both objects should be set to true
                $result.Connect | Should -BeTrue
                $result.Select | Should -BeTrue
                $result.Update | Should -BeTrue
                $result.Insert | Should -BeFalse
                $result.Delete | Should -BeFalse
            }
            }
        }

        Context 'When converting with empty permission array' {
            It 'Should return a DatabasePermissionSet with no permissions set' {
                $databasePermission = & (Get-Module -Name $script:moduleName) {
                    [DatabasePermission] @{
                        State      = 'Grant'
                        Permission = @()
                    }
                }

                $result = ConvertFrom-SqlDscDatabasePermission -Permission $databasePermission -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]
                $result.Connect | Should -BeFalse
                $result.Select | Should -BeFalse
                $result.Update | Should -BeFalse
                $result.Insert | Should -BeFalse
                $result.Delete | Should -BeFalse
            }
        }

        Context 'When verifying SMO object compatibility' {
            It 'Should return a DatabasePermissionSet that can be used with SMO database operations' {
                $databasePermission = & (Get-Module -Name $script:moduleName) {
                    [DatabasePermission] @{
                        State      = 'Grant'
                        Permission = @('Connect', 'Select')
                    }
                }

                $result = ConvertFrom-SqlDscDatabasePermission -Permission $databasePermission -ErrorAction 'Stop'

                # Verify the result has the expected SMO properties
                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DatabasePermissionSet]

                # Verify it has the correct SMO properties and methods available
                $result | Get-Member -Name 'Connect' -MemberType Property | Should -Not -BeNullOrEmpty
                $result | Get-Member -Name 'Select' -MemberType Property | Should -Not -BeNullOrEmpty
                $result | Get-Member -Name 'ToString' -MemberType Method | Should -Not -BeNullOrEmpty

                # Verify ToString() method works
                $result.ToString() | Should -Not -BeNullOrEmpty
            }
        }
    }
}
