<#
    .SYNOPSIS
        Unit test for DSC_SqlWaitForAG DSC resource.
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
    $script:dscResourceName = 'DSC_SqlWaitForAG'

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

Describe 'SqlWaitForAG\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            <#
                Function stub of Get-ClusterGroup (when the Failover Cluster
                powershell module available, e.g on Linux).

                Must scope the function to the script-scope otherwise the code
                being tests will not find the stub.
            #>
            function script:Get-ClusterGroup
            {
                param
                (
                    # Will contain the cluster group name so mock can bind filters on it.
                    [Parameter()]
                    [System.String]
                    $Name
                )

                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }
        }

        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name = 'AGTest'
                RetryIntervalSec = 1
                RetryCount = 2
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
            Mock -CommandName Get-ClusterGroup -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name = $Name
                }
            }

            Mock -CommandName Connect-SQL -MockWith {
                $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                $mockServerObject.IsHadrEnabled = $true
                $mockServerObject.Name = $ServerName
                $mockServerObject.ServiceName = $InstanceName

                # Define the availability group object
                $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                $mockAvailabilityGroupObject.Name = 'AGTest'

                # Add the availability group to the server object
                $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject)

                return $mockServerObject
            }
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.ServerName | Should -Be 'localhost'
                $result.InstanceName | Should -Be 'MSSQLSERVER'
                $result.Name | Should -Be 'AGTest'
                $result.RetryIntervalSec | Should -Be 1
                $result.RetryCount | Should -Be 2
            }

            Should -Invoke -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }

        It 'Should return that the group exist' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Get-TargetResource @mockGetTargetResourceParameters

                $result.GroupExist | Should -BeTrue
            }

            Should -Invoke -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Connect-SQL -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When there are no cluster group' {
            BeforeAll {
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return $null
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be 'localhost'
                    $result.InstanceName | Should -Be 'MSSQLSERVER'
                    $result.Name | Should -Be 'AGTest'
                    $result.RetryIntervalSec | Should -Be 1
                    $result.RetryCount | Should -Be 2
                }

                Should -Invoke -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
            }

            It 'Should return that the group does not exist' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.GroupExist | Should -BeFalse

                    Should -Invoke -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When high-availability and disaster recover (HADR) is not enabled' {
            BeforeAll {
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        Name = $Name
                    }
                }

                Mock -CommandName Connect-SQL -MockWith {
                    $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockServerObject.IsHadrEnabled = $false
                    $mockServerObject.Name = $ServerName
                    $mockServerObject.ServiceName = $InstanceName

                    # Define the availability group object
                    $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroupObject.Name = 'AGTest'

                    # Add the availability group to the server object
                    $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject)

                    return $mockServerObject
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be 'localhost'
                    $result.InstanceName | Should -Be 'MSSQLSERVER'
                    $result.Name | Should -Be 'AGTest'
                    $result.RetryIntervalSec | Should -Be 1
                    $result.RetryCount | Should -Be 2
                }

                Should -Invoke -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
            }

            It 'Should return that the group does not exist' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.GroupExist | Should -BeFalse
                }
            }
        }

        Context 'When high-availability and disaster recover (HADR) is enabled, but Availability Group does not exist' {
            BeforeAll {
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return New-Object -TypeName PSObject -Property @{
                        Name = $Name
                    }
                }

                Mock -CommandName Connect-SQL -MockWith {
                    $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
                    $mockServerObject.IsHadrEnabled = $true
                    $mockServerObject.Name = $ServerName
                    $mockServerObject.ServiceName = $InstanceName

                    # Define the availability group object
                    $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
                    $mockAvailabilityGroupObject.Name = 'OtherAG'

                    # Add the availability group to the server object
                    $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject)

                    return $mockServerObject
                }
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.ServerName | Should -Be 'localhost'
                    $result.InstanceName | Should -Be 'MSSQLSERVER'
                    $result.Name | Should -Be 'AGTest'
                    $result.RetryIntervalSec | Should -Be 1
                    $result.RetryCount | Should -Be 2
                }

                Should -Invoke -CommandName Get-ClusterGroup -Exactly -Times 1 -Scope It
            }

            It 'Should return that the group does not exist' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.GroupExist | Should -BeFalse
                }
            }
        }
    }
}

Describe 'SqlWaitForAG\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name = 'AGTest'
                RetryIntervalSec = 1
                RetryCount = 2
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    GroupExist = $true
                }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-TargetResource @mockTestTargetResourceParameters

                $result | Should -BeTrue
            }

            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    GroupExist = $false
                }
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $result = Test-TargetResource @mockTestTargetResourceParameters

                $result | Should -BeFalse
            }

            Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
        }
    }
}

Describe 'SqlWaitForAG\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                ServerName   = 'localhost'
                Name = 'AGTest'
                RetryIntervalSec = 1
                RetryCount = 2
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When there is no need to wait for Availability Group to be available' {
            BeforeAll {
                Mock -CommandName Start-Sleep
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        GroupExist = $true
                    }
                }
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Start-Sleep -Exactly -Times 1 -Scope It
            }
        }

        Context 'When waiting for the Availability Group to be available' {
            BeforeAll {
                $script:mockWaitForAvailabilityGroup = $true

                # Setting up the mock to exit the loop.
                Mock -CommandName Start-Sleep -MockWith {
                    $script:mockWaitForAvailabilityGroup = $false
                }

                # Setting up the mock to loop once.
                Mock -CommandName Get-TargetResource -MockWith {
                    if ($script:mockWaitForAvailabilityGroup)
                    {
                        $mockGroupExist = $false
                    }
                    else
                    {
                        $mockGroupExist = $true
                    }

                    return @{
                        GroupExist = $mockGroupExist
                    }
                }
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                # Looping twice so these mocks are called twice.
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Start-Sleep -Exactly -Times 2 -Scope It
            }
        }

        Context 'When the Availability Group is never available' {
            BeforeAll {
                Mock -CommandName Start-Sleep
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        GroupExist = $false
                    }
                }
            }

            It 'Should not throw and call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.FailedMessage -f 'AGTest'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }

                # Looping twice so these mocks are called twice.
                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Start-Sleep -Exactly -Times 2 -Scope It
            }
        }
    }
}
