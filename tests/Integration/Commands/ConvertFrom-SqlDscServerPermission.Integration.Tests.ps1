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

# NOTE: This integration test focuses on validating the ConvertFrom-SqlDscServerPermission command
# in a realistic environment. Since this is a conversion utility that doesn't directly interact
# with SQL Server, it tests the command's functionality with real ServerPermission objects
# rather than requiring SQL Server connectivity.
Describe 'ConvertFrom-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'When converting ServerPermission objects in integration environment' {
        It 'Should convert single permission correctly' {
            # Use the module scope to create ServerPermission object properly
            $serverPermission = & (Get-Module -Name $script:moduleName) {
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
            }

            $result = ConvertFrom-SqlDscServerPermission -Permission $serverPermission -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
            $result.ConnectSql | Should -BeTrue
            $result.ViewServerState | Should -BeFalse
        }

        It 'Should convert multiple permissions correctly' {
            $serverPermission = & (Get-Module -Name $script:moduleName) {
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql', 'ViewServerState', 'AlterAnyLogin')
                }
            }

            $result = ConvertFrom-SqlDscServerPermission -Permission $serverPermission -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
            $result.ConnectSql | Should -BeTrue
            $result.ViewServerState | Should -BeTrue
            $result.AlterAnyLogin | Should -BeTrue
            $result.ControlServer | Should -BeFalse
        }

        It 'Should convert permission using pipeline input' {
            $serverPermission = & (Get-Module -Name $script:moduleName) {
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ViewAnyDatabase', 'CreateAnyDatabase')
                }
            }

            $result = $serverPermission | ConvertFrom-SqlDscServerPermission -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
            $result.ViewAnyDatabase | Should -BeTrue
            $result.CreateAnyDatabase | Should -BeTrue
            $result.ConnectSql | Should -BeFalse
        }

        It 'Should convert permissions correctly regardless of state' {
            # Test with GrantWithGrant state
            $serverPermission = & (Get-Module -Name $script:moduleName) {
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @('AlterSettings', 'CreateEndpoint')
                }
            }

            $result = ConvertFrom-SqlDscServerPermission -Permission $serverPermission -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
            $result.AlterSettings | Should -BeTrue
            $result.CreateEndpoint | Should -BeTrue
            $result.ConnectSql | Should -BeFalse
        }

        It 'Should handle empty permission array correctly' {
            $serverPermission = & (Get-Module -Name $script:moduleName) {
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @()
                }
            }

            $result = ConvertFrom-SqlDscServerPermission -Permission $serverPermission -ErrorAction 'Stop'

            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]
            $result.ConnectSql | Should -BeFalse
            $result.ViewServerState | Should -BeFalse
            $result.ControlServer | Should -BeFalse
        }

        It 'Should convert multiple ServerPermission objects through pipeline into single combined set' {
            $serverPermissions = & (Get-Module -Name $script:moduleName) {
                @(
                    [ServerPermission] @{
                        State = 'Grant'
                        Permission = @('ConnectSql')
                    },
                    [ServerPermission] @{
                        State = 'Deny'
                        Permission = @('ViewServerState', 'AlterTrace')
                    }
                )
            }

            $result = $serverPermissions | ConvertFrom-SqlDscServerPermission -ErrorAction 'Stop'

            # The command combines all permissions into a single ServerPermissionSet
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]

            # All permissions from both objects should be set to true
            $result.ConnectSql | Should -BeTrue
            $result.ViewServerState | Should -BeTrue
            $result.AlterTrace | Should -BeTrue
        }

        It 'Should create compatible ServerPermissionSet for SQL Server permission operations' {
            # Test with realistic permissions commonly used in SQL Server administration
            $serverPermission = & (Get-Module -Name $script:moduleName) {
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql', 'ViewServerState', 'CreateAnyDatabase', 'AlterAnyLogin')
                }
            }

            $result = ConvertFrom-SqlDscServerPermission -Permission $serverPermission -ErrorAction 'Stop'

            # Verify this creates a valid ServerPermissionSet that could be used with SQL Server SMO
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]

            # Verify all specified permissions are set to true
            $result.ConnectSql | Should -BeTrue
            $result.ViewServerState | Should -BeTrue
            $result.CreateAnyDatabase | Should -BeTrue
            $result.AlterAnyLogin | Should -BeTrue

            # Verify unspecified permissions remain false
            $result.ControlServer | Should -BeFalse
            $result.Shutdown | Should -BeFalse
            $result.ViewAnyDefinition | Should -BeFalse
        }
    }
}
