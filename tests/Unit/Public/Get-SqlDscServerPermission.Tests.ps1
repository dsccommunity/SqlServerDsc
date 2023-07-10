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

Describe 'Get-SqlDscServerPermission' -Tag 'Public' {
    Context 'When the principal does not exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $false
            }
        }

        Context 'When specifying to throw on error' {
            BeforeAll {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.ServerPermission_MissingPrincipal
                }
            }

            It 'Should throw the correct error' {
                { Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'UnknownUser' -ErrorAction 'Stop' } |
                    Should -Throw -ExpectedMessage ($mockErrorMessage -f 'UnknownUser', 'MockInstance')
            }
        }

        Context 'When ignoring the error' {
            It 'Should not throw an exception and return $null' {
                Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'UnknownUser' -ErrorAction 'SilentlyContinue' |
                    Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the principal exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptMethod' -Name 'EnumServerPermissions' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $SqlServerLogin
                    )

                    $mockEnumServerPermissions = [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] @()

                    $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                        PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                            ConnectSql = $true
                        }
                        PermissionState = 'Grant'
                    }

                    $mockEnumServerPermissions += [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo] @{
                        PermissionType  =  [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                            AlterAnyAvailabilityGroup = $true
                        }
                        PermissionState = 'Grant'
                    }

                    return $mockEnumServerPermissions
                } -PassThru -Force

            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $true
            }
        }

        It 'Should return the correct values' {
            $mockResult = Get-SqlDscServerPermission -ServerObject $mockServerObject -Name 'Zebes\SamusAran' -ErrorAction 'Stop'

            $mockResult | Should -HaveCount 2

            $mockResult[0].PermissionState | Should -Be 'Grant'
            $mockResult[0].PermissionType.ConnectSql | Should -BeTrue
            $mockResult[0].PermissionType.AlterAnyAvailabilityGroup | Should -BeFalse

            $mockResult[1].PermissionState | Should -Be 'Grant'
            $mockResult[1].PermissionType.ConnectSql | Should -BeFalse
            $mockResult[1].PermissionType.AlterAnyAvailabilityGroup | Should -BeTrue
        }

        Context 'When passing ServerObject over the pipeline' {
            It 'Should return the correct values' {
                $mockResult = $mockServerObject | Get-SqlDscServerPermission -Name 'Zebes\SamusAran' -ErrorAction 'Stop'

                $mockResult | Should -HaveCount 2

                $mockResult[0].PermissionState | Should -Be 'Grant'
                $mockResult[0].PermissionType.ConnectSql | Should -BeTrue
                $mockResult[0].PermissionType.AlterAnyAvailabilityGroup | Should -BeFalse

                $mockResult[1].PermissionState | Should -Be 'Grant'
                $mockResult[1].PermissionType.ConnectSql | Should -BeFalse
                $mockResult[1].PermissionType.AlterAnyAvailabilityGroup | Should -BeTrue
            }
        }
    }
}
