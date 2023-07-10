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

Describe 'SqlResourceBase' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                { [SqlResourceBase]::new() } | Should -Not -Throw
            }
        }

        It 'Should have a default constructor' {
            InModuleScope -ScriptBlock {
                $instance = [SqlResourceBase]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.SqlServerObject | Should -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                $instance = [SqlResourceBase]::new()
                $instance.GetType().Name | Should -Be 'SqlResourceBase'
            }
        }
    }
}

Describe 'SqlResourceBase\GetServerObject()' -Tag 'GetServerObject' {
    Context 'When a server object does not exist' {
        BeforeAll {
            $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                [SqlResourceBase]::new()
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            }
        }

        It 'Should call the correct mock' {
            $result = $mockSqlResourceBaseInstance.GetServerObject()

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'

            Should -Invoke -CommandName Connect-SqlDscDatabaseEngine -Exactly -Times 1 -Scope It
        }

        Context 'When property Credential is used' {
            BeforeAll {
                $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                    [SqlResourceBase]::new()
                }

                $mockSqlResourceBaseInstance.Credential = [System.Management.Automation.PSCredential]::new(
                    'MyCredentialUserName',
                    [SecureString]::new()
                )
            }

            It 'Should call the correct mock' {
                $result = $mockSqlResourceBaseInstance.GetServerObject()

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'

                Should -Invoke -CommandName Connect-SqlDscDatabaseEngine -ParameterFilter {
                    $PesterBoundParameters.Keys -contains 'Credential'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When a server object already exist' {
        BeforeAll {
            $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                [SqlResourceBase]::new()
            }

            $mockSqlResourceBaseInstance.SqlServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            Mock -CommandName Connect-SqlDscDatabaseEngine
        }

        It 'Should call the correct mock' {
            $result = $mockSqlResourceBaseInstance.GetServerObject()
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'

            Should -Invoke -CommandName Connect-SqlDscDatabaseEngine -Exactly -Times 0 -Scope It
        }
    }
}
