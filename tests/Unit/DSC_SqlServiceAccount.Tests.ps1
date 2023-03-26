<#
    .SYNOPSIS
        Unit test for DSC_SqlServiceAccount DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
# Suppressing this rule because tests are mocking parameters with the name "Password".
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
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
    $script:dscResourceName = 'DSC_SqlServiceAccount'

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

Describe 'SqlServerServiceAccount\Get-TargetResource' -Tag 'Get' {
    Context 'When getting the service information for a default instance' {
        BeforeAll {
            Mock -CommandName Get-ServiceObject -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name           = 'MSSQLSERVER'
                    ServiceAccount = 'NT SERVICE\MSSQLSERVER'
                    Type           = 'SqlServer'
                }
            } -ParameterFilter {
                $ServiceType -eq 'DatabaseEngine'
            }

            Mock -CommandName Get-ServiceObject -MockWith {
                return $null
            } -ParameterFilter {
                $ServiceType -eq 'SQLServerAgent'
            }
        }

        It 'Should return the correct service information' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $defaultGetTargetResourceParameters = @{
                    ServerName     = 'TestServer'
                    InstanceName   = 'MSSQLSERVER'
                    ServiceType    = 'DatabaseEngine'
                    ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'NT SERVICE\MSSQLSERVER', (New-Object -TypeName System.Security.SecureString))
                }

                # Get the service information
                $testServiceInformation = Get-TargetResource @defaultGetTargetResourceParameters

                # Validate the hashtable returned
                $testServiceInformation.ServerName | Should -Be 'TestServer'
                $testServiceInformation.InstanceName | Should -Be 'MSSQLSERVER'
                $testServiceInformation.ServiceType | Should -Be 'DatabaseEngine'
                $testServiceInformation.ServiceAccountName | Should -Be 'NT SERVICE\MSSQLSERVER'
            }

            # Ensure mocks were properly used
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
        }

        It 'Should throw the correct exception when an invalid ServiceType and InstanceName are specified' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters = @{
                    ServerName     = 'TestServer'
                    InstanceName   = 'MSSQLSERVER'
                    ServiceType    = 'SQLServerAgent'
                    ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'NT SERVICE\MSSQLSERVER', (New-Object -TypeName System.Security.SecureString))
                }

                $mockErrorMessage = $script:localizedData.ServiceNotFound -f 'SQLServerAgent', 'TestServer', 'MSSQLSERVER'

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }

            # Ensure mocks were properly used
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
        }
    }

    Context 'When getting the service information for a named instance' {
        BeforeAll {
            Mock -CommandName Get-ServiceObject -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name           = 'MSSQL$TestInstance'
                    ServiceAccount = 'CONTOSO\sql.service'
                    Type           = 'SqlServer'
                }
            } -ParameterFilter {
                $ServiceType -eq 'DatabaseEngine'
            }

            Mock -CommandName Get-ServiceObject -MockWith {
                return $null
            } -ParameterFilter {
                $ServiceType -eq 'SQLServerAgent'
            }
        }

        It 'Should return the correct service information' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters = @{
                    ServerName     = 'TestServer'
                    InstanceName   = 'TestInstance'
                    ServiceType    = 'DatabaseEngine'
                    ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'CONTOSO\sql.service', (New-Object -TypeName System.Security.SecureString))
                }

                # Get the service information
                $testServiceInformation = Get-TargetResource @mockGetTargetResourceParameters

                # Validate the hashtable returned
                $testServiceInformation.ServerName | Should -Be 'TestServer'
                $testServiceInformation.InstanceName | Should -Be 'TestInstance'
                $testServiceInformation.ServiceType | Should -Be 'DatabaseEngine'
                $testServiceInformation.ServiceAccountName | Should -Be 'CONTOSO\sql.service'
            }

            # Ensure mocks were properly used
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
        }

        It 'Should throw the correct exception when an invalid ServiceType and InstanceName are specified' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters = @{
                    ServerName     = 'TestServer'
                    InstanceName   = 'TestInstance'
                    ServiceType    = 'SQLServerAgent'
                    ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'CONTOSO\sql.service', (New-Object -TypeName System.Security.SecureString))
                }

                $mockErrorMessage = $script:localizedData.ServiceNotFound -f 'SQLServerAgent', 'TestServer', 'TestInstance'

                { Get-TargetResource @mockGetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }

            # Ensure mocks were properly used
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
        }
    }

    Context 'When the service account is local to the machine' {
        BeforeAll {
            Mock -CommandName Get-ServiceObject -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name           = 'MSSQLSERVER'
                    ServiceAccount = '.\SqlService'
                    Type           = 'SqlServer'
                }
            }
        }

        It 'Should have the same domain name as the computer name' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters = @{
                    ServerName     = 'TestServer'
                    InstanceName   = 'MSSQLSERVER'
                    ServiceType    = 'DatabaseEngine'
                    ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'TestServer\SqlService', (New-Object -TypeName System.Security.SecureString))
                }

                $currentState = Get-TargetResource @mockGetTargetResourceParameters

                # Validate the service account
                $currentState.ServiceAccountName | Should -Be 'TestServer\SqlService'
            }

            # Ensure mocks were properly used
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
        }
    }

    Context 'When the service account is a Managed Service Account' {
        BeforeAll {
            Mock -CommandName Get-ServiceObject -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name           = 'MSSQLSERVER'
                    ServiceAccount = 'CONTOSO\sqlservice$'
                    Type           = 'SqlServer'
                }
            }
        }

        It 'Should have the Managed Service Account' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetTargetResourceParameters = @{
                    ServerName     = 'TestServer'
                    InstanceName   = 'MSSQLSERVER'
                    ServiceType    = 'DatabaseEngine'
                    ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'CONTOSO\sqlservice$', (New-Object -TypeName System.Security.SecureString))
                }

                $currentState = Get-TargetResource @mockGetTargetResourceParameters

                # Validate the managed service account
                $currentState.ServiceAccountName | Should -Be 'CONTOSO\sqlservice$'
            }

            # Ensure the mocks were properly used
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
        }
    }
}

Describe 'SqlServerServiceAccount\Test-TargetResource' -Tag 'Test' {
    Context 'When the system is not in the desired state' {
        Context 'When using default instance' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName         = 'TestServer'
                        InstanceName       = 'MSSQLSERVER'
                        ServiceType        = 'SqlServer'
                        ServiceAccountName = 'NotExpectedAccount'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        ServerName     = 'TestServer'
                        InstanceName   = 'MSSQLSERVER'
                        ServiceType    = 'DatabaseEngine'
                        ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'CONTOSO\sql.service', (New-Object -TypeName System.Security.SecureString))
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }

                # Ensure mocks are properly used
                Should -Invoke -CommandName Get-TargetResource -Scope It -Exactly -Times 1
            }
        }

        Context 'When using a named instance' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName         = 'TestServer'
                        InstanceName       = 'TestInstance'
                        ServiceType        = 'SqlServer'
                        ServiceAccountName = 'NotExpectedAccount'
                    }
                }
            }

            It 'Should return false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        ServerName     = 'TestServer'
                        InstanceName   =  'TestInstance'
                        ServiceType    = 'DatabaseEngine'
                        ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'NT SERVICE\MSSQLSERVER', (New-Object -TypeName System.Security.SecureString))
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                }

                # Ensure mocks are properly used
                Should -Invoke -CommandName Get-TargetResource -Scope It -Exactly -Times 1
            }
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When using default instance' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName         = 'TestServer'
                        InstanceName       = 'MSSQLSERVER'
                        ServiceType        = 'SqlServer'
                        ServiceAccountName = 'NT SERVICE\MSSQLSERVER'
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        ServerName     = 'TestServer'
                        InstanceName   = 'MSSQLSERVER'
                        ServiceType    = 'DatabaseEngine'
                        ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'NT SERVICE\MSSQLSERVER', (New-Object -TypeName System.Security.SecureString))
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }

                # Ensure mocks are properly used
                Should -Invoke -CommandName Get-TargetResource -Scope It -Exactly -Times 1
            }

            Context 'When the parameter Force is specified for default instance' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName         = 'TestServer'
                            InstanceName       = 'MSSQLSERVER'
                            ServiceType        = 'SqlServer'
                            ServiceAccountName = 'MyAccount'
                        }
                    }
                }

                It 'Should always return $false when Force is specified' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetResourceParameters = @{
                            ServerName     = 'TestServer'
                            InstanceName   = 'MSSQLSERVER'
                            ServiceType    = 'DatabaseEngine'
                            ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'CONTOSO\sql.service', (New-Object -TypeName System.Security.SecureString))
                            Force          = $true
                        }

                        Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                    }
                }
            }
        }

        Context 'When using a named instance' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        ServerName         = 'TestServer'
                        InstanceName       = 'TestInstance'
                        ServiceType        = 'SqlServer'
                        ServiceAccountName = 'CONTOSO\sql.service'
                    }
                }
            }

            It 'Should return true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testTargetResourceParameters = @{
                        ServerName     = 'TestServer'
                        InstanceName   = 'TestInstance'
                        ServiceType    = 'DatabaseEngine'
                        ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'CONTOSO\sql.service', (New-Object -TypeName System.Security.SecureString))
                    }

                    Test-TargetResource @testTargetResourceParameters | Should -BeTrue
                }

                # Ensure mocks are properly used
                Should -Invoke -CommandName Get-TargetResource -Scope It -Exactly -Times 1
            }

            Context 'When the parameter Force is specified for named instance' {
                BeforeAll {
                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            ServerName         = 'TestServer'
                            InstanceName       = 'TestInstance'
                            ServiceType        = 'SqlServer'
                            ServiceAccountName = 'CONTOSO\sql.service'
                        }
                    }
                }

                It 'Should return false' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $testTargetResourceParameters = @{
                            ServerName     = 'TestServer'
                            InstanceName   =  'TestInstance'
                            ServiceType    = 'DatabaseEngine'
                            ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'CONTOSO\sql.service', (New-Object -TypeName System.Security.SecureString))
                            Force          = $true
                        }

                        # Validate the return  value
                        Test-TargetResource @testTargetResourceParameters | Should -BeFalse
                    }
                }
            }
        }
    }
}

Describe 'SqlServerServiceAccount\Set-TargetResource' -Tag 'Set' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Stores the result of SetServiceAccount calls
            $script:testServiceAccountUpdated = @{
                Processed      = $false
                NewUserAccount = [System.String]::Empty
                NewPassword    = [System.String]::Empty
            }
        }
    }

    Context 'When changing the service account for the default instance' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:defaultSetTargetResourceParameters = @{
                    ServerName     = 'TestServer'
                    InstanceName   = 'MSSQLSERVER'
                    ServiceType    = 'DatabaseEngine'
                    ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'NT SERVICE\MSSQLSERVER', (New-Object -TypeName System.Security.SecureString))
                }
            }

            Mock -CommandName Get-ServiceObject -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name           = $MockInstanceName
                    ServiceAccount = 'NT SERVICE\MSSQLSERVER'
                    Type           = 'SqlServer'
                } | Add-Member -Name 'SetServiceAccount' -MemberType 'ScriptMethod' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $User,

                        [Parameter()]
                        [System.String]
                        $Password
                    )

                    $_.User = $User
                    $_.Password = $Password

                    # Update the object
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $testServiceAccountUpdated.Processed = $true
                        $testServiceAccountUpdated.NewUserAccount = $User
                        $testServiceAccountUpdated.NewPassword = $Password
                    }
                } -PassThru -Force
            } -ParameterFilter {
                $ServiceType -eq 'DatabaseEngine'
            }

            Mock -CommandName Get-ServiceObject -MockWith {
                return $null
            } -ParameterFilter {
                $ServiceType -eq 'SQLServerAgent'
            }

            Mock -CommandName Restart-SqlService
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                $testServiceAccountUpdated.Processed = $false
                $testServiceAccountUpdated.NewUserAccount = [System.String]::Empty
                $testServiceAccountUpdated.NewPassword = [System.String]::Empty
            }
        }

        It 'Should update the service account information' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                # Update the service information
                Set-TargetResource @setTargetResourceParameters

                # Validate that the correct information was passed through and updated
                $testServiceAccountUpdated.Processed | Should -BeTrue
                $testServiceAccountUpdated.NewUserAccount | Should -Be $setTargetResourceParameters.ServiceAccount.Username
                $testServiceAccountUpdated.NewPassword | Should -Be $setTargetResourceParameters.ServiceAccount.GetNetworkCredential().Password
            }

            # Ensure mocks are used properly
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Restart-SqlService -Scope It -Exactly -Times 0
        }

        It 'Should throw the correct exception when an invalid service name and type is provided' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                $setTargetResourceParameters.ServiceType = 'SQLServerAgent'

                # Get the localized error message
                $mockCorrectErrorMessage = $script:localizedData.ServiceNotFound -f $setTargetResourceParameters.ServiceType, $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName

                # Attempt to update the service account
                { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockCorrectErrorMessage)
            }

            # Ensure mocks are used properly
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Restart-SqlService -Scope It -Exactly -Times 0
        }

        It 'Should restart the service if requested' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                $setTargetResourceParameters += @{
                    RestartService = $true
                }

                Set-TargetResource @setTargetResourceParameters
            }

            # Ensure mocks are used properly
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Restart-SqlService -Scope It -Exactly -Times 1
        }
    }

    Context 'When changing the service account for the named instance' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:defaultSetTargetResourceParameters = @{
                    ServerName     = 'TestServer'
                    InstanceName   = 'TestInstance'
                    ServiceType    = 'DatabaseEngine'
                    ServiceAccount = (New-Object -TypeName System.Management.Automation.PSCredential 'NT SERVICE\TestInstance', (New-Object -TypeName System.Security.SecureString))
                }
            }

            Mock -CommandName Get-ServiceObject -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name           = $MockInstanceName
                    ServiceAccount = 'NT SERVICE\TestInstance'
                    Type           = 'SqlServer'
                } | Add-Member -Name 'SetServiceAccount' -MemberType 'ScriptMethod' -Value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $User,

                        [Parameter()]
                        [System.String]
                        $Password
                    )

                    $_.User = $User
                    $_.Password = $Password

                    # Update the object
                    InModuleScope -Parameters $_ -ScriptBlock {
                        $testServiceAccountUpdated.Processed = $true
                        $testServiceAccountUpdated.NewUserAccount = $User
                        $testServiceAccountUpdated.NewPassword = $Password
                    }
                } -PassThru -Force
            } -ParameterFilter {
                $ServiceType -eq 'DatabaseEngine'
            }

            Mock -CommandName Get-ServiceObject -MockWith {
                return $null
            } -ParameterFilter {
                $ServiceType -eq 'SQLServerAgent'
            }

            Mock -CommandName Restart-SqlService
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                $testServiceAccountUpdated.Processed = $false
                $testServiceAccountUpdated.NewUserAccount = [System.String]::Empty
                $testServiceAccountUpdated.NewPassword = [System.String]::Empty
            }
        }

        It 'Should update the service account information' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                # Update the service information
                Set-TargetResource @setTargetResourceParameters

                # Validate that the correct information was passed through and updated
                $testServiceAccountUpdated.Processed | Should -BeTrue
                $testServiceAccountUpdated.NewUserAccount | Should -Be $setTargetResourceParameters.ServiceAccount.Username
                $testServiceAccountUpdated.NewPassword | Should -Be $setTargetResourceParameters.ServiceAccount.GetNetworkCredential().Password
            }

            # Ensure mocks are used properly
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Restart-SqlService -Scope It -Exactly -Times 0
        }

        It 'Should throw the correct exception when an invalid service name and type is provided' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                $setTargetResourceParameters.ServiceType = 'SQLServerAgent'

                # Get the localized error message
                $mockCorrectErrorMessage = $script:localizedData.ServiceNotFound -f $setTargetResourceParameters.ServiceType, $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName

                # Attempt to update the service account
                { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockCorrectErrorMessage)
            }

            # Ensure mocks are used properly
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Restart-SqlService -Scope It -Exactly -Times 0
        }

        It 'Should restart the service if requested' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()
                $setTargetResourceParameters += @{
                    RestartService = $true
                }

                Set-TargetResource @setTargetResourceParameters
            }

            # Ensure mocks are used properly
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
            Should -Invoke -CommandName Restart-SqlService -Scope It -Exactly -Times 1
        }
    }

    Context 'When SetServiceAccount() method call fails' {
        BeforeEach {
            Mock -CommandName Get-ServiceObject -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name           = 'MSSQLSERVER'
                    ServiceAccount = 'NT SERVICE\MSSQLSERVER'
                    Type           = 'SqlServer'
                } | Add-Member -Name 'SetServiceAccount' -MemberType 'ScriptMethod' -Value {
                    throw (New-Object -TypeName Microsoft.SqlServer.Management.Smo.FailedOperationException 'Mock SetServiceAccount')
                } -PassThru -Force
            }
        }

        It 'Should throw the correct exception' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $setTargetResourceParameters = $defaultSetTargetResourceParameters.Clone()

                # Get the localized error message
                $mockCorrectErrorMessage = $script:localizedData.SetServiceAccountFailed -f $setTargetResourceParameters.ServerName, $setTargetResourceParameters.InstanceName, ''

                # Attempt to update the service account
                { Set-TargetResource @setTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $mockCorrectErrorMessage + '*Mock SetServiceAccount*')
            }

            # Ensure mocks are used properly
            Should -Invoke -CommandName Get-ServiceObject -Scope It -Exactly -Times 1
        }
    }
}

Describe 'SqlServerServiceAccount\ConvertTo-ManagedServiceType' -Tag 'Helper' {
    Context 'When translating to managed service types' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    MockServiceType  = 'DatabaseEngine'
                    MockExpectedType = 'SqlServer'
                }

                @{
                    MockServiceType  = 'SQLServerAgent'
                    MockExpectedType = 'SqlAgent'
                }

                @{
                    MockServiceType  = 'Search'
                    MockExpectedType = 'Search'
                }

                @{
                    MockServiceType  = 'IntegrationServices'
                    MockExpectedType = 'SqlServerIntegrationService'
                }

                @{
                    MockServiceType  = 'AnalysisServices'
                    MockExpectedType = 'AnalysisServer'
                }

                @{
                    MockServiceType  = 'ReportingServices'
                    MockExpectedType = 'ReportServer'
                }

                @{
                    MockServiceType  = 'SQLServerBrowser'
                    MockExpectedType = 'SqlBrowser'
                }

                @{
                    MockServiceType  = 'NotificationServices'
                    MockExpectedType = 'NotificationServer'
                }
            )
        }

        It 'Should properly map ''<MockServiceType>'' to managed service type ''<MockExpectedType>''' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                # Get the ManagedServiceType
                $managedServiceType = ConvertTo-ManagedServiceType -ServiceType $MockServiceType

                $managedServiceType | Should -BeOfType Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType
                $managedServiceType | Should -Be $MockExpectedType
            }
        }
    }
}

Describe 'SqlServerServiceAccount\ConvertTo-ResourceServiceType' -Tag 'Helper' {
    Context 'When translating to resource service types' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    MockServiceType  = 'SqlServer'
                    MockExpectedType = 'DatabaseEngine'
                }

                @{
                    MockServiceType  = 'SqlAgent'
                    MockExpectedType = 'SQLServerAgent'
                }

                @{
                    MockServiceType  = 'Search'
                    MockExpectedType = 'Search'
                }

                @{
                    MockServiceType  = 'SqlServerIntegrationService'
                    MockExpectedType = 'IntegrationServices'
                }

                @{
                    MockServiceType  = 'AnalysisServer'
                    MockExpectedType = 'AnalysisServices'
                }

                @{
                    MockServiceType  = 'ReportServer'
                    MockExpectedType = 'ReportingServices'
                }

                @{
                    MockServiceType  = 'SqlBrowser'
                    MockExpectedType = 'SQLServerBrowser'
                }

                @{
                    MockServiceType  = 'NotificationServer'
                    MockExpectedType = 'NotificationServices'
                }

                @{
                    MockServiceType  = 'UnknownTypeShouldReturnTheSame'
                    MockExpectedType = 'UnknownTypeShouldReturnTheSame'
                }
            )
        }

        It 'Should properly map ''<MockServiceType>'' to resource type ''<MockExpectedType>''' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                # Get the ManagedServiceType
                $managedServiceType = ConvertTo-ResourceServiceType -ServiceType $MockServiceType

                $managedServiceType | Should -BeOfType [System.String]
                $managedServiceType | Should -Be $MockExpectedType
            }
        }
    }
}

Describe 'SqlServerServiceAccount\Get-SqlServiceName' -Tag 'Helper' {
    BeforeAll {
        # Hashtable mirroring HKLM:\Software\Microsoft\Microsoft SQL Server\Services
        $testServicesRegistryTable = @{
            'Analysis Server' = @{
                LName = 'MSOLAP$'
                Name = 'MSSQLServerOLAPService'
                Type = 5
            }

            'Full Text' = @{
                LName = 'msftesql$'
                Name = 'msftesql'
                Type = 3
            }

            'Full-text Filter Daemon Launcher' = @{
                LName = 'MSSQLFDLauncher$'
                Name = 'MSSQLFDLauncher'
                Type = 9
            }

            'Launchpad Service' = @{
                LName = 'MSSQLLaunchpad$'
                Name = 'MSSQLLaunchpad'
                Type = 12
            }

            'Notification Services' = @{
                LName = 'NS$'
                Name = 'NsService'
                Type = 8
            }

            'Report Server' = @{
                LName = 'ReportServer$'
                Name = 'ReportServer'
                Type = 6
            }

            'ReportServer' = @{
                LName = 'ReportServer$'
                Name = 'ReportServer'
                Type = 6
            }

            'SQL Agent' = @{
                LName = 'SQLAGENT$'
                Name = 'SQLSERVERAGENT'
                Type = 2
            }

            'SQL Browser' = @{
                LName = ''
                Name = 'SQLBrowser'
                Type = 7
            }

            'SQL Server' = @{
                LName = 'MSSQL$'
                Name = 'MSSQLSERVER'
                Type = 1
            }

            'SQL Server Polybase Data Movement Service' = @{
                LName = 'SQLPBDMS$'
                Name = 'SQLPBDMS'
                Type = 11
            }

            'SQL Server Polybase Engine' = @{
                LName = 'SQLPBENGINE$'
                Name = 'SQLPBENGINE'
                Type = 10
            }

            'SSIS Server' = @{
                LName = ''
                Name = 'MsDtsServer'
                Type = 4
            }
        }
    }

    Context 'When getting the service name for a default instance' {
        BeforeDiscovery {
            # Define cases for the various parameters to test
            $testCases = @(
                @{
                    MockServiceType = 'DatabaseEngine'
                    MockExpectedServiceName = 'MSSQLSERVER'
                },
                @{
                    MockServiceType = 'SQLServerAgent'
                    MockExpectedServiceName = 'SQLSERVERAGENT'
                },
                @{
                    MockServiceType = 'Search'
                    MockExpectedServiceName = 'msftesql'
                },
                @{
                    MockServiceType = 'IntegrationServices'
                    MockExpectedServiceName = 'MsDtsServer'
                },
                @{
                    MockServiceType = 'AnalysisServices'
                    MockExpectedServiceName = 'MSSQLServerOLAPService'
                },
                @{
                    MockServiceType = 'ReportingServices'
                    MockExpectedServiceName = 'ReportServer'
                },
                @{
                    MockServiceType = 'SQLServerBrowser'
                    MockExpectedServiceName = 'SQLBrowser'
                },
                @{
                    MockServiceType = 'NotificationServices'
                    MockExpectedServiceName = 'NsService'
                }
            )
        }

        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                return @(
                    foreach ($serviceType in $testServicesRegistryTable.Keys)
                    {
                        New-Object -TypeName PSObject -Property @{
                            MockKeyName = $serviceType
                            MockName = $testServicesRegistryTable.$serviceType.Name
                            MockLName = $testServicesRegistryTable.$serviceType.LName
                            MockType = $testServicesRegistryTable.$serviceType.Type
                        } | Add-Member -MemberType ScriptMethod -Name 'GetValue' -Value {
                            param
                            (
                                [Parameter()]
                                [System.String]
                                $Property
                            )

                            $propertyToReturn = "Mock$($Property)"
                            return $this.$propertyToReturn
                        } -PassThru
                    }
                )
            }
        }

        It 'Should return the correct service name for <MockServiceType>' -ForEach $testCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                # Get the service name
                Get-SqlServiceName -InstanceName 'MSSQLSERVER' -ServiceType $MockServiceType | Should -Be $MockExpectedServiceName
            }

            # Ensure the mock is utilized
            Should -Invoke -CommandName Get-ChildItem -ParameterFilter {
                # Registry key used to index service type mappings
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services'
            } -Scope It -Exactly -Times 1
        }
    }

    Context 'When getting the service name for a named instance' {
        BeforeDiscovery {
            # Define cases for the various parameters to test
            $instanceAwareTestCases = @(
                @{
                    MockServiceType = 'DatabaseEngine'
                    MockExpectedServiceName = 'MSSQL$TestInstance'
                },
                @{
                    MockServiceType = 'SQLServerAgent'
                    MockExpectedServiceName = 'SQLAGENT$TestInstance'
                },
                @{
                    MockServiceType = 'Search'
                    MockExpectedServiceName = 'MSFTESQL$TestInstance'
                },
                @{
                    MockServiceType = 'AnalysisServices'
                    MockExpectedServiceName = 'MSOLAP$TestInstance'
                },
                @{
                    MockServiceType = 'ReportingServices'
                    MockExpectedServiceName = 'ReportServer$TestInstance'
                },
                @{
                    MockServiceType = 'NotificationServices'
                    MockExpectedServiceName = 'NS$TestInstance'
                }
            )

            $notInstanceAwareTestCases = @(
                @{
                    MockServiceType = 'IntegrationServices'
                },
                @{
                    MockServiceType = 'SQLServerBrowser'
                }
            )
        }

        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                return @(
                    foreach ($serviceType in $testServicesRegistryTable.Keys)
                    {
                        New-Object -TypeName PSObject -Property @{
                            MockKeyName = $serviceType
                            MockName = $testServicesRegistryTable.$serviceType.Name
                            MockLName = $testServicesRegistryTable.$serviceType.LName
                            MockType = $testServicesRegistryTable.$serviceType.Type
                        } | Add-Member -MemberType ScriptMethod -Name 'GetValue' -Value {
                            param
                            (
                                [Parameter()]
                                [System.String]
                                $Property
                            )

                            $propertyToReturn = "Mock$($Property)"
                            return $this.$propertyToReturn
                        } -PassThru
                    }
                )
            }
        }

        It 'Should return the correct service name for <MockServiceType>' -ForEach $instanceAwareTestCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                # Get the service name
                Get-SqlServiceName -InstanceName 'TestInstance' -ServiceType $MockServiceType | Should -Be $MockExpectedServiceName
            }

            # Ensure the mock is utilized
            Should -Invoke -CommandName Get-ChildItem -ParameterFilter {
                # Registry key used to index service type mappings
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services'
            } -Scope It -Exactly -Times 1
        }

        It 'Should throw an error for <MockServiceType> which is not instance-aware' -ForEach $notInstanceAwareTestCases {
            InModuleScope -Parameters $_ -ScriptBlock {
                Set-StrictMode -Version 1.0

                # Get the localized error message
                $mockErrorMessage = $script:localizedData.NotInstanceAware -f $MockServiceType

                # An exception should be raised
                { Get-SqlServiceName -InstanceName 'TestInstance' -ServiceType $MockServiceType } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }

    Context 'When getting the service name for a type that is not defined' {
        BeforeAll {
            Mock -CommandName Get-ChildItem -MockWith {
                return @()
            } -ParameterFilter {
                # Registry key used to index service type mappings
                $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Services'
            }
        }

        It 'Should throw an exception if the service name cannot be derived' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = '{0} (Parameter ''ServiceType'')' -f ($script:localizedData.UnknownServiceType -f 'DatabaseEngine')

                { Get-SqlServiceName -InstanceName 'TestInstance' -ServiceType DatabaseEngine } | Should -Throw -ExpectedMessage $mockErrorMessage
            }

            # Ensure the mock was called
            Should -Invoke -CommandName Get-ChildItem -Times 1 -Exactly -Scope It
        }
    }
}

Describe 'SqlServerServiceAccount\Get-ServiceObject' -Tag 'Helper' {
    BeforeAll {
        Mock -CommandName Import-SqlDscPreferredModule

        InModuleScope -ScriptBlock {
            $script:mockDefaultGetServiceObjectParameters = @{
                ServerName   = 'TestServer'
                InstanceName = ''
                ServiceType  = 'DatabaseEngine'
            }
        }
    }

    Context 'When getting the service information for a default instance' {
        BeforeAll {
            Mock -CommandName New-Object -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name     = 'TestServer'
                    Services = @(
                        New-Object -TypeName PSObject -Property @{
                            Name           = 'MSSQLSERVER'
                            ServiceAccount = 'NT SERVICE\MSSQLSERVER'
                            Type           = 'SqlServer'
                        }
                    )
                }
            } -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
            }

            Mock -CommandName Get-SqlServiceName -MockWith {
                return 'MSSQLServer'
            }
        }

        It 'Should have the correct Type for the service' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetServiceObjectParameters = $mockDefaultGetServiceObjectParameters.Clone()
                $mockGetServiceObjectParameters.InstanceName = 'MSSQLSERVER'

                $serviceObject = Get-ServiceObject @mockGetServiceObjectParameters

                $serviceObject.Type | Should -Be 'SqlServer'
            }

            # Ensure mocks are properly used
            Should -Invoke -CommandName Import-SqlDscPreferredModule -Scope It -Exactly -Times 1
            Should -Invoke -CommandName New-Object -Scope It -Exactly -Times 1
        }
    }

    Context 'When getting the service information for a named instance' {
        BeforeAll {
            Mock -CommandName New-Object -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name     = 'TestServer'
                    Services = @(
                        New-Object -TypeName PSObject -Property @{
                            Name           = 'MSSQL$TestInstance'
                            ServiceAccount = 'CONTOSO\sql.service'
                            Type           = 'SqlServer'
                        }
                    )
                }

                $managedComputerObject.Services | ForEach-Object -Process {
                    $_ | Add-Member @mockAddMemberParameters_SetServiceAccount
                }

                return $managedComputerObject
            } -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
            }

            Mock -CommandName Get-SqlServiceName -MockWith {
                return ('MSSQL${0}' -f  'TestInstance')
            }
        }

        It 'Should have the correct Type for the service' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetServiceObjectParameters = $mockDefaultGetServiceObjectParameters.Clone()
                $mockGetServiceObjectParameters.InstanceName =  'TestInstance'

                $serviceObject = Get-ServiceObject @mockGetServiceObjectParameters

                $serviceObject.Type | Should -Be 'SqlServer'
            }

            # Ensure mocks are properly used
            Should -Invoke -CommandName Import-SqlDscPreferredModule -Scope It -Exactly -Times 1
            Should -Invoke -CommandName New-Object -Scope It -Exactly -Times 1
        }
    }

    Context 'When getting service IntegrationServices' {
        BeforeAll {
            Mock -CommandName New-Object -MockWith {
                return New-Object -TypeName PSObject -Property @{
                    Name     = 'TestServer'
                    Services = @(
                        New-Object -TypeName PSObject -Property @{
                            Name           = 'MsDtsServer120'
                            ServiceAccount = 'NT SERVICE\INSTANCE'
                            Type           = 'IntegrationServices'
                        }
                        New-Object -TypeName PSObject -Property @{
                            Name           = 'MsDtsServer130'
                            ServiceAccount = 'NT SERVICE\MSSQLSERVER'
                            Type           = 'IntegrationServices'
                        }

                    )
                }
            } -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
            }

            Mock -CommandName Get-SqlServiceName -MockWith {
                return 'MsDtsServer'
            }

            Mock -CommandName New-Object -MockWith {
                return @{
                    Services = @{
                        Name = 'MsDtsServer130'
                    }
                }
            }
        }

        It 'Should throw an exception when VersionNumber is not specified' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetServiceObjectParameters = $mockDefaultGetServiceObjectParameters.Clone()
                $mockGetServiceObjectParameters.ServiceType = 'IntegrationServices'
                $mockGetServiceObjectParameters.InstanceName = 'MSSQLSERVER'

                $testErrorMessage = '{0} (Parameter ''VersionNumber'')' -f ($script:localizedData.MissingParameter -f 'IntegrationServices')

                { Get-ServiceObject @mockGetServiceObjectParameters } | Should -Throw $testErrorMessage
            }
        }

        It 'Should return service when VersionNumber is specified' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockGetServiceObjectParameters = $mockDefaultGetServiceObjectParameters.Clone()
                $mockGetServiceObjectParameters.ServiceType = 'IntegrationServices'
                $mockGetServiceObjectParameters.InstanceName = 'MSSQLSERVER'
                $mockGetServiceObjectParameters.VersionNumber = '130'

                $mockGetServiceObject = Get-ServiceObject @mockGetServiceObjectParameters

                $mockGetServiceObject | Should -HaveCount 1
                $mockGetServiceObject.Type | Should -Be 'IntegrationServices'
                $mockGetServiceObject.ServiceAccount | Should -Be 'NT SERVICE\MSSQLSERVER'
                $mockGetServiceObject.Name | Should -Be 'MsDtsServer130'
            }
        }
    }
}
