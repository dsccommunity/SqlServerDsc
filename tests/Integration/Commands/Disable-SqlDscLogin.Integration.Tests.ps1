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

Describe 'Disable-SqlDscLogin' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
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
        $script:testLoginName = 'TestLogin_Disable'
        $testLoginPassword = ConvertTo-SecureString -String 'P@ssw0rd123!' -AsPlainText -Force
        
        # Create the login if it doesn't exist
        $existingLogin = $script:serverObject.Logins[$script:testLoginName]
        if (-not $existingLogin)
        {
            $newLogin = [Microsoft.SqlServer.Management.Smo.Login]::new($script:serverObject, $script:testLoginName)
            $newLogin.LoginType = 'SqlLogin'
            $newLogin.Create($testLoginPassword)
        }

        # Ensure the login is initially enabled for testing
        $testLogin = $script:serverObject.Logins[$script:testLoginName]
        if ($testLogin.IsDisabled -eq $true)
        {
            $testLogin.Enable()
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

    Context 'When disabling a login using ServerObject parameter set' {
        It 'Should disable the specified login' {
            # Verify login is initially enabled
            $loginBefore = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginBefore.IsDisabled | Should -BeFalse

            # Disable the login
            Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Verify login is now disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }

        It 'Should disable the login with Refresh parameter' {
            # First enable the login
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Disable with Refresh parameter
            Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh -Force

            # Verify login is disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }

        It 'Should accept ServerObject from pipeline' {
            # First enable the login
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Disable using pipeline
            $script:serverObject | Disable-SqlDscLogin -Name $script:testLoginName -Force

            # Verify login is disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }
    }

    Context 'When disabling a login using LoginObject parameter set' {
        It 'Should disable the specified login object' {
            # First enable the login
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Get the login object and disable it
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            Disable-SqlDscLogin -LoginObject $loginObject -Force

            # Verify login is disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }

        It 'Should accept LoginObject from pipeline' {
            # First enable the login
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Disable using pipeline
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginObject | Disable-SqlDscLogin -Force

            # Verify login is disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }
    }

    Context 'When disabling a non-existent login' {
        It 'Should throw an error for non-existent login' {
            { Disable-SqlDscLogin -ServerObject $script:serverObject -Name 'NonExistentLogin' -Force -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage 'There is no login with the name ''NonExistentLogin''.'
        }
    }
}