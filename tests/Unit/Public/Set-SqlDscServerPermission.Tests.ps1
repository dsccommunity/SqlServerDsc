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

Describe 'Set-SqlDscServerPermission' -Tag 'Public' {
    Context 'When the principal does not exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName Test-SqlDscIsLogin -MockWith {
                return $false
            }

            $script:mockDefaultParameters = @{
                Name         = 'UnknownUser'
                State        = 'Grant'
                Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet]::new()
            }
        }

        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.ServerPermission_MissingPrincipal
            }

            { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                Should -Throw -ExpectedMessage ($mockErrorMessage -f 'UnknownUser', 'MockInstance')
        }
    }

    Context 'When the principal exist' {
        Context 'When using parameter Confirm with value $false' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                        $script:mockMethodDenyCallCount += 1
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    Name         = 'DOMAIN\MyLogin'
                    State        = 'Deny'
                    Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                        ConnectSql = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodDenyCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodDenyCallCount | Should -Be 1
            }
        }

        Context 'When using parameter Force' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                        $script:mockMethodDenyCallCount += 1
                    } -PassThru -Force


                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Force        = $true
                    Name         = 'DOMAIN\MyLogin'
                    State        = 'Deny'
                    Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                        ConnectSql = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodDenyCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodDenyCallCount | Should -Be 1
            }
        }

        Context 'When using parameter WhatIf' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                        $script:mockMethodDenyCallCount += 1
                    } -PassThru -Force


                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    WhatIf       = $true
                    Name         = 'DOMAIN\MyLogin'
                    State        = 'Deny'
                    Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                        ConnectSql = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodDenyCallCount = 0
            }

            It 'Should not call the mocked method' {
                { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodDenyCallCount | Should -Be 0
            }
        }

        Context 'When permission should be granted' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptMethod' -Name 'Grant' -Value {
                    $script:mockMethodGrantCallCount += 1
                } -PassThru -Force

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    Name         = 'DOMAIN\MyLogin'
                    State        = 'Grant'
                    Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                        ConnectSql = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodGrantCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodGrantCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscServerPermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodGrantCallCount | Should -Be 1
                }
            }
        }

        Context 'When permission should be granted and using parameter WithGrant' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Grant' -Value {
                        param
                        (
                            [Parameter()]
                            $Permission,

                            [Parameter()]
                            $Name,

                            [Parameter()]
                            $WithGrant
                        )

                        if ($WithGrant)
                        {
                            $script:mockMethodGrantUsingWithGrantCallCount += 1
                        }
                    } -PassThru -Force


                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    Name         = 'DOMAIN\MyLogin'
                    State        = 'Grant'
                    WithGrant    = $true
                    Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                        ConnectSql = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodGrantUsingWithGrantCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodGrantUsingWithGrantCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscServerPermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodGrantUsingWithGrantCallCount | Should -Be 1
                }
            }
        }

        Context 'When permission should be revoked' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Revoke' -Value {
                        $script:mockMethodRevokeCallCount += 1
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    Name         = 'DOMAIN\MyLogin'
                    State        = 'Revoke'
                    Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                        ConnectSql = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodRevokeCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodRevokeCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscServerPermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodRevokeCallCount | Should -Be 1
                }
            }
        }

        Context 'When permission should be revoked and using parameter WithGrant' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Revoke' -Value {
                        param
                        (
                            [Parameter()]
                            $Permission,

                            [Parameter()]
                            $Name,

                            [Parameter()]
                            $RevokeGrant,

                            [Parameter()]
                            $Cascade
                        )

                        if (-not $RevokeGrant -and $Cascade)
                        {
                            $script:mockMethodRevokeUsingWithGrantCallCount += 1
                        }
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    Name         = 'DOMAIN\MyLogin'
                    State        = 'Revoke'
                    WithGrant    = $true
                    Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                        ConnectSql = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodRevokeUsingWithGrantCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodRevokeUsingWithGrantCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscServerPermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodGrantUsingWithGrantCallCount | Should -Be 1
                }
            }
        }

        Context 'When permission should be denied' {
            BeforeAll {
                $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                    Add-Member -MemberType 'ScriptMethod' -Name 'Deny' -Value {
                        $script:mockMethodDenyCallCount += 1
                    } -PassThru -Force

                Mock -CommandName Test-SqlDscIsLogin -MockWith {
                    return $true
                }

                $script:mockDefaultParameters = @{
                    Confirm      = $false
                    Name         = 'DOMAIN\MyLogin'
                    State        = 'Deny'
                    Permission   = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
                        ConnectSql = $true
                    }
                }
            }

            BeforeEach {
                $script:mockMethodDenyCallCount = 0
            }

            It 'Should call the correct mocked method' {
                { Set-SqlDscServerPermission -ServerObject $mockServerObject @mockDefaultParameters } |
                    Should -Not -Throw

                $script:mockMethodDenyCallCount | Should -Be 1
            }

            Context 'When passing ServerObject over the pipeline' {
                It 'Should call the correct mocked method' {
                    { $mockServerObject | Set-SqlDscServerPermission @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodDenyCallCount | Should -Be 1
                }
            }

            Context 'When passing WithGrant' {
                BeforeAll {
                    Mock -CommandName Write-Warning
                }

                It 'Should output the correct warning message and return the correct values' {
                    $mockWarningMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.ServerPermission_IgnoreWithGrantForStateDeny
                    }

                    { $mockServerObject | Set-SqlDscServerPermission -WithGrant @mockDefaultParameters } |
                        Should -Not -Throw

                    $script:mockMethodDenyCallCount | Should -Be 1

                    Should -Invoke -CommandName 'Write-Warning' -ParameterFilter {
                        $Message -eq $mockWarningMessage
                    }
                }
            }
        }
    }
}
