<#
    .SYNOPSIS
        Unit test for SqlResourceBase class.
#>

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

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlResourceBase' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $null = [SqlResourceBase]::new()
            }
        }

        It 'Should have a default constructor' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $instance = [SqlResourceBase]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.SqlServerObject | Should -BeNullOrEmpty
            }
        }

        It 'Should be the correct type' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

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
                Set-StrictMode -Version 1.0

                [SqlResourceBase]::new()
            }

            Mock -CommandName Connect-SqlDscDatabaseEngine -MockWith {
                return [Microsoft.SqlServer.Management.Smo.Server]::new()
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
                    Set-StrictMode -Version 1.0

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

        Context 'When property Protocol is used' {
            BeforeAll {
                $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    [SqlResourceBase]::new()
                }

                $mockSqlResourceBaseInstance.Protocol = 'tcp'
            }

            It 'Should call the correct mock' {
                $result = $mockSqlResourceBaseInstance.GetServerObject()

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'

                Should -Invoke -CommandName Connect-SqlDscDatabaseEngine -ParameterFilter {
                    $PesterBoundParameters.Keys -contains 'Protocol'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When property Port is used' {
            BeforeAll {
                $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    [SqlResourceBase]::new()
                }

                $mockSqlResourceBaseInstance.Port = 1433
            }

            It 'Should call the correct mock' {
                $result = $mockSqlResourceBaseInstance.GetServerObject()

                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'

                Should -Invoke -CommandName Connect-SqlDscDatabaseEngine -ParameterFilter {
                    $PesterBoundParameters.Keys -contains 'Port'
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When a server object already exist' {
        BeforeAll {
            $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                [SqlResourceBase]::new()
            }

            $mockSqlResourceBaseInstance.SqlServerObject = [Microsoft.SqlServer.Management.Smo.Server]::new()
            Mock -CommandName Connect-SqlDscDatabaseEngine
        }

        It 'Should call the correct mock' {
            $result = $mockSqlResourceBaseInstance.GetServerObject()
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Server'

            Should -Invoke -CommandName Connect-SqlDscDatabaseEngine -Exactly -Times 0 -Scope It
        }
    }
}
