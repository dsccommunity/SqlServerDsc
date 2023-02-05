<#
    .SYNOPSIS
        Unit test for DSC_SqlDatabaseDefaultLocation DSC resource.
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
    $script:dscResourceName = 'DSC_SqlDatabaseDefaultLocation'

    $env:SqlServerDscCI = $true

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'SqlDatabaseDefaultLocation\Get-TargetResource' {
    BeforeAll {
        $mockConnectSQL = {
            $mockSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server

            $mockSmoServer.InstanceName = 'MSSQLSERVER'
            $mockSmoServer.ComputerNamePhysicalNetBIOS = 'localhost'
            $mockSmoServer.DefaultFile = 'C:\Program Files\Data\'
            $mockSmoServer.DefaultLog = 'C:\Program Files\Log\'
            <#
                Ending backslash is not set on the backup directory path here
                because of a regression test for issue #1307.
            #>
            $mockSmoServer.BackupDirectory = 'C:\Program Files\Backup'

            return $mockSmoServer
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Test-ActiveNode -MockWith {
                return $true
            }
        }

        Context 'When passing the parameter Type with the value ''<Type>''' -ForEach @(
            @{
                Type               = 'Data'
                Path               = 'C:\Program Files\Data\'
            },
            @{
                Type               = 'Log'
                Path               = 'C:\Program Files\Log\'
            },
            @{
                Type               = 'Backup'
                # Ending backslash is removed because of regression test for issue #1307.
                Path               = 'C:\Program Files\Backup'
            }
        ) {
            It 'Should return the correct values' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters -Type $Type -Path $Path

                    # Ending backslash is removed because of regression test for issue #1307.
                    $getTargetResourceResult.Path | Should -Be $Path
                    $getTargetResourceResult.Type | Should -Be $Type
                    $getTargetResourceResult.ServerName | Should -Be $mockGetTargetResourceParameters.ServerName
                    $getTargetResourceResult.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    $getTargetResourceResult.IsActiveNode | Should -BeTrue
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlDatabaseDefaultLocation\Test-TargetResource' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When passing the parameter Type with the value ''<Type>''' -ForEach @(
            @{
                Type               = 'Data'
                Path               = 'C:\Program Files\Data\'
            },
            @{
                Type               = 'Log'
                Path               = 'C:\Program Files\Log\'
            },
            @{
                Type               = 'Backup'
                # Ending backslash is removed because of regression test for issue #1307.
                Path               = 'C:\Program Files\Backup'
            }
        ) {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Type               = $Type
                        Path               = $Path
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        IsActiveNode       = $true
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters -Type $Type -Path $Path

                    $testTargetResourceResult | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Get-TargetResource returns the property IsActiveNode as <IsActiveNode>' -ForEach @(
            @{
                IsActiveNode = $false
            }
            @{
                IsActiveNode = $true
            }
        ) {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Type               = 'Data'
                        Path               = 'C:\Program Files\Data\'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        IsActiveNode       = $IsActiveNode
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.ProcessOnlyOnActiveNode = $true
                    $mockTestTargetResourceParameters.Type = 'Data'
                    $mockTestTargetResourceParameters.Path = 'C:\Program Files\Data\'

                    $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                    $testTargetResourceResult | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When passing the parameter Type with the value ''<Type>''' -ForEach @(
            @{
                Type               = 'Data'
                Path               = 'C:\Program Files\Data\'
            },
            @{
                Type               = 'Log'
                Path               = 'C:\Program Files\Log\'
            },
            @{
                Type               = 'Backup'
                # Ending backslash is removed because of regression test for issue #1307.
                Path               = 'C:\Program Files\Backup'
            }
        ) {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Type               = $Type
                        Path               = 'C:\OtherPath'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        IsActiveNode       = $true
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters -Type $Type -Path $Path

                    $testTargetResourceResult | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Get-TargetResource returns the property IsActiveNode as <IsActiveNode>' -ForEach @(
            @{
                IsActiveNode = $false
                ExpectedReturnValue = $true
            }
            @{
                IsActiveNode = $true
                ExpectedReturnValue = $false
            }
        ) {
            BeforeEach {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Type               = 'Data'
                        Path               = 'C:\OtherPath'
                        ServerName         = 'localhost'
                        InstanceName       = 'MSSQLSERVER'
                        IsActiveNode       = $IsActiveNode
                    }
                }
            }

            It 'Should return <ExpectedReturnValue>' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.ProcessOnlyOnActiveNode = $true
                    $mockTestTargetResourceParameters.Type = 'Data'
                    $mockTestTargetResourceParameters.Path = 'C:\Program Files\Data\'

                    $testTargetResourceResult = Test-TargetResource @mockTestTargetResourceParameters

                    $testTargetResourceResult | Should -Be $ExpectedReturnValue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlDatabaseDefaultLocation\Set-TargetResource' {
    BeforeAll {
        $mockConnectSQL = {
            $mockSmoServer = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server |
            Add-Member -MemberType ScriptMethod -Name Alter -Value {
                if ($mockInvalidOperationForAlterMethod)
                {
                    throw 'Mock Alter Method was called with invalid operation.'
                }

                InModuleScope -ScriptBlock {
                    $script:methodAlterWasCalled += 1
                }
            } -PassThru -Force

            $mockSmoServer.InstanceName = 'MSSQLSERVER'
            $mockSmoServer.ComputerNamePhysicalNetBIOS = 'localhost'
            $mockSmoServer.DefaultFile = 'C:\Program Files\Data\'
            $mockSmoServer.DefaultLog = 'C:\Program Files\Log\'
            <#
                Ending backslash is not set on the backup directory path here
                because of a regression test for issue #1307.
            #>
            $mockSmoServer.BackupDirectory = 'C:\Program Files\Backup'

            return $mockSmoServer
        }

        Mock -CommandName Connect-SQL -MockWith $mockConnectSQL

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:methodAlterWasCalled = 0

            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }
        }

        Context 'When passing the parameter Type with the value ''<Type>''' -ForEach @(
            @{
                Type               = 'Data'
                Path               = 'C:\Program Files\NewData\'
            },
            @{
                Type               = 'Log'
                Path               = 'C:\Program Files\NewLog\'
            },
            @{
                Type               = 'Backup'
                # Ending backslash is present because of regression test for issue #1307.
                Path               = 'C:\Program Files\NewBackup\'
            }
        ) {
            It 'Should not throw and call the correct method and mock' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockGetTargetResourceParameters -Type $Type -Path $Path } | Should -Not -Throw

                    $script:methodAlterWasCalled | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the method Alter() fails' {
            It 'Should throw the correct error message' {
                $mockInvalidOperationForAlterMethod = $true

                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.ChangingPathFailed

                    { Set-TargetResource @mockGetTargetResourceParameters -Type 'Data' -Path 'C:\AnyPath' } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')

                    $script:methodAlterWasCalled | Should -Be 0
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It

                $mockInvalidOperationForAlterMethod = $false
            }
        }

        Context 'When passing the parameter RestartService with the value $true' {
            BeforeAll {
                Mock -CommandName Restart-SqlService
            }

            It 'Should not throw and call the correct method and mock' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockGetTargetResourceParameters.Type = 'Data'
                    $mockGetTargetResourceParameters.Path = 'C:\AnyPath'
                    $mockGetTargetResourceParameters.RestartService = $true

                    { Set-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw

                    $script:methodAlterWasCalled | Should -Be 1
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the path passed in the parameter Path does not exist' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    return $false
                }
            }

            It 'Should not throw and call the correct method and mock' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.InvalidPath -f 'C:\AnyPath'

                    { Set-TargetResource @mockGetTargetResourceParameters -Type 'Data' -Path 'C:\AnyPath' } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage + '*')

                    $script:methodAlterWasCalled | Should -Be 0
                }

                Should -Invoke -CommandName Connect-SQL -Exactly -Times 0 -Scope It
            }
        }
    }
}
