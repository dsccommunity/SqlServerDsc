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

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'
}

Describe 'Remove-SqlDscLogin' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
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

    Context 'When removing a SQL Server login by ServerObject and Name' {
        BeforeAll {
            $script:testLoginName = 'TestRemoveLogin1'
            $script:testLoginPassword = ConvertTo-SecureString -String 'P@ssw0rd1!' -AsPlainText -Force
            $script:testLoginCredential = [System.Management.Automation.PSCredential]::new($script:testLoginName, $script:testLoginPassword)
        }

        BeforeEach {
            # Create the test login
            $createLoginQuery = "CREATE LOGIN [$($script:testLoginName)] WITH PASSWORD = 'P@ssw0rd1!'"
            $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -Query $createLoginQuery
        }

        AfterEach {
            # Clean up - remove the login if it still exists
            try {
                $cleanupQuery = "IF EXISTS (SELECT name FROM sys.server_principals WHERE name = '$($script:testLoginName)') DROP LOGIN [$($script:testLoginName)]"
                $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -Query $cleanupQuery
            }
            catch {
                # Ignore cleanup errors
            }
        }

        It 'Should remove the login when it exists' {
            # Verify the login exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginExists | Should -BeTrue

            # Remove the login
            $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName -Force

            # Verify the login is removed
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginExists | Should -BeFalse
        }

        It 'Should handle WhatIf parameter correctly' {
            # Verify the login exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginExists | Should -BeTrue

            # Use WhatIf - login should not be removed
            $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName -WhatIf

            # Verify the login still exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginExists | Should -BeTrue
        }

        It 'Should throw an error when the login does not exist' {
            # Remove the login first to ensure it doesn't exist
            $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName -Force

            # Try to remove a non-existent login
            {
                $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName -Force -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage "*There is no login with the name '$($script:testLoginName)'*"
        }
    }

    Context 'When removing a SQL Server login by LoginObject' {
        BeforeAll {
            $script:testLoginName2 = 'TestRemoveLogin2'
            $script:testLoginPassword2 = ConvertTo-SecureString -String 'P@ssw0rd2!' -AsPlainText -Force
            $script:testLoginCredential2 = [System.Management.Automation.PSCredential]::new($script:testLoginName2, $script:testLoginPassword2)
        }

        BeforeEach {
            # Create the test login
            $createLoginQuery = "CREATE LOGIN [$($script:testLoginName2)] WITH PASSWORD = 'P@ssw0rd2!'"
            $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -Query $createLoginQuery
        }

        AfterEach {
            # Clean up - remove the login if it still exists
            try {
                $cleanupQuery = "IF EXISTS (SELECT name FROM sys.server_principals WHERE name = '$($script:testLoginName2)') DROP LOGIN [$($script:testLoginName2)]"
                $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -Query $cleanupQuery
            }
            catch {
                # Ignore cleanup errors
            }
        }

        It 'Should remove the login when passed as LoginObject' {
            # Get the login object
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName2

            # Verify the login exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName2
            $loginExists | Should -BeTrue

            # Remove the login using LoginObject
            $loginObject | Remove-SqlDscLogin -Force

            # Verify the login is removed
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName2
            $loginExists | Should -BeFalse
        }

        It 'Should handle pipeline input correctly' {
            # Get the login object and remove it via pipeline
            Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName2 | Remove-SqlDscLogin -Force

            # Verify the login is removed
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName2
            $loginExists | Should -BeFalse
        }
    }

    Context 'When using the Refresh parameter' {
        BeforeAll {
            $script:testLoginName3 = 'TestRemoveLogin3'
        }

        BeforeEach {
            # Create the test login
            $createLoginQuery = "CREATE LOGIN [$($script:testLoginName3)] WITH PASSWORD = 'P@ssw0rd3!'"
            $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -Query $createLoginQuery
        }

        AfterEach {
            # Clean up - remove the login if it still exists
            try {
                $cleanupQuery = "IF EXISTS (SELECT name FROM sys.server_principals WHERE name = '$($script:testLoginName3)') DROP LOGIN [$($script:testLoginName3)]"
                $null = Invoke-SqlDscQuery -ServerObject $script:serverObject -Query $cleanupQuery
            }
            catch {
                # Ignore cleanup errors
            }
        }

        It 'Should work with the Refresh parameter' {
            # Remove the login with Refresh parameter
            $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName3 -Refresh -Force

            # Verify the login is removed
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName3
            $loginExists | Should -BeFalse
        }
    }
}
