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

Describe 'ConvertFrom-SqlDscDatabasePermission' -Tag 'Public' {
    BeforeAll {
        $mockPermission = InModuleScope -ScriptBlock {
            [DatabasePermission] @{
                State      = 'Grant'
                Permission = @(
                    'Connect'
                    'Alter'
                )
            }
        }
    }

    It 'Should return the correct values' {
        $mockResult = ConvertFrom-SqlDscDatabasePermission -Permission $mockPermission

        $mockResult.Connect | Should -BeTrue
        $mockResult.Alter | Should -BeTrue
        $mockResult.Update | Should -BeFalse
    }

    Context 'When passing DatabasePermissionInfo over the pipeline' {
        It 'Should return the correct values' {
            $mockResult = $mockPermission | ConvertFrom-SqlDscDatabasePermission

            $mockResult.Connect | Should -BeTrue
            $mockResult.Alter | Should -BeTrue
            $mockResult.Update | Should -BeFalse
        }
    }

    Context 'When passing multiple DatabasePermission objects over the pipeline' {
        It 'Should consolidate all permissions into a single DatabasePermissionSet' {
            $mockPermission1 = InModuleScope -ScriptBlock {
                [DatabasePermission] @{
                    State      = 'Grant'
                    Permission = @(
                        'Connect'
                        'Alter'
                    )
                }
            }

            $mockPermission2 = InModuleScope -ScriptBlock {
                [DatabasePermission] @{
                    State      = 'Grant'
                    Permission = @(
                        'Update'
                        'Delete'
                    )
                }
            }

            $mockResult = @($mockPermission1, $mockPermission2) | ConvertFrom-SqlDscDatabasePermission

            # Verify permissions from first object are set
            $mockResult.Connect | Should -BeTrue
            $mockResult.Alter | Should -BeTrue

            # Verify permissions from second object are set
            $mockResult.Update | Should -BeTrue
            $mockResult.Delete | Should -BeTrue

            # Verify a permission not specified in either object remains false
            $mockResult.Insert | Should -BeFalse
        }
    }

    Context 'When passing a DatabasePermission object with empty permissions' {
        It 'Should return a DatabasePermissionSet with all permissions set to false' {
            $mockEmptyPermission = InModuleScope -ScriptBlock {
                [DatabasePermission] @{
                    State      = 'Grant'
                    Permission = @()
                }
            }

            $mockResult = ConvertFrom-SqlDscDatabasePermission -Permission $mockEmptyPermission

            # Verify that common permissions remain false when no permissions are specified
            $mockResult.Connect | Should -BeFalse
            $mockResult.Alter | Should -BeFalse
            $mockResult.Update | Should -BeFalse
            $mockResult.Delete | Should -BeFalse
            $mockResult.Insert | Should -BeFalse
        }

        It 'Should return a DatabasePermissionSet with all permissions set to false when passed over the pipeline' {
            $mockEmptyPermission = InModuleScope -ScriptBlock {
                [DatabasePermission] @{
                    State      = 'Grant'
                    Permission = @()
                }
            }

            $mockResult = $mockEmptyPermission | ConvertFrom-SqlDscDatabasePermission

            # Verify that common permissions remain false when no permissions are specified
            $mockResult.Connect | Should -BeFalse
            $mockResult.Alter | Should -BeFalse
            $mockResult.Update | Should -BeFalse
            $mockResult.Delete | Should -BeFalse
            $mockResult.Insert | Should -BeFalse
        }
    }
}
