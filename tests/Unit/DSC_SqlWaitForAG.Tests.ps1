<#
    .SYNOPSIS
        Automated unit test for DSC_SqlWaitForAG DSC resource.
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

$script:dscModuleName   = 'SqlServerDsc'
$script:dscResourceName = 'DSC_SqlWaitForAG'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    # Load the default SQL Module stub
    Import-SQLModuleStub
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $script:moduleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Tests' -ChildPath (Join-Path -Path 'TestHelpers' -ChildPath 'CommonTestHelper.psm1'))) -Force

        $mockClusterGroupName = 'AGTest'
        $mockRetryInterval = 1
        $mockRetryCount = 2

        $mockOtherClusterGroupName = 'UnknownAG'
        $mockIsHadrEnabled = $true

        # Function stub of Get-ClusterGroup (when we do not have Failover Cluster powershell module available)
        function Get-ClusterGroup {
            param
            (
                # Will contain the cluster group name so mock can bind filters on it.
                [Parameter()]
                [System.String]
                $Name
            )

            throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
        }

        $mockGetClusterGroup = {
            if ($Name -ne $mockExpectedClusterGroupName)
            {
                throw ('Mock Get-ClusterGroup called with unexpected name. Expected ''{0}'', but was ''{1}''' -f $mockExpectedClusterGroupName, $Name)
            }

            return New-Object -TypeName PSObject -Property @{
                Name = $Name
            }
        }

        $mockGetClusterGroup_ParameterFilter_KnownGroup = {
            $Name -eq $mockClusterGroupName
        }

        $mockGetClusterGroup_ParameterFilter_UnknownGroup = {
            $Name -eq $mockOtherClusterGroupName
        }

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            ServerName   = $env:COMPUTERNAME
            InstanceName = 'MSSQLSERVER'
            Name = $mockClusterGroupName
            RetryIntervalSec = $mockRetryInterval
            RetryCount = $mockRetryCount
        }

        $mockConnectSql = {
            param
            (
                [Parameter()]
                [System.String]
                $ServerName,

                [Parameter()]
                [System.String]
                $InstanceName
            )

            $mockServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server
            $mockServerObject.IsHadrEnabled = $mockIsHadrEnabled
            $mockServerObject.Name = $ServerName
            $mockServerObject.ServiceName = $InstanceName

            # Define the availability group object
            $mockAvailabilityGroupObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.AvailabilityGroup
            $mockAvailabilityGroupObject.Name = $mockClusterGroupName

            # Add the availability group to the server object
            $mockServerObject.AvailabilityGroups.Add($mockAvailabilityGroupObject)

            return $mockServerObject
        }

        Describe 'SqlWaitForAG\Get-TargetResource' -Tag 'Get' {
            BeforeAll {
                $testParameters = $mockDefaultParameters.Clone()
                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock -CommandName Get-ClusterGroup -MockWith $mockGetClusterGroup -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup -Verifiable
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return $null
                } -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup -Verifiable
            }

            Context 'When the system is in the desired state' {
                BeforeAll {
                    $mockExpectedClusterGroupName = $mockClusterGroupName
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.RetryIntervalSec | Should -Be $mockRetryInterval
                    $result.RetryCount | Should -Be $mockRetryCount

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup `
                        -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup `
                        -Exactly -Times 0 -Scope It
                }

                It 'Should return that the group exist' {
                    $result = Get-TargetResource @testParameters
                    $result.GroupExist | Should -BeTrue
                }
            }

            Context 'When the system is not in the desired state' {
                BeforeAll {
                    $testParameters.Name = $mockOtherClusterGroupName
                    $mockExpectedClusterGroupName = $mockOtherClusterGroupName
                }

                It 'Should return the same values as passed as parameters' {
                    $result = Get-TargetResource @testParameters
                    $result.RetryIntervalSec | Should -Be $mockRetryInterval
                    $result.RetryCount | Should -Be $mockRetryCount

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup `
                        -Exactly -Times 0 -Scope It

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup `
                        -Exactly -Times 1 -Scope It
                }

                It 'Should return that the group does not exist' {
                    $result = Get-TargetResource @testParameters
                    $result.GroupExist | Should -BeFalse
                }
            }

            Assert-VerifiableMock
        }

        Describe 'SqlWaitForAG\Test-TargetResource' -Tag 'Test'{
            BeforeAll {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock -CommandName Get-ClusterGroup -MockWith $mockGetClusterGroup -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup -Verifiable
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return $null
                } -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup -Verifiable
            }

            Context 'When the system is in the desired state' {
                It 'Should return that desired state is present ($true)' {
                    $mockExpectedClusterGroupName = $mockClusterGroupName

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeTrue

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup `
                        -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup `
                        -Exactly -Times 0 -Scope It
                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should return that desired state is absent ($false)' {
                    $mockExpectedClusterGroupName = $mockOtherClusterGroupName
                    $testParameters.Name = $mockOtherClusterGroupName

                    $result = Test-TargetResource @testParameters
                    $result | Should -BeFalse

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup `
                        -Exactly -Times 0 -Scope It

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup `
                        -Exactly -Times 1 -Scope It
                }
            }

            Assert-VerifiableMock
        }

        Describe 'SqlWaitForAG\Set-TargetResource' -Tag 'Set'{
            BeforeAll {
                $testParameters = $mockDefaultParameters.Clone()

                Mock -CommandName Connect-SQL -MockWith $mockConnectSql -Verifiable
                Mock -CommandName Start-Sleep
                Mock -CommandName Get-ClusterGroup -MockWith $mockGetClusterGroup -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup -Verifiable
                Mock -CommandName Get-ClusterGroup -MockWith {
                    return $null
                } -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup -Verifiable
            }

            Context 'When the system is in the desired state' {
                It 'Should find the cluster group and return without throwing' {
                    $mockExpectedClusterGroupName = $mockClusterGroupName
                     { Set-TargetResource @testParameters } | Should -Not -Throw

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup `
                        -Exactly -Times 1 -Scope It

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup `
                        -Exactly -Times 0 -Scope It                }
            }

            Context 'When the system is not in the desired state' {
                It 'Should throw the correct error message' {
                    $mockExpectedClusterGroupName = $mockOtherClusterGroupName
                    $testParameters.Name = $mockOtherClusterGroupName

                    { Set-TargetResource @testParameters } | Should -Throw ($script:localizedData.FailedMessage -f $mockOtherClusterGroupName)

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_KnownGroup `
                        -Exactly -Times 0 -Scope It

                    Assert-MockCalled -CommandName Get-ClusterGroup `
                        -ParameterFilter $mockGetClusterGroup_ParameterFilter_UnknownGroup `
                        -Exactly -Times 2 -Scope It                }
            }

            Assert-VerifiableMock
        }
    }
}
finally
{
    Invoke-TestCleanup
}
