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
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Remove-SqlDscAudit' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction Stop
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When removing an audit using ServerObject parameter set' {
        BeforeEach {
            # Create a test audit for each test
            $script:testAuditName = 'SqlDscTestRemoveAudit_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -Force -ErrorAction Stop
        }

        It 'Should remove an audit successfully' {
            # Verify audit exists before removal
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $existingAudit | Should -Not -BeNullOrEmpty

            # Remove the audit
            $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction Stop

            # Verify audit no longer exists
            $removedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
            $removedAudit | Should -BeNullOrEmpty
        }

        It 'Should throw error when trying to remove non-existent audit' {
            { Remove-SqlDscAudit -ServerObject $script:serverObject -Name 'NonExistentAudit' -Force -ErrorAction Stop } |
                Should -Throw
        }

        It 'Should support the Refresh parameter' {
            # Verify audit exists before removal
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $existingAudit | Should -Not -BeNullOrEmpty

            # Remove the audit with Refresh parameter
            $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Refresh -Force -ErrorAction Stop

            # Verify audit no longer exists
            $removedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
            $removedAudit | Should -BeNullOrEmpty
        }
    }

    Context 'When removing an audit using AuditObject parameter set' {
        BeforeEach {
            # Create a test audit for each test
            $script:testAuditNameForObject = 'SqlDscTestRemoveAuditObj_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -LogType 'ApplicationLog' -Force -ErrorAction Stop
        }

        It 'Should remove an audit using audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $auditObject | Should -Not -BeNullOrEmpty

            # Remove the audit using audit object
            $null = Remove-SqlDscAudit -AuditObject $auditObject -Force -ErrorAction Stop

            # Verify audit no longer exists
            $removedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction 'SilentlyContinue'
            $removedAudit | Should -BeNullOrEmpty
        }

        It 'Should support pipeline input with audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $auditObject | Should -Not -BeNullOrEmpty

            # Remove the audit using pipeline
            $auditObject | Remove-SqlDscAudit -Force -ErrorAction Stop

            # Verify audit no longer exists
            $removedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction 'SilentlyContinue'
            $removedAudit | Should -BeNullOrEmpty
        }
    }

    Context 'When removing an audit using ServerObject parameter set with pipeline' {
        BeforeEach {
            # Create a test audit for each test
            $script:testAuditNameForPipeline = 'SqlDscTestRemoveAuditPipe_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -LogType 'ApplicationLog' -Force -ErrorAction Stop
        }

        It 'Should support pipeline input with server object' {
            # Verify audit exists before removal
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction Stop
            $existingAudit | Should -Not -BeNullOrEmpty

            # Remove the audit using pipeline with server object
            $script:serverObject | Remove-SqlDscAudit -Name $script:testAuditNameForPipeline -Force -ErrorAction Stop

            # Verify audit no longer exists
            $removedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction 'SilentlyContinue'
            $removedAudit | Should -BeNullOrEmpty
        }
    }

    Context 'When removing multiple audits' {
        BeforeAll {
            # Create multiple test audits
            $script:testAuditNames = @(
                'SqlDscTestMultiRemove1_' + (Get-Random),
                'SqlDscTestMultiRemove2_' + (Get-Random)
            )
            
            foreach ($auditName in $script:testAuditNames)
            {
                $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -LogType 'ApplicationLog' -Force -ErrorAction Stop
            }
        }

        It 'Should remove multiple audits successfully' {
            # Verify audits exist before removal
            foreach ($auditName in $script:testAuditNames)
            {
                $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction Stop
                $existingAudit | Should -Not -BeNullOrEmpty
            }

            # Remove the audits
            foreach ($auditName in $script:testAuditNames)
            {
                $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction Stop
            }

            # Verify audits no longer exist
            foreach ($auditName in $script:testAuditNames)
            {
                $removedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction 'SilentlyContinue'
                $removedAudit | Should -BeNullOrEmpty
            }
        }
    }
}