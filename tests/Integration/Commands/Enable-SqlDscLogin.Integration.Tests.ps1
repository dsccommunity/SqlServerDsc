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

Describe 'Enable-SqlDscLogin' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential

        # Use existing persistent login for testing
        $script:testLoginName = 'IntegrationTestSqlLogin'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When enabling a login using ServerObject parameter set' {
        BeforeEach {
            # Ensure the login is disabled before each test
            $testLogin = $script:serverObject.Logins[$script:testLoginName]
            if ($testLogin.IsDisabled -eq $false)
            {
                Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force
            }
        }

        It 'Should enable the specified login' {
            # Verify login is initially disabled
            $loginBefore = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginBefore.IsDisabled | Should -BeTrue

            # Enable the login
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force

            # Verify login is now enabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeFalse
        }

        It 'Should enable the login with Refresh parameter' {
            # Enable with Refresh parameter
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh -Force

            # Verify login is enabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeFalse
        }

        It 'Should accept ServerObject from pipeline' {
            # Enable using pipeline
            $script:serverObject | Enable-SqlDscLogin -Name $script:testLoginName -Force

            # Verify login is enabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeFalse
        }
    }

    Context 'When enabling a login using LoginObject parameter set' {
        BeforeEach {
            # Ensure the login is disabled before each test
            $testLogin = $script:serverObject.Logins[$script:testLoginName]
            if ($testLogin.IsDisabled -eq $false)
            {
                Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force
            }
        }

        It 'Should enable the specified login object' {
            # Get the login object and enable it
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            Enable-SqlDscLogin -LoginObject $loginObject -Force

            # Verify login is enabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeFalse
        }

        It 'Should accept LoginObject from pipeline' {
            # Enable using pipeline
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginObject | Enable-SqlDscLogin -Force

            # Verify login is enabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeFalse
        }
    }

    Context 'When enabling a non-existent login' {
        It 'Should throw an error for non-existent login' {
            { Enable-SqlDscLogin -ServerObject $script:serverObject -Name 'NonExistentLogin' -Force -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage 'There is no login with the name ''NonExistentLogin''.'
        }
    }
}
