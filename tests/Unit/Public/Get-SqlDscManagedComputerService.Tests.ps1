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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-SqlDscManagedComputerService' -Tag 'Public' {
    BeforeAll {
        Mock -CommandName Get-SqlDscManagedComputer -MockWith {
            return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Services' -Value {
                    return @(
                        @{
                            Name = 'SQLBrowser'
                            Type = 'SqlBrowser'
                            PathName = '"C:\Program Files\Microsoft SQL Server\90\Shared\sqlbrowser.exe"'
                            StartMode = 'Auto'
                        }
                        @{
                            Name = 'MSSQL$SQL2022'
                            Type = 'SqlServer'
                            PathName = '"C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\Binn\sqlservr.exe" -sMSSQL$SQL2022'
                            StartMode = 'Auto'
                        }
                        @{
                            Name = 'MSSQLSERVER'
                            Type = 'SqlServer'
                            PathName = '"C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Binn\sqlservr.exe" -sMSSQLSERVER'
                            StartMode = 'Manual'
                        }
                    )
                } -PassThru -Force
            }
    }

    Context 'When getting all the services on the current managed computer' {
        It 'Should return the correct values' {
            $result = Get-SqlDscManagedComputerService

            $result | Should -HaveCount 3
            $result.Name | Should -Contain 'MSSQL$SQL2022'
            $result.Name | Should -Contain 'SQLBrowser'
            $result.Name | Should -Contain 'MSSQLSERVER'

            Should -Invoke -CommandName Get-SqlDscManagedComputer -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting all the services on the specified managed computer' {
        It 'Should return the correct values' {
            $result = Get-SqlDscManagedComputerService -ServerName 'localhost'

            $result | Should -HaveCount 3
            $result.Name | Should -Contain 'MSSQL$SQL2022'
            $result.Name | Should -Contain 'SQLBrowser'
            $result.Name | Should -Contain 'MSSQLSERVER'

            Should -Invoke -CommandName Get-SqlDscManagedComputer -Exactly -Times 1 -Scope It
        }

        Context 'When passing parameter ManagedComputerObject over the pipeline' {
            It 'Should return the correct values' {
                $managedComputerObject1 = [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer]::new('localhost')

                $managedComputerObject1 |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Services' -Value {
                        return @(
                            @{
                                Name = 'SQLBrowser'
                                Type = 'SqlBrowser'
                            }
                            @{
                                Name = 'MSSQL$SQL2022'
                                Type = 'SqlServer'
                            }
                        )
                    } -PassThru -Force

                $managedComputerObject2 = [Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer]::new('localhost')

                $managedComputerObject2 |
                    Add-Member -MemberType 'ScriptProperty' -Name 'Services' -Value {
                        return @(
                            @{
                                Name = 'MSSQLSERVER'
                                Type = 'SqlServer'
                            }
                        )
                    } -PassThru -Force

                $result = @(
                    $managedComputerObject1
                    $managedComputerObject2
                 ) | Get-SqlDscManagedComputerService

                $result | Should -HaveCount 3
                $result.Name | Should -Contain 'MSSQL$SQL2022'
                $result.Name | Should -Contain 'SQLBrowser'
                $result.Name | Should -Contain 'MSSQLSERVER'

                Should -Invoke -CommandName Get-SqlDscManagedComputer -Exactly -Times 0 -Scope It
            }
        }
    }

    Context 'When getting a specific services' {
        It 'Should return the correct values' {
            $result = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine'

            $result | Should -HaveCount 2
            $result.Name | Should -Contain 'MSSQL$SQL2022'
            $result.Name | Should -Contain 'MSSQLSERVER'

            Should -Invoke -CommandName Get-SqlDscManagedComputer -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting a specific instance' {
        It 'Should return the correct values' {
            $result = Get-SqlDscManagedComputerService -InstanceName 'SQL2022'

            $result | Should -HaveCount 1
            $result.Name | Should -Contain 'MSSQL$SQL2022'

            Should -Invoke -CommandName Get-SqlDscManagedComputer -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using WithExtendedProperties parameter' {
        BeforeAll {
            Mock -CommandName ConvertFrom-ManagedServiceType -MockWith {
                switch ($ServiceType)
                {
                    'SqlServer' { return 'DatabaseEngine' }
                    'SqlBrowser' { return 'SQLServerBrowser' }
                    default { return $null }
                }
            }

            Mock -CommandName ConvertFrom-ServiceStartMode -MockWith {
                param ($StartMode)
                if ($StartMode -eq 'Auto') { return 'Automatic' }
                return $StartMode
            }

            Mock -CommandName Get-FileVersionInformation -MockWith {
                return @{
                    ProductVersion = '16.0.1000.6'
                }
            }

            Mock -CommandName Test-Path -MockWith { return $true }
        }

        It 'Should add all extended properties to each service object' {
            $result = Get-SqlDscManagedComputerService -WithExtendedProperties

            $result | Should -HaveCount 3

            # Verify each service has all extended properties
            foreach ($service in $result)
            {
                $service.PSObject.Properties.Name | Should -Contain 'ManagedServiceType'
                $service.PSObject.Properties.Name | Should -Contain 'ServiceExecutableVersion'
                $service.PSObject.Properties.Name | Should -Contain 'ServiceStartupType'
                $service.PSObject.Properties.Name | Should -Contain 'ServiceInstanceName'
            }

            Should -Invoke -CommandName Get-SqlDscManagedComputer -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName ConvertFrom-ManagedServiceType -Exactly -Times 3 -Scope It
            Should -Invoke -CommandName ConvertFrom-ServiceStartMode -Exactly -Times 3 -Scope It
        }

        It 'Should have correct ManagedServiceType values' {
            $result = Get-SqlDscManagedComputerService -WithExtendedProperties

            $result | Should -HaveCount 3

            # Verify the converted values
            $browserService = $result | Where-Object -FilterScript { $_.Name -eq 'SQLBrowser' }
            $browserService.ManagedServiceType | Should -Be 'SQLServerBrowser'

            $sqlService = $result | Where-Object -FilterScript { $_.Name -eq 'MSSQL$SQL2022' }
            $sqlService.ManagedServiceType | Should -Be 'DatabaseEngine'

            Should -Invoke -CommandName ConvertFrom-ManagedServiceType -Exactly -Times 3 -Scope It
        }

        It 'Should have correct ServiceInstanceName values' {
            $result = Get-SqlDscManagedComputerService -WithExtendedProperties

            $namedInstanceService = $result | Where-Object -FilterScript { $_.Name -eq 'MSSQL$SQL2022' }
            $namedInstanceService.ServiceInstanceName | Should -Be 'SQL2022'

            $defaultInstanceService = $result | Where-Object -FilterScript { $_.Name -eq 'MSSQLSERVER' }
            $defaultInstanceService.ServiceInstanceName | Should -BeNullOrEmpty
        }

        It 'Should work when combined with ServiceType filter' {
            $result = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -WithExtendedProperties

            $result | Should -HaveCount 2

            # Verify each service has all extended properties
            foreach ($service in $result)
            {
                $service.PSObject.Properties.Name | Should -Contain 'ManagedServiceType'
                $service.ManagedServiceType | Should -Be 'DatabaseEngine'
                $service.PSObject.Properties.Name | Should -Contain 'ServiceExecutableVersion'
                $service.PSObject.Properties.Name | Should -Contain 'ServiceStartupType'
                $service.PSObject.Properties.Name | Should -Contain 'ServiceInstanceName'
            }

            Should -Invoke -CommandName ConvertFrom-ManagedServiceType -Exactly -Times 2 -Scope It
        }

        It 'Should work when combined with InstanceName filter' {
            $result = Get-SqlDscManagedComputerService -InstanceName 'SQL2022' -WithExtendedProperties

            $result | Should -HaveCount 1
            $result.Name | Should -Contain 'MSSQL$SQL2022'
            $result.PSObject.Properties.Name | Should -Contain 'ManagedServiceType'
            $result.ManagedServiceType | Should -Be 'DatabaseEngine'
            $result.PSObject.Properties.Name | Should -Contain 'ServiceInstanceName'
            $result.ServiceInstanceName | Should -Be 'SQL2022'

            Should -Invoke -CommandName ConvertFrom-ManagedServiceType -Exactly -Times 1 -Scope It
        }

        It 'Should handle conversion errors silently' {
            Mock -CommandName ConvertFrom-ManagedServiceType -MockWith {
                return $null
            }

            $result = Get-SqlDscManagedComputerService -WithExtendedProperties

            $result | Should -HaveCount 3

            # Verify each service has the ManagedServiceType property even when conversion fails
            foreach ($service in $result)
            {
                $service.PSObject.Properties.Name | Should -Contain 'ManagedServiceType'
                $service.ManagedServiceType | Should -BeNullOrEmpty
            }
        }
    }
}
