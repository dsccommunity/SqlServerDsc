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

Describe 'Get-SqlDscDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When getting all SQL Server databases' {
        It 'Should return an array of Database objects' {
            $result = Get-SqlDscDatabase -ServerObject $script:serverObject

            <#
                Casting to array to ensure we get the count on Windows PowerShell
                when there is only one database.
            #>
            @($result).Count | Should -BeGreaterOrEqual 1
            @($result)[0] | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
        }

        It 'Should return system databases including master' {
            $result = Get-SqlDscDatabase -ServerObject $script:serverObject

            $result.Name | Should -Contain 'master'
            $result.Name | Should -Contain 'model'
            $result.Name | Should -Contain 'msdb'
            $result.Name | Should -Contain 'tempdb'
        }
    }

    Context 'When getting a specific SQL Server database' {
        It 'Should return the specified database when it exists (system database)' {
            $result = Get-SqlDscDatabase -ServerObject $script:serverObject -Name 'master'

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'master'
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Database'
        }

        It 'Should throw error when getting a non-existent database' {
            { Get-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should return nothing when getting a non-existent database with SilentlyContinue' {
            $result = Get-SqlDscDatabase -ServerObject $script:serverObject -Name 'NonExistentDatabase' -ErrorAction 'SilentlyContinue'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should refresh the database collection and return databases' {
            $result = Get-SqlDscDatabase -ServerObject $script:serverObject -Refresh

            @($result).Count | Should -BeGreaterOrEqual 1
            $result.Name | Should -Contain 'master'
        }
    }
}
