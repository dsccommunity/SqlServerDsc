<#
    .SYNOPSIS
        Unit test for ServerPermission class.
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
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

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

Describe 'ServerPermission' -Tag 'ServerPermission' {
    Context 'When instantiating the class' {
        It 'Should not throw an error' {
            $script:mockServerPermissionInstance = InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                [ServerPermission]::new()
            }
        }

        It 'Should be of the correct type' {
            $script:mockServerPermissionInstance | Should -Not -BeNullOrEmpty
            $script:mockServerPermissionInstance.GetType().Name | Should -Be 'ServerPermission'
        }
    }

    Context 'When setting an reading values' {
        It 'Should be able to set value in instance' {
            $script:mockServerPermissionInstance = InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $databasePermissionInstance = [ServerPermission]::new()

                $databasePermissionInstance.State = 'Grant'
                $databasePermissionInstance.Permission = 'ViewServerState'

                return $databasePermissionInstance
            }
        }

        It 'Should be able read the values from instance' {
            $script:mockServerPermissionInstance.State | Should -Be 'Grant'
            $script:mockServerPermissionInstance.Permission | Should -Be 'ViewServerState'
        }
    }

    Context 'When comparing two objects using method Equals()' {
        Context 'When both objects are equal' {
            Context 'When property Permission has a single value' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $databasePermissionInstance1 = [ServerPermission]::new()

                        $databasePermissionInstance1.State = 'Grant'
                        $databasePermissionInstance1.Permission = 'ViewServerState'

                        $databasePermissionInstance2 = [ServerPermission]::new()

                        $databasePermissionInstance2.State = 'Grant'
                        $databasePermissionInstance2.Permission = 'ViewServerState'

                        $databasePermissionInstance1 -eq $databasePermissionInstance2 | Should -BeTrue
                    }
                }
            }

            Context 'When property Permission has a multiple values' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $databasePermissionInstance1 = [ServerPermission]::new()

                        $databasePermissionInstance1.State = 'Grant'
                        $databasePermissionInstance1.Permission = @('ViewServerState', 'AlterAnyAvailabilityGroup')

                        $databasePermissionInstance2 = [ServerPermission]::new()

                        $databasePermissionInstance2.State = 'Grant'
                        $databasePermissionInstance2.Permission = @('ViewServerState', 'AlterAnyAvailabilityGroup')

                        $databasePermissionInstance1 -eq $databasePermissionInstance2 | Should -BeTrue
                    }
                }
            }
        }

        Context 'When object has different value for property State' {
            It 'Should instantiate two objects' {
                $script:mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $databasePermissionInstance = [ServerPermission]::new()

                    $databasePermissionInstance.State = 'Deny'
                    $databasePermissionInstance.Permission = 'ViewServerState'

                    return $databasePermissionInstance
                }

                $script:mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $databasePermissionInstance = [ServerPermission]::new()

                    $databasePermissionInstance.State = 'Grant'
                    $databasePermissionInstance.Permission = 'ViewServerState'

                    return $databasePermissionInstance
                }
            }

            It 'Should return $false' {
                $script:mockServerPermissionInstance1 -eq $script:mockServerPermissionInstance2 | Should -BeFalse
            }
        }

        Context 'When object has different value for property Permission' {
            It 'Should instantiate two objects' {
                $script:mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $databasePermissionInstance = [ServerPermission]::new()

                    $databasePermissionInstance.State = 'Grant'
                    $databasePermissionInstance.Permission = 'ViewServerState'

                    return $databasePermissionInstance
                }

                $script:mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $databasePermissionInstance = [ServerPermission]::new()

                    $databasePermissionInstance.State = 'Grant'
                    $databasePermissionInstance.Permission = 'AlterAnyAvailabilityGroup'

                    return $databasePermissionInstance
                }
            }

            It 'Should return $false' {
                $script:mockServerPermissionInstance1 -eq $script:mockServerPermissionInstance2 | Should -BeFalse
            }
        }
    }

    Context 'When comparing two objects using method CompareTo()' {
        Context 'When the instance is compared against an invalid object' {
            It 'Should return a value less than zero' {
                $mockServerPermissionInstance1 = InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    [ServerPermission] @{
                        State      = 'Grant'
                        Permission = 'ViewServerState'
                    }
                }

                $mockErrorMessage = InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
            BeforeDiscovery {
                $testCases = @(
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
                )
            }

            Context 'When the instance has the state ''<MockInstanceState>'' and object has state ''<MockObjectState>''' -ForEach $testCases {
                It 'Should return a value less than zero' {
                    $mockServerPermissionInstance1 = InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        [ServerPermission] @{
                            State      = $MockInstanceState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance2 = InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

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
            BeforeDiscovery {
                $testCases = @(
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
                )
            }

            Context 'When the instance has the state ''<MockInstanceState>'' and object has state ''<MockObjectState>''' -ForEach $testCases {
                It 'Should return a value less than zero' {
                    $mockServerPermissionInstance1 = InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        [ServerPermission] @{
                            State      = $MockInstanceState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance2 = InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

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
                        Set-StrictMode -Version 1.0

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
            BeforeDiscovery {
                $testCases = @(
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
                )
            }

            Context 'When the instance has the state ''<MockInstanceState>'' and object has state ''<MockObjectState>''' -ForEach $testCases {
                It 'Should return a value less than zero' {
                    $mockServerPermissionInstance1 = InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        [ServerPermission] @{
                            State      = $MockInstanceState
                            Permission = 'ViewServerState'
                        }
                    }

                    $mockServerPermissionInstance2 = InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

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
            BeforeDiscovery {
                $testCases = @(
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
                )
            }

            It 'Should always sort in the correct order' -ForEach $testCases {
                $mockServerPermissionArray = @(
                    InModuleScope -Parameters $_ -ScriptBlock {
                        Set-StrictMode -Version 1.0

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
