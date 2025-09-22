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

Describe 'Get-SqlDscAudit' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction Stop

        # Create test audits for the tests
        $script:testAuditName1 = 'SqlDscTestGetAudit1_' + (Get-Random)
        $script:testAuditName2 = 'SqlDscTestGetAudit2_' + (Get-Random)

        $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName1 -LogType 'ApplicationLog' -Force -ErrorAction Stop
        $null = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName2 -LogType 'ApplicationLog' -Force -ErrorAction Stop
    }

    AfterAll {
        # Clean up test audits
        $testAuditsToRemove = @($script:testAuditName1, $script:testAuditName2)

        foreach ($auditName in $testAuditsToRemove)
        {
            try
            {
                $existingAudit = Get-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -ErrorAction 'SilentlyContinue'
                if ($existingAudit)
                {
                    $null = Remove-SqlDscAudit -ServerObject $script:serverObject -Name $auditName -Force -ErrorAction 'SilentlyContinue'
                }
            }
            catch
            {
                # Ignore cleanup errors
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When getting all SQL Server audits' {
        It 'Should return an array of Audit objects' {
            $result = Get-SqlDscAudit -ServerObject $script:serverObject

            <#
                Casting to array to ensure we get the count on Windows PowerShell
                when there is only one audit.
            #>
            @($result).Count | Should -BeGreaterOrEqual 2
            @($result)[0] | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
        }

        It 'Should return test audits that were created' {
            $result = Get-SqlDscAudit -ServerObject $script:serverObject

            $result.Name | Should -Contain $script:testAuditName1
            $result.Name | Should -Contain $script:testAuditName2
        }
    }

    Context 'When getting a specific SQL Server audit' {
        It 'Should return the specified audit when it exists' {
            $result = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName1

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
            $result.Name | Should -Be $script:testAuditName1
        }

        It 'Should throw an error when the audit does not exist' {
            { Get-SqlDscAudit -ServerObject $script:serverObject -Name 'NonExistentAudit' -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should return null when the audit does not exist and error action is SilentlyContinue' {
            $result = Get-SqlDscAudit -ServerObject $script:serverObject -Name 'NonExistentAudit' -ErrorAction 'SilentlyContinue'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should return the same results with and without Refresh for all audits' {
            $resultWithoutRefresh = Get-SqlDscAudit -ServerObject $script:serverObject
            $resultWithRefresh = Get-SqlDscAudit -ServerObject $script:serverObject -Refresh

            @($resultWithoutRefresh).Count | Should -Be @($resultWithRefresh).Count
        }

        It 'Should return the same result with and without Refresh for specific audit' {
            $resultWithoutRefresh = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName1
            $resultWithRefresh = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName1 -Refresh

            $resultWithoutRefresh.Name | Should -Be $resultWithRefresh.Name
            $resultWithoutRefresh.Name | Should -Be $script:testAuditName1
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline for all audits' {
            $result = $script:serverObject | Get-SqlDscAudit

            @($result).Count | Should -BeGreaterOrEqual 2
            $result.Name | Should -Contain $script:testAuditName1
            $result.Name | Should -Contain $script:testAuditName2
        }

        It 'Should accept ServerObject from pipeline for specific audit' {
            $result = $script:serverObject | Get-SqlDscAudit -Name $script:testAuditName1

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Audit'
            $result.Name | Should -Be $script:testAuditName1
        }
    }

    Context 'When testing audit properties' {
        It 'Should return audits with expected properties' {
            $result = Get-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName1

            $result.Name | Should -Be $script:testAuditName1
            $result.Parent | Should -Be $script:serverObject
            $result.Enabled | Should -Not -BeNull
            $result.DestinationType | Should -Not -BeNull
        }
    }
}
