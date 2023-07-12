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

Describe 'ConvertTo-SqlDscDatabasePermission' -Tag 'Public' {
    Context 'When passing empty collection as PermissionInfo' {
        BeforeAll {
            [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()
        }

        It 'Should return the correct values' {
            $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

            $mockResult | Should -HaveCount 0
        }

        Context 'When passing DatabasePermissionInfo over the pipeline' {
            It 'Should return the correct values' {
                $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                $mockResult | Should -HaveCount 0
            }
        }
    }

    Context 'When permission state is only Grant' {
        Context 'When the array contain a single PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet.Connect = $true

                $mockDatabasePermissionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo.PermissionState = 'Grant'
                $mockDatabasePermissionInfo.PermissionType = $mockDatabasePermissionSet

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Grant'
                $mockResult[0].Permission | Should -Contain 'Connect'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Grant'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'Grant'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Alter = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'Grant'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Grant'
                $mockResult[0].Permission | Should -Contain 'Connect'
                $mockResult[0].Permission | Should -Contain 'Alter'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Grant'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                    $mockResult[0].Permission | Should -Contain 'Alter'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a multiple permissions' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true
                $mockDatabasePermissionSet1.Select = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'Grant'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Alter = $true
                $mockDatabasePermissionSet2.Delete = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'Grant'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Grant'
                $mockResult[0].Permission | Should -Contain 'Connect'
                $mockResult[0].Permission | Should -Contain 'Alter'
                $mockResult[0].Permission | Should -Contain 'Select'
                $mockResult[0].Permission | Should -Contain 'Delete'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Grant'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                    $mockResult[0].Permission | Should -Contain 'Alter'
                    $mockResult[0].Permission | Should -Contain 'Select'
                    $mockResult[0].Permission | Should -Contain 'Delete'
                }
            }
        }
    }

    Context 'When permission state is only Deny' {
        Context 'When the array contain a single PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet.Connect = $true

                $mockDatabasePermissionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo.PermissionState = 'Deny'
                $mockDatabasePermissionInfo.PermissionType = $mockDatabasePermissionSet

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Deny'
                $mockResult[0].Permission | Should -Contain 'Connect'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Deny'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'Deny'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Alter = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'Deny'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Deny'
                $mockResult[0].Permission | Should -Contain 'Connect'
                $mockResult[0].Permission | Should -Contain 'Alter'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Deny'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                    $mockResult[0].Permission | Should -Contain 'Alter'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a multiple permissions' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true
                $mockDatabasePermissionSet1.Select = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'Deny'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Alter = $true
                $mockDatabasePermissionSet2.Delete = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'Deny'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'Deny'
                $mockResult[0].Permission | Should -Contain 'Connect'
                $mockResult[0].Permission | Should -Contain 'Alter'
                $mockResult[0].Permission | Should -Contain 'Select'
                $mockResult[0].Permission | Should -Contain 'Delete'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'Deny'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                    $mockResult[0].Permission | Should -Contain 'Alter'
                    $mockResult[0].Permission | Should -Contain 'Select'
                    $mockResult[0].Permission | Should -Contain 'Delete'
                }
            }
        }
    }

    Context 'When permission state is only GrantWithGrant' {
        Context 'When the array contain a single PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet.Connect = $true

                $mockDatabasePermissionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo.PermissionState = 'GrantWithGrant'
                $mockDatabasePermissionInfo.PermissionType = $mockDatabasePermissionSet

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'GrantWithGrant'
                $mockResult[0].Permission | Should -Contain 'Connect'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'GrantWithGrant'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a single permission' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'GrantWithGrant'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Alter = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'GrantWithGrant'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'GrantWithGrant'
                $mockResult[0].Permission | Should -Contain 'Connect'
                $mockResult[0].Permission | Should -Contain 'Alter'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'GrantWithGrant'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                    $mockResult[0].Permission | Should -Contain 'Alter'
                }
            }
        }

        Context 'When the array contain multiple PermissionInfo with a multiple permissions' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true
                $mockDatabasePermissionSet1.Select = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'GrantWithGrant'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Alter = $true
                $mockDatabasePermissionSet2.Delete = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'GrantWithGrant'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 1

                $mockResult[0].State | Should -Be 'GrantWithGrant'
                $mockResult[0].Permission | Should -Contain 'Connect'
                $mockResult[0].Permission | Should -Contain 'Alter'
                $mockResult[0].Permission | Should -Contain 'Select'
                $mockResult[0].Permission | Should -Contain 'Delete'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 1

                    $mockResult[0].State | Should -Be 'GrantWithGrant'
                    $mockResult[0].Permission | Should -Contain 'Connect'
                    $mockResult[0].Permission | Should -Contain 'Alter'
                    $mockResult[0].Permission | Should -Contain 'Select'
                    $mockResult[0].Permission | Should -Contain 'Delete'
                }
            }
        }
    }

    Context 'When permission state have all states Grant, GrantWithGrant, and Deny' {
        Context 'When the array contain multiple PermissionInfo with a multiple permissions' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo[]] $mockDatabasePermissionInfoCollection = @()

                $mockDatabasePermissionSet1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet1.Connect = $true
                $mockDatabasePermissionSet1.Select = $true

                $mockDatabasePermissionInfo1 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo1.PermissionState = 'GrantWithGrant'
                $mockDatabasePermissionInfo1.PermissionType = $mockDatabasePermissionSet1

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo1

                $mockDatabasePermissionSet2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet2.Alter = $true
                $mockDatabasePermissionSet2.Delete = $true

                $mockDatabasePermissionInfo2 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo2.PermissionState = 'Grant'
                $mockDatabasePermissionInfo2.PermissionType = $mockDatabasePermissionSet2

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo2

                $mockDatabasePermissionSet3 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionSet'
                $mockDatabasePermissionSet3.Update = $true
                $mockDatabasePermissionSet3.Insert = $true

                $mockDatabasePermissionInfo3 = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.DatabasePermissionInfo'
                $mockDatabasePermissionInfo3.PermissionState = 'Deny'
                $mockDatabasePermissionInfo3.PermissionType = $mockDatabasePermissionSet3

                $mockDatabasePermissionInfoCollection += $mockDatabasePermissionInfo3
            }

            It 'Should return the correct values' {
                $mockResult = ConvertTo-SqlDscDatabasePermission -DatabasePermissionInfo $mockDatabasePermissionInfoCollection

                $mockResult | Should -HaveCount 3

                $grantPermission = $mockResult.Where({ $_.State -eq 'Grant' })

                $grantPermission.State | Should -Be 'Grant'
                $grantPermission.Permission | Should -Contain 'Alter'
                $grantPermission.Permission | Should -Contain 'Delete'

                $grantWithGrantPermission = $mockResult.Where({ $_.State -eq 'GrantWithGrant' })

                $grantWithGrantPermission.State | Should -Be 'GrantWithGrant'
                $grantWithGrantPermission.Permission | Should -Contain 'Connect'
                $grantWithGrantPermission.Permission | Should -Contain 'Select'


                $denyPermission = $mockResult.Where({ $_.State -eq 'Deny' })

                $denyPermission.State | Should -Be 'Deny'
                $denyPermission.Permission | Should -Contain 'Update'
                $denyPermission.Permission | Should -Contain 'Insert'
            }

            Context 'When passing DatabasePermissionInfo over the pipeline' {
                It 'Should return the correct values' {
                    $mockResult = $mockDatabasePermissionInfoCollection | ConvertTo-SqlDscDatabasePermission

                    $mockResult | Should -HaveCount 3

                    $grantPermission = $mockResult.Where({ $_.State -eq 'Grant' })

                    $grantPermission.State | Should -Be 'Grant'
                    $grantPermission.Permission | Should -Contain 'Alter'
                    $grantPermission.Permission | Should -Contain 'Delete'

                    $grantWithGrantPermission = $mockResult.Where({ $_.State -eq 'GrantWithGrant' })

                    $grantWithGrantPermission.State | Should -Be 'GrantWithGrant'
                    $grantWithGrantPermission.Permission | Should -Contain 'Connect'
                    $grantWithGrantPermission.Permission | Should -Contain 'Select'


                    $denyPermission = $mockResult.Where({ $_.State -eq 'Deny' })

                    $denyPermission.State | Should -Be 'Deny'
                    $denyPermission.Permission | Should -Contain 'Update'
                    $denyPermission.Permission | Should -Contain 'Insert'
                }
            }
        }
    }
}
