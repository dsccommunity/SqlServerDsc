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

Describe 'Test-SqlDscIsLoginEnabled' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Create a test login for testing
        $script:testLoginName = 'TestLogin_IsEnabled'
        $testLoginPassword = ConvertTo-SecureString -String 'P@ssw0rd123!' -AsPlainText -Force
        
        # Create the login if it doesn't exist
        $existingLogin = $script:serverObject.Logins[$script:testLoginName]
        if (-not $existingLogin)
        {
            $newLogin = [Microsoft.SqlServer.Management.Smo.Login]::new($script:serverObject, $script:testLoginName)
            $newLogin.LoginType = 'SqlLogin'
            $newLogin.Create($testLoginPassword)
        }
    }

    AfterAll {
        # Clean up test login
        $testLogin = $script:serverObject.Logins[$script:testLoginName]
        if ($testLogin)
        {
            $testLogin.Drop()
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When testing login state using ServerObject parameter set' {
        It 'Should return True when login is enabled' {
            # Ensure login is enabled
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Test if login is enabled
            $result = Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $script:testLoginName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return False when login is disabled' {
            # Ensure login is disabled
            Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Test if login is enabled
            $result = Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $script:testLoginName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should work with Refresh parameter when login is enabled' {
            # Ensure login is enabled
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Test with Refresh parameter
            $result = Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $script:testLoginName -Refresh

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should work with Refresh parameter when login is disabled' {
            # Ensure login is disabled
            Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Test with Refresh parameter
            $result = Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name $script:testLoginName -Refresh

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should accept ServerObject from pipeline' {
            # Ensure login is enabled
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Test using pipeline
            $result = $script:serverObject | Test-SqlDscIsLoginEnabled -Name $script:testLoginName

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }
    }

    Context 'When testing login state using LoginObject parameter set' {
        It 'Should return True when login object is enabled' {
            # Ensure login is enabled
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Get login object and test
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $result = Test-SqlDscIsLoginEnabled -LoginObject $loginObject

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should return False when login object is disabled' {
            # Ensure login is disabled
            Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Get login object and test
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $result = Test-SqlDscIsLoginEnabled -LoginObject $loginObject

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }

        It 'Should accept LoginObject from pipeline when enabled' {
            # Ensure login is enabled
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Test using pipeline
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $result = $loginObject | Test-SqlDscIsLoginEnabled

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeTrue
        }

        It 'Should accept LoginObject from pipeline when disabled' {
            # Ensure login is disabled
            Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Test using pipeline
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $result = $loginObject | Test-SqlDscIsLoginEnabled

            $result | Should -BeOfType [System.Boolean]
            $result | Should -BeFalse
        }
    }

    Context 'When testing a non-existent login' {
        It 'Should throw an error for non-existent login' {
            { Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name 'NonExistentLogin' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage 'There is no login with the name ''NonExistentLogin''.'
        }
    }

    Context 'When testing built-in logins' {
        It 'Should return correct state for sa login' {
            $result = Test-SqlDscIsLoginEnabled -ServerObject $script:serverObject -Name 'sa'

            $result | Should -BeOfType [System.Boolean]
            # sa login should typically be enabled by default, but we just verify it returns a boolean
            $result | Should -BeIn @($true, $false)
        }
    }
}