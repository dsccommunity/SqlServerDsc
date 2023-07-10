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

Describe 'ConvertTo-SqlDscServerPermission' -Tag 'Public' {
    Context 'When passing empty collection as PermissionInfo' {
        BeforeAll {
            [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()
        }

        It 'Should return the correct values' {
            $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

            $mockResult | Should -HaveCount 0
        }

        Context 'When passing ServerPermissionInfo over the pipeline' {
            It 'Should return the correct values' {
                $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                $mockResult | Should -HaveCount 0
            }
        }
    }

    Context 'When permission state is only Grant' {
        Context 'When the array contain a single PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet.ConnectSql = $true

                $mockServerPermissionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo.PermissionState = 'Grant'
                $mockServerPermissionInfo.PermissionType = $mockServerPermissionSet

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Grant'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Grant'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'Grant'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.AlterAnyAvailabilityGroup = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'Grant'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Grant'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
                $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Grant'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                    $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a multiple permissions' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true
                $mockServerPermissionSet1.ViewServerState = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'Grant'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.AlterAnyAvailabilityGroup = $true
                $mockServerPermissionSet2.ControlServer = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'Grant'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Grant'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
                $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                $mockResult[0].Permission | Should -Contain 'ViewServerState'
                $mockResult[0].Permission | Should -Contain 'ControlServer'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Grant'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                    $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                    $mockResult[0].Permission | Should -Contain 'ViewServerState'
                    $mockResult[0].Permission | Should -Contain 'ControlServer'
                }
            }
        }
    }

    Context 'When permission state is only Deny' {
        Context 'When the array contain a single PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet.ConnectSql = $true

                $mockServerPermissionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo.PermissionState = 'Deny'
                $mockServerPermissionInfo.PermissionType = $mockServerPermissionSet

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Deny'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Deny'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'Deny'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.AlterAnyAvailabilityGroup = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'Deny'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Deny'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
                $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Deny'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                    $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a multiple permissions' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true
                $mockServerPermissionSet1.ViewServerState = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'Deny'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.AlterAnyAvailabilityGroup = $true
                $mockServerPermissionSet2.ControlServer = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'Deny'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Deny'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
                $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                $mockResult[0].Permission | Should -Contain 'ViewServerState'
                $mockResult[0].Permission | Should -Contain 'ControlServer'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Deny'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                    $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                    $mockResult[0].Permission | Should -Contain 'ViewServerState'
                    $mockResult[0].Permission | Should -Contain 'ControlServer'
                }
            }
        }
    }

    Context 'When permission state is only GrantWithGrant' {
        Context 'When the array contain a single PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet.ConnectSql = $true

                $mockServerPermissionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo.PermissionState = 'GrantWithGrant'
                $mockServerPermissionInfo.PermissionType = $mockServerPermissionSet

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'GrantWithGrant'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'GrantWithGrant'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'GrantWithGrant'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.AlterAnyAvailabilityGroup = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'GrantWithGrant'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'GrantWithGrant'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
                $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'GrantWithGrant'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                    $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a multiple permissions' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true
                $mockServerPermissionSet1.ViewServerState = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'GrantWithGrant'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.AlterAnyAvailabilityGroup = $true
                $mockServerPermissionSet2.ControlServer = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'GrantWithGrant'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'GrantWithGrant'
                $mockResult[0].Permission | Should -Contain 'ConnectSql'
                $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                $mockResult[0].Permission | Should -Contain 'ViewServerState'
                $mockResult[0].Permission | Should -Contain 'ControlServer'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'GrantWithGrant'
                    $mockResult[0].Permission | Should -Contain 'ConnectSql'
                    $mockResult[0].Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                    $mockResult[0].Permission | Should -Contain 'ViewServerState'
                    $mockResult[0].Permission | Should -Contain 'ControlServer'
                }
            }
        }
    }

    Context 'When permission state have all states Grant, GrantWithGrant, and Deny' {
        Context 'When the array contain multiple PermissionInfo with a multiple permissions' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.ServerPermissionInfo[]] $mockServerPermissionInfoCollection = @()

                $mockServerPermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet1.ConnectSql = $true
                $mockServerPermissionSet1.ViewServerState = $true

                $mockServerPermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo1.PermissionState = 'GrantWithGrant'
                $mockServerPermissionInfo1.PermissionType = $mockServerPermissionSet1

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo1

                $mockServerPermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet2.AlterAnyAvailabilityGroup = $true
                $mockServerPermissionSet2.ControlServer = $true

                $mockServerPermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo2.PermissionState = 'Grant'
                $mockServerPermissionInfo2.PermissionType = $mockServerPermissionSet2

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo2

                $mockServerPermissionSet3 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionSet'
                $mockServerPermissionSet3.AlterAnyEndpoint = $true
                $mockServerPermissionSet3.CreateEndpoint = $true

                $mockServerPermissionInfo3 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.ServerPermissionInfo'
                $mockServerPermissionInfo3.PermissionState = 'Deny'
                $mockServerPermissionInfo3.PermissionType = $mockServerPermissionSet3

                $mockServerPermissionInfoCollection += $mockServerPermissionInfo3
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscServerPermission -ServerPermissionInfo $mockServerPermissionInfoCollection

                $mockResult | Should -HaveCount 3

                $grantPermission = $mockResult.Where({ $_.State -eq 'Grant' })

                $grantPermission.State | Should -Be 'Grant'
                $grantPermission.Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                $grantPermission.Permission | Should -Contain 'ControlServer'

                $grantWithGrantPermission = $mockResult.Where({ $_.State -eq 'GrantWithGrant' })

                $grantWithGrantPermission.State | Should -Be 'GrantWithGrant'
                $grantWithGrantPermission.Permission | Should -Contain 'ConnectSql'
                $grantWithGrantPermission.Permission | Should -Contain 'ViewServerState'


                $denyPermission = $mockResult.Where({ $_.State -eq 'Deny' })

                $denyPermission.State | Should -Be 'Deny'
                $denyPermission.Permission | Should -Contain 'AlterAnyEndpoint'
                $denyPermission.Permission | Should -Contain 'CreateEndpoint'
            }

            Context 'When passing ServerPermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockServerPermissionInfoCollection | ConvertTo-SqlDscServerPermission

                    $mockResult | Should -HaveCount 3

                    $grantPermission = $mockResult.Where({ $_.State -eq 'Grant' })

                    $grantPermission.State | Should -Be 'Grant'
                    $grantPermission.Permission | Should -Contain 'AlterAnyAvailabilityGroup'
                    $grantPermission.Permission | Should -Contain 'ControlServer'

                    $grantWithGrantPermission = $mockResult.Where({ $_.State -eq 'GrantWithGrant' })

                    $grantWithGrantPermission.State | Should -Be 'GrantWithGrant'
                    $grantWithGrantPermission.Permission | Should -Contain 'ConnectSql'
                    $grantWithGrantPermission.Permission | Should -Contain 'ViewServerState'


                    $denyPermission = $mockResult.Where({ $_.State -eq 'Deny' })

                    $denyPermission.State | Should -Be 'Deny'
                    $denyPermission.Permission | Should -Contain 'AlterAnyEndpoint'
                    $denyPermission.Permission | Should -Contain 'CreateEndpoint'
                }
            }
        }
    }
}
