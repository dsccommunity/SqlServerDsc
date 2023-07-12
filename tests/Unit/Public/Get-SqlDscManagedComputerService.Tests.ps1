[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

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
                        }
                        @{
                            Name = 'MSSQL$SQL2022'
                            Type = 'SqlServer'
                        }
                        @{
                            Name = 'MSSQLSERVER'
                            Type = 'SqlServer'
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
}
