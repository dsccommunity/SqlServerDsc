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

Describe 'Test-SqlDscServerPermissionState' -Tag 'Private' {
    BeforeAll {
        $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
        $mockServerObject.InstanceName = 'MockInstance'

        Mock -CommandName Get-SqlDscServerPermission -MockWith {
            $mockPermissionInfo = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

            $mockPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
            $mockPermissionSet.ConnectSql = $true

            $mockInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
            $mockInfo.PermissionState = 'Grant'
            $mockInfo.PermissionType = $mockPermissionSet

            $mockPermissionInfo += $mockInfo

            return $mockPermissionInfo
        }

        Mock -CommandName ConvertTo-SqlDscServerPermission -MockWith {
            return @(
                [ServerPermission] @{
                    State = 'Grant'
                    Permission = @('ConnectSql')
                }
                [ServerPermission] @{
                    State = 'GrantWithGrant'
                    Permission = @()
                }
                [ServerPermission] @{
                    State = 'Deny'
                    Permission = @()
                }
            )
        }
    }

    Context 'When permissions are in desired state' {
        It 'Should return true when permissions match' {
            InModuleScope -ScriptBlock {
                $desiredPermissions = @(
                    [ServerPermission] @{
                        State = 'Grant'
                        Permission = @('ConnectSql')
                    }
                    [ServerPermission] @{
                        State = 'GrantWithGrant'
                        Permission = @()
                    }
                    [ServerPermission] @{
                        State = 'Deny'
                        Permission = @()
                    }
                )

                $result = Test-SqlDscServerPermissionState -ServerObject $mockServerObject -Name 'TestUser' -Permission $desiredPermissions

                $result | Should -BeTrue
            }
        }
    }

    Context 'When permissions are not in desired state' {
        It 'Should return false when desired permission is missing' {
            InModuleScope -ScriptBlock {
                $desiredPermissions = @(
                    [ServerPermission] @{
                        State = 'Grant'
                        Permission = @('ConnectSql', 'ViewServerState')
                    }
                    [ServerPermission] @{
                        State = 'GrantWithGrant'
                        Permission = @()
                    }
                    [ServerPermission] @{
                        State = 'Deny'
                        Permission = @()
                    }
                )

                $result = Test-SqlDscServerPermissionState -ServerObject $mockServerObject -Name 'TestUser' -Permission $desiredPermissions

                $result | Should -BeFalse
            }
        }

        It 'Should return false when extra permission is present' {
            InModuleScope -ScriptBlock {
                $desiredPermissions = @(
                    [ServerPermission] @{
                        State = 'Grant'
                        Permission = @()
                    }
                    [ServerPermission] @{
                        State = 'GrantWithGrant'
                        Permission = @()
                    }
                    [ServerPermission] @{
                        State = 'Deny'
                        Permission = @()
                    }
                )

                $result = Test-SqlDscServerPermissionState -ServerObject $mockServerObject -Name 'TestUser' -Permission $desiredPermissions

                $result | Should -BeFalse
            }
        }
    }

    Context 'When principal has no permissions' {
        BeforeAll {
            Mock -CommandName Get-SqlDscServerPermission -MockWith {
                return $null
            }
        }

        It 'Should return true when no permissions are desired' {
            InModuleScope -ScriptBlock {
                $desiredPermissions = @(
                    [ServerPermission] @{
                        State = 'Grant'
                        Permission = @()
                    }
                    [ServerPermission] @{
                        State = 'GrantWithGrant'
                        Permission = @()
                    }
                    [ServerPermission] @{
                        State = 'Deny'
                        Permission = @()
                    }
                )

                $result = Test-SqlDscServerPermissionState -ServerObject $mockServerObject -Name 'TestUser' -Permission $desiredPermissions

                $result | Should -BeTrue
            }
        }
    }
}