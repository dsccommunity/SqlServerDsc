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

Describe 'Set-SqlDscAudit' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction Stop
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When modifying an audit using ServerObject parameter set' {
        BeforeEach {
            # Create a test audit for each test
            $script:testAuditName = 'SqlDscTestSetAudit_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -Force -ErrorAction Stop
        }

        AfterEach {
            # Clean up the test audit
            Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should modify audit QueueDelay property successfully' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $originalQueueDelay = $originalAudit.QueueDelay
            $newQueueDelay = 5000

            # Modify the audit
            $null = Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -QueueDelay $newQueueDelay -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $modifiedAudit.QueueDelay | Should -Be $newQueueDelay
            $modifiedAudit.QueueDelay | Should -Not -Be $originalQueueDelay
        }

        It 'Should modify audit OnFailure property successfully' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $originalOnFailure = $originalAudit.OnFailure
            $newOnFailure = 'FailOperation'

            # Modify the audit
            $null = Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -OnFailure $newOnFailure -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $modifiedAudit.OnFailure | Should -Be $newOnFailure
            $modifiedAudit.OnFailure | Should -Not -Be $originalOnFailure
        }

        It 'Should modify audit AuditFilter property successfully' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $newAuditFilter = "([server_principal_name] like '%test%')"

            # Modify the audit
            $null = Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -AuditFilter $newAuditFilter -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $modifiedAudit.Filter | Should -Be $newAuditFilter
        }

        It 'Should modify audit AuditGuid property when AllowAuditGuidChange is specified' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $originalGuid = $originalAudit.Guid
            $newGuid = [System.Guid]::NewGuid().ToString()

            # Modify the audit with AllowAuditGuidChange parameter
            $null = Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -AuditGuid $newGuid -AllowAuditGuidChange -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $modifiedAudit.Guid | Should -Be $newGuid
            $modifiedAudit.Guid | Should -Not -Be $originalGuid
        }

        It 'Should throw an error when trying to change AuditGuid without AllowAuditGuidChange parameter' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $newGuid = [System.Guid]::NewGuid().ToString()

            # Attempt to modify the audit GUID without AllowAuditGuidChange should throw an error
            { Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -AuditGuid $newGuid -Force -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*AllowAuditGuidChange*'
        }

        It 'Should support multiple property modifications in one call' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $newQueueDelay = 3000
            $newOnFailure = 'FailOperation'
            $newAuditFilter = "([server_principal_name] like '%integration%')"

            # Modify multiple properties
            $null = Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -QueueDelay $newQueueDelay -OnFailure $newOnFailure -AuditFilter $newAuditFilter -Force -ErrorAction Stop

            # Verify all properties were modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $modifiedAudit.QueueDelay | Should -Be $newQueueDelay
            $modifiedAudit.OnFailure | Should -Be $newOnFailure
            $modifiedAudit.Filter | Should -Be $newAuditFilter
        }

        It 'Should support the Refresh parameter' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $newQueueDelay = 4000

            # Modify the audit with Refresh parameter
            $null = Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -QueueDelay $newQueueDelay -Refresh -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $modifiedAudit.QueueDelay | Should -Be $newQueueDelay
        }

        It 'Should support the PassThru parameter' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $newQueueDelay = 6000

            # Modify the audit with PassThru parameter
            $result = Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -QueueDelay $newQueueDelay -PassThru -Force -ErrorAction Stop

            # Verify PassThru returns the audit object
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
            $result.Name | Should -Be $script:testAuditName
            $result.QueueDelay | Should -Be $newQueueDelay
        }

        It 'Should throw error when trying to modify non-existent audit' {
            { Set-SqlDscAudit -ServerObject $script:serverObject -Name 'NonExistentAudit' -QueueDelay 5000 -Force -ErrorAction Stop } |
                Should -Throw
        }
    }

    Context 'When modifying an audit using AuditObject parameter set' {
        BeforeEach {
            # Create a test audit for each test
            $script:testAuditNameForObject = 'SqlDscTestSetAuditObj_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -LogType 'ApplicationLog' -Force -ErrorAction Stop
        }

        AfterEach {
            # Clean up the test audit
            Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should modify audit using audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $auditObject | Should -Not -BeNullOrEmpty

            $originalQueueDelay = $auditObject.QueueDelay
            $newQueueDelay = 7000

            # Modify the audit using audit object
            $null = Set-SqlDscAudit -AuditObject $auditObject -QueueDelay $newQueueDelay -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $modifiedAudit.QueueDelay | Should -Be $newQueueDelay
            $modifiedAudit.QueueDelay | Should -Not -Be $originalQueueDelay
        }

        It 'Should support pipeline input with audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $auditObject | Should -Not -BeNullOrEmpty

            $originalQueueDelay = $auditObject.QueueDelay
            $newQueueDelay = 8000

            # Modify the audit using pipeline
            $auditObject | Set-SqlDscAudit -QueueDelay $newQueueDelay -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $modifiedAudit.QueueDelay | Should -Be $newQueueDelay
            $modifiedAudit.QueueDelay | Should -Not -Be $originalQueueDelay
        }

        It 'Should support PassThru with audit object' {
            $auditObject = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForObject -ErrorAction Stop
            $auditObject | Should -Not -BeNullOrEmpty

            $newQueueDelay = 9000

            # Modify the audit using audit object with PassThru
            $result = Set-SqlDscAudit -AuditObject $auditObject -QueueDelay $newQueueDelay -PassThru -Force -ErrorAction Stop

            # Verify PassThru returns the audit object
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
            $result.Name | Should -Be $script:testAuditNameForObject
            $result.QueueDelay | Should -Be $newQueueDelay
        }
    }

    Context 'When modifying an audit using ServerObject parameter set with pipeline' {
        BeforeEach {
            # Create a test audit for each test
            $script:testAuditNameForPipeline = 'SqlDscTestSetAuditPipe_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -LogType 'ApplicationLog' -Force -ErrorAction Stop
        }

        AfterEach {
            # Clean up the test audit
            Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -Force -ErrorAction 'SilentlyContinue'
        }

        It 'Should support pipeline input with server object' {
            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty

            $originalQueueDelay = $originalAudit.QueueDelay
            $newQueueDelay = 10000

            # Modify the audit using pipeline with server object
            $script:serverObject | Set-SqlDscAudit -Name $script:testAuditNameForPipeline -QueueDelay $newQueueDelay -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditNameForPipeline -ErrorAction Stop
            $modifiedAudit.QueueDelay | Should -Be $newQueueDelay
            $modifiedAudit.QueueDelay | Should -Not -Be $originalQueueDelay
        }
    }

    Context 'When modifying file audit properties' {
        BeforeAll {
            # Use a path that SQL Server service can access (under SQL Server shared directory)
            $script:tempAuditPath = 'C:\Program Files\Microsoft SQL Server\TestAudits'
            if (-not (Test-Path -Path $script:tempAuditPath))
            {
                New-Item -Path $script:tempAuditPath -ItemType Directory -Force | Out-Null
            }
        }

        BeforeEach {
            # Create a test file audit for each test
            $script:testFileAuditName = 'SqlDscTestFileAudit_' + (Get-Random)
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testFileAuditName -Path $script:tempAuditPath -Force -ErrorAction Stop
        }

        AfterEach {
            # Clean up the test audit
            Remove-SqlDscAudit -ServerObject $script:serverObject -Name $script:testFileAuditName -Force -ErrorAction 'SilentlyContinue'
        }

        AfterAll {
            # Clean up the temporary directory
            if (Test-Path -Path $script:tempAuditPath)
            {
                Remove-Item -Path $script:tempAuditPath -Recurse -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should modify file audit Path property successfully' {
            # Create another directory for the new path under SQL Server directory
            $newTempPath = 'C:\Program Files\Microsoft SQL Server\TestAudits2'
            if (-not (Test-Path -Path $newTempPath))
            {
                New-Item -Path $newTempPath -ItemType Directory -Force | Out-Null
            }

            # Verify audit exists before modification
            $originalAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testFileAuditName -ErrorAction Stop
            $originalAudit | Should -Not -BeNullOrEmpty
            $originalAudit.DestinationType | Should -Be 'File'

            $originalPath = $originalAudit.FilePath

            # Modify the audit path
            $null = Set-SqlDscAudit -ServerObject $script:serverObject -Name $script:testFileAuditName -Path $newTempPath -Force -ErrorAction Stop

            # Verify audit was modified
            $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testFileAuditName -ErrorAction Stop
            $modifiedAudit.FilePath | Should -Be $newTempPath
            $modifiedAudit.FilePath | Should -Not -Be $originalPath

            # Clean up the new temp directory
            if (Test-Path -Path $newTempPath)
            {
                Remove-Item -Path $newTempPath -Recurse -Force -ErrorAction 'SilentlyContinue'
            }
        }
    }

    Context 'When modifying multiple audits sequentially' {
        BeforeAll {
            # Create multiple test audits
            $script:testAuditNames = @(
                'SqlDscTestMultiSet1_' + (Get-Random),
                'SqlDscTestMultiSet2_' + (Get-Random)
            )

            foreach ($auditName in $script:testAuditNames)
            {
                $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -LogType 'ApplicationLog' -Force -ErrorAction Stop
            }
        }

        AfterAll {
            # Clean up all test audits
            foreach ($auditName in $script:testAuditNames)
            {
                Remove-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should modify multiple audits successfully' {
            $newQueueDelay = 11000

            # Verify audits exist before modification
            foreach ($auditName in $script:testAuditNames)
            {
                $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction Stop
                $existingAudit | Should -Not -BeNullOrEmpty
            }

            # Modify the audits
            foreach ($auditName in $script:testAuditNames)
            {
                $null = Set-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -QueueDelay $newQueueDelay -Force -ErrorAction Stop
            }

            # Verify audits were modified
            foreach ($auditName in $script:testAuditNames)
            {
                $modifiedAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction Stop
                $modifiedAudit.QueueDelay | Should -Be $newQueueDelay
            }
        }
    }
}
