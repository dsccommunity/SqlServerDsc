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

Describe 'New-SqlDscAudit' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction Stop

        # Create a temporary directory for file audits if it doesn't exist
        $script:testAuditPath = Join-Path -Path $env:TEMP -ChildPath 'SqlDscTestAudits'
        if (-not (Test-Path -Path $script:testAuditPath))
        {
            $null = New-Item -Path $script:testAuditPath -ItemType Directory -Force
        }
    }

    AfterAll {
        # Clean up any test audits that might remain
        $testAudits = Get-SqlDscAudit -ServerObject $script:serverObject -ErrorAction 'SilentlyContinue' | 
            Where-Object { $_.Name -like 'SqlDscTestAudit*' }
        
        foreach ($audit in $testAudits)
        {
            try
            {
                Remove-SqlDscAudit -AuditObject $audit -Force -ErrorAction 'SilentlyContinue'
            }
            catch
            {
                # Ignore cleanup errors
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Clean up temporary directory
        if (Test-Path -Path $script:testAuditPath)
        {
            Remove-Item -Path $script:testAuditPath -Recurse -Force -ErrorAction 'SilentlyContinue'
        }

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When creating a new application log audit' {
        BeforeEach {
            $script:testAuditName = 'SqlDscTestAudit_AppLog_' + (Get-Random)
        }

        AfterEach {
            # Clean up the audit created in this test
            $auditToRemove = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
            if ($auditToRemove)
            {
                Remove-SqlDscAudit -AuditObject $auditToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should create an application log audit successfully' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testAuditName
            $result.DestinationType | Should -Be 'ApplicationLog'
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'

            # Verify the audit exists in the server
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit | Should -Not -BeNullOrEmpty
            $createdAudit.Name | Should -Be $script:testAuditName
            $createdAudit.DestinationType | Should -Be 'ApplicationLog'
        }

        It 'Should create a security log audit successfully' {
            $securityLogAuditName = 'SqlDscTestAudit_SecLog_' + (Get-Random)
            
            try
            {
                $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $securityLogAuditName -LogType 'SecurityLog' -PassThru -Force -ErrorAction Stop

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be $securityLogAuditName
                $result.DestinationType | Should -Be 'SecurityLog'

                # Verify the audit exists in the server
                $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $securityLogAuditName -ErrorAction Stop
                $createdAudit | Should -Not -BeNullOrEmpty
                $createdAudit.DestinationType | Should -Be 'SecurityLog'
            }
            finally
            {
                # Clean up
                $auditToRemove = Get-SqlDscAudit -ServerObject $script:serverObject -Name $securityLogAuditName -ErrorAction 'SilentlyContinue'
                if ($auditToRemove)
                {
                    Remove-SqlDscAudit -AuditObject $auditToRemove -Force -ErrorAction 'SilentlyContinue'
                }
            }
        }

        It 'Should support PassThru parameter' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
            $result.Name | Should -Be $script:testAuditName
        }
    }

    Context 'When creating a new file audit' {
        BeforeEach {
            $script:testAuditName = 'SqlDscTestAudit_File_' + (Get-Random)
        }

        AfterEach {
            # Clean up the audit created in this test
            $auditToRemove = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
            if ($auditToRemove)
            {
                Remove-SqlDscAudit -AuditObject $auditToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should create a file audit successfully' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $script:testAuditPath -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testAuditName
            $result.DestinationType | Should -Be 'File'
            $result.FilePath | Should -Be $script:testAuditPath

            # Verify the audit exists in the server
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit | Should -Not -BeNullOrEmpty
            $createdAudit.DestinationType | Should -Be 'File'
            $createdAudit.FilePath | Should -Be $script:testAuditPath
        }

        It 'Should create a file audit with maximum file size' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $script:testAuditPath -MaximumFileSize 100 -MaximumFileSizeUnit 'Megabyte' -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.MaximumFileSize | Should -Be 100
            $result.MaximumFileSizeUnit | Should -Be 'MB'

            # Verify the audit exists with correct properties
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit.MaximumFileSize | Should -Be 100
            $createdAudit.MaximumFileSizeUnit | Should -Be 'MB'
        }

        It 'Should create a file audit with maximum files and reserve disk space' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $script:testAuditPath -MaximumFiles 5 -ReserveDiskSpace -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.MaximumFiles | Should -Be 5
            $result.ReserveDiskSpace | Should -BeTrue

            # Verify the audit exists with correct properties
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit.MaximumFiles | Should -Be 5
            $createdAudit.ReserveDiskSpace | Should -BeTrue
        }

        It 'Should create a file audit with maximum rollover files' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $script:testAuditPath -MaximumRolloverFiles 10 -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.MaximumRolloverFiles | Should -Be 10

            # Verify the audit exists with correct properties
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit.MaximumRolloverFiles | Should -Be 10
        }
    }

    Context 'When creating an audit with advanced options' {
        BeforeEach {
            $script:testAuditName = 'SqlDscTestAudit_Advanced_' + (Get-Random)
        }

        AfterEach {
            # Clean up the audit created in this test
            $auditToRemove = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
            if ($auditToRemove)
            {
                Remove-SqlDscAudit -AuditObject $auditToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should create an audit with OnFailure setting' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -OnFailure 'Continue' -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.OnFailure | Should -Be 'Continue'

            # Verify the audit exists with correct properties
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit.OnFailure | Should -Be 'Continue'
        }

        It 'Should create an audit with QueueDelay setting' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -QueueDelay 5000 -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.QueueDelay | Should -Be 5000

            # Verify the audit exists with correct properties
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit.QueueDelay | Should -Be 5000
        }

        It 'Should create an audit with AuditGuid setting' {
            $testGuid = [System.Guid]::NewGuid().ToString()
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -AuditGuid $testGuid -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Guid | Should -Be $testGuid

            # Verify the audit exists with correct properties
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit.Guid | Should -Be $testGuid
        }

        It 'Should create an audit with AuditFilter setting' {
            $testFilter = "([database_name] = 'master')"
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -AuditFilter $testFilter -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Filter | Should -Be $testFilter

            # Verify the audit exists with correct properties
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit.Filter | Should -Be $testFilter
        }

        It 'Should support Refresh parameter' {
            $result = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -Refresh -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testAuditName

            # Verify the audit exists
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When creating an audit using pipeline input' {
        BeforeEach {
            $script:testAuditName = 'SqlDscTestAudit_Pipeline_' + (Get-Random)
        }

        AfterEach {
            # Clean up the audit created in this test
            $auditToRemove = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
            if ($auditToRemove)
            {
                Remove-SqlDscAudit -AuditObject $auditToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should support pipeline input with server object' {
            $result = $script:serverObject | New-SqlDscAudit -Name $script:testAuditName -LogType 'ApplicationLog' -PassThru -Force -ErrorAction Stop

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:testAuditName

            # Verify the audit exists
            $createdAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction Stop
            $createdAudit | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When handling error conditions' {
        BeforeEach {
            $script:testAuditName = 'SqlDscTestAudit_Error_' + (Get-Random)
        }

        AfterEach {
            # Clean up the audit created in this test
            $auditToRemove = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -ErrorAction 'SilentlyContinue'
            if ($auditToRemove)
            {
                Remove-SqlDscAudit -AuditObject $auditToRemove -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should throw error when trying to create an audit that already exists' {
            # First, create an audit
            $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -Force -ErrorAction Stop

            # Then try to create another audit with the same name
            { New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -Force -ErrorAction Stop } |
                Should -Throw
        }

        It 'Should throw error when path does not exist for file audit' {
            $nonExistentPath = Join-Path -Path $env:TEMP -ChildPath 'NonExistentPath'
            
            { New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $nonExistentPath -Force -ErrorAction Stop } |
                Should -Throw
        }
    }
}
