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

# cSpell: ignore DSCSQLTEST
Describe 'Get-SqlDscManagedComputerService' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'

        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockServerName = Get-ComputerName
    }

    AfterAll {
        # Stop the named instance SQL Server service to save memory on the build worker.
        Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
    }

    Context 'When using parameter set ByServerName' {
        Context 'When getting all services on the current managed computer' {
            It 'Should return all available services' {
                $result = Get-SqlDscManagedComputerService -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

                # Should contain SQL Server related services
                $sqlServices = $result | Where-Object -FilterScript { $_.Name -like '*SQL*' }
                $sqlServices | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When getting all services on the specified managed computer' {
            It 'Should return all available services' {
                $result = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

                # Should contain SQL Server related services
                $sqlServices = $result | Where-Object -FilterScript { $_.Name -like '*SQL*' }
                $sqlServices | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When filtering by ServiceType' {
            It 'Should return only Database Engine services' {
                $result = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -ServiceType 'DatabaseEngine' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

                # All returned services should be of type SqlServer
                foreach ($service in $result)
                {
                    $service.Type | Should -Be 'SqlServer'
                }
            }

            It 'Should return SQL Server Browser service when filtering by SQLServerBrowser' {
                $result = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -ServiceType 'SQLServerBrowser' -ErrorAction 'Stop'

                if ($result)
                {
                    $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])
                    $result.Type | Should -Be 'SqlBrowser'
                }
            }
        }

        Context 'When filtering by InstanceName' {
            It 'Should return services for the specified instance' {
                $result = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                if ($result)
                {
                    $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

                    # All returned services should contain the instance name
                    foreach ($service in $result)
                    {
                        $service.Name | Should -Match ('\$' + $script:mockInstanceName + '$')
                    }
                }
            }

            It 'Should return services for the default instance when filtering by MSSQLSERVER' {
                $result = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -InstanceName 'MSSQLSERVER' -ErrorAction 'Stop'

                if ($result)
                {
                    $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

                    # Should contain the default instance service
                    $defaultInstanceService = $result | Where-Object -FilterScript { $_.Name -eq 'MSSQLSERVER' }
                    $defaultInstanceService | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When using parameter set ByManagedComputerObject' {
        BeforeAll {
            $script:managedComputerObject = Get-SqlDscManagedComputer -ServerName $script:mockServerName -ErrorAction 'Stop'
        }

        Context 'When getting all services from managed computer object' {
            It 'Should return all available services' {
                $result = $script:managedComputerObject | Get-SqlDscManagedComputerService -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

                # Should contain SQL Server related services
                $sqlServices = $result | Where-Object -FilterScript { $_.Name -like '*SQL*' }
                $sqlServices | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When filtering by ServiceType from managed computer object' {
            It 'Should return only Database Engine services' {
                $result = $script:managedComputerObject | Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -ErrorAction 'Stop'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

                # All returned services should be of type SqlServer
                foreach ($service in $result)
                {
                    $service.Type | Should -Be 'SqlServer'
                }
            }
        }

        Context 'When filtering by InstanceName from managed computer object' {
            It 'Should return services for the specified instance' {
                $result = $script:managedComputerObject | Get-SqlDscManagedComputerService -InstanceName $script:mockInstanceName -ErrorAction 'Stop'

                if ($result)
                {
                    $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

                    # All returned services should contain the instance name
                    foreach ($service in $result)
                    {
                        $service.Name | Should -Match ('\$' + $script:mockInstanceName + '$')
                    }
                }
            }
        }
    }

    Context 'When validating SMO object properties' {
        It 'Should return objects with correct SMO properties' {
            $result = Get-SqlDscManagedComputerService -ServerName $script:mockServerName -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty

            # Verify it's a proper SMO Service object
            $result | Should -BeOfType ([Microsoft.SqlServer.Management.Smo.Wmi.Service])

            # Verify key properties exist for at least one service
            $firstService = $result | Select-Object -First 1
            $firstService.Name | Should -Not -BeNullOrEmpty
            $firstService.Type | Should -Not -BeNullOrEmpty

            # Verify the service has access to its parent ManagedComputer
            $firstService.Parent | Should -Not -BeNullOrEmpty
            $firstService.Parent.Name | Should -Be $script:mockServerName
        }
    }
}
