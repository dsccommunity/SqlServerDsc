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

Describe 'SqlResourceBase' {
    Context 'When class is instantiated' {
        It 'Should not throw an exception' {
            InModuleScope -ScriptBlock {
                $null = [SqlResourceBase]::new()
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

Describe 'SqlResourceBase\ConvertToSmoEnumType()' -Tag 'ConvertToSmoEnumType' {
    Context 'When converting an enum type using the default namespace' {
        BeforeAll {
            $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                [SqlResourceBase]::new()
            }
        }

        It 'Should return the correct enum value for RecoveryModel' {
            $result = $mockSqlResourceBaseInstance.ConvertToSmoEnumType('RecoveryModel', 'Full')

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.RecoveryModel'
            $result.ToString() | Should -Be 'Full'
        }

        It 'Should return the correct enum value for CompatibilityLevel' {
            $result = $mockSqlResourceBaseInstance.ConvertToSmoEnumType('CompatibilityLevel', 'Version160')

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.CompatibilityLevel'
            $result.ToString() | Should -Be 'Version160'
        }

        It 'Should handle case-insensitive value matching' {
            $result = $mockSqlResourceBaseInstance.ConvertToSmoEnumType('RecoveryModel', 'full')

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.RecoveryModel'
            $result.ToString() | Should -Be 'Full'
        }
    }

    Context 'When converting an enum type using a custom namespace' {
        BeforeAll {
            $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                [SqlResourceBase]::new()
            }
        }

        It 'Should return the correct enum value' {
            $result = $mockSqlResourceBaseInstance.ConvertToSmoEnumType(
                'RecoveryModel',
                'Simple',
                'Microsoft.SqlServer.Management.Smo'
            )

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.RecoveryModel'
            $result.ToString() | Should -Be 'Simple'
        }
    }

    Context 'When converting an enum type using the full type name' {
        BeforeAll {
            $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                [SqlResourceBase]::new()
            }
        }

        It 'Should return the correct enum value when full type name is provided' {
            $result = $mockSqlResourceBaseInstance.ConvertToSmoEnumType(
                'Microsoft.SqlServer.Management.Smo.RecoveryModel',
                'BulkLogged'
            )

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.RecoveryModel'
            $result.ToString() | Should -Be 'BulkLogged'
        }
    }

    Context 'When the enum type cannot be found' {
        BeforeAll {
            $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                [SqlResourceBase]::new()
            }

            $script:mockExpectedErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.ConvertToSmoEnumType_FailedToFindType -f 'Microsoft.SqlServer.Management.Smo.NonExistentEnumType'
            }
        }

        It 'Should throw the correct exception' {
            {
                $mockSqlResourceBaseInstance.ConvertToSmoEnumType('NonExistentEnumType', 'SomeValue')
            } | Should -Throw -ExpectedMessage $script:mockExpectedErrorMessage
        }
    }

    Context 'When enum type caching is used' {
        BeforeAll {
            # Clear the cache before testing
            InModuleScope -ScriptBlock {
                [SqlResourceBase]::EnumTypeCache.Clear()
            }

            $mockSqlResourceBaseInstance = InModuleScope -ScriptBlock {
                [SqlResourceBase]::new()
            }
        }

        AfterAll {
            # Clear the cache after testing
            InModuleScope -ScriptBlock {
                [SqlResourceBase]::EnumTypeCache.Clear()
            }
        }

        It 'Should cache the enum type after first resolution' {
            # First call should resolve and cache the type
            $result = $mockSqlResourceBaseInstance.ConvertToSmoEnumType('RecoveryModel', 'Full')

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.RecoveryModel'

            # Verify the type was cached
            $cacheContainsType = InModuleScope -ScriptBlock {
                [SqlResourceBase]::EnumTypeCache.ContainsKey('Microsoft.SqlServer.Management.Smo.RecoveryModel')
            }

            $cacheContainsType | Should -BeTrue
        }

        It 'Should use cached type on subsequent calls' {
            # First call to populate cache
            $null = $mockSqlResourceBaseInstance.ConvertToSmoEnumType('CompatibilityLevel', 'Version160')

            # Second call should use cached type
            $result = $mockSqlResourceBaseInstance.ConvertToSmoEnumType('CompatibilityLevel', 'Version150')

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.CompatibilityLevel'
            $result.ToString() | Should -Be 'Version150'
        }

        It 'Should have static cache shared across instances' {
            # Get cache count before
            $cacheCountBefore = InModuleScope -ScriptBlock {
                [SqlResourceBase]::EnumTypeCache.Count
            }

            # Create a new instance and resolve a type
            $newInstance = InModuleScope -ScriptBlock {
                [SqlResourceBase]::new()
            }

            # Use a type that should already be in cache from previous tests
            $null = $newInstance.ConvertToSmoEnumType('RecoveryModel', 'Simple')

            # Cache count should remain the same (type already cached)
            $cacheCountAfter = InModuleScope -ScriptBlock {
                [SqlResourceBase]::EnumTypeCache.Count
            }

            $cacheCountAfter | Should -Be $cacheCountBefore
        }
    }
}
