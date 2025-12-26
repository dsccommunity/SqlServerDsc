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

Describe 'Remove-SqlDscLogin' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
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

    Context 'When removing a SQL Server login by ServerObject and Name' {
        BeforeAll {
            $script:testLoginName = 'TestRemoveLogin1'
            $script:testLoginPassword = ConvertTo-SecureString -String 'P@ssw0rd1!' -AsPlainText -Force
        }

        It 'Should remove the login when it exists' {
            # Create the test login
            $null = $script:serverObject | New-SqlDscLogin -Name $script:testLoginName -SqlLogin -SecurePassword $script:testLoginPassword -Force

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
            # Ensure the login exists for this scenario (don't rely on other Its)
            $null = $script:serverObject | New-SqlDscLogin -Name $script:testLoginName -SqlLogin -SecurePassword $script:testLoginPassword -Force

            # Use WhatIf - login should not be removed
            $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName -WhatIf

            # Verify the login still exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginExists | Should -BeTrue
        }

        It 'Should throw an error when the login does not exist' {
            # Ensure the login does not exist for this scenario (don't rely on other Its)
            if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName)
            {
                $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName -Force
            }

            # Try to remove a non-existent login
            {
                $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName -Force -ErrorAction 'Stop'
            } | Should -Throw
        }
    }

    Context 'When removing a SQL Server login by LoginObject' {
        BeforeAll {
            $script:testLoginName2 = 'TestRemoveLogin2'
            $script:testLoginPassword2 = ConvertTo-SecureString -String 'P@ssw0rd2!' -AsPlainText -Force
        }

        It 'Should remove the login when passed as LoginObject' {
            # Create the test login
            $null = $script:serverObject | New-SqlDscLogin -Name $script:testLoginName2 -SqlLogin -SecurePassword $script:testLoginPassword2 -Force

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
            # Create the test login
            $null = $script:serverObject | New-SqlDscLogin -Name $script:testLoginName2 -SqlLogin -SecurePassword $script:testLoginPassword2 -Force

            # Verify the login exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName2
            $loginExists | Should -BeTrue

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

        It 'Should work with the Refresh parameter' {
            # Create the test login
            $testLoginPassword3 = ConvertTo-SecureString -String 'P@ssw0rd3!' -AsPlainText -Force
            $null = $script:serverObject | New-SqlDscLogin -Name $script:testLoginName3 -SqlLogin -SecurePassword $testLoginPassword3 -Force

            # Verify the login exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName3
            $loginExists | Should -BeTrue

            # Remove the login with Refresh parameter
            $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName3 -Refresh -Force

            # Verify the login is removed
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName3
            $loginExists | Should -BeFalse
        }
    }

    Context 'When using the KillActiveSessions parameter' {
        BeforeAll {
            $script:testLoginName4 = 'TestRemoveLogin4'
            $script:testLoginPassword4 = ConvertTo-SecureString -String 'P@ssw0rd4!' -AsPlainText -Force
            $script:testCredential4 = [System.Management.Automation.PSCredential]::new($script:testLoginName4, $script:testLoginPassword4)
        }

        AfterEach {
            # Clean up any remaining sessions
            if ($script:activeConnection)
            {
                Disconnect-SqlDscDatabaseEngine -ServerObject $script:activeConnection -ErrorAction 'SilentlyContinue'
                $script:activeConnection = $null
            }

            # Clean up the login if it still exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName4

            if ($loginExists)
            {
                # Use KillActiveSessions to ensure cleanup
                $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName4 -KillActiveSessions -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should remove a login with active sessions when using KillActiveSessions parameter' {
            # Create the test login
            $null = $script:serverObject | New-SqlDscLogin -Name $script:testLoginName4 -SqlLogin -SecurePassword $script:testLoginPassword4 -Force

            # Verify the login exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName4
            $loginExists | Should -BeTrue

            # Connect using the test login to create an active session
            $script:activeConnection = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -LoginType 'SqlLogin' -Credential $script:testCredential4 -ErrorAction 'Stop'

            # Verify there is an active session for this login
            $processes = $script:serverObject.EnumProcesses($script:testLoginName4)
            $processes.Rows.Count | Should -BeGreaterThan 0 -Because 'There should be at least one active session for the login'

            # Remove the login with KillActiveSessions - should succeed
            $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName4 -KillActiveSessions -Force

            # Verify the login is removed
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName4
            $loginExists | Should -BeFalse
        }

        It 'Should fail to remove a login with active sessions when not using KillActiveSessions parameter' {
            # Create the test login
            $null = $script:serverObject | New-SqlDscLogin -Name $script:testLoginName4 -SqlLogin -SecurePassword $script:testLoginPassword4 -Force

            # Verify the login exists
            $loginExists = Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName4
            $loginExists | Should -BeTrue

            # Connect using the test login to create an active session
            $script:activeConnection = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -LoginType 'SqlLogin' -Credential $script:testCredential4 -ErrorAction 'Stop'

            # Verify there is an active session for this login
            $processes = $script:serverObject.EnumProcesses($script:testLoginName4)
            $processes.Rows.Count | Should -BeGreaterThan 0 -Because 'There should be at least one active session for the login'

            # Try to remove the login without KillActiveSessions - should fail
            { $script:serverObject | Remove-SqlDscLogin -Name $script:testLoginName4 -Force -ErrorAction 'Stop' } | Should -Throw
        }
    }
}
