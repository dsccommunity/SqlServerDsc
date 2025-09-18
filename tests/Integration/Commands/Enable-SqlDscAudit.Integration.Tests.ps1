[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Using ConvertTo-SecureString with plaintext is allowed in tests.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '', Justification = 'Empty catch blocks are used intentionally for cleanup in test teardown.')]
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

Describe 'Enable-SqlDscAudit' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
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

    Context 'When enabling an audit using ServerObject parameter set' {
        BeforeEach {
            # Create a test audit for each test (disabled by default)
            $script:testAuditName = 'SqlDscTestEnableAudit_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -Force -ErrorAction Stop
            
            # Verify audit is created but disabled
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $auditObject.IsEnabled | Should -BeFalse
        }

        AfterEach {
            # Clean up: disable and remove the test audit
            try {
                $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
                if ($auditObject) {
                    if ($auditObject.IsEnabled) {
                        $auditObject.Disable()
                    }
                    $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction 'SilentlyContinue'
                }
            }
            catch {
                # Ignore cleanup errors
            }
        }

        It 'Should enable an audit successfully' {
            # Enable the audit
            $null = Enable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction Stop

            # Verify audit is now enabled
            $enabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $enabledAudit.IsEnabled | Should -BeTrue
        }

        It 'Should throw error when trying to enable non-existent audit' {
            { Enable-SqlDscAudit -ServerObject $script:serverObject -Name 'NonExistentAudit' -Force -ErrorAction Stop } |
                Should -Throw
        }

        It 'Should support the Refresh parameter' {
            # Enable the audit with Refresh parameter
            $null = Enable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Refresh -Force -ErrorAction Stop

            # Verify audit is now enabled
            $enabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $enabledAudit.IsEnabled | Should -BeTrue
        }

        It 'Should not fail when enabling an already enabled audit' {
            # Enable the audit first time
            $null = Enable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction Stop

            # Verify audit is enabled
            $enabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $enabledAudit.IsEnabled | Should -BeTrue

            # Enable the audit again - should not fail
            { Enable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction Stop } |
                Should -Not -Throw

            # Verify audit is still enabled
            $stillEnabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $stillEnabledAudit.IsEnabled | Should -BeTrue
        }
    }

    Context 'When enabling an audit using AuditObject parameter set' {
        BeforeEach {
            # Create a test audit for each test (disabled by default)
            $script:testAuditNameForObject = 'SqlDscTestEnableAuditObj_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -LogType 'ApplicationLog' -Force -ErrorAction Stop
            
            # Verify audit is created but disabled
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $auditObject.IsEnabled | Should -BeFalse
        }

        AfterEach {
            # Clean up: disable and remove the test audit
            try {
                $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction 'SilentlyContinue'
                if ($auditObject) {
                    if ($auditObject.IsEnabled) {
                        $auditObject.Disable()
                    }
                    $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -Force -ErrorAction 'SilentlyContinue'
                }
            }
            catch {
                # Ignore cleanup errors
            }
        }

        It 'Should enable an audit using audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $auditObject | Should -Not -BeNullOrEmpty
            $auditObject.IsEnabled | Should -BeFalse

            # Enable the audit using audit object
            $null = Enable-SqlDscAudit -AuditObject $auditObject -Force -ErrorAction Stop

            # Verify audit is now enabled
            $enabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $enabledAudit.IsEnabled | Should -BeTrue
        }

        It 'Should support pipeline input with audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $auditObject | Should -Not -BeNullOrEmpty
            $auditObject.IsEnabled | Should -BeFalse

            # Enable the audit using pipeline
            $auditObject | Enable-SqlDscAudit -Force -ErrorAction Stop

            # Verify audit is now enabled
            $enabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $enabledAudit.IsEnabled | Should -BeTrue
        }
    }

    Context 'When enabling an audit using ServerObject parameter set with pipeline' {
        BeforeEach {
            # Create a test audit for each test (disabled by default)
            $script:testAuditNameForPipeline = 'SqlDscTestEnableAuditPipe_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -LogType 'ApplicationLog' -Force -ErrorAction Stop
            
            # Verify audit is created but disabled
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction Stop
            $auditObject.IsEnabled | Should -BeFalse
        }

        AfterEach {
            # Clean up: disable and remove the test audit
            try {
                $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction 'SilentlyContinue'
                if ($auditObject) {
                    if ($auditObject.IsEnabled) {
                        $auditObject.Disable()
                    }
                    $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -Force -ErrorAction 'SilentlyContinue'
                }
            }
            catch {
                # Ignore cleanup errors
            }
        }

        It 'Should support pipeline input with server object' {
            # Enable the audit using pipeline with server object
            $script:serverObject | Enable-SqlDscAudit -Name $script:testAuditNameForPipeline -Force -ErrorAction Stop

            # Verify audit is now enabled
            $enabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction Stop
            $enabledAudit.IsEnabled | Should -BeTrue
        }
    }

    Context 'When enabling multiple audits' {
        BeforeAll {
            # Create multiple test audits (disabled by default)
            $script:testAuditNames = @(
                'SqlDscTestMultiEnable1_' + (Get-Random),
                'SqlDscTestMultiEnable2_' + (Get-Random)
            )
            
            foreach ($auditName in $script:testAuditNames)
            {
                $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -LogType 'ApplicationLog' -Force -ErrorAction Stop
                
                # Verify audit is created but disabled
                $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction Stop
                $auditObject.IsEnabled | Should -BeFalse
            }
        }

        AfterAll {
            # Clean up: disable and remove all test audits
            foreach ($auditName in $script:testAuditNames)
            {
                try {
                    $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction 'SilentlyContinue'
                    if ($auditObject) {
                        if ($auditObject.IsEnabled) {
                            $auditObject.Disable()
                        }
                        $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction 'SilentlyContinue'
                    }
                }
                catch {
                    # Ignore cleanup errors
                }
            }
        }

        It 'Should enable multiple audits successfully' {
            # Enable the audits
            foreach ($auditName in $script:testAuditNames)
            {
                $null = Enable-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction Stop
            }

            # Verify audits are now enabled
            foreach ($auditName in $script:testAuditNames)
            {
                $enabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction Stop
                $enabledAudit.IsEnabled | Should -BeTrue
            }
        }
    }
}