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

Describe 'ServerPermission' -Tag 'ServerPermission' {
    Context 'When instantiating the class' {
        It 'Should not throw an error' {
            $script:mockServerPermissionInstance = InModuleScope -ScriptBlock {
                [ServerPermission]::new()
            }
        }

        It 'Should be of the correct type' {
            $mockServerPermissionInstance | Should -Not -BeNullOrEmpty
            $mockServerPermissionInstance.GetType().Name | Should -Be 'ServerPermission'
        }
    }

    Context 'When setting an reading values' {
        It 'Should be able to set value in instance' {
            $script:mockServerPermissionInstance = InModuleScope -ScriptBlock {
                $databasPermissionInstance = [ServerPermission]::new()

                $databasPermissionInstance.State = 'Grant'
                $databasPermissionInstance.Permission = 'ViewServerState'

                return $databasPermissionInstance
            }
        }

        It 'Should be able read the values from instance' {
            $mockServerPermissionInstance.State | Should -Be 'Grant'
            $mockServerPermissionInstance.Permission = 'ViewServerState'
        }
    }

    Context 'When comparing two objects using method Equals()' {
        Context 'When both objects are equal' {
            Context 'When property Permission has a single value' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        $databasPermissionInstance1 = [ServerPermission]::new()

                        $databasPermissionInstance1.State = 'Grant'
                        $databasPermissionInstance1.Permission = 'ViewServerState'

                        $databasPermissionInstance2 = [ServerPermission]::new()

                        $databasPermissionInstance2.State = 'Grant'
                        $databasPermissionInstance2.Permission = 'ViewServerState'

                        $databasPermissionInstance1 -eq $databasPermissionInstance2 | Should -BeTrue
                    }
                }
            }

            Context 'When property Permission has a multiple values' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        $databasPermissionInstance1 = [ServerPermission]::new()

                        $databasPermissionInstance1.State = 'Grant'
                        $databasPermissionInstance1.Permission = @('ViewServerState', 'AlterAnyAvailabilityGroup')

                        $databasPermissionInstance2 = [ServerPermission]::new()

                        $databasPermissionInstance2.State = 'Grant'
                        $databasPermissionInstance2.Permission = @('ViewServerState', 'AlterAnyAvailabilityGroup')

                        $databasPermissionInstance1 -eq $databasPermissionInstance2 | Should -BeTrue
                    }
                }
            }
        }

        Context 'When object has different value for property State' {
            It 'Should instantiate two objects' {
                $script:mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    $databasPermissionInstance = [ServerPermission]::new()

                    $databasPermissionInstance.State = 'Deny'
                    $databasPermissionInstance.Permission = 'ViewServerState'

                    return $databasPermissionInstance
                }

                $script:mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    $databasPermissionInstance = [ServerPermission]::new()

                    $databasPermissionInstance.State = 'Grant'
                    $databasPermissionInstance.Permission = 'ViewServerState'

                    return $databasPermissionInstance
                }
            }

            It 'Should return $false' {
                $mockServerPermissionInstance1 -eq $mockServerPermissionInstance2 | Should -BeFalse
            }
        }

        Context 'When object has different value for property Permission' {
            It 'Should instantiate two objects' {
                $script:mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    $databasPermissionInstance = [ServerPermission]::new()

                    $databasPermissionInstance.State = 'Grant'
                    $databasPermissionInstance.Permission = 'ViewServerState'

                    return $databasPermissionInstance
                }

                $script:mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    $databasPermissionInstance = [ServerPermission]::new()

                    $databasPermissionInstance.State = 'Grant'
                    $databasPermissionInstance.Permission = 'AlterAnyAvailabilityGroup'

                    return $databasPermissionInstance
                }
            }

            It 'Should return $false' {
                $mockServerPermissionInstance1 -eq $mockServerPermissionInstance2 | Should -BeFalse
            }
        }
    }

    Context 'When comparing two objects using method CompareTo()' {
        Context 'When the instance is compared against an invalid object' {
            It 'Should return a value less than zero' {
                $mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    [ServerPermission] @{
                        State      = 'Grant'
                        Permission = 'ViewServerState'
                    }
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.InvalidTypeForCompare
                }

                $mockErrorMessage = $mockErrorMessage -f @(
                    $mockServerPermissionInstance1.GetType().FullName
                    'System.String'
                )

                $mockErrorMessage += " (Parameter 'Object')"

                # Escape the brackets so Pester can evaluate the string correctly.
                $mockErrorMessage = $mockErrorMessage -replace '\[', '`['
                $mockErrorMessage = $mockErrorMessage -replace '\]', '`]'

                { $mockServerPermissionInstance1.CompareTo('AnyValue') } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        Context 'When the instance precedes the object being compared' {
            Context 'When the instance has the state ''<MockInstanceState>'' and object has state ''<MockObjectState>''' -ForEach @(
                @{
                    MockInstanceState = 'Grant'
                    MockObjectState   = 'GrantWithGrant'
                }
                @{
                    MockInstanceState = 'Grant'
                    MockObjectState   = 'Deny'
                }
                @{
                    MockInstanceState = 'GrantWithGrant'
                    MockObjectState   = 'Deny'
                }
            ) {
                It 'Should return a value less than zero' {
                    $mockServerPermissionInstance1 = InModuleScope -Parameters $_ -ScriptBlock {
                        [ServerPermission] @{
                            State      = $MockInstanceState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance2 = InModuleScope -Parameters $_ -ScriptBlock {
                        [ServerPermission] @{
                            State      = $MockObjectState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance1.CompareTo($mockServerPermissionInstance2) | Should -BeLessThan 0
                }
            }
        }

        Context 'When the instance follows the object being compared' {
            Context 'When the instance has the state ''<MockInstanceState>'' and object has state ''<MockObjectState>''' -ForEach @(
                @{
                    MockInstanceState = 'Deny'
                    MockObjectState   = 'Grant'
                }
                @{
                    MockInstanceState = 'GrantWithGrant'
                    MockObjectState   = 'Grant'
                }
                @{
                    MockInstanceState = 'Deny'
                    MockObjectState   = 'GrantWithGrant'
                }
            ) {
                It 'Should return a value less than zero' {
                    $mockServerPermissionInstance1 = InModuleScope -Parameters $_ -ScriptBlock {
                        [ServerPermission] @{
                            State      = $MockInstanceState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance2 = InModuleScope -Parameters $_ -ScriptBlock {
                        [ServerPermission] @{
                            State      = $MockObjectState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance1.CompareTo($mockServerPermissionInstance2) | Should -BeGreaterThan 0
                }
            }

            Context 'When the instance is compared against an object that is $null' {
                It 'Should return a value less than zero' {
                    $mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                        [ServerPermission] @{
                            State      = 'Grant'
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance1.CompareTo($null) | Should -BeGreaterThan 0
                }
            }
        }

        Context 'When the instance is in the same position as the object being compared' {
            Context 'When the instance has the state ''<MockInstanceState>'' and object has state ''<MockObjectState>''' -ForEach @(
                @{
                    MockInstanceState = 'Grant'
                    MockObjectState   = 'Grant'
                }
                @{
                    MockInstanceState = 'GrantWithGrant'
                    MockObjectState   = 'GrantWithGrant'
                }
                @{
                    MockInstanceState = 'Deny'
                    MockObjectState   = 'Deny'
                }
            ) {
                It 'Should return a value less than zero' {
                    $mockServerPermissionInstance1 = InModuleScope -Parameters $_ -ScriptBlock {
                        [ServerPermission] @{
                            State      = $MockInstanceState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance2 = InModuleScope -Parameters $_ -ScriptBlock {
                        [ServerPermission] @{
                            State      = $MockObjectState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance1.CompareTo($mockServerPermissionInstance2) | Should -Be 0
                }
            }
        }

        Context 'When sorting the instances' {
            It 'Should always sort in the correct order' -ForEach @(
                @{
                    MockState = @('Grant', 'GrantWithGrant', 'Deny')
                }
                @{
                    MockState = @('GrantWithGrant', 'Grant', 'Deny')
                }
                @{
                    MockState = @('GrantWithGrant', 'Deny', 'Grant')
                }
                @{
                    MockState = @('Deny', 'GrantWithGrant', 'Grant')
                }
                @{
                    MockState = @('Grant', 'Deny', 'GrantWithGrant')
                }
                @{
                    MockState = @('Deny', 'Grant', 'GrantWithGrant')
                }
            ) {
                $mockServerPermissionArray = @(
                    InModuleScope -Parameters $_ -ScriptBlock {
                        foreach ($currentMockState in $MockState)
                        {
                            [ServerPermission] @{
                                State      = $currentMockState
                                Permission = 'ViewServerState'
                            }
                        }
                    }
                )

                $mockSortedArray = $mockServerPermissionArray | Sort-Object

                $mockSortedArray[0].State | Should -Be 'Grant'
                $mockSortedArray[1].State | Should -Be 'GrantWithGrant'
                $mockSortedArray[2].State | Should -Be 'Deny'
            }
        }
    }
}
