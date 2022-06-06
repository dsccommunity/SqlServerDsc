<#
    .SYNOPSIS
        Unit test for DSC_SqlPermission DSC resource.
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
    $script:dscResourceName = 'DSC_SqlPermission'

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

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
}

Describe 'SqlPermission\Get-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'DEFAULT'
                ServerName   = 'localhost'
                Principal    = 'COMPANY\SqlServiceAcct'
                Permission   = @('ConnectSql', 'AlterAnyAvailabilityGroup', 'ViewServerState')
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockObjectSmoServer.Name = "localhost\DEFAULT"
                $mockObjectSmoServer.DisplayName = 'DEFAULT'
                $mockObjectSmoServer.InstanceName = 'DEFAULT'
                $mockObjectSmoServer.IsHadrEnabled = $false
                $mockObjectSmoServer.MockGranteeName = 'COMPANY\SqlServiceAcct'

                return $mockObjectSmoServer
            }
        }

        Context 'When no permission is set for the principal' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false
            }

            It 'Should return the desired state as absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be 'localhost'
                    $result.InstanceName | Should -Be 'DEFAULT'
                    $result.Principal | Should -Be 'COMPANY\SqlServiceAcct'
                }
            }

            It 'Should not return any permissions' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Permission | Should -Be ''
                }
            }

            It 'Should call the mock function Connect-SQL' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When one permission is missing for the principal' {
            BeforeAll {
                [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true
            }

            AfterAll {
                [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $mockGetTargetResourceParameters.Permission = @( 'AlterAnyAvailabilityGroup', 'ViewServerState', 'AlterAnyEndpoint')
                }
            }

            It 'Should return the desired state as absent' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Ensure | Should -Be 'Absent'
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be 'localhost'
                    $result.InstanceName | Should -Be 'DEFAULT'
                    $result.Principal | Should -Be 'COMPANY\SqlServiceAcct'
                }
            }

            It 'Should not return any permissions' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.Permission | Should -Be @('AlterAnyAvailabilityGroup', 'ConnectSql', 'ViewServerState')
                }
            }

            It 'Should call the mock function Connect-SQL' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    Get-TargetResource @mockGetTargetResourceParameters | Out-Null

                    Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When the Get-TargetResource throws an error' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                throw 'Mocked error.'
            }
        }

        It 'Should return the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = $script:localizedData.PermissionGetError -f 'COMPANY\SqlServiceAcct'

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockObjectSmoServer.Name = "localhost\DEFAULT"
                $mockObjectSmoServer.DisplayName = 'DEFAULT'
                $mockObjectSmoServer.InstanceName = 'DEFAULT'
                $mockObjectSmoServer.IsHadrEnabled = $false
                $mockObjectSmoServer.MockGranteeName = 'COMPANY\SqlServiceAcct'

                return $mockObjectSmoServer
            }

            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true
        }

        AfterAll {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false
        }

        It 'Should return the desired state as present' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ServerName | Should -Be 'localhost'
                $result.InstanceName | Should -Be 'DEFAULT'
                $result.Principal | Should -Be 'COMPANY\SqlServiceAcct'
            }
        }

        It 'Should return the permissions passed as parameter' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                foreach ($currentPermission in @('ConnectSql', 'AlterAnyAvailabilityGroup', 'ViewServerState'))
                {
                    if ( $result.Permission -ccontains $currentPermission )
                    {
                        $permissionState = $true
                    }
                    else
                    {
                        $permissionState = $false
                        break
                    }
                }

                $permissionState | Should -BeTrue
            }
        }

        It 'Should call the mock function Connect-SQL' {
            InModuleScope -ScriptBlock {
                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlPermission\Test-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'DEFAULT'
                ServerName   = 'localhost'
                Principal    = 'COMPANY\SqlServiceAcct'
                Permission   = @('ConnectSql', 'AlterAnyAvailabilityGroup', 'ViewServerState')
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockObjectSmoServer.Name = "localhost\DEFAULT"
                $mockObjectSmoServer.DisplayName = 'DEFAULT'
                $mockObjectSmoServer.InstanceName = 'DEFAULT'
                $mockObjectSmoServer.IsHadrEnabled = $false
                $mockObjectSmoServer.MockGranteeName = 'COMPANY\SqlServiceAcct'

                return $mockObjectSmoServer
            }
        }

        It 'Should return that desired state is absent when wanted desired state is to be Present' {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters.Add('Ensure', 'Present')

                $result = Test-TargetResource @mockTestTargetResourceParameters
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return that desired state is absent when wanted desired state is to be Absent' {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters.Add('Ensure', 'Absent')

                $result = Test-TargetResource @mockTestTargetResourceParameters
                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockObjectSmoServer.Name = "localhost\DEFAULT"
                $mockObjectSmoServer.DisplayName = 'DEFAULT'
                $mockObjectSmoServer.InstanceName = 'DEFAULT'
                $mockObjectSmoServer.IsHadrEnabled = $false
                $mockObjectSmoServer.MockGranteeName = 'COMPANY\SqlServiceAcct'

                return $mockObjectSmoServer
            }
        }

        It 'Should return that desired state is present when wanted desired state is to be Present' {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters.Add('Ensure', 'Present')

                $result = Test-TargetResource @mockTestTargetResourceParameters
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false
        }

        It 'Should return that desired state is present when wanted desired state is to be Absent' {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockTestTargetResourceParameters.Add('Ensure', 'Absent')

                $result = Test-TargetResource @mockTestTargetResourceParameters
                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlPermission\Set-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'DEFAULT'
                ServerName   = 'localhost'
                Principal    = 'COMPANY\SqlServiceAcct'
                Permission   = @('ConnectSql', 'AlterAnyAvailabilityGroup', 'ViewServerState')
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockObjectSmoServer.Name = "localhost\DEFAULT"
                $mockObjectSmoServer.DisplayName = 'DEFAULT'
                $mockObjectSmoServer.InstanceName = 'DEFAULT'
                $mockObjectSmoServer.IsHadrEnabled = $false
                $mockObjectSmoServer.MockGranteeName = 'COMPANY\SqlServiceAcct'

                return $mockObjectSmoServer
            }
        }

        It 'Should not throw error when desired state is to be Present' {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.Add('Ensure', 'Present')

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It
        }

        It 'Should not throw error when desired state is to be Absent' {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.Add('Ensure', 'Absent')

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 2 -Scope It

            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Connect-SQL -MockWith {
                $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockObjectSmoServer.Name = "localhost\DEFAULT"
                $mockObjectSmoServer.DisplayName = 'DEFAULT'
                $mockObjectSmoServer.InstanceName = 'DEFAULT'
                $mockObjectSmoServer.IsHadrEnabled = $false
                $mockObjectSmoServer.MockGranteeName = 'COMPANY\SqlServiceAcct'

                return $mockObjectSmoServer
            }
        }

        It 'Should not throw error when desired state is to be Present' {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $true

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.Add('Ensure', 'Present')

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false
        }

        It 'Should not throw error when desired state is to be Absent' {
            [Microsoft.SqlServer.Management.Smo.Globals]::GenerateMockData = $false

            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockSetTargetResourceParameters.Add('Ensure', 'Absent')

                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
            }

            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        Context 'When the Set-TargetResource throws an error' {
            BeforeAll {
                Mock -CommandName Connect-SQL -MockWith {
                    $mockObjectSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockObjectSmoServer.Name = "localhost\DEFAULT"
                    $mockObjectSmoServer.DisplayName = 'DEFAULT'
                    $mockObjectSmoServer.InstanceName = 'DEFAULT'
                    $mockObjectSmoServer.IsHadrEnabled = $false
                    # This make the SMO Server object mock to throw when Grant() method is called.
                    $mockObjectSmoServer.MockGranteeName = 'COMPANY\OtherAccount'

                    return $mockObjectSmoServer
                }

            }
            It 'Should return the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.ChangingPermissionFailed -f 'COMPANY\SqlServiceAcct'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')
                }
            }
        }
    }

    Assert-VerifiableMock
}
