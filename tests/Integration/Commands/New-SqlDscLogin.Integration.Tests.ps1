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

Describe 'New-SqlDscLogin' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:instanceName = 'DSCSQLTEST'
        $script:computerName = Get-ComputerName

        # Test login names - prefixed to avoid conflicts
        $script:testSqlLoginName = 'IntegrationTestSqlLogin'
        $script:testWindowsUserName = '{0}\SqlIntegrationTest' -f $script:computerName
        $script:testWindowsGroupName = 'NT AUTHORITY\SYSTEM'
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
                { New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testSqlLoginName -SqlLogin -SecurePassword $script:testPassword -Confirm:$false } | Should -Not -Throw
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
                    { New-SqlDscLogin -ServerObject $script:serverObject -Name $customLoginName -SqlLogin -SecurePassword $script:testPassword -DefaultDatabase 'tempdb' -Confirm:$false } | Should -Not -Throw

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
                    $result = New-SqlDscLogin -ServerObject $script:serverObject -Name $passthroughLoginName -SqlLogin -SecurePassword $script:testPassword -PassThru -Confirm:$false

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
                    { New-SqlDscLogin -ServerObject $script:serverObject -Name $disabledLoginName -SqlLogin -SecurePassword $script:testPassword -Disabled -Confirm:$false } | Should -Not -Throw

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

            It 'Should throw an error when trying to create a login that already exists' {
                { New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testSqlLoginName -SqlLogin -SecurePassword $script:testPassword -Confirm:$false } | Should -Throw -ExpectedMessage "*The login '$script:testSqlLoginName' already exists on the instance '$($script:serverObject.InstanceName)'*"
            }
        }

        Context 'When creating a Windows user login' {
            It 'Should create a Windows user login without error' {
                $windowsLoginName = 'IntegrationTestWindowsUser'
                $fullWindowsLoginName = '{0}\{1}' -f $script:computerName, $windowsLoginName

                try
                {
                    # Using the SqlIntegrationTest user created by Prerequisites integration test
                    { New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsUserName -WindowsUser -Confirm:$false } | Should -Not -Throw

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
                try
                {
                    { New-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName -WindowsGroup -Confirm:$false } | Should -Not -Throw

                    Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName | Should -BeTrue

                    $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName
                    $loginObject.LoginType | Should -Be 'WindowsGroup'
                }
                finally
                {
                    # Clean up
                    if (Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $script:testWindowsGroupName)
                    {
                        $script:serverObject.Logins[$script:testWindowsGroupName].Drop()
                    }
                }
            }
        }

        Context 'When using Force parameter' {
            It 'Should create a login with Force parameter without confirmation prompt' {
                $forceLoginName = 'IntegrationTestForce'

                try
                {
                    { New-SqlDscLogin -ServerObject $script:serverObject -Name $forceLoginName -SqlLogin -SecurePassword $script:testPassword -Force } | Should -Not -Throw

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

        Context 'When testing ShouldProcess functionality' {
            It 'Should not create a login when using WhatIf' {
                $whatIfLoginName = 'IntegrationTestWhatIf'

                { New-SqlDscLogin -ServerObject $script:serverObject -Name $whatIfLoginName -SqlLogin -SecurePassword $script:testPassword -WhatIf } | Should -Not -Throw

                Test-SqlDscIsLogin -ServerObject $script:serverObject -Name $whatIfLoginName | Should -BeFalse
            }
        }
    }
}
