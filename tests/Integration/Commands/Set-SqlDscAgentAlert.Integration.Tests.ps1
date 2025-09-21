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

Describe 'Set-SqlDscAgentAlert' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Integration tests are run on the DSCSQLTEST instance
        $script:sqlServerInstance = 'DSCSQLTEST'

        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Create a test alert for updating
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity 14 -ErrorAction Stop
    }

    AfterAll {
        $null = $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Force -ErrorAction 'SilentlyContinue'

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    It 'Should update alert severity using ServerObject parameter set' {
        $null = $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity 16 -ErrorAction 'Stop' -Force

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert'
        $alert.Severity | Should -Be 16
        $alert.MessageId | Should -Be 0
    }

    It 'Should update alert message ID using ServerObject parameter set' {
                # Add SQL Server system message for testing message ID alerts
        $addMessageQuery = @'
IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = 50003 AND language_id = 1033)
BEGIN
    EXECUTE sp_addmessage
        50003,
        16,
        N'Mock message 50003';
END
'@
        $script:sqlServerObject | Invoke-SqlDscQuery -DatabaseName 'master' -Query $addMessageQuery -Verbose -Force -ErrorAction 'Stop'


        $null = $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -MessageId 50003 -ErrorAction 'Stop' -Force

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert'
        $alert.MessageId | Should -Be 50003
        $alert.Severity | Should -Be 0
    }

    It 'Should update alert using AlertObject parameter set' {
        # First reset to severity for this test
        $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity 14 -ErrorAction 'Stop' -Force

        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert'

        $null = $alert | Set-SqlDscAgentAlert -Severity 18 -ErrorAction 'Stop' -Force

        # Refresh the alert to get updated values
        $updatedAlert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert'
        $updatedAlert.Severity | Should -Be 18
        $updatedAlert.MessageId | Should -Be 0
    }

    It 'Should return updated alert when PassThru is specified' {
        $result = $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity 20 -PassThru -ErrorAction 'Stop' -Force

        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Be 'IntegrationTest_UpdateAlert'
        $result.Severity | Should -Be 20
    }

    It 'Should throw error when alert does not exist' {
        { $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'NonExistentAlert' -Severity 16 -Force -ErrorAction 'Stop' } |
            Should -Throw
    }

    It 'Should throw error when both Severity and MessageId are specified' {
        { $script:sqlServerObject | Set-SqlDscAgentAlert -Name 'IntegrationTest_UpdateAlert' -Severity 16 -MessageId 50001 -Force -ErrorAction 'Stop' } |
            Should -Throw
    }
}
