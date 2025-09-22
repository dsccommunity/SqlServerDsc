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

Describe 'Test-SqlDscAgentAlertProperty' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022'){
    BeforeAll {
        # Integration tests are run on the DSCSQLTEST instance
        $script:sqlServerInstance = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

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
    }

    Context 'When checking severity' {
        It 'Should return true for matching severity' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlertProperty -Name 'IntegrationTest_SeverityAlert' -Severity 16 -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false for non-matching severity' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlertProperty -Name 'IntegrationTest_SeverityAlert' -Severity 14 -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }

    Context 'When checking message ID' {
        It 'Should return true for matching message ID' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlertProperty -Name 'IntegrationTest_MessageIdAlert' -MessageId 50001 -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false for non-matching message ID' {
            $result = $script:sqlServerObject | Test-SqlDscAgentAlertProperty -Name 'IntegrationTest_MessageIdAlert' -MessageId 50002 -ErrorAction 'Stop'

            $result | Should -BeFalse
        }
    }

    Context 'When alert does not exist' {
        It 'Should throw an exception for non-existent alert with severity' {
            {
                $null = $script:sqlServerObject |
                    Test-SqlDscAgentAlertProperty -Name 'NonExistentAlert' -Severity 16 -ErrorAction 'Stop'
            } | Should -Throw
        }

        It 'Should throw an exception for non-existent alert with message ID' {
            {
                $null = $script:sqlServerObject |
                    Test-SqlDscAgentAlertProperty -Name 'NonExistentAlert' -MessageId 50001 -ErrorAction 'Stop'
            } | Should -Throw
        }
    }

    Context 'When no properties are specified' {
        It 'Should throw error when no property parameters are specified' {
            { $script:sqlServerObject | Test-SqlDscAgentAlertProperty -Name 'IntegrationTest_SeverityAlert' -ErrorAction 'Stop' } |
                Should -Throw
        }
    }

    Context 'When using AlertObject parameter' {
        It 'Should return true when alert object has matching severity' {
            $alertObject = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -ErrorAction 'Stop'
            $result = $alertObject | Test-SqlDscAgentAlertProperty -Severity 16 -ErrorAction 'Stop'

            $result | Should -BeTrue
        }

        It 'Should return false when alert object has non-matching severity' {
            $alertObject = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_SeverityAlert' -ErrorAction 'Stop'
            $result = $alertObject | Test-SqlDscAgentAlertProperty -Severity 14 -ErrorAction 'Stop'

            $result | Should -BeFalse
        }

        It 'Should return true when alert object has matching message ID' {
            $alertObject = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_MessageIdAlert' -ErrorAction 'Stop'
            $result = $alertObject | Test-SqlDscAgentAlertProperty -MessageId 50001 -ErrorAction 'Stop'

            $result | Should -BeTrue
        }
    }

    Context 'When both Severity and MessageId are specified' {
        It 'Should throw error for both Severity and MessageId parameters' {
            { $script:sqlServerObject | Test-SqlDscAgentAlertProperty -Name 'IntegrationTest_SeverityAlert' -Severity 16 -MessageId 50001 -ErrorAction 'Stop' } |
                Should -Throw
        }
    }
}
