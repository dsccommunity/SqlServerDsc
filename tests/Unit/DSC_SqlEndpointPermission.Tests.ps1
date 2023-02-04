<#
    .SYNOPSIS
        Unit test for DSC_SqlEndpointPermission DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscResourceName = 'DSC_SqlEndpointPermission'

    $env:SqlServerDscCI = $true

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlEndpointPermission\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockConnectSql = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name 'Endpoints' -Value {
                return @(
                    @{
                        # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                        'DefaultEndpointMirror' = New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DefaultEndpointMirror' -PassThru |
                            Add-Member -MemberType ScriptMethod -Name 'EnumObjectPermissions' -Value {
                                param
                                (
                                    $permissionSet
                                )

                                return @(
                                    (
                                        New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'Grantee' -Value 'COMPANY\Account' -PassThru |
                                            Add-Member -MemberType NoteProperty -Name 'PermissionState' -Value 'Grant' -PassThru -Force
                                    )
                                )
                            } -PassThru -Force
                    }
                )
            } -PassThru -Force
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

        Mock -CommandName New-Object -MockWith {
            return [PSCustomObject]@{
                Connect = $true
            }
        } -ParameterFilter {
            $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
        }

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name         = 'DefaultEndpointMirror'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the endpoint exist' {
            Context 'When the permission should be present' {
                It 'Should return the correct value for each property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockGetTargetResourceParameters.Principal = 'COMPANY\Account'

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.Principal | Should -Be $mockGetTargetResourceParameters.Principal
                        $result.Permission | Should -Be 'CONNECT'
                    }
                }
            }

            Context 'When the permission should be absent' {
                It 'Should return the correct value for each property' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockGetTargetResourceParameters.Principal = 'COMPANY\MissingAccount'

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        $result.Name | Should -Be $mockGetTargetResourceParameters.Name
                        $result.Principal | Should -Be $mockGetTargetResourceParameters.Principal
                        $result.Permission | Should -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the endpoint does not exist' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockGetTargetResourceParameters.Name = 'MissingEndpoint'
                    $mockGetTargetResourceParameters.Principal = 'COMPANY\MissingAccount'

                    <#
                        This will throw an exception because the endpoint does not exist,
                        but that will also throw the outer exception in Get-TargetResource.
                    #>
                    $mockErrorMessage = '{0}*{1}' -f @(
                        ($script:localizedData.UnexpectedErrorFromGet -f 'MissingEndpoint'),
                        ($script:localizedData.EndpointNotFound -f 'MissingEndpoint')
                    )

                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
                }
            }
        }
    }
}

Describe 'SqlEndpointPermission\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name         = 'DefaultEndpointMirror'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the endpoint should exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        Ensure       = 'Present'
                        Name         = 'DefaultEndpointMirror'
                        Principal    = 'COMPANY\Account'
                        Permission   = 'CONNECT'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Principal = 'COMPANY\Account'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When the endpoint should not exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        Ensure       = 'Absent'
                        Name         = 'DefaultEndpointMirror'
                        Principal    = 'COMPANY\Account'
                        Permission   = 'CONNECT'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Ensure = 'Absent'
                    $mockTestTargetResourceParameters.Principal = 'COMPANY\Account'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the endpoint exist' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'MSSQLSERVER'
                        ServerName   = 'localhost'
                        Ensure       = 'Absent'
                        Name         = 'DefaultEndpointMirror'
                        Principal    = 'COMPANY\MissingAccount'
                        Permission   = ''
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Principal = 'COMPANY\MissingAccount'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }
    }
}

Describe 'SqlEndpointPermission\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name         = 'DefaultEndpointMirror'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the permission should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return the correct value for each property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Principal = 'COMPANY\Account'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When the permission should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return the correct value for each property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Ensure = 'Absent'
                    $mockSetTargetResourceParameters.Principal = 'COMPANY\MissingAccount'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            $mockConnectSql = {
                return New-Object -TypeName Object |
                    Add-Member -MemberType ScriptProperty -Name 'Endpoints' -Value {
                    return @(
                        @{
                            # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                            'DefaultEndpointMirror' = New-Object -TypeName Object |
                                Add-Member -MemberType NoteProperty -Name 'Name' -Value 'DefaultEndpointMirror' -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Grant' -Value {
                                    param
                                    (
                                        $permissionSet,
                                        $mockPrincipal
                                    )

                                    InModuleScope -ScriptBlock {
                                        $script:mockMethodGrantWasRun += 1
                                    }
                                } -PassThru |
                                Add-Member -MemberType ScriptMethod -Name 'Revoke' -Value {
                                    param
                                    (
                                        $permissionSet,
                                        $mockPrincipal
                                    )

                                    InModuleScope -ScriptBlock {
                                        $script:mockMethodRevokeWasRun += 1
                                    }
                                } -PassThru -Force
                        }
                    )
                } -PassThru -Force
            }

            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

            Mock -CommandName New-Object -MockWith {
                return [PSCustomObject]@{
                    Connect = $true
                }
            } -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.ObjectPermissionSet'
            }
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:mockMethodGrantWasRun = 0
                $script:mockMethodRevokeWasRun = 0
            }
        }

        Context 'When the permission should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return the correct value for each property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Principal = 'COMPANY\Account'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It

                    $mockMethodGrantWasRun | Should -Be 1
                    $mockMethodRevokeWasRun | Should -Be 0
                }
            }
        }

        Context 'When the permission should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return the correct value for each property' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Ensure = 'Absent'
                    $mockSetTargetResourceParameters.Principal = 'COMPANY\MissingAccount'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It

                    $mockMethodRevokeWasRun | Should -Be 1
                    $mockMethodGrantWasRun | Should -Be 0
                }
            }
        }

        Context 'When the endpoint is missing' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockSetTargetResourceParameters.Ensure = 'Absent'
                    $mockSetTargetResourceParameters.Name = 'MissingEndpoint'
                    $mockSetTargetResourceParameters.Principal = 'COMPANY\Account'

                    $mockErrorMessage = $script:localizedData.EndpointNotFound -f 'MissingEndpoint'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }
    }
}
