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

    Import-Module -Name $script:dscModuleName

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
}

Describe 'DatabasePermission' -Tag 'DatabasePermission' {
    Context 'When instantiating the class' {
        It 'Should not throw an error' {
            $script:mockDatabasePermissionInstance = InModuleScope -ScriptBlock {
                [DatabasePermission]::new()
            }
        }

        It 'Should be of the correct type' {
            $mockDatabasePermissionInstance | Should -Not -BeNullOrEmpty
            $mockDatabasePermissionInstance.GetType().Name | Should -Be 'DatabasePermission'
        }
    }

    Context 'When setting an reading values' {
        It 'Should be able to set value in instance' {
            $script:mockDatabasePermissionInstance = InModuleScope -ScriptBlock {
                $databasPermissionInstance = [DatabasePermission]::new()

                $databasPermissionInstance.State = 'Grant'
                $databasPermissionInstance.Permission = 'select'

                return $databasPermissionInstance
            }
        }

        It 'Should be able read the values from instance' {
            $mockDatabasePermissionInstance.State | Should -Be 'Grant'
            $mockDatabasePermissionInstance.Permission = 'select'
        }
    }

    Context 'When comparing two objects' {
        # TODO: See comment in code regarding the code this test was suppose to cover.
        # Context 'When the object to compare against is the wrong type' {
        #     It 'Should throw an error on compare' {
        #         InModuleScope -ScriptBlock {
        #             $databasPermissionInstance = [DatabasePermission]::new()

        #             $databasPermissionInstance.State = 'Grant'
        #             $databasPermissionInstance.Permission = 'select'

        #             # Must escape the brackets with ` for expected message comparison to work.
        #             { $databasPermissionInstance -eq 'invalid type' } |
        #                 Should -Throw -ExpectedMessage 'Invalid type in comparison. Expected type `[DatabasePermission`], but the type was `[System.String`].'
        #         }
        #     }
        # }

        Context 'When both objects are equal' {
            Context 'When property Permission has a single value' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        $databasPermissionInstance1 = [DatabasePermission]::new()

                        $databasPermissionInstance1.State = 'Grant'
                        $databasPermissionInstance1.Permission = 'select'

                        $databasPermissionInstance2 = [DatabasePermission]::new()

                        $databasPermissionInstance2.State = 'Grant'
                        $databasPermissionInstance2.Permission = 'select'

                        $databasPermissionInstance1 -eq $databasPermissionInstance2 | Should -BeTrue
                    }
                }
            }

            Context 'When property Permission has a multiple values' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        $databasPermissionInstance1 = [DatabasePermission]::new()

                        $databasPermissionInstance1.State = 'Grant'
                        $databasPermissionInstance1.Permission = @('select', 'update')

                        $databasPermissionInstance2 = [DatabasePermission]::new()

                        $databasPermissionInstance2.State = 'Grant'
                        $databasPermissionInstance2.Permission = @('select', 'update')

                        $databasPermissionInstance1 -eq $databasPermissionInstance2 | Should -BeTrue
                    }
                }
            }
        }

        Context 'When object has different value for property State' {
            It 'Should instantiate two objects' {
                $script:mockDatabasePermissionInstance1 = InModuleScope -ScriptBlock {
                    $databasPermissionInstance = [DatabasePermission]::new()

                    $databasPermissionInstance.State = 'Deny'
                    $databasPermissionInstance.Permission = 'select'

                    return $databasPermissionInstance
                }

                $script:mockDatabasePermissionInstance1 = InModuleScope -ScriptBlock {
                    $databasPermissionInstance = [DatabasePermission]::new()

                    $databasPermissionInstance.State = 'Grant'
                    $databasPermissionInstance.Permission = 'select'

                    return $databasPermissionInstance
                }
            }

            It 'Should return $false' {
                $mockDatabasePermissionInstance1 -eq $mockDatabasePermissionInstance2 | Should -BeFalse
            }
        }

        Context 'When object has different value for property Permission' {
            It 'Should instantiate two objects' {
                $script:mockDatabasePermissionInstance1 = InModuleScope -ScriptBlock {
                    $databasPermissionInstance = [DatabasePermission]::new()

                    $databasPermissionInstance.State = 'Grant'
                    $databasPermissionInstance.Permission = 'select'

                    return $databasPermissionInstance
                }

                $script:mockDatabasePermissionInstance1 = InModuleScope -ScriptBlock {
                    $databasPermissionInstance = [DatabasePermission]::new()

                    $databasPermissionInstance.State = 'Grant'
                    $databasPermissionInstance.Permission = 'update'

                    return $databasPermissionInstance
                }
            }

            It 'Should return $false' {
                $mockDatabasePermissionInstance1 -eq $mockDatabasePermissionInstance2 | Should -BeFalse
            }
        }
    }
}
