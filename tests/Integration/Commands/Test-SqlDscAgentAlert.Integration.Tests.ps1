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

Describe 'Test-SqlDscAgentAlert' -Tag 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022' {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $script:mockSqlAdminCredential

        # Create test alerts for testing
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity 16 -ErrorAction Stop
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId 50001 -ErrorAction Stop
    }

    AfterAll {
        # Clean up test alerts
        $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Force -ErrorAction 'SilentlyContinue'
        $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -Force -ErrorAction 'SilentlyContinue'

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When checking existence only' {
        It 'Should return true for existing alert' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert'

            $result | Should -BeTrue
        }

        It 'Should return false for non-existent alert' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'NonExistentAlert'

            $result | Should -BeFalse
        }
    }

    Context 'When checking severity' {
        It 'Should return true for matching severity' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity 16

            $result | Should -BeTrue
        }

        It 'Should return false for non-matching severity' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity 14

            $result | Should -BeFalse
        }
    }

    Context 'When checking message ID' {
        It 'Should return true for matching message ID' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId 50001

            $result | Should -BeTrue
        }

        It 'Should return false for non-matching message ID' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -MessageId 50002

            $result | Should -BeFalse
        }
    }

    Context 'When both Severity and MessageId are specified' {
        It 'Should throw error for both Severity and MessageId parameters' {
            { $script:sqlServerObject | Test-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -Severity 16 -MessageId 50001 } |
                Should -Throw
        }
    }
}
