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

Describe 'Get-SqlDscAgentAlert' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Integration tests are run on the DSCSQLTEST instance
        $script:sqlServerInstance = 'DSCSQLTEST'

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Connect to the SQL Server instance
        $script:sqlServerObject = Connect-SqlDscDatabaseEngine -InstanceName $script:sqlServerInstance -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Add SQL Server system message for testing message ID alerts
        $addMessageQuery = @'
IF NOT EXISTS (SELECT 1 FROM sys.messages WHERE message_id = 50001 AND language_id = 1033)
BEGIN
    EXECUTE sp_addmessage
        50001,
        16,
        N'Mock message 50001';
END
'@
        $script:sqlServerObject | Invoke-SqlDscQuery -DatabaseName 'master' -Query $addMessageQuery -Verbose -Force -ErrorAction 'Stop'

        # Create test alerts for getting
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert1' -Severity 16 -ErrorAction Stop
        $script:sqlServerObject | New-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert2' -MessageId 50001 -ErrorAction Stop
    }

    AfterAll {
        $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert1' -Force -ErrorAction 'SilentlyContinue'
        $script:sqlServerObject | Remove-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert2' -Force -ErrorAction 'SilentlyContinue'

# TODO: Keep this commented until we have a correct command to remove messages, and we can have another integration tests keeping a persistent message
#         # Remove SQL Server system message
#         $removeMessageQuery = @'
# EXECUTE sp_dropmessage 50001;
# '@
#         $script:sqlServerObject | Invoke-SqlDscQuery -DatabaseName 'master' -Query $removeMessageQuery -Force -ErrorAction 'SilentlyContinue'

        # Disconnect from the SQL Server
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:sqlServerObject
    }

    It 'Should get all alerts' {
        $alerts = $script:sqlServerObject | Get-SqlDscAgentAlert

        $alerts | Should -Not -BeNullOrEmpty
        $alerts | Should -BeOfType [Microsoft.SqlServer.Management.Smo.Agent.Alert]
    }

    It 'Should get specific alert by name' {
        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert1'

        $alert | Should -Not -BeNullOrEmpty
        $alert.Name | Should -Be 'IntegrationTest_GetAlert1'
        $alert.Severity | Should -Be 16
    }

    It 'Should return null for non-existent alert' {
        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'NonExistentAlert'

        $alert | Should -BeNull
    }

    It 'Should get alert with message ID' {
        $alert = $script:sqlServerObject | Get-SqlDscAgentAlert -Name 'IntegrationTest_GetAlert2'

        $alert | Should -Not -BeNullOrEmpty
        $alert.Name | Should -Be 'IntegrationTest_GetAlert2'
        $alert.MessageId | Should -Be 50001
    }
}
