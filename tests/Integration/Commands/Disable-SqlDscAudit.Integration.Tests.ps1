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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

Describe 'Disable-SqlDscAudit' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When disabling an audit using ServerObject parameter set' {
        BeforeEach {
            # Create and enable a test audit for each test
            $script:testAuditName = 'SqlDscTestDisableAudit_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -Force -ErrorAction 'Stop'
            $null = Enable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction 'Stop'
        }

        AfterEach {
            # Clean up: Disable and remove the test audit if it still exists
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
            if ($existingAudit)
            {
                # Disable the audit first if it's enabled (required before removal)
                if ($existingAudit.Enabled)
                {
                    $null = Disable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction 'SilentlyContinue'
                }
                $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should disable an enabled audit successfully' {
            # Verify audit exists and is enabled before disabling
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'Stop'
            $existingAudit | Should -Not -BeNullOrEmpty
            $existingAudit.Enabled | Should -BeTrue

            # Disable the audit
            $null = Disable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction 'Stop'

            # Verify audit is now disabled
            $disabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'Stop'
            $disabledAudit | Should -Not -BeNullOrEmpty
            $disabledAudit.Enabled | Should -BeFalse
        }

        It 'Should throw error when trying to disable non-existent audit' {
            { Disable-SqlDscAudit -ServerObject $script:serverObject -Name 'NonExistentAudit' -Force -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should support the Refresh parameter' {
            # Verify audit exists and is enabled before disabling
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'Stop'
            $existingAudit | Should -Not -BeNullOrEmpty
            $existingAudit.Enabled | Should -BeTrue

            # Disable the audit with Refresh parameter
            $null = Disable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Refresh -Force -ErrorAction 'Stop'

            # Verify audit is now disabled
            $disabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'Stop'
            $disabledAudit | Should -Not -BeNullOrEmpty
            $disabledAudit.Enabled | Should -BeFalse
        }
    }

    Context 'When disabling an audit using AuditObject parameter set' {
        BeforeEach {
            # Create and enable a test audit for each test
            $script:testAuditNameForObject = 'SqlDscTestDisableAuditObj_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -LogType 'ApplicationLog' -Force -ErrorAction 'Stop'
            $null = Enable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -Force -ErrorAction 'Stop'
        }

        AfterEach {
            # Clean up: Disable and remove the test audit if it still exists
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction 'SilentlyContinue'
            if ($existingAudit)
            {
                # Disable the audit first if it's enabled (required before removal)
                if ($existingAudit.Enabled)
                {
                    $null = Disable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -Force -ErrorAction 'SilentlyContinue'
                }
                $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should disable an audit using audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction 'Stop'
            $auditObject | Should -Not -BeNullOrEmpty
            $auditObject.Enabled | Should -BeTrue

            # Disable the audit using audit object
            $null = Disable-SqlDscAudit -AuditObject $auditObject -Force -ErrorAction 'Stop'

            # Verify audit is now disabled
            $disabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction 'Stop'
            $disabledAudit | Should -Not -BeNullOrEmpty
            $disabledAudit.Enabled | Should -BeFalse
        }

        It 'Should support pipeline input with audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction 'Stop'
            $auditObject | Should -Not -BeNullOrEmpty
            $auditObject.Enabled | Should -BeTrue

            # Disable the audit using pipeline
            $auditObject | Disable-SqlDscAudit -Force -ErrorAction 'Stop'

            # Verify audit is now disabled
            $disabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction 'Stop'
            $disabledAudit | Should -Not -BeNullOrEmpty
            $disabledAudit.Enabled | Should -BeFalse
        }
    }

    Context 'When disabling an audit using ServerObject parameter set with pipeline' {
        BeforeEach {
            # Create and enable a test audit for each test
            $script:testAuditNameForPipeline = 'SqlDscTestDisableAuditPipe_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -LogType 'ApplicationLog' -Force -ErrorAction 'Stop'
            $null = Enable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -Force -ErrorAction 'Stop'
        }

        AfterEach {
            # Clean up: Disable and remove the test audit if it still exists
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction 'SilentlyContinue'
            if ($existingAudit)
            {
                # Disable the audit first if it's enabled (required before removal)
                if ($existingAudit.Enabled)
                {
                    $null = Disable-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -Force -ErrorAction 'SilentlyContinue'
                }
                $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should support pipeline input with server object' {
            # Verify audit exists and is enabled before disabling
            $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction 'Stop'
            $existingAudit | Should -Not -BeNullOrEmpty
            $existingAudit.Enabled | Should -BeTrue

            # Disable the audit using pipeline with server object
            $script:serverObject | Disable-SqlDscAudit -Name $script:testAuditNameForPipeline -Force -ErrorAction 'Stop'

            # Verify audit is now disabled
            $disabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction 'Stop'
            $disabledAudit | Should -Not -BeNullOrEmpty
            $disabledAudit.Enabled | Should -BeFalse
        }
    }

    Context 'When disabling multiple audits' {
        BeforeAll {
            # Create and enable multiple test audits
            $script:testAuditNames = @(
                'SqlDscTestMultiDisable1_' + (Get-Random),
                'SqlDscTestMultiDisable2_' + (Get-Random)
            )

            foreach ($auditName in $script:testAuditNames)
            {
                $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -LogType 'ApplicationLog' -Force -ErrorAction 'Stop'
                $null = Enable-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction 'Stop'
            }
        }

        AfterAll {
            # Clean up: Disable and remove all test audits
            foreach ($auditName in $script:testAuditNames)
            {
                $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction 'SilentlyContinue'
                if ($existingAudit)
                {
                    # Disable the audit first if it's enabled (required before removal)
                    if ($existingAudit.Enabled)
                    {
                        $null = Disable-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction 'SilentlyContinue'
                    }
                    $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction 'SilentlyContinue'
                }
            }
        }

        It 'Should disable multiple audits successfully' {
            # Verify audits exist and are enabled before disabling
            foreach ($auditName in $script:testAuditNames)
            {
                $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction 'Stop'
                $existingAudit | Should -Not -BeNullOrEmpty
                $existingAudit.Enabled | Should -BeTrue
            }

            # Disable the audits
            foreach ($auditName in $script:testAuditNames)
            {
                $null = Disable-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction 'Stop'
            }

            # Verify audits are now disabled
            foreach ($auditName in $script:testAuditNames)
            {
                $disabledAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction 'Stop'
                $disabledAudit | Should -Not -BeNullOrEmpty
                $disabledAudit.Enabled | Should -BeFalse
            }
        }
    }
}
