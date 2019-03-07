<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlRSSetup DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlRSSetup'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
        $mockInstanceName = 'SSRS'

        # Default parameters that are used for the It-blocks.
        $mockDefaultParameters = @{
            InstanceName       = $mockInstanceName
            IAcceptLicensTerms = 'Yes'
            SourcePath         = 'TestDrive:\'
        }

        Describe "MSFT_SqlRSSetup\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                $getTargetResourceParameters = $mockDefaultParameters.Clone()
            }

            Context 'When the system is in the desired state' {
                Context 'When there are no installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-ItemProperty
                    }

                    It 'Should return $null as the InstanceName' {
                        $result = Get-TargetResource @getTargetResourceParameters
                        $result.InstanceName | Should -BeNullOrEmpty

                        Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @getTargetResourceParameters
                        $result.IAcceptLicensTerms | Should -Be $getTargetResourceParameters.IAcceptLicensTerms
                        $result.SourcePath | Should -Be $getTargetResourceParameters.SourcePath

                        Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
                    }

                    It 'Should return $null or $false for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Action | Should -BeNullOrEmpty
                        $getTargetResourceResult.SourceCredential | Should -BeNullOrEmpty
                        $getTargetResourceResult.ProductKey | Should -BeNullOrEmpty
                        $getTargetResourceResult.ForceReboot | Should -BeFalse
                        $getTargetResourceResult.EditionUpgrade | Should -BeFalse
                        $getTargetResourceResult.Edition | Should -BeNullOrEmpty
                        $getTargetResourceResult.LogPath | Should -BeNullOrEmpty
                        $getTargetResourceResult.InstallFolder | Should -BeNullOrEmpty
                        $getTargetResourceResult.ErrorDumpDirectory | Should -BeNullOrEmpty
                        $getTargetResourceResult.CurrentVersion | Should -BeNullOrEmpty
                        $getTargetResourceResult.ServiceName | Should -BeNullOrEmpty

                        Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When there is an installed Reporting Services' {
                    BeforeAll {
                        $mockGetItemProperty_InstanceName = {
                            <#
                                Currently only the one instance name of 'SSRS' is supported, and
                                the same name is currently used for instance id.
                            #>
                            return @{
                                $mockInstanceName = $mockInstanceName
                            }
                        }

                        $mockGetItemProperty_InstanceName_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' `
                            -and $Name -eq $mockInstanceName
                        }

                        $mockGetItemPropertyValue_InstallRootDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                        $mockGetItemProperty_InstallRootDirectory = {
                            return @{
                                InstallRootDirectory = $mockGetItemPropertyValue_InstallRootDirectory
                            }
                        }

                        $mockGetItemProperty_InstallRootDirectory_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' `
                            -and $Name -eq 'InstallRootDirectory'
                        }

                        $mockGetItemPropertyValue_ServiceName = 'SQLServerReportingServices'
                        $mockGetItemProperty_ServiceName = {
                            return @{
                                ServiceName = $mockGetItemPropertyValue_ServiceName
                            }
                        }

                        $mockGetItemProperty_ServiceName_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' `
                            -and $Name -eq 'ServiceName'
                        }

                        $mockGetItemPropertyValue_ErrorDumpDir = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
                        $mockGetItemProperty_ErrorDumpDir = {
                            return @{
                                ErrorDumpDir = $mockGetItemPropertyValue_ErrorDumpDir
                            }
                        }

                        $mockGetItemProperty_ErrorDumpDir_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' `
                            -and $Name -eq 'ErrorDumpDir'
                        }

                        $mockGetItemPropertyValue_CurrentVersion = '14.0.600.1109'
                        $mockGetItemProperty_CurrentVersion = {
                            return @{
                                CurrentVersion = $mockGetItemPropertyValue_CurrentVersion
                            }
                        }

                        $mockGetItemProperty_CurrentVersion_ParameterFilter = {
                            $Path -eq ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\MSSQLServer\CurrentVersion' -f $mockInstanceName) `
                            -and $Name -eq 'CurrentVersion'
                        }

                        Mock -CommandName Get-ItemProperty `
                            -MockWith $mockGetItemProperty_InstanceName `
                            -ParameterFilter $mockGetItemProperty_InstanceName_ParameterFilter

                        Mock -CommandName Get-ItemProperty `
                            -MockWith $mockGetItemProperty_InstallRootDirectory `
                            -ParameterFilter $mockGetItemProperty_InstallRootDirectory_ParameterFilter

                        Mock -CommandName Get-ItemProperty `
                            -MockWith $mockGetItemProperty_ServiceName `
                            -ParameterFilter $mockGetItemProperty_ServiceName_ParameterFilter

                        Mock -CommandName Get-ItemProperty `
                            -MockWith $mockGetItemProperty_ErrorDumpDir `
                            -ParameterFilter $mockGetItemProperty_ErrorDumpDir_ParameterFilter

                        Mock -CommandName Get-ItemProperty `
                            -MockWith $mockGetItemProperty_CurrentVersion `
                            -ParameterFilter $mockGetItemProperty_CurrentVersion_ParameterFilter
                    }

                    It 'Should return the correct InstanceName' {
                        $result = Get-TargetResource @getTargetResourceParameters
                        $result.InstanceName | Should -Be $getTargetResourceParameters.InstanceName

                        Assert-MockCalled Get-ItemProperty `
                            -ParameterFilter $mockGetItemProperty_InstanceName_ParameterFilter `
                            -Exactly -Times 1 -Scope It
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @getTargetResourceParameters
                        $result.IAcceptLicensTerms | Should -Be $getTargetResourceParameters.IAcceptLicensTerms
                        $result.SourcePath | Should -Be $getTargetResourceParameters.SourcePath
                   }

                    It 'Should return the correct values for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @getTargetResourceParameters
                        $getTargetResourceResult.Action | Should -BeNullOrEmpty
                        $getTargetResourceResult.SourceCredential | Should -BeNullOrEmpty
                        $getTargetResourceResult.ProductKey | Should -BeNullOrEmpty
                        $getTargetResourceResult.ForceReboot | Should -BeFalse
                        $getTargetResourceResult.EditionUpgrade | Should -BeFalse
                        $getTargetResourceResult.Edition | Should -BeNullOrEmpty
                        $getTargetResourceResult.LogPath | Should -BeNullOrEmpty
                        $getTargetResourceResult.InstallFolder | Should -Be $mockGetItemPropertyValue_InstallRootDirectory
                        $getTargetResourceResult.ErrorDumpDirectory | Should -Be $mockGetItemPropertyValue_ErrorDumpDir
                        $getTargetResourceResult.CurrentVersion | Should -Be $mockGetItemPropertyValue_CurrentVersion
                        $getTargetResourceResult.ServiceName | Should -Be $mockGetItemPropertyValue_ServiceName

                        Assert-MockCalled Get-ItemProperty `
                            -ParameterFilter $mockGetItemProperty_InstallRootDirectory_ParameterFilter `
                            -Exactly -Times 1 -Scope It

                        Assert-MockCalled Get-ItemProperty `
                            -ParameterFilter $mockGetItemProperty_ServiceName_ParameterFilter `
                            -Exactly -Times 1 -Scope It

                        Assert-MockCalled Get-ItemProperty `
                            -ParameterFilter $mockGetItemProperty_ErrorDumpDir_ParameterFilter `
                            -Exactly -Times 1 -Scope It

                        Assert-MockCalled Get-ItemProperty `
                            -ParameterFilter $mockGetItemProperty_CurrentVersion_ParameterFilter `
                            -Exactly -Times 1 -Scope It
                    }
                }
            }

            Assert-VerifiableMock
        }

        # Describe "MSFT_SqlServerDatabaseMail\Test-TargetResource" -Tag 'Test' {
        #     BeforeAll {
        #         $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
        #         $mockDynamicLoggingLevelValue = $mockLoggingLevelExtendedValue
        #         $mockDynamicDescription = $mockDescription
        #         $mockDynamicAgentMailType = $mockAgentMailTypeDatabaseMail
        #         $mockDynamicDatabaseMailProfile = $mockProfileName
        #     }

        #     BeforeEach {
        #         Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

        #         $testTargetResourceParameters = $mockDefaultParameters.Clone()
        #     }

        #     Context 'When the system is in the desired state' {
        #         Context 'When the configuration is absent' {
        #             BeforeEach {
        #                 $testTargetResourceParameters['Ensure'] = 'Absent'
        #                 $testTargetResourceParameters['AccountName'] = $mockMissingAccountName
        #             }

        #             It 'Should return the state as $true' {
        #                 $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
        #                 $testTargetResourceResult | Should -Be $true

        #                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #             }
        #         }

        #         Context 'When the configuration is present' {
        #             BeforeEach {
        #                 $testTargetResourceParameters['DisplayName'] = $mockDisplayName
        #                 $testTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
        #                 $testTargetResourceParameters['Description'] = $mockDescription
        #                 $testTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
        #                 $testTargetResourceParameters['TcpPort'] = $mockTcpPort
        #             }

        #             It 'Should return the state as $true' {
        #                 $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
        #                 $testTargetResourceResult | Should -Be $true

        #                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #             }
        #         }
        #     }

        #     Context 'When the system is not in the desired state' {
        #         Context 'When the configuration should be absent' {
        #             BeforeEach {
        #                 $testTargetResourceParameters['Ensure'] = 'Absent'
        #             }

        #             It 'Should return the state as $false' {
        #                 $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
        #                 $testTargetResourceResult | Should -Be $false

        #                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #             }
        #         }

        #         Context 'When the configuration should be present' {
        #             $defaultTestCase = @{
        #                 AccountName    = $mockAccountName
        #                 EmailAddress   = $mockEmailAddress
        #                 MailServerName = $mockMailServerName
        #                 ProfileName    = $mockProfileName
        #                 DisplayName    = $mockDisplayName
        #                 ReplyToAddress = $mockReplyToAddress
        #                 Description    = $mockDescription
        #                 LoggingLevel   = $mockLoggingLevelExtended
        #                 TcpPort        = $mockTcpPort
        #             }

        #             $testCaseAccountNameIsMissing = $defaultTestCase.Clone()
        #             $testCaseAccountNameIsMissing['TestName'] = 'AccountName is missing'
        #             $testCaseAccountNameIsMissing['AccountName'] = 'MissingAccountName'

        #             $testCaseEmailAddressIsWrong = $defaultTestCase.Clone()
        #             $testCaseEmailAddressIsWrong['TestName'] = 'EmailAddress is wrong'
        #             $testCaseEmailAddressIsWrong['EmailAddress'] = 'wrong@email.address'

        #             $testCaseMailServerNameIsWrong = $defaultTestCase.Clone()
        #             $testCaseMailServerNameIsWrong['TestName'] = 'MailServerName is wrong'
        #             $testCaseMailServerNameIsWrong['MailServerName'] = 'smtp.contoso.com'

        #             $testCaseProfileNameIsWrong = $defaultTestCase.Clone()
        #             $testCaseProfileNameIsWrong['TestName'] = 'ProfileName is wrong'
        #             $testCaseProfileNameIsWrong['ProfileName'] = 'NewProfile'

        #             $testCaseDisplayNameIsWrong = $defaultTestCase.Clone()
        #             $testCaseDisplayNameIsWrong['TestName'] = 'DisplayName is wrong'
        #             $testCaseDisplayNameIsWrong['DisplayName'] = 'New display name'

        #             $testCaseReplyToAddressIsWrong = $defaultTestCase.Clone()
        #             $testCaseReplyToAddressIsWrong['TestName'] = 'ReplyToAddress is wrong'
        #             $testCaseReplyToAddressIsWrong['ReplyToAddress'] = 'new-reply@email.address'

        #             $testCaseDescriptionIsWrong = $defaultTestCase.Clone()
        #             $testCaseDescriptionIsWrong['TestName'] = 'Description is wrong'
        #             $testCaseDescriptionIsWrong['Description'] = 'New description'

        #             $testCaseLoggingLevelIsWrong = $defaultTestCase.Clone()
        #             $testCaseLoggingLevelIsWrong['TestName'] = 'LoggingLevel is wrong'
        #             $testCaseLoggingLevelIsWrong['LoggingLevel'] = $mockLoggingLevelNormal

        #             $testCaseTcpPortIsWrong = $defaultTestCase.Clone()
        #             $testCaseTcpPortIsWrong['TestName'] = 'TcpPort is wrong'
        #             $testCaseTcpPortIsWrong['TcpPort'] = 2525

        #             $testCases = @(
        #                 $testCaseAccountNameIsMissing
        #                 $testCaseEmailAddressIsWrong
        #                 $testCaseMailServerNameIsWrong
        #                 $testCaseProfileNameIsWrong
        #                 $testCaseDisplayNameIsWrong
        #                 $testCaseReplyToAddressIsWrong
        #                 $testCaseDescriptionIsWrong
        #                 $testCaseLoggingLevelIsWrong
        #                 $testCaseTcpPortIsWrong
        #             )

        #             It 'Should return the state as $false when <TestName>' -TestCases $testCases {
        #                 param
        #                 (
        #                     $AccountName,
        #                     $EmailAddress,
        #                     $MailServerName,
        #                     $ProfileName,
        #                     $DisplayName,
        #                     $ReplyToAddress,
        #                     $Description,
        #                     $LoggingLevel,
        #                     $TcpPort
        #                 )

        #                 $testTargetResourceParameters['AccountName'] = $AccountName
        #                 $testTargetResourceParameters['EmailAddress'] = $EmailAddress
        #                 $testTargetResourceParameters['MailServerName'] = $MailServerName
        #                 $testTargetResourceParameters['ProfileName'] = $ProfileName
        #                 $testTargetResourceParameters['DisplayName'] = $DisplayName
        #                 $testTargetResourceParameters['ReplyToAddress'] = $ReplyToAddress
        #                 $testTargetResourceParameters['Description'] = $Description
        #                 $testTargetResourceParameters['LoggingLevel'] = $LoggingLevel
        #                 $testTargetResourceParameters['TcpPort'] = $TcpPort

        #                 $testTargetResourceResult = Test-TargetResource @testTargetResourceParameters
        #                 $testTargetResourceResult | Should -Be $false

        #                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #             }
        #         }
        #     }

        #     Assert-VerifiableMock
        # }

        # Describe "MSFT_SqlServerDatabaseMail\Set-TargetResource" -Tag 'Set' {
        #     BeforeAll {
        #         $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailEnabledConfigValue
        #         $mockDynamicLoggingLevelValue = $mockLoggingLevelExtendedValue
        #         $mockDynamicDescription = $mockDescription
        #         $mockDynamicAgentMailType = $mockAgentMailTypeDatabaseMail
        #         $mockDynamicDatabaseMailProfile = $mockProfileName
        #     }

        #     BeforeEach {
        #         Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
        #         Mock -CommandName New-Object -MockWith $mockNewObject_MailAccount -ParameterFilter {
        #             $TypeName -eq 'Microsoft.SqlServer.Management.SMO.Mail.MailAccount'
        #         } -Verifiable

        #         Mock -CommandName New-Object -MockWith $mockNewObject_MailProfile -ParameterFilter {
        #             $TypeName -eq 'Microsoft.SqlServer.Management.SMO.Mail.MailProfile'
        #         } -Verifiable

        #         $setTargetResourceParameters = $mockDefaultParameters.Clone()

        #         $script:MailAccountCreateMethodCallCount = 0
        #         $script:MailServerRenameMethodCallCount = 0
        #         $script:MailServerAlterMethodCallCount = 0
        #         $script:MailAccountAlterMethodCallCount = 0
        #         $script:MailProfileCreateMethodCallCount = 0
        #         $script:MailProfileAlterMethodCallCount = 0
        #         $script:MailProfileAddPrincipalMethodCallCount = 0
        #         $script:MailProfileAddAccountMethodCallCount = 0
        #         $script:JobServerAlterMethodCallCount = 0
        #         $script:LoggingLevelAlterMethodCallCount = 0
        #         $script:MailProfileDropMethodCallCount = 0
        #         $script:MailAccountDropMethodCallCount = 0

        #         $mockDynamicExpectedAccountName = $mockMissingAccountName
        #     }

        #     Context 'When the system is in the desired state' {
        #         Context 'When the configuration is absent' {
        #             BeforeEach {
        #                 $setTargetResourceParameters['Ensure'] = 'Absent'
        #                 $setTargetResourceParameters['AccountName'] = $mockMissingAccountName
        #                 $setTargetResourceParameters['ProfileName'] = 'MissingProfile'

        #                 $mockDynamicAgentMailType = $mockAgentMailTypeSqlAgentMail
        #                 $mockDynamicDatabaseMailProfile = $null
        #             }

        #             It 'Should call the correct methods without throwing' {
        #                 { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
        #                 $script:MailAccountCreateMethodCallCount | Should -Be 0
        #                 $script:MailServerRenameMethodCallCount | Should -Be 0
        #                 $script:MailServerAlterMethodCallCount | Should -Be 0
        #                 $script:MailAccountAlterMethodCallCount | Should -Be 0
        #                 $script:MailProfileCreateMethodCallCount | Should -Be 0
        #                 $script:MailProfileAlterMethodCallCount | Should -Be 0
        #                 $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
        #                 $script:MailProfileAddAccountMethodCallCount | Should -Be 0
        #                 $script:JobServerAlterMethodCallCount | Should -Be 0
        #                 $script:LoggingLevelAlterMethodCallCount | Should -Be 0
        #                 $script:MailProfileDropMethodCallCount | Should -Be 0
        #                 $script:MailAccountDropMethodCallCount | Should -Be 0

        #                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #             }
        #         }

        #         Context 'When the configuration is present' {
        #             BeforeEach {
        #                 $setTargetResourceParameters['DisplayName'] = $mockDisplayName
        #                 $setTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
        #                 $setTargetResourceParameters['Description'] = $mockDescription
        #                 $setTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
        #                 $setTargetResourceParameters['TcpPort'] = $mockTcpPort
        #             }

        #             It 'Should call the correct methods without throwing' {
        #                 { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
        #                 $script:MailAccountCreateMethodCallCount | Should -Be 0
        #                 $script:MailServerRenameMethodCallCount | Should -Be 0
        #                 $script:MailServerAlterMethodCallCount | Should -Be 0
        #                 $script:MailAccountAlterMethodCallCount | Should -Be 0
        #                 $script:MailProfileCreateMethodCallCount | Should -Be 0
        #                 $script:MailProfileAlterMethodCallCount | Should -Be 0
        #                 $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
        #                 $script:MailProfileAddAccountMethodCallCount | Should -Be 0
        #                 $script:JobServerAlterMethodCallCount | Should -Be 0
        #                 $script:LoggingLevelAlterMethodCallCount | Should -Be 0
        #                 $script:MailProfileDropMethodCallCount | Should -Be 0
        #                 $script:MailAccountDropMethodCallCount | Should -Be 0

        #                 Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #             }
        #         }
        #     }

        #     Context 'When the system is not in the desired state' {
        #         Context 'When the configuration should be absent' {
        #             BeforeEach {
        #                 $setTargetResourceParameters['Ensure'] = 'Absent'
        #             }

        #             It 'Should return the state as $false' {
        #                 { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
        #                 $script:JobServerAlterMethodCallCount | Should -Be 1
        #                 $script:MailProfileDropMethodCallCount | Should -Be 1
        #                 $script:MailAccountDropMethodCallCount | Should -Be 1
        #             }
        #         }

        #         Context 'When the configuration should be present' {
        #             Context 'When Database Mail XPs is enabled but fails evaluation' {
        #                 $mockDynamicDatabaseMailEnabledRunValue = $mockDatabaseMailDisabledConfigValue

        #                 It 'Should throw the correct error message' {
        #                     {
        #                         Set-TargetResource @setTargetResourceParameters
        #                     } | Should -Throw $script:localizedData.DatabaseMailDisabled

        #                     Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #                 }
        #             }

        #             Context 'When account name is missing' {
        #                 It 'Should call the correct methods without throwing' {
        #                     $setTargetResourceParameters['AccountName'] = $mockMissingAccountName
        #                     $setTargetResourceParameters['DisplayName'] = $mockDisplayName
        #                     $setTargetResourceParameters['ReplyToAddress'] = $mockReplyToAddress
        #                     $setTargetResourceParameters['Description'] = $mockDescription
        #                     $setTargetResourceParameters['LoggingLevel'] = $mockLoggingLevelExtended
        #                     $setTargetResourceParameters['TcpPort'] = $mockTcpPort

        #                     { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
        #                     $script:MailAccountCreateMethodCallCount | Should -Be 1
        #                     $script:MailServerRenameMethodCallCount | Should -Be 1
        #                     $script:MailServerAlterMethodCallCount | Should -Be 1
        #                     $script:MailAccountAlterMethodCallCount | Should -Be 0

        #                     Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #                 }
        #             }

        #             Context 'When properties are not in desired state' {
        #                 $defaultTestCase = @{
        #                     AccountName    = $mockAccountName
        #                     EmailAddress   = $mockEmailAddress
        #                     MailServerName = $mockMailServerName
        #                     ProfileName    = $mockProfileName
        #                     DisplayName    = $mockDisplayName
        #                     ReplyToAddress = $mockReplyToAddress
        #                     Description    = $mockDescription
        #                     LoggingLevel   = $mockLoggingLevelExtended
        #                     TcpPort        = $mockTcpPort
        #                 }

        #                 $testCaseEmailAddressIsWrong = $defaultTestCase.Clone()
        #                 $testCaseEmailAddressIsWrong['TestName'] = 'EmailAddress is wrong'
        #                 $testCaseEmailAddressIsWrong['EmailAddress'] = 'wrong@email.address'

        #                 $testCaseMailServerNameIsWrong = $defaultTestCase.Clone()
        #                 $testCaseMailServerNameIsWrong['TestName'] = 'MailServerName is wrong'
        #                 $testCaseMailServerNameIsWrong['MailServerName'] = 'smtp.contoso.com'

        #                 $testCaseProfileNameIsWrong = $defaultTestCase.Clone()
        #                 $testCaseProfileNameIsWrong['TestName'] = 'ProfileName is wrong'
        #                 $testCaseProfileNameIsWrong['ProfileName'] = 'NewProfile'

        #                 $testCaseDisplayNameIsWrong = $defaultTestCase.Clone()
        #                 $testCaseDisplayNameIsWrong['TestName'] = 'DisplayName is wrong'
        #                 $testCaseDisplayNameIsWrong['DisplayName'] = 'New display name'

        #                 $testCaseReplyToAddressIsWrong = $defaultTestCase.Clone()
        #                 $testCaseReplyToAddressIsWrong['TestName'] = 'ReplyToAddress is wrong'
        #                 $testCaseReplyToAddressIsWrong['ReplyToAddress'] = 'new-reply@email.address'

        #                 $testCaseDescriptionIsWrong = $defaultTestCase.Clone()
        #                 $testCaseDescriptionIsWrong['TestName'] = 'Description is wrong'
        #                 $testCaseDescriptionIsWrong['Description'] = 'New description'

        #                 $testCaseLoggingLevelIsWrong_Normal = $defaultTestCase.Clone()
        #                 $testCaseLoggingLevelIsWrong_Normal['TestName'] = 'LoggingLevel is wrong, should be ''Normal'''
        #                 $testCaseLoggingLevelIsWrong_Normal['LoggingLevel'] = $mockLoggingLevelNormal

        #                 $testCaseLoggingLevelIsWrong_Verbose = $defaultTestCase.Clone()
        #                 $testCaseLoggingLevelIsWrong_Verbose['TestName'] = 'LoggingLevel is wrong, should be ''Verbose'''
        #                 $testCaseLoggingLevelIsWrong_Verbose['LoggingLevel'] = $mockLoggingLevelVerbose

        #                 $testCaseTcpPortIsWrong = $defaultTestCase.Clone()
        #                 $testCaseTcpPortIsWrong['TestName'] = 'TcpPort is wrong'
        #                 $testCaseTcpPortIsWrong['TcpPort'] = 2525

        #                 $testCases = @(
        #                     $testCaseEmailAddressIsWrong
        #                     $testCaseMailServerNameIsWrong
        #                     $testCaseProfileNameIsWrong
        #                     $testCaseDisplayNameIsWrong
        #                     $testCaseReplyToAddressIsWrong
        #                     $testCaseDescriptionIsWrong
        #                     $testCaseLoggingLevelIsWrong_Normal
        #                     $testCaseLoggingLevelIsWrong_Verbose
        #                     $testCaseTcpPortIsWrong
        #                 )

        #                 It 'Should return the state as $false when <TestName>' -TestCases $testCases {
        #                     param
        #                     (
        #                         $TestName,
        #                         $AccountName,
        #                         $EmailAddress,
        #                         $MailServerName,
        #                         $ProfileName,
        #                         $DisplayName,
        #                         $ReplyToAddress,
        #                         $Description,
        #                         $LoggingLevel,
        #                         $TcpPort
        #                     )

        #                     $setTargetResourceParameters['AccountName'] = $AccountName
        #                     $setTargetResourceParameters['EmailAddress'] = $EmailAddress
        #                     $setTargetResourceParameters['MailServerName'] = $MailServerName
        #                     $setTargetResourceParameters['ProfileName'] = $ProfileName
        #                     $setTargetResourceParameters['DisplayName'] = $DisplayName
        #                     $setTargetResourceParameters['ReplyToAddress'] = $ReplyToAddress
        #                     $setTargetResourceParameters['Description'] = $Description
        #                     $setTargetResourceParameters['LoggingLevel'] = $LoggingLevel
        #                     $setTargetResourceParameters['TcpPort'] = $TcpPort

        #                     { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw

        #                     $script:MailAccountCreateMethodCallCount | Should -Be 0

        #                     if ($TestName -like '*MailServerName*')
        #                     {
        #                         $script:MailServerRenameMethodCallCount | Should -Be 1
        #                         $script:MailServerAlterMethodCallCount | Should -Be 1
        #                         $script:MailAccountAlterMethodCallCount | Should -Be 0
        #                         $script:MailProfileCreateMethodCallCount | Should -Be 0
        #                         $script:MailProfileAlterMethodCallCount | Should -Be 0
        #                         $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
        #                         $script:MailProfileAddAccountMethodCallCount | Should -Be 0
        #                         $script:JobServerAlterMethodCallCount | Should -Be 0
        #                         $script:LoggingLevelAlterMethodCallCount | Should -Be 0
        #                     }
        #                     elseif ($TestName -like '*TcpPort*')
        #                     {
        #                         $script:MailServerRenameMethodCallCount | Should -Be 0
        #                         $script:MailServerAlterMethodCallCount | Should -Be 1
        #                         $script:MailAccountAlterMethodCallCount | Should -Be 0
        #                         $script:MailProfileCreateMethodCallCount | Should -Be 0
        #                         $script:MailProfileAlterMethodCallCount | Should -Be 0
        #                         $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
        #                         $script:MailProfileAddAccountMethodCallCount | Should -Be 0
        #                         $script:JobServerAlterMethodCallCount | Should -Be 0
        #                         $script:LoggingLevelAlterMethodCallCount | Should -Be 0
        #                     }
        #                     elseif ($TestName -like '*ProfileName*')
        #                     {
        #                         $script:MailServerRenameMethodCallCount | Should -Be 0
        #                         $script:MailServerAlterMethodCallCount | Should -Be 0
        #                         $script:MailAccountAlterMethodCallCount | Should -Be 0
        #                         $script:MailProfileCreateMethodCallCount | Should -Be 1
        #                         $script:MailProfileAlterMethodCallCount | Should -Be 1
        #                         $script:MailProfileAddPrincipalMethodCallCount | Should -Be 1
        #                         $script:MailProfileAddAccountMethodCallCount | Should -Be 1
        #                         $script:JobServerAlterMethodCallCount | Should -Be 1
        #                         $script:LoggingLevelAlterMethodCallCount | Should -Be 0
        #                     }
        #                     elseif ($TestName -like '*LoggingLevel*')
        #                     {
        #                         $script:MailServerRenameMethodCallCount | Should -Be 0
        #                         $script:MailServerAlterMethodCallCount | Should -Be 0
        #                         $script:MailAccountAlterMethodCallCount | Should -Be 0
        #                         $script:MailProfileCreateMethodCallCount | Should -Be 0
        #                         $script:MailProfileAlterMethodCallCount | Should -Be 0
        #                         $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
        #                         $script:MailProfileAddAccountMethodCallCount | Should -Be 0
        #                         $script:JobServerAlterMethodCallCount | Should -Be 0
        #                         $script:LoggingLevelAlterMethodCallCount | Should -Be 1
        #                     }
        #                     else
        #                     {
        #                         $script:MailServerRenameMethodCallCount | Should -Be 0
        #                         $script:MailServerAlterMethodCallCount | Should -Be 0
        #                         $script:MailAccountAlterMethodCallCount | Should -Be 1
        #                         $script:MailProfileCreateMethodCallCount | Should -Be 0
        #                         $script:MailProfileAlterMethodCallCount | Should -Be 0
        #                         $script:MailProfileAddPrincipalMethodCallCount | Should -Be 0
        #                         $script:MailProfileAddAccountMethodCallCount | Should -Be 0
        #                         $script:JobServerAlterMethodCallCount | Should -Be 0
        #                         $script:LoggingLevelAlterMethodCallCount | Should -Be 0
        #                     }

        #                     Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope It
        #                 }
        #             }
        #         }
        #     }

        #     Assert-VerifiableMock
    #     }
    }
}
finally
{
    Invoke-TestCleanup
}

