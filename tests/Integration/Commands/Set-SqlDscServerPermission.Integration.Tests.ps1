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

Describe 'Set-SqlDscServerPermission' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

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
        Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewServerState') -Force -ErrorAction 'SilentlyContinue'
        Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewAnyDefinition') -Force -ErrorAction 'SilentlyContinue'

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When setting server permissions to Grant state for login' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Clean up any existing permissions
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDatabase' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'CreateAnyDatabase' -WithGrant -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should set ViewServerState permission to Grant state' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewServerState = $true

            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission @('ViewServerState') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set multiple permissions to Grant state' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewServerState = $true
            $permissionSet.ViewAnyDatabase = $true

            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permissions were granted
            $result1 = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission @('ViewServerState') -ErrorAction 'Stop'
            $result1 | Should -BeTrue

            $result2 = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission @('ViewAnyDatabase') -ErrorAction 'Stop'
            $result2 | Should -BeTrue
        }

        It 'Should set permission to Grant state with WithGrant option' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.CreateAnyDatabase = $true

            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -WithGrant -Force -ErrorAction 'Stop'

            # Verify the permission was granted with grant option
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission @('CreateAnyDatabase') -WithGrant -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should accept ServerObject from pipeline' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewAnyDatabase = $true

            $null = $script:serverObject | Set-SqlDscServerPermission -Name $script:testLoginName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission @('ViewAnyDatabase') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }

    Context 'When setting server permissions to Deny state for login' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Clean up any existing permissions
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
            Revoke-SqlDscServerPermission -Login $script:loginObject -Permission 'ViewAnyDefinition' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should set ViewServerState permission to Deny state' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewServerState = $true

            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -State 'Deny' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Deny -Permission @('ViewServerState') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set permission to Deny state and ignore WithGrant parameter' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewAnyDefinition = $true

            # WithGrant should be ignored for Deny state (should show warning)
            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -State 'Deny' -Permission $permissionSet -WithGrant -Force -ErrorAction 'Stop'

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Deny -Permission @('ViewAnyDefinition') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }

    Context 'When setting server permissions to Revoke state for login' {
        BeforeEach {
            # Get the login object for testing
            $script:loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -ErrorAction 'Stop'

            # Set up known permissions to revoke
            $null = Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('ViewServerState') -Force -ErrorAction 'Stop'
            $null = Grant-SqlDscServerPermission -Login $script:loginObject -Permission @('CreateAnyDatabase') -WithGrant -Force -ErrorAction 'Stop'
        }

        It 'Should revoke ViewServerState permission' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewServerState = $true

            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -State 'Revoke' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was revoked
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission @('ViewServerState') -ErrorAction 'Stop'
            $result | Should -BeFalse
        }

        It 'Should revoke permission with WithGrant option (cascade revoke)' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.CreateAnyDatabase = $true

            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testLoginName -State 'Revoke' -Permission $permissionSet -WithGrant -Force -ErrorAction 'Stop'

            # Verify the permission with grant was revoked
            $result = Test-SqlDscServerPermission -Login $script:loginObject -Grant -Permission @('CreateAnyDatabase') -WithGrant -ErrorAction 'Stop'
            $result | Should -BeFalse
        }
    }

    Context 'When setting server permissions for role' {
        BeforeEach {
            # Get the role object for testing
            $script:roleObject = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'Stop'

            # Clean up any existing permissions
            Revoke-SqlDscServerPermission -ServerRole $script:roleObject -Permission 'ViewServerState' -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should set ViewServerState permission to Grant state for role' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewServerState = $true

            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was granted
            $result = Test-SqlDscServerPermission -ServerRole $script:roleObject -Grant -Permission @('ViewServerState') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }

        It 'Should set ViewServerState permission to Deny state for role' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewServerState = $true

            $null = Set-SqlDscServerPermission -ServerObject $script:serverObject -Name $script:testRoleName -State 'Deny' -Permission $permissionSet -Force -ErrorAction 'Stop'

            # Verify the permission was denied
            $result = Test-SqlDscServerPermission -ServerRole $script:roleObject -Deny -Permission @('ViewServerState') -ErrorAction 'Stop'
            $result | Should -BeTrue
        }
    }

    Context 'When attempting to set permissions for non-existent principal' {
        It 'Should throw an error for non-existent principal' {
            $permissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $permissionSet.ViewServerState = $true

            {
                Set-SqlDscServerPermission -ServerObject $script:serverObject -Name 'NonExistentPrincipal' -State 'Grant' -Permission $permissionSet -Force -ErrorAction 'Stop'
            } | Should -Throw
        }
    }
}

