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

Describe 'New-SqlDscLogin' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:instanceName = 'DSCSQLTEST'
        $script:computerName = Get-ComputerName

        # Test login names - prefixed to avoid conflicts
        $script:testSqlLoginName = 'IntegrationTestSqlLogin'
        $script:testWindowsUserName = '{0}\SqlIntegrationTest' -f $script:computerName
        $script:testWindowsGroupName = '{0}\SqlIntegrationTestGroup' -f $script:computerName
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

            BeforeEach {
                $script:testLoginName = $null
                $script:isPersistentLogin = $false
            }

            AfterEach {
                # Clean up any login created in the test (but not persistent logins)
                if ($script:testLoginName -and -not $script:isPersistentLogin -and (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName))
                {
                    $script:serverObject.Logins[$script:testLoginName].Drop()
                }
            }

            It 'Should create a SQL Server login and verify it was created with correct properties' {
                $script:testLoginName = $script:testSqlLoginName
                $script:isPersistentLogin = $true  # This is a persistent login for other tests

                # Only create if it doesn't already exist
                if (-not (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName))
                {
                    $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -SqlLogin -SecurePassword $script:testPassword -Force
                }

                # Verify the login was created
                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testLoginName | Should -BeTrue

                # Verify the login type
                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
                $loginObject.LoginType | Should -Be 'SqlLogin'

                # Verify the default database
                $loginObject.DefaultDatabase | Should -Be 'master'
            }

            It 'Should create a SQL Server login with custom default database' {
                $script:testLoginName = 'IntegrationTestCustomDb'

                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -SqlLogin -SecurePassword $script:testPassword -DefaultDatabase 'tempdb' -Force

                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
                $loginObject.DefaultDatabase | Should -Be 'tempdb'
            }

            It 'Should create a SQL Server login with PassThru parameter' {
                $script:testLoginName = 'IntegrationTestPassThru'

                $result = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -SqlLogin -SecurePassword $script:testPassword -PassThru -Force

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be $script:testLoginName
                $result.LoginType | Should -Be 'SqlLogin'
            }

            It 'Should create a disabled SQL Server login' {
                $script:testLoginName = 'IntegrationTestDisabled'

                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -SqlLogin -SecurePassword $script:testPassword -Disabled -Force

                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
                $loginObject.IsDisabled | Should -BeTrue
            }

            It 'Should throw an error when trying to create a login that already exists' {
                $script:testLoginName = 'IntegrationTestDuplicate'

                # First create the login
                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -SqlLogin -SecurePassword $script:testPassword -Force

                # Then try to create it again, which should throw
                { New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -SqlLogin -SecurePassword $script:testPassword -Force } | Should -Throw
            }
        }

        Context 'When creating a Windows user login' {
            AfterEach {
                # Clean up Windows user login
                if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName)
                {
                    $script:serverObject.Logins[$script:testWindowsUserName].Drop()
                }
            }

            It 'Should create a Windows user login without error' {
                # Using the SqlIntegrationTest user created by Prerequisites integration test
                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName -WindowsUser -Force

                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName | Should -BeTrue

                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName
                $loginObject.LoginType | Should -Be 'WindowsUser'
            }
        }

        Context 'When creating a Windows group login' {
            It 'Should create a Windows group login without error' {
                # This is a persistent login for other tests
                # Only create if it doesn't already exist
                if (-not (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName))
                {
                    $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName -WindowsGroup -Force
                }

                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName | Should -BeTrue

                $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName
                $loginObject.LoginType | Should -Be 'WindowsGroup'
            }
        }

        Context 'When using Force parameter' {
            BeforeEach {
                $script:forceLoginName = 'IntegrationTestForce'
            }

            AfterEach {
                # Clean up Force test login
                if ($script:forceLoginName -and (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:forceLoginName))
                {
                    $script:serverObject.Logins[$script:forceLoginName].Drop()
                }
            }

            It 'Should create a login with Force parameter without confirmation prompt' {
                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $script:forceLoginName -SqlLogin -SecurePassword $script:testPassword -Force

                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:forceLoginName | Should -BeTrue
            }
        }

        Context 'When running with WhatIf' {
            It 'Should not create a login' {
                $whatIfLoginName = 'IntegrationTestWhatIf'

                $null = New-SqlDscLogin -ServerObject $script:serverObject -Name $whatIfLoginName -SqlLogin -SecurePassword $script:testPassword -WhatIf

                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $whatIfLoginName | Should -BeFalse
            }
        }
    }
}
