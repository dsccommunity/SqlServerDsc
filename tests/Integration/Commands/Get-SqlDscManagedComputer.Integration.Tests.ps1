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

# cSpell: ignore DSCSQLTEST
Describe 'Get-SqlDscManagedComputer' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Starting the named instance SQL Server service prior to running tests.
        # Note: On Windows CI environment, this would start the SQL Server service
        if (Get-Command -Name 'Start-Service' -ErrorAction 'SilentlyContinue')
        {
            Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
        }

        $script:mockServerName = Get-ComputerName
    }

    AfterAll {
        # Stop the named instance SQL Server service to save memory on the build worker.
        # Note: On Windows CI environment, this would stop the SQL Server service
        if (Get-Command -Name 'Stop-Service' -ErrorAction 'SilentlyContinue')
        {
            Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
        }
    }

    Context 'When using default parameters' {
        It 'Should return the managed computer object for the local computer' {
            $result = Get-SqlDscManagedComputer -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer])
            $result.Name | Should -Be $script:mockServerName
        }
    }

    Context 'When specifying a server name' {
        It 'Should return the managed computer object for the specified server' {
            $result = Get-SqlDscManagedComputer -ServerName $script:mockServerName -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer])
            $result.Name | Should -Be $script:mockServerName
        }
    }

    Context 'When validating SMO object properties' {
        It 'Should return objects with correct SMO properties' {
            $result = Get-SqlDscManagedComputer -ServerName $script:mockServerName -ErrorAction 'Stop'

            # Verify it's a proper SMO ManagedComputer object
            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer])

            # Verify key properties exist
            $result.Name | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $script:mockServerName

            # Verify ServerInstances collection is accessible
            $result.ServerInstances | Should -Not -BeNullOrEmpty
            $result.ServerInstances.Count | Should -BeGreaterThan 0

            # Verify Services collection is accessible
            $result.Services | Should -Not -BeNullOrEmpty
            $result.Services.Count | Should -BeGreaterThan 0

            # Verify the DSCSQLTEST instance is present in the ServerInstances collection
            $testInstance = $result.ServerInstances | Where-Object -FilterScript { $_.Name -eq 'DSCSQLTEST' }
            $testInstance | Should -Not -BeNullOrEmpty
            $testInstance.Name | Should -Be 'DSCSQLTEST'
        }
    }

    Context 'When using the managed computer object with other commands' {
        It 'Should be compatible with Get-SqlDscManagedComputerInstance' {
            $managedComputer = Get-SqlDscManagedComputer -ServerName $script:mockServerName -ErrorAction 'Stop'

            # Test pipeline compatibility
            $result = $managedComputer | Get-SqlDscManagedComputerInstance -InstanceName 'DSCSQLTEST' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance])
            $result.Name | Should -Be 'DSCSQLTEST'
            $result.Parent.Name | Should -Be $script:mockServerName
        }
    }

    Context 'When testing error handling' {
        It 'Should handle non-existent server names gracefully' {
            # This test verifies that the command creates a ManagedComputer object
            # even for non-existent servers (SMO behavior)
            $result = Get-SqlDscManagedComputer -ServerName 'NonExistentServer123' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer])
            $result.Name | Should -Be 'NonExistentServer123'
        }
    }
}