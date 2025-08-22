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

Describe 'New-SqlDscLogin' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:instanceName = 'DSCSQLTEST'
        $script:computerName = Get-ComputerName

        # Test login names - prefixed to avoid conflicts
        $script:testSqlLoginName = 'IntegrationTestSqlLogin'
        $script:testWindowsUserName = '{0}\SqlIntegrationTest' -f $script:computerName
        $script:testWindowsGroupName = '{0}\SqlIntegrationTestGroup' -f $script:computerName
    }

    AfterAll {
        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When connecting to SQL Server instance' {
        BeforeAll {
            $sqlAdministratorUserName = 'SqlAdmin'
            $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

            $script:sqlAdminCredential = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)

            $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:instanceName -Credential $script:sqlAdminCredential
        }

        AfterAll {
            # Disconnect from SQL Server
            if ($script:serverObject)
            {
                Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
            }
        }

        Context 'When creating a SQL Server login' {
            BeforeAll {
                $script:testPassword = ConvertTo-SecureString -String 'P@ssw0rd123!' -AsPlainText -Force
            }

            It 'Should create a SQL Server login without error' {
                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testSqlLoginName -SqlLogin -SecurePassword $script:testPassword -Force
            }

            It 'Should verify the SQL Server login was created' {
                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testSqlLoginName | Should -BeTrue
            }

            It 'Should verify the login type is SqlLogin' {
                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testSqlLoginName
                $loginObject.LoginType | Should -Be 'SqlLogin'
            }

            It 'Should verify the default database is set correctly' {
                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testSqlLoginName
                $loginObject.DefaultDatabase | Should -Be 'master'
            }

            It 'Should create a SQL Server login with custom default database' {
                $customLoginName = 'IntegrationTestCustomDb'

                try
                {
                    $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $customLoginName -SqlLogin -SecurePassword $script:testPassword -DefaultDatabase 'tempdb' -Force

                    $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $customLoginName
                    $loginObject.DefaultDatabase | Should -Be 'tempdb'
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $customLoginName)
                    {
                        $script:serverObject.Logins[$customLoginName].Drop()
                    }
                }
            }

            It 'Should create a SQL Server login with PassThru parameter' {
                $passthroughLoginName = 'IntegrationTestPassThru'

                try
                {
                    $result = New-SqlDscLogin -ServerObject $script:serverObject -Name $passthroughLoginName -SqlLogin -SecurePassword $script:testPassword -PassThru -Force

                    $result | Should -Not -BeNullOrEmpty
                    $result.Name | Should -Be $passthroughLoginName
                    $result.LoginType | Should -Be 'SqlLogin'
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $passthroughLoginName)
                    {
                        $script:serverObject.Logins[$passthroughLoginName].Drop()
                    }
                }
            }

            It 'Should create a disabled SQL Server login' {
                $disabledLoginName = 'IntegrationTestDisabled'

                try
                {
                    $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $disabledLoginName -SqlLogin -SecurePassword $script:testPassword -Disabled -Force

                    $loginObject = $script:serverObject.Logins[$disabledLoginName]
                    $loginObject.IsDisabled | Should -BeTrue
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $disabledLoginName)
                    {
                        $script:serverObject.Logins[$disabledLoginName].Drop()
                    }
                }
            }

            It 'Should create a disabled login and then enable it using Enable-SqlDscLogin' {
                $disableEnableLoginName = 'IntegrationTestDisableEnable'

                try
                {
                    # Create a disabled login
                    $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $disableEnableLoginName -SqlLogin -SecurePassword $script:testPassword -Disabled -Force

                    # Verify it is disabled using Test-SqlDscIsLoginEnabled
                    Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $disableEnableLoginName | Should -BeFalse

                    # Enable the login using Enable-SqlDscLogin
                    Enable-SqlDscLogin -ServerObject $script:serverObject -Name $disableEnableLoginName -Force

                    # Verify it is now enabled
                    Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $disableEnableLoginName | Should -BeTrue
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $disableEnableLoginName)
                    {
                        $script:serverObject.Logins[$disableEnableLoginName].Drop()
                    }
                }
            }

            It 'Should create an enabled login and then disable it using Disable-SqlDscLogin' {
                $enableDisableLoginName = 'IntegrationTestEnableDisable'

                try
                {
                    # Create an enabled login (default)
                    $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $enableDisableLoginName -SqlLogin -SecurePassword $script:testPassword -Force

                    # Verify it is enabled using Test-SqlDscIsLoginEnabled
                    Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $enableDisableLoginName | Should -BeTrue

                    # Disable the login using Disable-SqlDscLogin
                    Disable-SqlDscLogin -ServerObject $script:serverObject -Name $enableDisableLoginName -Force

                    # Verify it is now disabled
                    Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $enableDisableLoginName | Should -BeFalse
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $enableDisableLoginName)
                    {
                        $script:serverObject.Logins[$enableDisableLoginName].Drop()
                    }
                }
            }

            It 'Should demonstrate login state management workflow using login objects' {
                $workflowLoginName = 'IntegrationTestWorkflow'

                try
                {
                    # Create an enabled login
                    $loginObject = New-SqlDscLogin -ServerObject $script:serverObject -Name $workflowLoginName -SqlLogin -SecurePassword $script:testPassword -PassThru -Force

                    # Verify initial state is enabled
                    Test-SqlDscIsLoginEnabled -LoginObject $loginObject | Should -BeTrue

                    # Disable using login object
                    Disable-SqlDscLogin -LoginObject $loginObject -Force

                    # Verify it is disabled using login object
                    Test-SqlDscIsLoginEnabled -LoginObject $loginObject | Should -BeFalse

                    # Re-enable using login object
                    Enable-SqlDscLogin -LoginObject $loginObject -Force

                    # Verify it is enabled again
                    Test-SqlDscIsLoginEnabled -LoginObject $loginObject | Should -BeTrue
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $workflowLoginName)
                    {
                        $script:serverObject.Logins[$workflowLoginName].Drop()
                    }
                }
            }

            It 'Should throw an error when trying to create a login that already exists' {
                { New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testSqlLoginName -SqlLogin -SecurePassword $script:testPassword -Force } | Should -Throw
            }
        }

        Context 'When creating a Windows user login' {
            It 'Should create a Windows user login without error' {
                try
                {
                    # Using the SqlIntegrationTest user created by Prerequisites integration test
                    $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName -WindowsUser -Force

                    Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName | Should -BeTrue

                    $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName
                    $loginObject.LoginType | Should -Be 'WindowsUser'
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName)
                    {
                        $script:serverObject.Logins[$script:testWindowsUserName].Drop()
                    }
                }
            }
        }

        Context 'When creating a Windows group login' {
            It 'Should create a Windows group login without error' {
                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName -WindowsGroup -Force

                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName | Should -BeTrue

                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName
                $loginObject.LoginType | Should -Be 'WindowsGroup'
            }
        }

        Context 'When using Force parameter' {
            It 'Should create a login with Force parameter without confirmation prompt' {
                $forceLoginName = 'IntegrationTestForce'

                try
                {
                    $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $forceLoginName -SqlLogin -SecurePassword $script:testPassword -Force

                    Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $forceLoginName | Should -BeTrue
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $forceLoginName)
                    {
                        $script:serverObject.Logins[$forceLoginName].Drop()
                    }
                }
            }
        }

        Context 'When running with WhatIf' {
            It 'Should not create a login' {
                $whatIfLoginName = 'IntegrationTestWhatIf'

                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $whatIfLoginName -SqlLogin -SecurePassword $script:testPassword -WhatIf

                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $whatIfLoginName | Should -BeFalse
            }
        }

        Context 'When demonstrating comprehensive login state management integration' {
            It 'Should manage complete login lifecycle with multiple commands' {
                $lifecycleLoginName = 'IntegrationTestLifecycle'

                try
                {
                    # Step 1: Create a new login
                    $loginObject = New-SqlDscLogin -ServerObject $script:serverObject -Name $lifecycleLoginName -SqlLogin -SecurePassword $script:testPassword -PassThru -Force

                    # Step 2: Verify it exists and is enabled by default
                    Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $lifecycleLoginName | Should -BeTrue
                    Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $lifecycleLoginName | Should -BeTrue

                    # Step 3: Disable the login
                    Disable-SqlDscLogin -ServerObject $script:serverObject -Name $lifecycleLoginName -Force

                    # Step 4: Verify it is disabled
                    Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $lifecycleLoginName | Should -BeFalse

                    # Step 5: Re-enable the login
                    Enable-SqlDscLogin -ServerObject $script:serverObject -Name $lifecycleLoginName -Force

                    # Step 6: Verify it is enabled again
                    Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $lifecycleLoginName | Should -BeTrue

                    # Step 7: Get the login object for final verification
                    $retrievedLogin = Get-SqlDscLogin -ServerObject $script:serverObject -Name $lifecycleLoginName
                    $retrievedLogin.Name | Should -Be $lifecycleLoginName
                    $retrievedLogin.LoginType | Should -Be 'SqlLogin'
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $lifecycleLoginName)
                    {
                        $script:serverObject.Logins[$lifecycleLoginName].Drop()
                    }
                }
            }
        }
    }
}
