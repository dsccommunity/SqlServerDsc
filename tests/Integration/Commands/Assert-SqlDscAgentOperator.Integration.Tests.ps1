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

    $env:SqlServerDscCI = $true

    # Integration tests are run on the DSCSQLTEST instance
    $script:sqlServerInstance = 'DSCSQLTEST'
}

AfterAll {
    $env:SqlServerDscCI = $null

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Assert-SqlDscAgentOperator' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Create a test operator for assertion tests
        $script:sqlServerObject | New-SqlDscAgentOperator -Name 'IntegrationTest_AssertOperator' -EmailAddress 'assert@contoso.com' -ErrorAction Stop
    }

    AfterAll {
        $script:sqlServerObject | Remove-SqlDscAgentOperator -Name 'IntegrationTest_AssertOperator' -Force -ErrorAction 'SilentlyContinue'

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When operator exists' {
        It 'Should not throw when asserting existing operator' {
            { Assert-SqlDscAgentOperator -ServerObject $script:sqlServerObject -Name 'IntegrationTest_AssertOperator' -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should not throw when asserting persistent operator created by New-SqlDscAgentOperator' {
            { Assert-SqlDscAgentOperator -ServerObject $script:sqlServerObject -Name 'SqlDscIntegrationTestOperator_Persistent' -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should not return anything when operator exists' {
            $result = Assert-SqlDscAgentOperator -ServerObject $script:sqlServerObject -Name 'IntegrationTest_AssertOperator' -ErrorAction Stop
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When operator does not exist' {
        It 'Should throw terminating error when operator does not exist' {
            { Assert-SqlDscAgentOperator -ServerObject $script:sqlServerObject -Name 'NonExistentOperator' -ErrorAction Stop } | Should -Throw
        }

        It 'Should throw with specific error category when operator does not exist' {
            try
            {
                Assert-SqlDscAgentOperator -ServerObject $script:sqlServerObject -Name 'NonExistentOperator' -ErrorAction Stop
                # Should not reach this line
                $false | Should -Be $true
            }
            catch
            {
                $_.CategoryInfo.Category | Should -Be 'ObjectNotFound'
                $_.FullyQualifiedErrorId | Should -Match 'GAOO0001'
            }
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            { $script:sqlServerObject | Assert-SqlDscAgentOperator -Name 'IntegrationTest_AssertOperator' -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
