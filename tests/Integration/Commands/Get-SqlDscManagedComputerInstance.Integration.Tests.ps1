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

# cSpell: ignore DSCSQLTEST
Describe 'Get-SqlDscManagedComputerInstance' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockServerName = Get-ComputerName
    }

    Context 'When using parameter set ByServerName' {
        Context 'When getting a specific instance' {
            It 'Should return the correct server instance' {
                $result = Get-SqlDscManagedComputerInstance -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be $script:mockInstanceName
                $result.Parent.Name | Should -Be $script:mockServerName
            }

            It 'Should throw when the instance does not exist' {
                {
                    Get-SqlDscManagedComputerInstance -ServerName $script:mockServerName -InstanceName 'NonExistentInstance' -ErrorAction 'Stop'
                } | Should -Throw -ErrorId 'SqlServerInstanceNotFound,Get-SqlDscManagedComputerInstance'
            }
        }

        Context 'When getting all instances' {
            It 'Should return all available instances' {
                $result = Get-SqlDscManagedComputerInstance -ServerName $script:mockServerName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance])

                # Should contain the test instance
                $testInstance = $result | Where-Object -FilterScript { $_.Name -eq $script:mockInstanceName }
                $testInstance | Should -Not -BeNullOrEmpty
                $testInstance.Name | Should -Be $script:mockInstanceName
            }
        }

        Context 'When using default server name' {
            It 'Should use the local computer name when ServerName is not specified' {
                $result = Get-SqlDscManagedComputerInstance -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be $script:mockInstanceName
                $result.Parent.Name | Should -Be $script:mockServerName
            }
        }
    }

    Context 'When using parameter set ByManagedComputerObject' {
        BeforeAll {
            $script:managedComputerObject = Get-SqlDscManagedComputer -ServerName $script:mockServerName -ErrorAction 'Stop'
        }

        Context 'When getting a specific instance from managed computer object' {
            It 'Should return the correct server instance' {
                $result = $script:managedComputerObject | Get-SqlDscManagedComputerInstance -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be $script:mockInstanceName
                $result.Parent.Name | Should -Be $script:mockServerName
            }

            It 'Should throw when the instance does not exist' {
                {
                    $script:managedComputerObject | Get-SqlDscManagedComputerInstance -InstanceName 'NonExistentInstance' -ErrorAction 'Stop'
                } | Should -Throw -ErrorId 'SqlServerInstanceNotFound,Get-SqlDscManagedComputerInstance'
            }
        }

        Context 'When getting all instances from managed computer object' {
            It 'Should return all available instances' {
                $result = $script:managedComputerObject | Get-SqlDscManagedComputerInstance -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance])

                # Should contain the test instance
                $testInstance = $result | Where-Object -FilterScript { $_.Name -eq $script:mockInstanceName }
                $testInstance | Should -Not -BeNullOrEmpty
                $testInstance.Name | Should -Be $script:mockInstanceName
            }
        }
    }

    Context 'When validating SMO object properties' {
        It 'Should return objects with correct SMO properties' {
            $result = Get-SqlDscManagedComputerInstance -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

            # Verify it's a proper SMO ServerInstance object
            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.ServerInstance])

            # Verify key properties exist
            $result.Name | Should -Not -BeNullOrEmpty
            $result.Parent | Should -Not -BeNullOrEmpty
            $result.Parent.Name | Should -Be $script:mockServerName

            # Verify ServerProtocols collection is accessible
            $result.ServerProtocols | Should -Not -BeNullOrEmpty
            $result.ServerProtocols.Count | Should -BeGreaterThan 0
        }
    }
}
