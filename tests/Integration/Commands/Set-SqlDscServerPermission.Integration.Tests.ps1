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

Describe 'Set-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Use existing persistent principals created by earlier integration tests
        $script:testLoginName = 'IntegrationTestSqlLogin'
        $script:testRoleName = 'SqlDscIntegrationTestRole_Persistent'
    }

    AfterAll {
        # Restore the expected state for shared test login that other tests depend on
        $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

        # Revoke any permissions we may have set
        Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
        Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
        Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
        Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'

        # Restore the expected permissions that other tests depend on
        # Based on Grant test setup and Test command ExactMatch test expectations
        Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ConnectSql', 'ViewServerState') -Force -ErrorAction 'SilentlyContinue'
        Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewAnyDefinition') -Force -ErrorAction 'SilentlyContinue'

        # Restore the CreateEndpoint permission on the persistent role that other tests depend on
        $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
        Grant-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'CreateEndpoint' -Force -ErrorAction 'SilentlyContinue'

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When setting exact permissions for a login' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Clean up any existing permissions
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should set exact Grant permissions' {
            Set-SqlDscServerPermission -Login $script:loginObject -Grant 'ViewServerState', 'ViewAnyDatabase' -Force -ErrorAction 'Stop'

            # Verify the permissions were granted
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewServerState', 'ViewAnyDatabase' -ExactMatch -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set exact GrantWithGrant permissions' {
            Set-SqlDscServerPermission -Login $script:loginObject -GrantWithGrant 'CreateAnyDatabase' -Force -ErrorAction 'Stop'

            # Verify the permission was granted with grant option
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'CreateAnyDatabase' -WithGrant -ExactMatch -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set exact Deny permissions' {
            Set-SqlDscServerPermission -Login $script:loginObject -Deny 'ViewAnyDefinition' -Force -ErrorAction 'Stop'

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Deny -Permission 'ViewAnyDefinition' -ExactMatch -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set combined Grant, GrantWithGrant, and Deny permissions' {
            $setPermissionParams = @{
                Login          = $script:loginObject
                Grant          = 'ViewServerState'
                GrantWithGrant = 'CreateAnyDatabase'
                Deny           = 'ViewAnyDefinition'
                Force          = $true
                ErrorAction    = 'Stop'
            }

            Set-SqlDscServerPermission @setPermissionParams

            # Verify Grant permission
            $grantResult = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $grantResult | Should -BeTrue

            # Verify GrantWithGrant permission
            $grantWithGrantResult = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'CreateAnyDatabase' -WithGrant -ErrorAction 'Stop'
            $grantWithGrantResult | Should -BeTrue

            # Verify Deny permission
            $denyResult = Test-SqlDscServerPermission -Login $script:loginObject -Deny -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $denyResult | Should -BeTrue
        }
    }

    Context 'When revoking permissions by setting empty arrays' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Clean up any existing permissions before each test
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should revoke all Grant permissions when empty Grant array is specified' {
            # Set up known Grant permissions to revoke
            Grant-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState', 'ViewAnyDatabase' -Force -ErrorAction 'Stop'

            Set-SqlDscServerPermission -Login $script:loginObject -Grant @() -Force -ErrorAction 'Stop'

            # Verify the permissions were revoked
            $result1 = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $result1 | Should -BeFalse

            $result2 = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewAnyDatabase' -ErrorAction 'Stop'
            $result2 | Should -BeFalse
        }

        It 'Should revoke all GrantWithGrant permissions when empty GrantWithGrant array is specified' {
            # Set up known GrantWithGrant permissions to revoke
            Grant-SqlDscServerPermission -Login $script:loginObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'Stop'

            Set-SqlDscServerPermission -Login $script:loginObject -GrantWithGrant @() -Force -ErrorAction 'Stop'

            # Verify the permission was revoked
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'CreateAnyDatabase' -WithGrant -ErrorAction 'Stop'
            $result | Should -BeFalse
        }

        It 'Should revoke all Deny permissions when empty Deny array is specified' {
            # Set up known Deny permissions to revoke
            Deny-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'Stop'

            Set-SqlDscServerPermission -Login $script:loginObject -Deny @() -Force -ErrorAction 'Stop'

            # Verify the permission was revoked
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Deny -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $result | Should -BeFalse
        }

        It 'Should only affect Grant permissions when empty Grant array is specified with existing GrantWithGrant and Deny' {
            # Set up permissions in all categories
            Grant-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'Stop'
            Grant-SqlDscServerPermission -Login $script:loginObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'Stop'
            Deny-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'Stop'

            # Revoke only Grant permissions
            Set-SqlDscServerPermission -Login $script:loginObject -Grant @() -Force -ErrorAction 'Stop'

            # Verify Grant permission was revoked
            $grantResult = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $grantResult | Should -BeFalse

            # Verify GrantWithGrant permission still exists
            $grantWithGrantResult = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'CreateAnyDatabase' -WithGrant -ErrorAction 'Stop'
            $grantWithGrantResult | Should -BeTrue

            # Verify Deny permission still exists
            $denyResult = Test-SqlDscServerPermission -Login $script:loginObject -Deny -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $denyResult | Should -BeTrue
        }
    }

    Context 'When replacing existing permissions with new ones' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Set up initial permissions
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'

            Grant-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState', 'ViewAnyDatabase' -Force -ErrorAction 'Stop'
        }

        It 'Should replace existing permissions with new specified permissions' {
            # Change from ViewServerState,ViewAnyDatabase to ViewAnyDefinition
            Set-SqlDscServerPermission -Login $script:loginObject -Grant 'ViewAnyDefinition' -Force -ErrorAction 'Stop'

            # Verify old permissions were revoked
            $result1 = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $result1 | Should -BeFalse

            $result2 = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewAnyDatabase' -ErrorAction 'Stop'
            $result2 | Should -BeFalse

            # Verify new permission was granted
            $result3 = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $result3 | Should -BeTrue
        }
    }

    Context 'When using pipeline input' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Clean up
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should accept Login object from pipeline' {
            $script:loginObject | Set-SqlDscServerPermission -Grant 'ViewServerState' -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }

    Context 'When setting exact permissions for a server role' {
        BeforeEach {
            # Get the role object for testing
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            # Clean up any existing permissions
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        AfterAll {
            # Clean up role permissions
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should set exact Grant permissions for role' {
            Set-SqlDscServerPermission -ServerRole $script:roleObject -Grant 'ViewServerState', 'ViewAnyDatabase' -Force -ErrorAction 'Stop'

            # Verify the permissions were granted
            $result = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewServerState', 'ViewAnyDatabase' -ExactMatch -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set exact GrantWithGrant permissions for role' {
            Set-SqlDscServerPermission -ServerRole $script:roleObject -GrantWithGrant 'CreateAnyDatabase' -Force -ErrorAction 'Stop'

            # Verify the permission was granted with grant option
            $result = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'CreateAnyDatabase' -WithGrant -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set exact Deny permissions for role' {
            Set-SqlDscServerPermission -ServerRole $script:roleObject -Deny 'ViewAnyDefinition' -Force -ErrorAction 'Stop'

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -ServerRole $script:roleObject -Deny -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set combined Grant, GrantWithGrant, and Deny permissions for role' {
            $setPermissionParams = @{
                ServerRole     = $script:roleObject
                Grant          = 'ViewServerState'
                GrantWithGrant = 'CreateAnyDatabase'
                Deny           = 'ViewAnyDefinition'
                Force          = $true
                ErrorAction    = 'Stop'
            }

            Set-SqlDscServerPermission @setPermissionParams

            # Verify Grant permission
            $grantResult = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $grantResult | Should -BeTrue

            # Verify GrantWithGrant permission
            $grantWithGrantResult = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'CreateAnyDatabase' -WithGrant -ErrorAction 'Stop'
            $grantWithGrantResult | Should -BeTrue

            # Verify Deny permission
            $denyResult = Test-SqlDscServerPermission -ServerRole $script:roleObject -Deny -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $denyResult | Should -BeTrue
        }
    }

    Context 'When revoking permissions for a server role by setting empty arrays' {
        BeforeEach {
            # Get the role object for testing
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            # Clean up any existing permissions before each test
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        AfterAll {
            # Clean up role permissions
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should revoke all Grant permissions for role when empty Grant array is specified' {
            # Set up known Grant permissions to revoke
            Grant-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState', 'ViewAnyDatabase' -Force -ErrorAction 'Stop'

            Set-SqlDscServerPermission -ServerRole $script:roleObject -Grant @() -Force -ErrorAction 'Stop'

            # Verify the permissions were revoked
            $result1 = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $result1 | Should -BeFalse

            $result2 = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewAnyDatabase' -ErrorAction 'Stop'
            $result2 | Should -BeFalse
        }

        It 'Should revoke all GrantWithGrant permissions for role when empty GrantWithGrant array is specified' {
            # Set up known GrantWithGrant permissions to revoke
            Grant-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'Stop'

            Set-SqlDscServerPermission -ServerRole $script:roleObject -GrantWithGrant @() -Force -ErrorAction 'Stop'

            # Verify the permission was revoked
            $result = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'CreateAnyDatabase' -WithGrant -ErrorAction 'Stop'
            $result | Should -BeFalse
        }

        It 'Should revoke all Deny permissions for role when empty Deny array is specified' {
            # Set up known Deny permissions to revoke
            Deny-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'Stop'

            Set-SqlDscServerPermission -ServerRole $script:roleObject -Deny @() -Force -ErrorAction 'Stop'

            # Verify the permission was revoked
            $result = Test-SqlDscServerPermission -ServerRole $script:roleObject -Deny -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $result | Should -BeFalse
        }

        It 'Should only affect Grant permissions for role when empty Grant array is specified with existing GrantWithGrant and Deny' {
            # Set up permissions in all categories
            Grant-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'Stop'
            Grant-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'Stop'
            Deny-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'Stop'

            # Revoke only Grant permissions
            Set-SqlDscServerPermission -ServerRole $script:roleObject -Grant @() -Force -ErrorAction 'Stop'

            # Verify Grant permission was revoked
            $grantResult = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $grantResult | Should -BeFalse

            # Verify GrantWithGrant permission still exists
            $grantWithGrantResult = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'CreateAnyDatabase' -WithGrant -ErrorAction 'Stop'
            $grantWithGrantResult | Should -BeTrue

            # Verify Deny permission still exists
            $denyResult = Test-SqlDscServerPermission -ServerRole $script:roleObject -Deny -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $denyResult | Should -BeTrue
        }
    }

    Context 'When replacing existing permissions with new ones for a server role' {
        BeforeEach {
            # Get the role object for testing
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            # Set up initial permissions
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'

            Grant-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState', 'ViewAnyDatabase' -Force -ErrorAction 'Stop'
        }

        AfterAll {
            # Clean up role permissions
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should replace existing permissions with new specified permissions for role' {
            # Change from ViewServerState,ViewAnyDatabase to ViewAnyDefinition
            Set-SqlDscServerPermission -ServerRole $script:roleObject -Grant 'ViewAnyDefinition' -Force -ErrorAction 'Stop'

            # Verify old permissions were revoked
            $result1 = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $result1 | Should -BeFalse

            $result2 = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewAnyDatabase' -ErrorAction 'Stop'
            $result2 | Should -BeFalse

            # Verify new permission was granted
            $result3 = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewAnyDefinition' -ErrorAction 'Stop'
            $result3 | Should -BeTrue
        }
    }

    Context 'When using pipeline input for a server role' {
        BeforeEach {
            # Get the role object for testing
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            # Clean up
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
        }

        AfterAll {
            # Clean up role permissions
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should accept ServerRole object from pipeline' {
            $script:roleObject | Set-SqlDscServerPermission -Grant 'ViewServerState' -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $result = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission 'ViewServerState' -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }

    Context 'When specifying invalid permission values' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'
        }

        It 'Should throw when specifying an invalid permission name' {
            {
                Set-SqlDscServerPermission -Login $script:loginObject -Grant 'InvalidPermissionName' -Force -ErrorAction 'Stop'
            } | Should -Throw
        }
    }

    Context 'When specifying a non-existent principal' {
        It 'Should throw when using a login object that no longer exists' {
            # Create a temporary login
            $tempLoginName = 'TempLoginForErrorTest'
            $mockPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

            New-SqlDscLogin -ServerObject $script:serverObject -Name $tempLoginName -SqlLogin -SecurePassword $mockPassword -Force -ErrorAction 'Stop'

            $tempLoginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $tempLoginName -ErrorAction 'Stop'

            # Remove the login
            Remove-SqlDscLogin -LoginObject $tempLoginObject -Force -ErrorAction 'Stop'

            # Attempt to set permissions on the removed login should throw
            {
                Set-SqlDscServerPermission -Login $tempLoginObject -Grant 'ViewServerState' -Force -ErrorAction 'Stop'
            } | Should -Throw
        }

        It 'Should throw when using a server role object that no longer exists' {
            # Create a temporary role
            $tempRoleName = 'TempRoleForErrorTest'

            New-SqlDscRole -ServerObject $script:serverObject -Name $tempRoleName -Force -ErrorAction 'Stop'

            $tempRoleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $tempRoleName -ErrorAction 'Stop'

            # Remove the role
            Remove-SqlDscRole -RoleObject $tempRoleObject -Force -ErrorAction 'Stop'

            # Attempt to set permissions on the removed role should throw
            {
                Set-SqlDscServerPermission -ServerRole $tempRoleObject -Grant 'ViewServerState' -Force -ErrorAction 'Stop'
            } | Should -Throw
        }
    }
}
