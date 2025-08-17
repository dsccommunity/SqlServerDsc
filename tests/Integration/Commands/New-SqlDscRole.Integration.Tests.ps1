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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName
}

Describe 'New-SqlDscRole' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Test role names that will be created and cleaned up
        $script:testRoleName = 'TestRole_' + (Get-Random)
        $script:testRoleNameWithOwner = 'TestRoleOwner_' + (Get-Random)
    }

    AfterAll {
        # Clean up any test roles that might have been created
        try 
        {
            $existingRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -ErrorAction 'SilentlyContinue'
            if ($existingRole) 
            {
                Remove-SqlDscRole -RoleObject $existingRole -Force
            }

            $existingRoleWithOwner = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameWithOwner -ErrorAction 'SilentlyContinue'
            if ($existingRoleWithOwner) 
            {
                Remove-SqlDscRole -RoleObject $existingRoleWithOwner -Force
            }
        }
        catch 
        {
            # Ignore cleanup errors
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When creating a new SQL Server role' {
        It 'Should create a role and return a ServerRole object' {
            $result = New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:testRoleName
            $result.IsFixedRole | Should -BeFalse

            # Verify the role exists in the server
            $verifyRole = Get-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName
            $verifyRole | Should -Not -BeNullOrEmpty
            $verifyRole.Name | Should -Be $script:testRoleName
        }

        It 'Should create a role with a specified owner' {
            $result = New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleNameWithOwner -Owner 'sa' -Force

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
            $result.Name | Should -Be $script:testRoleNameWithOwner
            $result.Owner | Should -Be 'sa'
            $result.IsFixedRole | Should -BeFalse
        }

        It 'Should throw an error when creating a role that already exists' {
            # First, create the role
            New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -Force

            # Then try to create it again, should fail
            { New-SqlDscRole -ServerObject $script:serverObject -Name $script:testRoleName -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            $uniqueRoleName = 'PipelineTestRole_' + (Get-Random)
            
            try 
            {
                $result = $script:serverObject | New-SqlDscRole -Name $uniqueRoleName -Force

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.ServerRole'
                $result.Name | Should -Be $uniqueRoleName
            }
            finally 
            {
                # Clean up
                try 
                {
                    $roleToCleanup = Get-SqlDscRole -ServerObject $script:serverObject -Name $uniqueRoleName -ErrorAction 'SilentlyContinue'
                    if ($roleToCleanup) 
                    {
                        Remove-SqlDscRole -RoleObject $roleToCleanup -Force
                    }
                }
                catch 
                {
                    # Ignore cleanup errors
                }
            }
        }
    }
}