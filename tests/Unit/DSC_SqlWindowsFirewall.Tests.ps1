<#
    .SYNOPSIS
        Unit test for DSC_SqlWindowsFirewall DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
# Suppressing this rule because tests are mocking passwords in clear text.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
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
    $script:dscResourceName = 'DSC_SqlWindowsFirewall'

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

Describe 'SqlWindowsFirewall\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                SourcePath = $TestDrive
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When using the instance <MockInstanceName>' -ForEach @(
        @{
            MockInstanceName = 'MSSQLSERVER'
        }
        @{
            MockInstanceName = 'TEST'
        }
    ) {
        BeforeEach {
            <#
                Pester only holds the inner-most foreach-variable in the $_-table,
                so it vill hold variables MockFeatures and MockSqlMajorVersion from
                the next Context-block. This adds this context-blocks foreach-variable
                to the $_-table so it is available.
            #>
            $_.MockInstanceName = $MockInstanceName

            InModuleScope -Parameters $_ -ScriptBlock {
                $script:mockGetTargetResourceParameters.InstanceName = $MockInstanceName
            }
        }

        Context 'When using the feature ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'SQLENGINE'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using lower-case to test that casing does not matter.
                MockFeatures = 'SQLEngine'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the feature is not installed (the service is missing)' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        return @()
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    }
                }

                It 'Should not return $null for the read parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        $result.BrowserFirewall | Should -BeNullOrEmpty
                        $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                        $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                        $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                    }
                }

                It 'Should not return any installed features' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Features | Should -BeNullOrEmpty
                    }
                }

                It 'Should return state as absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        if ($MockInstanceName -eq 'MSSQLSERVER')
                        {
                            $mockServiceName = 'MSSQLSERVER'
                        }
                        else
                        {
                            $mockServiceName = 'MSSQL${0}' -f $MockInstanceName
                        }

                        return @(
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockServiceName -PassThru -Force
                            )
                        )
                    }

                    Mock -CommandName Get-SQLPath -MockWith {
                        return 'C:\Program Files\Microsoft SQL Server'
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are enabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq ('SQL Server Database Engine instance {0}' -f $MockInstanceName)
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Browser'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.DatabaseEngineFirewall | Should -BeTrue
                            $result.BrowserFirewall | Should -BeTrue
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'SQLENGINE'
                        }
                    }

                    It 'Should return state as present' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Present'
                        }
                    }
                }

                Context 'When firewall rules for SQL Engine is disabled and SQL Browser is enabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq ('SQL Server Database Engine instance {0}' -f $MockInstanceName)
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Browser'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.DatabaseEngineFirewall | Should -BeFalse
                            $result.BrowserFirewall | Should -BeTrue
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'SQLENGINE'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }

                Context 'When firewall rules for SQL Engine is enabled and SQL Browser is disabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq ('SQL Server Database Engine instance {0}' -f $MockInstanceName)
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Browser'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.DatabaseEngineFirewall | Should -BeTrue
                            $result.BrowserFirewall | Should -BeFalse
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'SQLENGINE'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }

                Context 'When firewall rules for both SQL Engine and SQL Browser are disabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq ('SQL Server Database Engine instance {0}' -f $MockInstanceName)
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Browser'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.DatabaseEngineFirewall | Should -BeFalse
                            $result.BrowserFirewall | Should -BeFalse
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'SQLENGINE'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }
            }
        }

        Context 'When using the feature ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'AS'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using lower-case to test that casing does not matter.
                MockFeatures = 'As'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the feature is not installed (the service is missing)' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        return @()
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    }
                }

                It 'Should not return $null for the read parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        $result.BrowserFirewall | Should -BeNullOrEmpty
                        $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                        $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                        $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                    }
                }

                It 'Should not return any installed features' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Features | Should -BeNullOrEmpty
                    }
                }

                It 'Should return state as absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        if ($MockInstanceName -eq 'MSSQLSERVER')
                        {
                            $mockServiceName = 'MSSQLServerOLAPService'
                        }
                        else
                        {
                            $mockServiceName = 'MSOLAP${0}' -f $MockInstanceName
                        }

                        return @(
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockServiceName -PassThru -Force
                            )
                        )
                    }

                    Mock -CommandName Get-SQLPath -MockWith {
                        return 'C:\Program Files\Microsoft SQL Server'
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are enabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq ('SQL Server Analysis Services instance {0}' -f $MockInstanceName)
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Browser'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.AnalysisServicesFirewall | Should -BeTrue
                            $result.BrowserFirewall | Should -BeTrue
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'AS'
                        }
                    }

                    It 'Should return state as present' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Present'
                        }
                    }
                }

                Context 'When firewall rules for Analysis Services is disabled and SQL Browser is enabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq ('SQL Server Analysis Services instance {0}' -f $MockInstanceName)
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Browser'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.AnalysisServicesFirewall | Should -BeFalse
                            $result.BrowserFirewall | Should -BeTrue
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'AS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }

                Context 'When firewall rules for Analysis Services is enabled and SQL Browser is disabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq ('SQL Server Analysis Services instance {0}' -f $MockInstanceName)
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Browser'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.AnalysisServicesFirewall | Should -BeTrue
                            $result.BrowserFirewall | Should -BeFalse
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'AS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }

                Context 'When firewall rules for both Analysis Services and SQL Browser are disabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq ('SQL Server Analysis Services instance {0}' -f $MockInstanceName)
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Browser'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.AnalysisServicesFirewall | Should -BeFalse
                            $result.BrowserFirewall | Should -BeFalse
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'AS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }
            }
        }

        Context 'When using the feature ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'RS'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using lower-case to test that casing does not matter.
                MockFeatures = 'Rs'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the feature is not installed (the service is missing)' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        return @()
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    }
                }

                It 'Should not return $null for the read parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        $result.BrowserFirewall | Should -BeNullOrEmpty
                        $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                        $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                        $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                    }
                }

                It 'Should not return any installed features' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Features | Should -BeNullOrEmpty
                    }
                }

                It 'Should return state as absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        if ($MockInstanceName -eq 'MSSQLSERVER')
                        {
                            $mockServiceName = 'ReportServer'
                        }
                        else
                        {
                            $mockServiceName = 'ReportServer${0}' -f $MockInstanceName
                        }

                        return @(
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockServiceName -PassThru -Force
                            )
                        )
                    }

                    Mock -CommandName Get-SQLPath -MockWith {
                        return 'C:\Program Files\Microsoft SQL Server'
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are enabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Reporting Services 80'
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Reporting Services 443'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.ReportingServicesFirewall | Should -BeTrue
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.BrowserFirewall | Should -BeNullOrEmpty
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'RS'
                        }
                    }

                    It 'Should return state as present' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Present'
                        }
                    }
                }

                Context 'When firewall rule for SQL Server Reporting Services port 80 is disabled and and port 443 is enabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Reporting Services 80'
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Reporting Services 443'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.ReportingServicesFirewall | Should -BeFalse
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.BrowserFirewall | Should -BeNullOrEmpty
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'RS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }

                Context 'When firewall rule for SQL Server Reporting Services port 80 is enabled and and port 443 is disabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Reporting Services 80'
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Reporting Services 443'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.ReportingServicesFirewall | Should -BeFalse
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.BrowserFirewall | Should -BeNullOrEmpty
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'RS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }

                Context 'When firewall rules for SQL Server Reporting Services port 80 and and port 443 is disabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Reporting Services 80'
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Reporting Services 443'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.ReportingServicesFirewall | Should -BeFalse
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.BrowserFirewall | Should -BeNullOrEmpty
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                            $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'RS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }
            }
        }

        Context 'When using the feature ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'IS'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using lower-case to test that casing does not matter.
                MockFeatures = 'Is'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the feature is not installed (the service is missing)' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        return @()
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    }
                }

                It 'Should not return $null for the read parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        $result.BrowserFirewall | Should -BeNullOrEmpty
                        $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                        $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                        $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                    }
                }

                It 'Should not return any installed features' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Features | Should -BeNullOrEmpty
                    }
                }

                It 'Should return state as absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        $mockServiceName = 'MsDtsServer{0}0' -f $MockSqlMajorVersion

                        return @(
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockServiceName -PassThru -Force
                            )
                        )
                    }

                    Mock -CommandName Get-SQLPath -MockWith {
                        return 'C:\Program Files\Microsoft SQL Server'
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are enabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Integration Services Application'
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Integration Services Port'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.IntegrationServicesFirewall | Should -BeTrue
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.BrowserFirewall | Should -BeNullOrEmpty
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'IS'
                        }
                    }

                    It 'Should return state as present' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Present'
                        }
                    }
                }

                Context 'When firewall rule for SQL Server Integration Services application is not in desired state and port 135 is in desired state' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Integration Services Application'
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Integration Services Port'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.IntegrationServicesFirewall | Should -BeFalse
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.BrowserFirewall | Should -BeNullOrEmpty
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'IS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }

                Context 'When firewall rule for SQL Server Integration Services application is in desired state and port 135 is not in desired state' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Integration Services Application'
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Integration Services Port'
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.IntegrationServicesFirewall | Should -BeFalse
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.BrowserFirewall | Should -BeNullOrEmpty
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'IS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }

                Context 'When firewall rule for SQL Server Integration Services application and port 135 is not in desired state' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Integration Services Application'
                        }

                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $false
                        } -ParameterFilter {
                            $DisplayName -eq 'SQL Server Integration Services Port'
                        }
                    }
                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.IntegrationServicesFirewall | Should -BeFalse
                            $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                            $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                            $result.BrowserFirewall | Should -BeNullOrEmpty
                            $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'IS'
                        }
                    }

                    It 'Should return state as absent' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Absent'
                        }
                    }
                }
            }
        }

        Context 'When using the features ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'RS,AS,SQLENGINE,IS'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using another order and lower-case to test that casing and order does not matter.
                MockFeatures = 'Is,Rs,As,SQLEngine'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the features are not installed (the service is missing)' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        return @()
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should return the same values as passed as parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                    }
                }

                It 'Should not return $null for the read parameters' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.DatabaseEngineFirewall | Should -BeNullOrEmpty
                        $result.BrowserFirewall | Should -BeNullOrEmpty
                        $result.ReportingServicesFirewall | Should -BeNullOrEmpty
                        $result.AnalysisServicesFirewall | Should -BeNullOrEmpty
                        $result.IntegrationServicesFirewall | Should -BeNullOrEmpty
                    }
                }

                It 'Should not return any installed features' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Features | Should -BeNullOrEmpty
                    }
                }

                It 'Should return state as absent' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $result = Get-TargetResource @mockGetTargetResourceParameters

                        $result.Ensure | Should -Be 'Absent'
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-Service -MockWith {
                        if ($MockInstanceName -eq 'MSSQLSERVER')
                        {
                            $mockDatabaseServiceName = 'MSSQLSERVER'
                            $mockReportServiceName = 'ReportServer'
                            $mockAnalysisServiceName = 'MSSQLServerOLAPService'
                        }
                        else
                        {
                            $mockDatabaseServiceName = 'MSSQL${0}' -f $MockInstanceName
                            $mockReportServiceName = 'ReportServer${0}' -f $MockInstanceName
                            $mockAnalysisServiceName = 'MSOLAP${0}' -f $MockInstanceName
                        }

                        $mockIntegrationServiceName = 'MsDtsServer{0}0' -f $MockSqlMajorVersion

                        return @(
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockIntegrationServiceName -PassThru -Force
                            )
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockDatabaseServiceName -PassThru -Force
                            )
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockReportServiceName -PassThru -Force
                            )
                            (
                                New-Object -TypeName Object |
                                    Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockAnalysisServiceName -PassThru -Force
                            )
                        )
                    }

                    Mock -CommandName Get-SQLPath -MockWith {
                        return 'C:\Program Files\Microsoft SQL Server'
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockGetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are enabled' {
                    BeforeAll {
                        Mock -CommandName Test-IsFirewallRuleInDesiredState -MockWith {
                            return $true
                        }
                    }

                    It 'Should return the same values as passed as parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                        }
                    }

                    It 'Should not return correct value for read parameters' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.IntegrationServicesFirewall | Should -BeTrue
                            $result.ReportingServicesFirewall | Should -BeTrue
                            $result.AnalysisServicesFirewall | Should -BeTrue
                            $result.BrowserFirewall | Should -BeTrue
                            $result.DatabaseEngineFirewall | Should -BeTrue
                        }
                    }

                    It 'Should return correct installed feature' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Features | Should -Be 'SQLENGINE,RS,AS,IS'
                        }
                    }

                    It 'Should return state as present' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            $result = Get-TargetResource @mockGetTargetResourceParameters

                            $result.Ensure | Should -Be 'Present'
                        }
                    }
                }
            }
        }

        Context 'When passing credentials in the parameter SourceCredential' {
            BeforeAll {
                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return $MockSqlMajorVersion
                }

                Mock -CommandName Get-Service -MockWith {
                    return @()
                }

                Mock -CommandName New-SmbMapping
                Mock -CommandName Remove-SmbMapping
            }

            BeforeEach {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $script:mockGetTargetResourceParameters.Features = 'SQLENGINE'
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockGetTargetResourceParameters.Features = 'SQLENGINE'
                    $script:mockGetTargetResourceParameters.SourceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\SqlAdmin',
                        ('dummyPassword' | ConvertTo-SecureString -AsPlainText -Force)
                    )

                    { Get-TargetResource @mockGetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke New-SmbMapping -Exactly -Times 1 -Scope It
                Should -Invoke Remove-SmbMapping -Exactly -Times 1 -Scope It
            }
        }
    }
}

Describe 'SqlWindowsFirewall\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName = 'MSSQLSERVER'
                Features     = 'SQLENGINE'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When the firewall rules should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Present'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When the firewall rules should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters.Ensure = 'Absent'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When the firewall rules should be present' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When the firewall rules should be absent' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Ensure = 'Absent'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }
            }
        }
    }
}

Describe 'SqlWindowsFirewall\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                SourcePath = $TestDrive
            }
        }

        Mock -CommandName Set-NetFirewallRule
        Mock -CommandName New-NetFirewallRule
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When using the instance <MockInstanceName>' -ForEach @(
        @{
            MockInstanceName = 'MSSQLSERVER'
        }
        @{
            MockInstanceName = 'TEST'
        }
    ) {
        BeforeAll {
            Mock -CommandName Test-TargetResource -MockWith {
                return $true
            }
        }

        BeforeEach {
            <#
                Pester only holds the inner-most foreach-variable in the $_-table,
                so it vill hold variables MockFeatures and MockSqlMajorVersion from
                the next Context-block. This adds this context-blocks foreach-variable
                to the $_-table so it is available.
            #>
            $_.MockInstanceName = $MockInstanceName

            InModuleScope -Parameters $_ -ScriptBlock {
                $script:mockSetTargetResourceParameters.InstanceName = $MockInstanceName
            }
        }

        Context 'When using the feature ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'SQLENGINE'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using lower-case to test that casing does not matter.
                MockFeatures = 'SQLEngine'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the feature is not installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockSetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should call the expected mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                        Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockSetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are present for Database Engine and SQL Browser' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'SQLENGINE'
                                DatabaseEngineFirewall = $true
                                BrowserFirewall = $true
                            }
                        }
                    }

                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context 'When firewall rules are absent for Database Engine and present for SQL Browser' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'SQLENGINE'
                                DatabaseEngineFirewall = $false
                                BrowserFirewall = $true
                            }
                        }

                        Mock -CommandName Get-SQLPath -MockWith {
                            return 'C:\Program Files\Microsoft SQL Server'
                        }
                    }

                    Context 'When firewall rule already exist' {
                        BeforeAll {
                            Mock -CommandName Get-NetFirewallRule -MockWith {
                                return @{
                                    DisplayName = 'SQL Server Database Engine instance {0}' -f $MockInstanceName
                                }
                            }
                        }

                        It 'Should call the expected mocks' {
                            InModuleScope -ScriptBlock {
                                Set-StrictMode -Version 1.0

                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                                Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It
                                Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                            }
                        }
                    }

                    Context 'When firewall rule do not exist' {
                        BeforeAll {
                            Mock -CommandName Get-NetFirewallRule
                        }

                        It 'Should call the expected mocks' {
                            InModuleScope -ScriptBlock {
                                Set-StrictMode -Version 1.0

                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                                Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                                Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 1 -Scope It
                            }
                        }
                    }
                }

                Context 'When firewall rules are present for Database Engine and absent for SQL Browser' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'SQLENGINE'
                                DatabaseEngineFirewall = $true
                                BrowserFirewall = $false
                            }
                        }
                    }

                    Context 'When firewall rule do not exist' {
                        It 'Should call the expected mocks' {
                            InModuleScope -ScriptBlock {
                                Set-StrictMode -Version 1.0

                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                                Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It
                                Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 1 -Scope It
                            }
                        }
                    }
                }

                Context 'When firewall rules for both SQL Engine and SQL Browser are disabled' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'SQLENGINE'
                                DatabaseEngineFirewall = $false
                                BrowserFirewall = $false
                            }
                        }

                        Mock -CommandName Get-SQLPath -MockWith {
                            return 'C:\Program Files\Microsoft SQL Server'
                        }
                    }

                    Context 'When firewall rule for Database Engine already exist' {
                        BeforeAll {
                            Mock -CommandName Get-NetFirewallRule -MockWith {
                                return @{
                                    DisplayName = 'SQL Server Database Engine instance {0}' -f $MockInstanceName
                                }
                            }
                        }

                        It 'Should call the expected mocks' {
                            InModuleScope -ScriptBlock {
                                Set-StrictMode -Version 1.0

                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                                Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 1 -Scope It #-Because 'the rule already exist for the Database Engine'
                                Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 1 -Scope It #-Because 'no rule exist for the SQL Browser'
                            }
                        }
                    }

                    Context 'When firewall rule for Database Engine do not exist' {
                        BeforeAll {
                            Mock -CommandName Get-NetFirewallRule
                        }

                        It 'Should call the expected mocks' {
                            InModuleScope -ScriptBlock {
                                Set-StrictMode -Version 1.0

                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                                Should -Invoke -CommandName Set-NetFirewallRule -Exactly -Times 0 -Scope It #-Because 'no rules exist to change'
                                Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 2 -Scope It #-Because 'no rule exist for either the Database Engine or SQL Browser'
                            }
                        }
                    }
                }
            }
        }

        Context 'When using the feature ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'AS'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using lower-case to test that casing does not matter.
                MockFeatures = 'As'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the feature is not installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockSetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should call the expected mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockSetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are present for Analysis Services and SQL Browser' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'AS'
                                AnalysisServicesFirewall = $true
                                BrowserFirewall = $true
                            }
                        }
                    }

                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context 'When firewall rules are absent for Analysis Services and present for SQL Browser' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'AS'
                                AnalysisServicesFirewall = $false
                                BrowserFirewall = $true
                            }
                        }
                    }

                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 1 -Scope It
                        }
                    }
                }

                Context 'When firewall rules are present for Analysis Services and absent for SQL Browser' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'AS'
                                AnalysisServicesFirewall = $true
                                BrowserFirewall = $false
                            }
                        }
                    }

                    Context 'When firewall rule do not exist' {
                        It 'Should call the expected mocks' {
                            InModuleScope -ScriptBlock {
                                Set-StrictMode -Version 1.0

                                { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                                Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 1 -Scope It
                            }
                        }
                    }
                }

                Context 'When firewall rules for both Analysis Services and SQL Browser are disabled' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'AS'
                                AnalysisServicesFirewall = $false
                                BrowserFirewall = $false
                            }
                        }
                    }

                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 2 -Scope It #-Because 'no rule exist for either Analysis Services or SQL Browser'
                        }
                    }
                }
            }
        }

        Context 'When using the feature ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'RS'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using lower-case to test that casing does not matter.
                MockFeatures = 'Rs'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the feature is not installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockSetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should call the expected mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockSetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are present for Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'RS'
                                ReportingServicesFirewall = $true
                            }
                        }
                    }

                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context 'When firewall rules are absent for Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'RS'
                                ReportingServicesFirewall = $false
                            }
                        }
                    }

                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 2 -Scope It
                        }
                    }
                }
            }
        }


        Context 'When using the feature ''<MockFeatures>'' and major version ''<MockSqlMajorVersion>''' -ForEach @(
            <#
                Testing two major versions to verify Integration Services differences (i.e service name).
                No point in testing each supported SQL Server version, since there are no difference
                between the other major versions.
            #>
            @{
                MockFeatures = 'IS'
                MockSqlMajorVersion = '11' # SQL Server 2012
            }
            @{
                # Using lower-case to test that casing does not matter.
                MockFeatures = 'Is'
                MockSqlMajorVersion = '10' # SQL Server 2008 and 2008 R2
            }
        ) {
            Context 'When the feature is not installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Features = ''
                        }
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockSetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                It 'Should call the expected mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When the feature is installed' {
                BeforeAll {
                    Mock -CommandName Get-FilePathMajorVersion -MockWith {
                        return $MockSqlMajorVersion
                    }
                }

                BeforeEach {
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $script:mockSetTargetResourceParameters.Features = $MockFeatures
                    }
                }

                Context 'When firewall rules are present for Integration Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'IS'
                                IntegrationServicesFirewall = $true
                            }
                        }
                    }

                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 0 -Scope It
                        }
                    }
                }

                Context 'When firewall rules are absent for Integration Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                Features = 'IS'
                                IntegrationServicesFirewall = $false
                            }
                        }

                        Mock -CommandName Get-SQLPath -MockWith {
                            return 'C:\Program Files\Microsoft SQL Server'
                        }
                    }

                    It 'Should call the expected mocks' {
                        InModuleScope -ScriptBlock {
                            Set-StrictMode -Version 1.0

                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Should -Invoke -CommandName New-NetFirewallRule -Exactly -Times 2 -Scope It
                        }
                    }
                }
            }
        }

        Context 'When passing credentials in the parameter SourceCredential' {
            BeforeAll {
                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return $MockSqlMajorVersion
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = ''
                    }
                }

                Mock -CommandName New-SmbMapping
                Mock -CommandName Remove-SmbMapping
            }

            BeforeEach {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $script:mockSetTargetResourceParameters.Features = 'SQLENGINE'
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters.Features = 'SQLENGINE'
                    $script:mockSetTargetResourceParameters.SourceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\SqlAdmin',
                        ('dummyPassword' | ConvertTo-SecureString -AsPlainText -Force)
                    )

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke New-SmbMapping -Exactly -Times 1 -Scope It
                Should -Invoke Remove-SmbMapping -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Test-TargetResource returns false at the end of Set-TargetResource' {
            BeforeAll {
                Mock -CommandName Get-FilePathMajorVersion -MockWith {
                    return $MockSqlMajorVersion
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        Features = ''
                    }
                }

                Mock -CommandName Test-TargetResource -MockWith {
                    return $false
                }
            }

            BeforeEach {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $script:mockSetTargetResourceParameters.Features = 'SQLENGINE'
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters.Features = 'SQLENGINE'

                    $mockErrorMessage = $script:localizedData.TestFailedAfterSet

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
                }
            }
        }
    }
}

Describe 'SqlWindowsFirewall/Get-SqlRootPath' -Tag 'Helper' {
    BeforeDiscovery {
        $mockTestCases = @(
            @{
                MockFeature = 'AS'
                MockSqlMajorVersion = $null
            }
            @{
                # Lower-case to test that casing does not matter.
                MockFeature = 'SQLEngine'
                MockSqlMajorVersion = $null
            }
            @{
                MockFeature = 'IS'
                MockSqlMajorVersion = '12'
            }
        )
    }

    Context 'When getting path for feature ''<MockFeature>''' -ForEach $mockTestCases {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                return  @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'MSSQLSERVER' -Value 'MSSQL$TEST' -PassThru -Force
                    )
                )
            } -ParameterFilter {
                $Name -eq 'MSSQLSERVER'
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'SQLBinRoot' -Value 'C:\Mocked\Path' -PassThru -Force
                    )
                )
            } -ParameterFilter {
                $Name -eq 'SQLBinRoot'
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'SQLPath' -Value 'C:\Mocked\Path' -PassThru -Force
                    )
                )
            } -ParameterFilter {
                $Name -eq 'SQLPath'
            }
        }

        It 'Should return the the correct path' {
            InModuleScope -Parameters $_ -ScriptBlock {
                $result = Get-SQLPath -Feature $MockFeature -InstanceName 'MSSQLSERVER' -SQLVersion $MockSqlMajorVersion

                $result | Should -Be 'C:\Mocked\Path'
            }
        }
    }
}

Describe 'SqlWindowsFirewall/Test-IsFirewallRuleInDesiredState' -Tag 'Helper' {
    Context 'When the firewall rule does not exist' {
        BeforeAll {
            Mock -CommandName Get-NetFirewallRule -MockWith {
                return @()
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled $true -Profile 'Any' -Direction 'Inbound'

                $result | Should -BeFalse
            }
        }
    }

    Context 'When the firewall rule exist' {
        BeforeAll {
            Mock -CommandName Get-NetFirewallRule -MockWith {
                return @(
                    @{
                        DisplayName = 'RuleName'
                        Enabled = 'True'
                        Profile = 'Any'
                        Direction = 'Inbound'
                    }
                )
            }
        }

        Context 'When the property Enabled does not match' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'False' -Profile 'Any' -Direction 'Inbound'

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When the property Profile does not match' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Domain' -Direction 'Inbound'

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When the property Direction does not match' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Outbound'

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When neither the parameter Program, Service, Protocol, and LocalPort is specified in the call' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Inbound'

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When the parameter Program is specified in the call' {
            BeforeAll {
                Mock -CommandName Get-NetFirewallRule -MockWith {
                    return @(
                        (
                            New-CimInstance -ClassName 'MSFT_NetFirewallRule' -Property @{
                                DisplayName = 'RuleName'
                                Enabled = $true
                                Profile = 'Any'
                                Direction = 1 # 1 = Inbound, 2 = Outbound
                            } -Namespace 'root/standardcimv2' -ClientOnly
                        )
                    )
                }

                Mock -CommandName Get-NetFirewallApplicationFilter -MockWith {
                    return @(
                        @{
                            Program = 'ProgramName'
                        }
                    )
                }
            }

            Context 'When the program specified does not match' {
                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Inbound' -Program 'WrongProgramName'

                        $result | Should -BeFalse
                    }
                }
            }

            Context 'When the program specified do match' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Inbound' -Program 'ProgramName'

                        $result | Should -BeTrue
                    }
                }
            }
        }

        Context 'When the parameter Service is specified in the call' {
            BeforeAll {
                Mock -CommandName Get-NetFirewallRule -MockWith {
                    return @(
                        (
                            New-CimInstance -ClassName 'MSFT_NetFirewallRule' -Property @{
                                DisplayName = 'RuleName'
                                Enabled = $true
                                Profile = 'Any'
                                Direction = 1 # 1 = Inbound, 2 = Outbound
                            } -Namespace 'root/standardcimv2' -ClientOnly
                        )
                    )
                }

                Mock -CommandName Get-NetFirewallServiceFilter -MockWith {
                    return @(
                        @{
                            Service = 'ServiceName'
                        }
                    )
                }
            }

            Context 'When the service specified does not match' {
                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Inbound' -Service 'WrongServiceName'

                        $result | Should -BeFalse
                    }
                }
            }

            Context 'When the service specified do match' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Inbound' -Service 'ServiceName'

                        $result | Should -BeTrue
                    }
                }
            }
        }

        Context 'When just the parameter Protocol is specified in the call' {
            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Inbound' -Protocol 'TCP'

                    $result | Should -BeFalse
                }
            }
        }

        Context 'When both the parameter Protocol And LocalPort is specified in the call' {
            BeforeAll {
                Mock -CommandName Get-NetFirewallRule -MockWith {
                    return @(
                        (
                            New-CimInstance -ClassName 'MSFT_NetFirewallRule' -Property @{
                                DisplayName = 'RuleName'
                                Enabled = $true
                                Profile = 'Any'
                                Direction = 1 # 1 = Inbound, 2 = Outbound
                            } -Namespace 'root/standardcimv2' -ClientOnly
                        )
                    )
                }

                Mock -CommandName Get-NetFirewallPortFilter -MockWith {
                    return @(
                        @{
                            Protocol = 'TCP'
                            LocalPort = '1433'
                        }
                    )
                }
            }

            Context 'When the protocol and local port specified does not match' {
                It 'Should return $false' {
                    InModuleScope -ScriptBlock {
                        $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Inbound' -Protocol 'TCP' -LocalPort '1434'

                        $result | Should -BeFalse
                    }
                }
            }

            Context 'When the protocol and local port specified do match' {
                It 'Should return $true' {
                    InModuleScope -ScriptBlock {
                        $result = Test-IsFirewallRuleInDesiredState -DisplayName 'RuleName' -Enabled 'True' -Profile 'Any' -Direction 'Inbound' -Protocol 'TCP' -LocalPort '1433'

                        $result | Should -BeTrue
                    }
                }
            }
        }
    }
}
