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

    Context 'When disabling a login using ServerObject parameter set' {
        BeforeEach {
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force -ErrorAction 'Stop'
        }

        It 'Should disable the specified login' {
            # Verify login is initially enabled
            $loginBefore = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginBefore.IsDisabled | Should -BeFalse

            # Disable the login
            Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force -ErrorAction 'Stop'

            # Verify login is now disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }

        It 'Should disable the login with Refresh parameter' {
            # Disable with Refresh parameter
            Disable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh -Force -ErrorAction 'Stop'

            # Verify login is disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }

        It 'Should accept ServerObject from pipeline' {
            # Disable using pipeline
            $script:serverObject | Disable-SqlDscLogin -Name $script:testLoginName -Force -ErrorAction 'Stop'

            # Verify login is disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }
    }

    Context 'When disabling a login using LoginObject parameter set' {
        BeforeEach {
            Enable-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Force -ErrorAction 'Stop'
        }

        It 'Should disable the specified login object' {
            # Get the login object and disable it
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            Disable-SqlDscLogin -LoginObject $loginObject -Force -ErrorAction 'Stop'

            # Verify login is disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }

        It 'Should accept LoginObject from pipeline' {
            # Disable using pipeline
            $loginObject = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName
            $loginObject | Disable-SqlDscLogin -Force -ErrorAction 'Stop'

            # Verify login is disabled
            $loginAfter = Get-SqlDscLogin -ServerObject $script:serverObject -Name $script:testLoginName -Refresh
            $loginAfter.IsDisabled | Should -BeTrue
        }
    }

    Context 'When disabling a non-existent login' {
        It 'Should throw an error for non-existent login' {
            { Disable-SqlDscLogin -ServerObject $script:serverObject -Name 'NonExistentLogin' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }
    }
}
