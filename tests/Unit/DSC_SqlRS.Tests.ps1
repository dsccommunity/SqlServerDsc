<#
    .SYNOPSIS
        Unit test for DSC_SqlRS DSC resource.
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
    $script:dscResourceName = 'DSC_SqlRS'

    $env:SqlServerDscCI = $true

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

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

<#Describe 'SqlRS\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        $mockNamedInstanceName = 'INSTANCE'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockReportingServicesDatabaseServerName = 'SERVER'
        $mockReportingServicesDatabaseNamedInstanceName = $mockNamedInstanceName
        $mockReportingServicesDatabaseDefaultInstanceName = $mockDefaultInstanceName
        $mockReportingServicesDatabaseName = 'ReportServer'
        $mockServiceAccountName = 'Contoso\ServiceAccount'
        $mockReportsApplicationName = 'ReportServerWebApp'
        $mockReportServerApplicationName = 'ReportServerWebService'
        $mockReportsApplicationUrl = 'http://+:80'
        $mockReportServerApplicationUrl = 'http://+:80'
        $mockVirtualDirectoryReportManagerName = 'Reports_SQL2016'
        $mockVirtualDirectoryReportServerName = 'ReportServer_SQL2016'

        $mockInvokeRsCimMethod_ListReservedUrls = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name 'Application' -Value {
                return @(
                    $mockDynamicReportServerApplicationName,
                    $mockDynamicReportsApplicationName
                )
            } -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'UrlString' -Value {
                return @(
                    $mockDynamicReportsApplicationUrlString,
                    $mockDynamicReportServerApplicationUrlString
                )
            } -PassThru -Force
        }

        $mockGetCimInstance_ConfigurationSetting_NamedInstance = {
            return @(
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                        'MSReportServer_ConfigurationSetting'
                        'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
                    ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'DatabaseName' -Value $mockReportingServicesDatabaseName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $mockDynamicIsInitialized -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockNamedInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value $mockVirtualDirectoryReportServerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value $mockVirtualDirectoryReportManagerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $mockDynamicSecureConnectionLevel -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'WindowsServiceIdentityActual' -Value $mockServiceAccountName -PassThru -Force
                ),
                (
                    # Array is a regression test for issue #819.
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $true -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value 'DummyInstance' -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_ConfigurationSetting_DefaultInstance = {
            return New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                'MSReportServer_ConfigurationSetting'
                'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
            ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName" -PassThru |
                Add-Member -MemberType NoteProperty -Name 'DatabaseName' -Value $mockReportingServicesDatabaseName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockDefaultInstanceName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value '' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value '' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $mockDynamicSecureConnectionLevel -PassThru |
                Add-Member -MemberType NoteProperty -Name WindowsServiceIdentityActual -Value $mockServiceAccountName -PassThru -Force
        }

        Mock -CommandName Invoke-RsCimMethod -MockWith $mockInvokeRsCimMethod_ListReservedUrls -ParameterFilter {
            $MethodName -eq 'ListReservedUrls'
        }

        InModuleScope -ScriptBlock {
            $script:mockNamedInstanceName = 'INSTANCE'
            $script:mockReportingServicesDatabaseServerName = 'SERVER'
            $script:mockReportingServicesDatabaseNamedInstanceName = $mockNamedInstanceName

            $script:mockDefaultParameters = @{
                InstanceName         = $mockNamedInstanceName
                DatabaseServerName   = $mockReportingServicesDatabaseServerName
                DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                Encrypt              = 'Optional'
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ReportingServicesData -MockWith {
                return @{
                    Configuration          = (& $mockGetCimInstance_ConfigurationSetting_NamedInstance)[0]
                    ReportsApplicationName = 'ReportServerWebApp'
                    SqlVersion             = 13
                }
            }

            $mockDynamicReportServerApplicationName = $mockReportServerApplicationName
            $mockDynamicReportsApplicationName = $mockReportsApplicationName
            $mockDynamicReportsApplicationUrlString = $mockReportsApplicationUrl
            $mockDynamicReportServerApplicationUrlString = $mockReportServerApplicationUrl

            $mockDynamicIsInitialized = $true
        }

        AfterAll {
            # Setting the value back to the default.
            $mockDynamicSecureConnectionLevel = 0
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $resultGetTargetResource = Get-TargetResource @mockDefaultParameters

                $resultGetTargetResource.InstanceName | Should -Be $mockNamedInstanceName
                $resultGetTargetResource.DatabaseServerName | Should -Be $mockReportingServicesDatabaseServerName
                $resultGetTargetResource.DatabaseInstanceName | Should -Be $mockReportingServicesDatabaseNamedInstanceName
                $resultGetTargetResource.Encrypt | Should -Be 'Optional'
                $resultGetTargetResource | Should -BeOfType [System.Collections.Hashtable]
            }
        }

        It 'Should return the the state as initialized' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockServiceAccountName = 'Contoso\ServiceAccount'
                $mockReportsApplicationUrl = 'http://+:80'
                $mockReportServerApplicationUrl = 'http://+:80'
                $mockVirtualDirectoryReportManagerName = 'Reports_SQL2016'
                $mockVirtualDirectoryReportServerName = 'ReportServer_SQL2016'

                $resultGetTargetResource = Get-TargetResource @mockDefaultParameters

                $resultGetTargetResource.IsInitialized | Should -BeTrue
                $resultGetTargetResource.ReportServerVirtualDirectory | Should -Be $mockVirtualDirectoryReportServerName
                $resultGetTargetResource.ReportsVirtualDirectory | Should -Be $mockVirtualDirectoryReportManagerName
                $resultGetTargetResource.ReportServerReservedUrl | Should -Be $mockReportServerApplicationUrl
                $resultGetTargetResource.ReportsReservedUrl | Should -Be $mockReportsApplicationUrl
                $resultGetTargetResource.UseSsl | Should -BeFalse
                $resultGetTargetResource.WindowsServiceIdentityActual | Should -Be $mockServiceAccountName
            }

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ListReservedUrls'
            } -Exactly -Times 1 -Scope It
        }

        Context 'When SSL is not used' {
            BeforeAll {
                $mockDynamicSecureConnectionLevel = 0 # Do not use SSL
            }

            It 'Should return the the state as initialized' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $resultGetTargetResource = Get-TargetResource @mockDefaultParameters

                    $resultGetTargetResource.UseSsl | Should -BeFalse
                }
            }
        }

        Context 'When SSL is used' {
            BeforeAll {
                $mockDynamicSecureConnectionLevel = 1 # Use SSL
            }

            It 'Should return the the state as initialized' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $resultGetTargetResource = Get-TargetResource @mockDefaultParameters

                    $resultGetTargetResource.UseSsl | Should -BeTrue
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ReportingServicesData -MockWith {
                return @{
                    Configuration          = (& $mockGetCimInstance_ConfigurationSetting_DefaultInstance)[0]
                    ReportsApplicationName = 'ReportServerWebApp'
                    SqlVersion             = 13
                }
            }

            InModuleScope -ScriptBlock {
                $script:mockDefaultInstanceName = 'MSSQLSERVER'

                $script:testParameters = $mockDefaultParameters.Clone()
                $script:testParameters['InstanceName'] = $mockDefaultInstanceName
            }

            $mockDynamicIsInitialized = $false
        }

        It 'Should return the same values as passed as parameters' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockReportingServicesDatabaseServerName = 'SERVER'
                $mockReportingServicesDatabaseDefaultInstanceName = $mockDefaultInstanceName

                $resultGetTargetResource = Get-TargetResource @testParameters

                $resultGetTargetResource.InstanceName | Should -Be $mockDefaultInstanceName
                $resultGetTargetResource.DatabaseServerName | Should -Be $mockReportingServicesDatabaseServerName
                $resultGetTargetResource.DatabaseInstanceName | Should -Be $mockReportingServicesDatabaseDefaultInstanceName
                $resultGetTargetResource | Should -BeOfType [System.Collections.Hashtable]
            }
        }

        It 'Should return the state as not initialized' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $resultGetTargetResource = Get-TargetResource @testParameters

                $resultGetTargetResource.IsInitialized | Should -BeFalse
                $resultGetTargetResource.ReportServerVirtualDirectory | Should -BeNullOrEmpty
                $resultGetTargetResource.ReportsVirtualDirectory | Should -BeNullOrEmpty
                $resultGetTargetResource.ReportServerReservedUrl | Should -BeNullOrEmpty
                $resultGetTargetResource.ReportsReservedUrl | Should -BeNullOrEmpty
            }

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ListReservedUrls'
            } -Exactly -Times 1 -Scope It
        }

        # Regression test for issue #822.
        Context 'When Reporting Services has not been initialized (IsInitialized returns $null)' {
            BeforeAll {
                $mockDynamicIsInitialized = $null
            }

            It 'Should return the state as not initialized' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $resultGetTargetResource = Get-TargetResource @testParameters

                    $resultGetTargetResource.IsInitialized | Should -BeFalse
                }
            }
        }

        # Regression test for issue #822.
        Context 'When Reporting Services has not been initialized (IsInitialized returns empty string)' {
            BeforeAll {
                $mockDynamicIsInitialized = ''
            }

            It 'Should return the state as not initialized' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $resultGetTargetResource = Get-TargetResource @testParameters

                    $resultGetTargetResource.IsInitialized | Should -BeFalse
                }
            }
        }
    }

    Context 'When there is no Reporting Services instance' {
        BeforeAll {
            Mock -CommandName Get-ReportingServicesData -MockWith {
                return @{
                    Configuration          = $null
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Get-TargetResource @mockDefaultParameters } | Should -Throw -ExpectedMessage ('*' + ($script:localizedData.ReportingServicesNotFound -f $mockDefaultParameters.InstanceName))
            }
        }
    }
}#>

<#Describe 'SqlRS\Set-TargetResource' -Tag 'Set' {
    BeforeDiscovery {
        $sqlVersions = @(
            @{
                TestCaseVersionName = "SQL Server Reporting Services 2016"
                TestCaseVersion = 13
            }
            @{
                TestCaseVersionName = "SQL Server Reporting Services 2017"
                TestCaseVersion = 14
            }
            @{
                TestCaseVersionName = "SQL Server Reporting Services 2019"
                TestCaseVersion = 15
            }
        )
    }

    BeforeAll {
        InModuleScope -ScriptBlock {
            # Inject a stub in the module scope to support testing cross-plattform
            function script:Get-CimInstance
            {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-ParameterBlockParameterAttribute', '', Justification='The stub cannot use [Parameter()].')]
                param
                (
                    $ClassName
                )

                return
            }

            # Inject a stub in the module scope to support testing cross-plattform
            function script:Invoke-CimMethod
            {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-ParameterBlockParameterAttribute', '', Justification='The stub cannot use [Parameter()].')]
                param
                (
                    $MethodName,
                    $Arguments
                )

                return
            }
        }

        $mockNamedInstanceName = 'INSTANCE'
        $mockDefaultInstanceName = 'MSSQLSERVER'
        $mockReportingServicesDatabaseServerName = 'SERVER'
        $mockReportingServicesDatabaseNamedInstanceName = $mockNamedInstanceName
        $mockReportingServicesDatabaseDefaultInstanceName = $mockDefaultInstanceName
        $mockReportingServicesDatabaseName = 'ReportServer'

        $mockReportsApplicationName = 'ReportServerWebApp'
        $mockReportsApplicationNameLegacy = 'ReportManager'
        $mockReportServerApplicationName = 'ReportServerWebService'
        $mockReportsApplicationUrl = 'http://+:80'
        $mockReportServerApplicationUrl = 'http://+:80'
        $mockVirtualDirectoryReportManagerName = 'Reports_SQL2016'
        $mockVirtualDirectoryReportServerName = 'ReportServer_SQL2016'

        $mockServiceNamePowerBiReportServer = 'PowerBIReportServer'

        $mockServiceAccount = 'CONTOSO\ServiceAccount'
        $mockPassword = [System.Security.SecureString]::new()
        $mockPassword.AppendChar(' ')
        $mockServiceAccountCredential = [System.Management.Automation.PSCredential]::new($mockServiceAccount, $mockPassword)

        $mockInvokeCimMethod = {
            throw 'Should not call Invoke-CimMethod directly, should call the wrapper Invoke-RsCimMethod.'
        }

        $mockInvokeRsCimMethod_ListReservedUrls = {
            return New-Object -TypeName Object |
                Add-Member -MemberType ScriptProperty -Name 'Application' -Value {
                return @(
                    $mockDynamicReportServerApplicationName,
                    $mockDynamicReportsApplicationName
                )
            } -PassThru |
                Add-Member -MemberType ScriptProperty -Name 'UrlString' -Value {
                return @(
                    $mockDynamicReportsApplicationUrlString,
                    $mockDynamicReportServerApplicationUrlString
                )
            } -PassThru -Force
        }

        $mockInvokeRsCimMethod_GenerateDatabaseCreationScript = {
            return @{
                Script = 'select * from something'
            }
        }

        $mockInvokeRsCimMethod_GenerateDatabaseRightsScript = {
            return @{
                Script = 'select * from something'
            }
        }

        $mockGetCimInstance_ConfigurationSetting_NamedInstance = {
            return @(
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                        'MSReportServer_ConfigurationSetting'
                        'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
                    ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $mockDynamicIsInitialized -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockNamedInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value $mockVirtualDirectoryReportServerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value $mockVirtualDirectoryReportManagerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $mockDynamicSecureConnectionLevel -PassThru -Force
                ),
                (
                    # Array is a regression test for issue #819.
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $true -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value 'DummyInstance' -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_ConfigurationSetting_DefaultInstance = {
            return New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                'MSReportServer_ConfigurationSetting'
                'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
            ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName" -PassThru |
                Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $false -PassThru |
                Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockDefaultInstanceName -PassThru |
                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value '' -PassThru |
                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value '' -PassThru -Force |
                Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $mockDynamicSecureConnectionLevel -PassThru -Force
        }

        $mockGetCimInstance_ConfigurationSetting_PowerBIReportServer = {
            return @(
                (
                    New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                        'MSReportServer_ConfigurationSetting'
                        'root/Microsoft/SQLServer/ReportServer/RS_PBIRS/v15/Admin'
                    ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $mockDynamicIsInitialized -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockNamedInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value $mockVirtualDirectoryReportServerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value $mockVirtualDirectoryReportManagerName -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $mockDynamicSecureConnectionLevel -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'ServiceName' -Value $mockServiceNamePowerBiReportServer -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'WindowsServiceIdentityActual' -Value 'NT AUTHORITY\SYSTEM' -PassThru -Force
                ),
                (
                    # Array is a regression test for issue #819.
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $true -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value 'DummyInstance' -PassThru -Force
                )
            )
        }

        $mockGetCimInstance_ConfigurationSetting_ParameterFilter = {
            $ClassName -eq 'MSReportServer_ConfigurationSetting'
        }

        $mockGetCimInstance_Language = {
            return @{
                Language = '1033'
            }
        }

        $mockGetCimInstance_OperatingSystem_ParameterFilter = {
            $ClassName -eq 'Win32_OperatingSystem'
        }

        $mockGetCimInstance_ServiceAccountUserName = {
            return @{
                Name = $mockServiceAccountName
            }
        }

        Mock -CommandName Invoke-RsCimMethod -MockWith $mockInvokeRsCimMethod_ListReservedUrls -ParameterFilter {
            $MethodName -eq 'ListReservedUrls'
        }

        #This is mocked here so that no calls are made to it directly, or if any mock of Invoke-RsCimMethod are wrong.
        Mock -CommandName Invoke-CimMethod -MockWith $mockInvokeCimMethod

        Mock -CommandName Import-SqlDscPreferredModule
        Mock -CommandName Invoke-SqlCmd
        Mock -CommandName Restart-ReportingServicesService
        Mock -CommandName Invoke-RsCimMethod
        Mock -CommandName Invoke-RsCimMethod -MockWith $mockInvokeRsCimMethod_GenerateDatabaseCreationScript -ParameterFilter {
            $MethodName -eq 'GenerateDatabaseCreationScript'
        }

        Mock -CommandName Invoke-RsCimMethod -MockWith $mockInvokeRsCimMethod_GenerateDatabaseRightsScript -ParameterFilter {
            $MethodName -eq 'GenerateDatabaseRightsScript'
        }

        # This is mocked here so that no calls are made to it directly, or if any mock of Invoke-RsCimMethod are wrong.
        Mock -CommandName Invoke-CimMethod -MockWith $mockInvokeCimMethod

        $mockDynamicReportServerApplicationName = $mockReportServerApplicationName
        $mockDynamicReportsApplicationName = $mockReportsApplicationName
        $mockDynamicReportsApplicationUrlString = $mockReportsApplicationUrl
        $mockDynamicReportServerApplicationUrlString = $mockReportServerApplicationUrl

        InModuleScope -ScriptBlock {
            $script:mockNamedInstanceName = 'INSTANCE'
            $script:mockReportingServicesDatabaseServerName = 'SERVER'
            $script:mockReportingServicesDatabaseNamedInstanceName = $mockNamedInstanceName

            # Inject a stub in the module scope to support testing cross-plattform
            function script:Invoke-CimMethod
            {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-ParameterBlockParameterAttribute', '', Justification='The stub cannot use [Parameter()].')]
                param
                (
                    $MethodName,
                    $Arguments
                )

                return
            }
        }
    }

    Context "When the system is not in the desired state (<TestCaseVersionName>)" -ForEach $sqlVersions {
        Context "When configuring a named instance that is not initialized (<TestCaseVersionName>)" {
            BeforeAll {
                $mockDynamicIsInitialized = $false

                Mock -CommandName Get-ReportingServicesData -MockWith {
                    return @{
                        Configuration          = (& $mockGetCimInstance_ConfigurationSetting_NamedInstance)[0]
                        ReportsApplicationName = 'ReportServerWebApp'
                        SqlVersion             = $TestCaseVersion
                    }
                }

                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                }

                BeforeAll {
                    Mock -CommandName Get-Command -ParameterFilter {
                        $Name -eq 'Invoke-SqlCmd'
                    } -MockWith {
                        return @{
                            Parameters = @{
                                Keys = @()
                            }
                        }
                    }
                }
            }

            BeforeEach {
                Mock -CommandName Get-CimInstance `
                    -MockWith $mockGetCimInstance_Language `
                    -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter

                Mock -CommandName Get-CimInstance `
                    -MockWith $mockGetCimInstance_ServiceAccountUserName `
                    -ParameterFilter $mockGetCimInstance_Service_ParameterFilter
            }

            It 'Should configure Reporting Service without throwing an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockDefaultParameters = @{
                        InstanceName         = $mockNamedInstanceName
                        DatabaseServerName   = $mockReportingServicesDatabaseServerName
                        DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                        UseSsl               = $true
                    }

                    { Set-TargetResource @mockDefaultParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetSecureConnectionLevel'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL'
                } -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'InitializeReportServer'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetDatabaseConnection'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseRightsScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseCreationScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_OperatingSystem'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-SqlCmd -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Restart-ReportingServicesService -Exactly -Times 2 -Scope It
            }

            Context 'When there is no Reporting Services instance after Set-TargetResource has been called' {
                BeforeEach {
                    Mock -CommandName Get-ItemProperty
                    Mock -CommandName Test-TargetResource
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        # This tests should not pass the parameter Encrypt to test that det default value works.
                        $mockDefaultParameters = @{
                            InstanceName         = $mockNamedInstanceName
                            DatabaseServerName   = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            UseSsl               = $true
                        }

                        { Set-TargetResource @mockDefaultParameters } | Should -Throw -ExpectedMessage ('*' + $script:localizedData.TestFailedAfterSet)

                        Should -Invoke -CommandName Invoke-SqlCmd -ParameterFilter {
                            $PesterBoundParameters.Keys -notcontains 'Encrypt'
                        } -Times 2 -Exactly -Scope It
                    }
                }
            }

            Context 'When it is not possible to evaluate OSLanguage' {
                BeforeEach {
                    Mock -CommandName Get-CimInstance -MockWith {
                        return $null
                    } -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $mockDefaultParameters = @{
                            InstanceName         = $mockNamedInstanceName
                            DatabaseServerName   = $mockReportingServicesDatabaseServerName
                            DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                            UseSsl               = $true
                        }

                        { Set-TargetResource @mockDefaultParameters } | Should -Throw ('*' + 'Unable to find WMI object Win32_OperatingSystem.')
                    }
                }
            }
        }

        Context "When configuring a named instance that is already initialized (<TestCaseVersionName>)" {
            BeforeAll {
                $mockDynamicIsInitialized = $true

                Mock -CommandName Get-ReportingServicesData -MockWith {
                    return @{
                        Configuration          = (& $mockGetCimInstance_ConfigurationSetting_NamedInstance)[0]
                        ReportsApplicationName = 'ReportServerWebApp'
                        SqlVersion             = $TestCaseVersion
                    }
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        DatabaseName = $mockReportingServicesDatabaseName
                        ReportServerReservedUrl = $mockReportServerApplicationUrl
                        ReportsReservedUrl      = $mockReportsApplicationUrl
                    }
                }

                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                }

                $testParameters = @{
                    InstanceName                 = $mockNamedInstanceName
                    DatabaseServerName           = $mockReportingServicesDatabaseServerName
                    DatabaseInstanceName         = $mockReportingServicesDatabaseNamedInstanceName
                    DatabaseName                 = 'NewDatabase'
                    ReportServerVirtualDirectory = 'ReportServer_NewName'
                    ReportsVirtualDirectory      = 'Reports_NewName'
                    ReportServerReservedUrl      = 'https://+:4443'
                    ReportsReservedUrl           = 'https://+:4443'
                    UseSsl                       = $true
                }
            }

            BeforeEach {
                Mock -CommandName Get-CimInstance `
                    -MockWith $mockGetCimInstance_Language `
                    -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter
            }

            It 'Should configure Reporting Service without throwing an error' {
                { Set-TargetResource @testParameters } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetSecureConnectionLevel'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'InitializeReportServer'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetDatabaseConnection'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseRightsScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseCreationScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-SqlCmd -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Restart-ReportingServicesService -Exactly -Times 2 -Scope It
            }
        }

        Context "When configuring a named instance that is already initialized (<TestCaseVersionName>), suppress restart" {
            BeforeAll {
                $mockDynamicIsInitialized = $true

                Mock -CommandName Get-ReportingServicesData -MockWith {
                    return @{
                        Configuration          = (& $mockGetCimInstance_ConfigurationSetting_NamedInstance)[0]
                        ReportsApplicationName = 'ReportServerWebApp'
                        SqlVersion             = $TestCaseVersion
                    }
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        DatabaseName = $mockReportingServicesDatabaseName
                        ReportServerReservedUrl = $mockReportServerApplicationUrl
                        ReportsReservedUrl      = $mockReportsApplicationUrl
                    }
                }

                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                }

                $testParameters = @{
                    InstanceName                 = $mockNamedInstanceName
                    DatabaseServerName           = $mockReportingServicesDatabaseServerName
                    DatabaseInstanceName         = $mockReportingServicesDatabaseNamedInstanceName
                    ReportServerVirtualDirectory = 'ReportServer_NewName'
                    ReportsVirtualDirectory      = 'Reports_NewName'
                    ReportServerReservedUrl      = 'https://+:4443'
                    ReportsReservedUrl           = 'https://+:4443'
                    UseSsl                       = $true
                    SuppressRestart              = $true
                }
            }

            BeforeEach {
                Mock -CommandName Get-CimInstance `
                    -MockWith $mockGetCimInstance_Language `
                    -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter
            }

            It 'Should configure Reporting Service without throwing an error' {
                { Set-TargetResource @testParameters } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetSecureConnectionLevel'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'InitializeReportServer'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetDatabaseConnection'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseRightsScript'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseCreationScript'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-SqlCmd -Exactly -Times 0 -Scope It
                Should -Invoke -CommandName Restart-ReportingServicesService -Exactly -Times 1 -Scope It
            }
        }

        Context "When configuring a default instance that is not initialized (<TestCaseVersionName>)" {
            BeforeAll {
                $mockDynamicIsInitialized = $false

                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                }

                                Mock -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Invoke-SqlCmd'
                } -MockWith {
                    return @{
                        Parameters = @{
                            Keys = @('Encrypt')
                        }
                    }
                }

                $defaultParameters = @{
                    InstanceName         = $mockDefaultInstanceName
                    DatabaseServerName   = $mockReportingServicesDatabaseServerName
                    DatabaseInstanceName = $mockReportingServicesDatabaseDefaultInstanceName
                    # Testing passing Encrypt.
                    Encrypt                      = 'Optional'
                }
            }

            BeforeEach {
                # This mocks the SQL Server Reporting Services 2014 and older
                Mock -CommandName Get-ReportingServicesData -MockWith {
                    return @{
                        Configuration          = (& $mockGetCimInstance_ConfigurationSetting_DefaultInstance)[0]
                        ReportsApplicationName = 'ReportManager'
                        SqlVersion             = $TestCaseVersion
                    }
                }

                Mock -CommandName Get-CimInstance `
                    -MockWith $mockGetCimInstance_Language `
                    -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter
            }

            It 'Should configure Reporting Service without throwing an error' {
                { Set-TargetResource @defaultParameters } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'InitializeReportServer'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetDatabaseConnection'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseRightsScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseCreationScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationNameLegacy
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationNameLegacy
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-SqlCmd -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Restart-ReportingServicesService -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-SqlCmd -ParameterFilter {
                    $Encrypt -eq 'Optional'
                } -Times 2 -Exactly -Scope It
            }
        }
    }

    Context 'When Power BI Report Server is not in the desired state' {
        Context "When configuring an instance that is not initialized" {
            BeforeAll {
                $mockDynamicIsInitialized = $false

                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                }

                $defaultParameters = @{
                    InstanceName         = 'PBIRS'
                    DatabaseServerName   = $mockReportingServicesDatabaseServerName
                    DatabaseInstanceName = $mockReportingServicesDatabaseDefaultInstanceName
                    ServiceAccount       = $mockServiceAccountCredential
                }

                Mock -CommandName Get-ReportingServicesData -MockWith {
                    return @{
                        Configuration          = (& $mockGetCimInstance_ConfigurationSetting_PowerBIReportServer)[0]
                        ReportsApplicationName = 'ReportServerWebApp'
                        SqlVersion             = 15
                    }
                }

                Mock -CommandName Get-CimInstance `
                    -MockWith $mockGetCimInstance_Language `
                    -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter
            }

            It 'Should configure Reporting Service without throwing an error' {
                { Set-TargetResource @defaultParameters } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetWindowsServiceIdentity'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL'
                } -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'InitializeReportServer'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetDatabaseConnection'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseRightsScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseCreationScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-Sqlcmd -Exactly -Times 2 -Scope It
                Should -Invoke -CommandName Restart-ReportingServicesService -Exactly -Times 2 -Scope It
            }
        }

        Context "When configuring an instance that is already initialized" {
            BeforeAll {
                $mockDynamicIsInitialized = $true

                Mock -CommandName Get-ReportingServicesData -MockWith {
                    return @{
                        Configuration          = (& $mockGetCimInstance_ConfigurationSetting_PowerBIReportServer)[0]
                        ReportsApplicationName = 'ReportServerWebApp'
                        SqlVersion             = 15
                    }
                }

                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        DatabaseName = $mockReportingServicesDatabaseName
                        ReportServerReservedUrl = $mockReportServerApplicationUrl
                        ReportsReservedUrl      = $mockReportsApplicationUrl
                    }
                }

                Mock -CommandName Test-TargetResource -MockWith {
                    return $true
                }

                $testParameters = @{
                    InstanceName                 = 'PBIRS'
                    DatabaseServerName           = $mockReportingServicesDatabaseServerName
                    DatabaseInstanceName         = $mockReportingServicesDatabaseNamedInstanceName
                    ReportServerVirtualDirectory = 'ReportServer_NewName'
                    ReportsVirtualDirectory      = 'Reports_NewName'
                    ReportServerReservedUrl      = 'https://+:4443'
                    ReportsReservedUrl           = 'https://+:4443'
                    UseSsl                       = $true
                    ServiceAccount               = $mockServiceAccountCredential
                }
            }

            BeforeEach {
                Mock -CommandName Get-CimInstance `
                    -MockWith $mockGetCimInstance_Language `
                    -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter
            }

            It 'Should configure Reporting Service without throwing an error' {
                { Set-TargetResource @testParameters } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetWindowsServiceIdentity'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetSecureConnectionLevel'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'RemoveURL' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 2 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'InitializeReportServer'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetDatabaseConnection'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseRightsScript'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'GenerateDatabaseCreationScript'
                } -Exactly -Times 0 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                    $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Invoke-Sqlcmd -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName Restart-ReportingServicesService -Exactly -Times 2 -Scope It
            }
        }
    }

    Context "When configuring a named instance of SQL Server Reporting Services 2019 that have been initialized by restarting the service" {
        BeforeAll {
            $script:alreadyCalledGetReportingServicesData = $false
            $script:mockDynamicIsInitialized = $false
            $script:mockDynamicSecureConnectionLevel = $false

            Mock -CommandName Get-ReportingServicesData -MockWith {
                if ($script:alreadyCalledGetReportingServicesData)
                {
                    $script:mockDynamicIsInitialized = $true
                }
                else
                {
                    $script:alreadyCalledGetReportingServicesData = $true
                }

                return @{
                    Configuration          = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                                'MSReportServer_ConfigurationSetting'
                                'root/Microsoft/SQLServer/ReportServer/RS_SQL2019/v15/Admin'
                            ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value "$mockReportingServicesDatabaseServerName\$mockReportingServicesDatabaseNamedInstanceName" -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $script:mockDynamicIsInitialized -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value $mockNamedInstanceName -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value $mockVirtualDirectoryReportServerName -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value $mockVirtualDirectoryReportManagerName -PassThru |
                                Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $script:mockDynamicSecureConnectionLevel -PassThru -Force
                    ReportsApplicationName = 'ReportServerWebApp'
                    SqlVersion             = $sqlVersion.Version
                }
            }

            Mock -CommandName Test-TargetResource -MockWith {
                return $true
            }

            $defaultParameters = @{
                InstanceName         = $mockNamedInstanceName
                DatabaseServerName   = $mockReportingServicesDatabaseServerName
                DatabaseInstanceName = $mockReportingServicesDatabaseNamedInstanceName
                UseSsl               = $false
            }
        }

        BeforeEach {
            Mock -CommandName Get-CimInstance `
                -MockWith $mockGetCimInstance_Language `
                -ParameterFilter $mockGetCimInstance_OperatingSystem_ParameterFilter
        }

        It 'Should configure Reporting Service without throwing an error' {
            { Set-TargetResource @defaultParameters } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetSecureConnectionLevel'
            } -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'RemoveURL'
            } -Exactly -Times 2 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'InitializeReportServer'
            } -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetDatabaseConnection'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'GenerateDatabaseRightsScript'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'GenerateDatabaseCreationScript'
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportServerApplicationName
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'SetVirtualDirectory' -and $Arguments.Application -eq $mockReportsApplicationName
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportServerApplicationName
            } -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Invoke-RsCimMethod -ParameterFilter {
                $MethodName -eq 'ReserveUrl' -and $Arguments.Application -eq $mockReportsApplicationName
            } -Exactly -Times 0 -Scope It

            Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Invoke-SqlCmd -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Restart-ReportingServicesService -Exactly -Times 1 -Scope It
        }
    }
}#>

<#Describe 'SqlRS\Test-TargetResource' -Tag 'Test' {
    Context 'When the system is not in the desired state' {
        Context 'When Reporting Services are not initialized' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized = $false
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        InstanceName         = 'INSTANCE'
                        DatabaseServerName   = 'DBSERVER'
                        DatabaseInstanceName = 'DBINSTANCE'
                        Encrypt              = 'Optional'
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When current Report Server reserved URL is $null' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized           = $false
                        ReportServerReservedUrl = $null
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        InstanceName            = 'INSTANCE'
                        DatabaseServerName      = 'DBSERVER'
                        DatabaseInstanceName    = 'DBINSTANCE'
                        ReportServerReservedUrl = 'ReportServer_SQL2016'
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When current Reports reserved URL is $null' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized      = $false
                        ReportsReservedUrl = $null
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        InstanceName         = 'INSTANCE'
                        DatabaseServerName   = 'DBSERVER'
                        DatabaseInstanceName = 'DBINSTANCE'
                        ReportsReservedUrl   = 'Reports_SQL2016'
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When Report Server virtual directory is different' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized                = $true
                        ReportServerVirtualDirectory = 'ReportServer_SQL2016'
                        ReportsVirtualDirectory      = 'Reports_SQL2016'
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        InstanceName                 = 'INSTANCE'
                        DatabaseServerName           = 'DBSERVER'
                        DatabaseInstanceName         = 'DBINSTANCE'
                        ReportsVirtualDirectory      = 'Reports_SQL2016'
                        ReportServerVirtualDirectory = 'ReportServer_NewName'
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When Reports virtual directory is different' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized                = $true
                        ReportServerVirtualDirectory = 'ReportServer_SQL2016'
                        ReportsVirtualDirectory      = 'Reports_SQL2016'
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        InstanceName                 = 'INSTANCE'
                        DatabaseServerName           = 'DBSERVER'
                        DatabaseInstanceName         = 'DBINSTANCE'
                        ReportServerVirtualDirectory = 'ReportServer_SQL2016'
                        ReportsVirtualDirectory      = 'Reports_NewName'
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When Report Server Report Server reserved URLs is different' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized           = $true
                        ReportServerReservedUrl = 'http://+:80'
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        InstanceName            = 'INSTANCE'
                        DatabaseServerName      = 'DBSERVER'
                        DatabaseInstanceName    = 'DBINSTANCE'
                        ReportServerReservedUrl = 'https://+:443'
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When Report Server Reports reserved URLs is different' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized      = $true
                        ReportsReservedUrl = 'http://+:80'
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        InstanceName         = 'INSTANCE'
                        DatabaseServerName   = 'DBSERVER'
                        DatabaseInstanceName = 'DBINSTANCE'
                        ReportsReservedUrl   = 'https://+:443'
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When SSL is not used' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized      = $true
                        UseSsl             = $false
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParameters = @{
                        InstanceName         = 'INSTANCE'
                        DatabaseServerName   = 'DBSERVER'
                        DatabaseInstanceName = 'DBINSTANCE'
                        UseSsl               = $true
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters

                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }

        Context 'When the service account is not to the desired state' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        IsInitialized                = $true
                        WindowsServiceIdentityActual = 'NT AUTHORITY\SYSTEM'
                    }
                }
            }

            It 'Should return state as not in desired state' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockServiceAccount = 'CONTOSO\ServiceAccount'
                    $mockPassword = [System.Security.SecureString]::new()
                    $mockPassword.AppendChar(' ')
                    $mockServiceAccountCredential = [System.Management.Automation.PSCredential]::new($mockServiceAccount,$mockPassword)

                    $testParameters = @{
                        InstanceName         = 'INSTANCE'
                        DatabaseServerName   = 'DBSERVER'
                        DatabaseInstanceName = 'DBINSTANCE'
                        ServiceAccount       = $mockServiceAccountCredential
                    }

                    $resultTestTargetResource = Test-TargetResource @testParameters
                    $resultTestTargetResource | Should -BeFalse
                }
            }
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-TargetResource -MockWith {
                return @{
                    IsInitialized = $true
                    DatabaseName = 'ReportServer'
                    ReportServerReservedUrl = @('http://+:80')
                    ReportsReservedUrl = @('http://+:80')
                }
            }
        }

        It 'Should return state as in desired state' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $defaultParameters = @{
                    InstanceName         = 'INSTANCE'
                    DatabaseServerName   = 'DBSERVER'
                    DatabaseInstanceName = 'DBINSTANCE'
                }

                $resultTestTargetResource = Test-TargetResource @defaultParameters

                $resultTestTargetResource | Should -BeTrue
            }
        }
    }
}#>

Describe 'SqlRS\Invoke-RsCimMethod' -Tag 'Helper' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $script:mockCimInstance = New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                'MSReportServer_ConfigurationSetting'
                'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
            )

            # Inject a stub in the module scope to support testing cross-plattform
            function script:Invoke-CimMethod
            {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-ParameterBlockParameterAttribute', '', Justification='The stub cannot use [Parameter()].')]
                param
                (
                    $MethodName,
                    $Arguments
                )

                return
            }
        }
    }

    Context 'When calling a method that execute successfully' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return @{
                    HRESULT = 0
                }
            }
        }

        Context 'When calling Invoke-CimMethod without arguments' {
            It 'Should call Invoke-CimMethod without throwing an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $mockCimInstance
                        MethodName  = 'AnyMethod'
                    }

                    $resultTestTargetResource = Invoke-RsCimMethod @invokeRsCimMethodParameters
                    $resultTestTargetResource.HRESULT | Should -Be 0
                }

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'AnyMethod' -and $Arguments -eq $null
                } -Exactly -Times 1
            }
        }

        Context 'When calling Invoke-CimMethod with arguments' {
            It 'Should call Invoke-CimMethod without throwing an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $mockCimInstance
                        MethodName  = 'AnyMethod'
                        Arguments   = @{
                            Argument1 = 'ArgumentValue1'
                        }
                    }

                    $resultTestTargetResource = Invoke-RsCimMethod @invokeRsCimMethodParameters
                    $resultTestTargetResource.HRESULT | Should -Be 0
                }

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'AnyMethod' -and $Arguments.Argument1 -eq 'ArgumentValue1'
                } -Exactly -Times 1
            }
        }
    }

    Context 'When calling a method that fails with an error' {
        Context 'When Invoke-CimMethod fails and returns an object with a Error property' {
            BeforeAll {
                Mock -CommandName Invoke-CimMethod -MockWith {
                    return @{
                        HRESULT = 1
                        Error   = 'Something went wrong'
                    }
                }
            }

            It 'Should call Invoke-CimMethod and throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $mockCimInstance
                        MethodName  = 'AnyMethod'
                    }

                    { Invoke-RsCimMethod @invokeRsCimMethodParameters } | Should -Throw 'Method AnyMethod() failed with an error. Error: Something went wrong (HRESULT:1)'
                }

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'AnyMethod'
                } -Exactly -Times 1
            }
        }

        Context 'When Invoke-CimMethod fails and returns an object with a ExtendedErrors property' {
            BeforeAll {
                Mock -CommandName Invoke-CimMethod -MockWith {
                    return New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'HRESULT' -Value 1 -PassThru |
                        Add-Member -MemberType NoteProperty -Name 'ExtendedErrors' -Value @('Something went wrong', 'Another thing went wrong') -PassThru -Force
                }
            }

            It 'Should call Invoke-CimMethod and throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $mockCimInstance
                        MethodName  = 'AnyMethod'
                    }

                    { Invoke-RsCimMethod @invokeRsCimMethodParameters } | Should -Throw 'Method AnyMethod() failed with an error. Error: Something went wrong;Another thing went wrong (HRESULT:1)'
                }

                Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                    $MethodName -eq 'AnyMethod'
                } -Exactly -Times 1
            }
        }
    }
}

Describe 'SqlRS\Get-ReportingServicesData' -Tag 'Helper' {
    BeforeAll {
        $mockInstanceId = 'MSRS13.INSTANCE'

        $mockGetItemProperty_Sql2014 = {
            return @{
                Version = '12.0.6024.0'
            }
        }

        $mockGetItemProperty_Sql2016 = {
            return @{
                Version ='13.0.4001.0'
            }
        }

        $mockGetItemProperty_Sql2017 = {
            return @{
                CurrentVersion = '14.0.6514.11481'
            }
        }

        $mockGetItemProperty_Sql2019 = {
            return @{
                CurrentVersion = '15.0.2000.5'
            }
        }

        $mockGetItemProperty_PBIRS = {
            return @{
                CurrentVersion = '15.0.1108.297'
            }
        }

        $mockGetItemProperty_InstanceNames_ParameterFilter = {
            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'
        }

        $mockGetItemProperty_Sql2014AndSql2016_ParameterFilter = {
            $Path -eq ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\Setup' -f $mockInstanceId)
        }

        $mockGetItemProperty_Sql2017AndLater_ParameterFilter = {
            $Path -eq ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\MSSQLServer\CurrentVersion' -f $mockInstanceId)
        }

        # Inject a stub in the module scope to support testing cross-plattform
        InModuleScope -ScriptBlock {
            function script:Get-CimInstance
            {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules\Measure-ParameterBlockParameterAttribute', '', Justification='The stub cannot use [Parameter()].')]
                param
                (
                    $ClassName
                )

                return
            }
        }
    }

    Context 'When there is a Reporting Services instance' {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                return @{
                    'INSTANCE' = $mockInstanceId
                }
            } -ParameterFilter $mockGetItemProperty_InstanceNames_ParameterFilter

            Mock -CommandName Get-CimInstance -MockWith {
                return @(
                    (
                        New-Object -TypeName Microsoft.Management.Infrastructure.CimInstance -ArgumentList @(
                            'MSReportServer_ConfigurationSetting'
                            'root/Microsoft/SQLServer/ReportServer/RS_SQL2016/v13/Admin'
                        ) | Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value 'DBSERVER\DBINSTANCE' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value 'INSTANCE' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportServer' -Value 'ReportServer' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'VirtualDirectoryReportManager' -Value 'Reports' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'SecureConnectionLevel' -Value $false -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'WindowsServiceIdentityActual' -Value 'Contoso\ssrsServiceAccount' -PassThru -Force
                    ),
                    (
                        # Array is a regression test for issue #819.
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'DatabaseServerName' -Value 'DBSERVER\DBINSTANCE' -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'IsInitialized' -Value $true -PassThru |
                            Add-Member -MemberType NoteProperty -Name 'InstanceName' -Value 'DummyInstance' -PassThru -Force
                    )
                )
            } -ParameterFilter {
                $ClassName -eq 'MSReportServer_ConfigurationSetting'
            }
        }

        Context 'When the instance is SQL Server Reporting Services 2014 or older' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    return $false
                }

                Mock -CommandName Get-ItemProperty `
                    -MockWith $mockGetItemProperty_Sql2014 `
                    -ParameterFilter $mockGetItemProperty_Sql2014AndSql2016_ParameterFilter
            }

            It 'Should return the correct information' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getReportingServicesDataResult = Get-ReportingServicesData -InstanceName 'INSTANCE'

                    $getReportingServicesDataResult.Configuration | Should -BeOfType [Microsoft.Management.Infrastructure.CimInstance]
                    $getReportingServicesDataResult.Configuration.InstanceName | Should -Be 'INSTANCE'
                    $getReportingServicesDataResult.Configuration.DatabaseServerName | Should -Be 'DBSERVER\DBINSTANCE'
                    $getReportingServicesDataResult.Configuration.IsInitialized | Should -BeFalse
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportServer | Should -Be 'ReportServer'
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportManager | Should -Be 'Reports'
                    $getReportingServicesDataResult.Configuration.SecureConnectionLevel | Should -Be 0
                    $getReportingServicesDataResult.Configuration.WindowsServiceIdentityActual | Should -Be 'Contoso\ssrsServiceAccount'
                    $getReportingServicesDataResult.ReportsApplicationName | Should -Be 'ReportManager'
                    $getReportingServicesDataResult.SqlVersion | Should -Be '12'
                }

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_InstanceNames_ParameterFilter `
                    -Exactly -Times 2 -Scope 'It'

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_Sql2014AndSql2016_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the instance is SQL Server Reporting Services 2016' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    return $false
                }

                Mock -CommandName Get-ItemProperty `
                    -MockWith $mockGetItemProperty_Sql2016 `
                    -ParameterFilter $mockGetItemProperty_Sql2014AndSql2016_ParameterFilter
            }

            It 'Should return the correct information' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getReportingServicesDataResult = Get-ReportingServicesData -InstanceName 'INSTANCE'

                    $getReportingServicesDataResult.Configuration | Should -BeOfType [Microsoft.Management.Infrastructure.CimInstance]
                    $getReportingServicesDataResult.Configuration.InstanceName | Should -Be 'INSTANCE'
                    $getReportingServicesDataResult.Configuration.DatabaseServerName | Should -Be 'DBSERVER\DBINSTANCE'
                    $getReportingServicesDataResult.Configuration.IsInitialized | Should -BeFalse
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportServer | Should -Be 'ReportServer'
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportManager | Should -Be 'Reports'
                    $getReportingServicesDataResult.Configuration.SecureConnectionLevel | Should -Be 0
                    $getReportingServicesDataResult.Configuration.WindowsServiceIdentityActual | Should -Be 'Contoso\ssrsServiceAccount'
                    $getReportingServicesDataResult.ReportsApplicationName | Should -Be 'ReportServerWebApp'
                    $getReportingServicesDataResult.SqlVersion | Should -Be '13'
                }

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_InstanceNames_ParameterFilter `
                    -Exactly -Times 2 -Scope 'It'

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_Sql2014AndSql2016_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the instance is SQL Server Reporting Services 2017' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-ItemProperty `
                    -MockWith $mockGetItemProperty_Sql2017 `
                    -ParameterFilter $mockGetItemProperty_Sql2017AndLater_ParameterFilter
            }

            It 'Should return the correct information' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getReportingServicesDataResult = Get-ReportingServicesData -InstanceName 'INSTANCE'

                    $getReportingServicesDataResult.Configuration | Should -BeOfType [Microsoft.Management.Infrastructure.CimInstance]
                    $getReportingServicesDataResult.Configuration.InstanceName | Should -Be 'INSTANCE'
                    $getReportingServicesDataResult.Configuration.DatabaseServerName | Should -Be 'DBSERVER\DBINSTANCE'
                    $getReportingServicesDataResult.Configuration.IsInitialized | Should -BeFalse
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportServer | Should -Be 'ReportServer'
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportManager | Should -Be 'Reports'
                    $getReportingServicesDataResult.Configuration.SecureConnectionLevel | Should -Be 0
                    $getReportingServicesDataResult.Configuration.WindowsServiceIdentityActual | Should -Be 'Contoso\ssrsServiceAccount'
                    $getReportingServicesDataResult.ReportsApplicationName | Should -Be 'ReportServerWebApp'
                    $getReportingServicesDataResult.SqlVersion | Should -Be '14'
                }

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_InstanceNames_ParameterFilter `
                    -Exactly -Times 2 -Scope 'It'

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_Sql2017AndLater_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the instance is SQL Server Reporting Services 2019' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-ItemProperty `
                    -MockWith $mockGetItemProperty_Sql2019 `
                    -ParameterFilter $mockGetItemProperty_Sql2017AndLater_ParameterFilter
            }

            It 'Should return the correct information' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getReportingServicesDataResult = Get-ReportingServicesData -InstanceName 'INSTANCE'

                    $getReportingServicesDataResult.Configuration | Should -BeOfType [Microsoft.Management.Infrastructure.CimInstance]
                    $getReportingServicesDataResult.Configuration.InstanceName | Should -Be 'INSTANCE'
                    $getReportingServicesDataResult.Configuration.DatabaseServerName | Should -Be 'DBSERVER\DBINSTANCE'
                    $getReportingServicesDataResult.Configuration.IsInitialized | Should -BeFalse
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportServer | Should -Be 'ReportServer'
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportManager | Should -Be 'Reports'
                    $getReportingServicesDataResult.Configuration.SecureConnectionLevel | Should -Be 0
                    $getReportingServicesDataResult.Configuration.WindowsServiceIdentityActual | Should -Be 'Contoso\ssrsServiceAccount'
                    $getReportingServicesDataResult.ReportsApplicationName | Should -Be 'ReportServerWebApp'
                    $getReportingServicesDataResult.SqlVersion | Should -Be '15'
                }

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_InstanceNames_ParameterFilter `
                    -Exactly -Times 2 -Scope 'It'

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_Sql2017AndLater_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the instance is Power BI Reporting Services' {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-ItemProperty `
                    -MockWith $mockGetItemProperty_PBIRS `
                    -ParameterFilter $mockGetItemProperty_Sql2017AndLater_ParameterFilter
            }

            It 'Should return the correct information' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getReportingServicesDataResult = Get-ReportingServicesData -InstanceName 'INSTANCE'

                    $getReportingServicesDataResult.Configuration | Should -BeOfType [Microsoft.Management.Infrastructure.CimInstance]
                    $getReportingServicesDataResult.Configuration.InstanceName | Should -Be 'INSTANCE'
                    $getReportingServicesDataResult.Configuration.DatabaseServerName | Should -Be 'DBSERVER\DBINSTANCE'
                    $getReportingServicesDataResult.Configuration.IsInitialized | Should -BeFalse
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportServer | Should -Be 'ReportServer'
                    $getReportingServicesDataResult.Configuration.VirtualDirectoryReportManager | Should -Be 'Reports'
                    $getReportingServicesDataResult.Configuration.SecureConnectionLevel | Should -Be 0
                    $getReportingServicesDataResult.Configuration.WindowsServiceIdentityActual | Should -Be 'Contoso\ssrsServiceAccount'
                    $getReportingServicesDataResult.ReportsApplicationName | Should -Be 'ReportServerWebApp'
                    $getReportingServicesDataResult.SqlVersion | Should -Be '15'
                }

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_InstanceNames_ParameterFilter `
                    -Exactly -Times 2 -Scope 'It'

                Should -Invoke -CommandName Get-ItemProperty `
                    -ParameterFilter $mockGetItemProperty_Sql2017AndLater_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'

                Should -Invoke -CommandName Get-CimInstance -Exactly -Times 1 -Scope 'It'
            }
        }
    }
}

Describe 'SqlRS\Get-LocalServiceAccountName' -Tag 'Helper' {
    BeforeDiscovery {
        $builtinServiceAccountTestCases = @(
            @{
                ServiceAccountTypeName = 'LocalService'
                ServiceAccountName     = 'NT AUTHORITY\LocalService'
            }
            @{
                ServiceAccountTypeName = 'NetworkService'
                ServiceAccountName     = 'NT AUTHORITY\NetworkService'
            }
            @{
                ServiceAccountTypeName = 'System'
                ServiceAccountName     = 'NT AUTHORITY\System'
            }
        )

        $virtualAccountTestCases = @(
            @{
                ServiceName = 'ReportServer'
            }
            @{
                ServiceName = 'SQLServerReportingServices'
            }
            @{
                ServiceName = 'PowerBIReportServer'
            }
        )
    }

    Context 'When a builtin account is specified' {
        It 'Should be "<ServiceAccountName>" when "LocalServiceAccountType" is "<ServiceAccountTypeName>"' -ForEach $builtinServiceAccountTestCases {
            $localServiceAccountName = Get-LocalServiceAccountName -LocalServiceAccountType $ServiceAccountTypeName
            $localServiceAccountName | Should -Be $ServiceAccountName
        }
    }

    Context 'When a virtual account is specified' {
        It 'Should be "NT SERVICE\<ServiceName>" when "LocalServiceAccountType" is "VirtualAccount" and the service name is "<ServiceName>"' -ForEach $virtualAccountTestCases {
            $localServiceAccountName = Get-LocalServiceAccountName -LocalServiceAccountType VirtualAccount -ServiceName $ServiceName
            $localServiceAccountName | Should -Be "NT SERVICE\$ServiceName"
        }

        It 'Should throw the correct error when when "LocalServiceAccountType" is "VirtualAccount" and the service name is not supplied' {
            { Get-LocalServiceAccountName -LocalServiceAccountType VirtualAccount } | Should -Throw "The 'ServiceName' parameter is required with the 'LocalServiceAccountType' is 'VirtualAccount'.*Parameter name: ServiceName"
        }
    }
}
