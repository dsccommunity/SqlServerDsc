<#
    .SYNOPSIS
        Unit test for helper functions in module SqlServerDsc.Common.

    .NOTES
        SMO stubs
        ---------
        These are loaded at the start so that it is known that they are left in the
        session after test finishes, and will spill over to other tests. There does
        not exist a way to unload assemblies. It is possible to load these in a
        InModuleScope but the classes are still present in the parent scope when
        Pester has ran.

        SqlServer/SQLPS stubs
        ---------------------
        These are imported using Import-SqlModuleStub in a BeforeAll-block in only
        a test that requires them, and must be removed in an AfterAll-block using
        Remove-SqlModuleStub so the stub cmdlets does not spill over to another
        test.
#>

# Suppressing this rule because ConvertTo-SecureString is used to simplify the tests.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:subModuleName = 'SqlServerDsc.Common'

    $script:parentModule = Get-Module -Name $script:moduleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\TestHelpers\CommonTestHelper.psm1')

    # Loading SMO stubs.
    if (-not ('Microsoft.SqlServer.Management.Smo.Server' -as [Type]))
    {
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs') -ChildPath 'SMO.cs')
    }

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlServerDsc.Common\Connect-SqlAnalysis' -Tag 'ConnectSqlAnalysis' {
    BeforeAll {
        $mockInstanceName = 'TEST'
        $mockDynamicConnectedStatus = $true

        $mockNewObject_MicrosoftAnalysisServicesServer = {
            return New-Object -TypeName Object |
                Add-Member -MemberType 'NoteProperty' -Name 'Connected' -Value $mockDynamicConnectedStatus -PassThru |
                Add-Member -MemberType 'ScriptMethod' -Name 'Connect' -Value {
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [ValidateNotNullOrEmpty()]
                        [System.String]
                        $DataSource
                    )

                    if ($DataSource -ne $mockExpectedDataSource)
                    {
                        throw ("Datasource was expected to be '{0}', but was '{1}'." -f $mockExpectedDataSource, $dataSource)
                    }

                    if ($mockThrowInvalidOperation)
                    {
                        throw 'Unable to connect.'
                    }
                } -PassThru -Force
        }

        $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter = {
            $TypeName -eq 'Microsoft.AnalysisServices.Server'
        }

        $mockSqlCredentialUserName = 'TestUserName12345'
        $mockSqlCredentialPassword = 'StrongOne7.'
        $mockSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockSqlCredentialPassword -AsPlainText -Force
        $mockSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockSqlCredentialUserName, $mockSqlCredentialSecurePassword)

        $mockNetBiosSqlCredentialUserName = 'DOMAIN\TestUserName12345'
        $mockNetBiosSqlCredentialPassword = 'StrongOne7.'
        $mockNetBiosSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockNetBiosSqlCredentialPassword -AsPlainText -Force
        $mockNetBiosSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockNetBiosSqlCredentialUserName, $mockNetBiosSqlCredentialSecurePassword)

        $mockFqdnSqlCredentialUserName = 'TestUserName12345@domain.local'
        $mockFqdnSqlCredentialPassword = 'StrongOne7.'
        $mockFqdnSqlCredentialSecurePassword = ConvertTo-SecureString -String $mockFqdnSqlCredentialPassword -AsPlainText -Force
        $mockFqdnSqlCredential = New-Object -TypeName PSCredential -ArgumentList ($mockFqdnSqlCredentialUserName, $mockFqdnSqlCredentialSecurePassword)

        $mockComputerName = Get-ComputerName
    }

    BeforeEach {
        Mock -CommandName New-Object `
            -MockWith $mockNewObject_MicrosoftAnalysisServicesServer `
            -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
    }

    Context 'When using feature flag ''AnalysisServicesConnection''' {
        BeforeAll {
            Mock -CommandName Import-SqlDscPreferredModule

            $mockExpectedDataSource = "Data Source=$mockComputerName"
        }

        Context 'When connecting to the default instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $null = Connect-SQLAnalysis -FeatureFlag 'AnalysisServicesConnection'

                Should -Invoke -CommandName Import-SqlDscPreferredModule -Exactly -Times 1 -Scope It
                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }

            Context 'When Connected status is $false' {
                BeforeAll {
                    $mockDynamicConnectedStatus = $false
                }

                AfterAll {
                    $mockDynamicConnectedStatus = $true
                }

                It 'Should throw the correct error' {
                    $mockLocalizedString = InModuleScope -ScriptBlock {
                        $script:localizedData.FailedToConnectToAnalysisServicesInstance
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message (
                        $mockLocalizedString -f $mockComputerName
                    )

                    { Connect-SQLAnalysis -FeatureFlag 'AnalysisServicesConnection' } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')
                }
            }
        }

        Context 'When connecting to the named instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName"

                $null = Connect-SQLAnalysis -InstanceName $mockInstanceName -FeatureFlag 'AnalysisServicesConnection'
            }
        }

        Context 'When connecting to the named instance using Windows Authentication impersonation' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName;User ID=$mockSqlCredentialUserName;Password=$mockSqlCredentialPassword"

                $null = Connect-SQLAnalysis -InstanceName $mockInstanceName -SetupCredential $mockSqlCredential -FeatureFlag 'AnalysisServicesConnection'
            }
        }
    }

    Context 'When not using feature flag ''AnalysisServicesConnection''' {
        BeforeAll {
            Mock -CommandName Import-Assembly
        }

        Context 'When connecting to the default instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$mockComputerName"

                $null = Connect-SQLAnalysis

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the named instance using Windows Authentication' {
            It 'Should not throw when connecting' {
                $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName"

                $null = Connect-SQLAnalysis -InstanceName $mockInstanceName

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the named instance using Windows Authentication impersonation' {
            Context 'When authentication without NetBIOS domain and Fully Qualified Domain Name (FQDN)' {
                It 'Should not throw when connecting' {
                    $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName;User ID=$mockSqlCredentialUserName;Password=$mockSqlCredentialPassword"

                    $null = Connect-SQLAnalysis -InstanceName $mockInstanceName -SetupCredential $mockSqlCredential

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
                }
            }

            Context 'When authentication using NetBIOS domain' {
                It 'Should not throw when connecting' {
                    $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName;User ID=$mockNetBiosSqlCredentialUserName;Password=$mockNetBiosSqlCredentialPassword"

                    $null = Connect-SQLAnalysis -InstanceName $mockInstanceName -SetupCredential $mockNetBiosSqlCredential

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
                }
            }

            Context 'When authentication using Fully Qualified Domain Name (FQDN)' {
                It 'Should not throw when connecting' {
                    $mockExpectedDataSource = "Data Source=$mockComputerName\$mockInstanceName;User ID=$mockFqdnSqlCredentialUserName;Password=$mockFqdnSqlCredentialPassword"

                    $null = Connect-SQLAnalysis -InstanceName $mockInstanceName -SetupCredential $mockFqdnSqlCredential

                    Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                        -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
                }
            }
        }

        Context 'When connecting to the default instance using the correct service instance but does not return a correct Analysis Service object' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = ''

                Mock -CommandName New-Object `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.FailedToConnectToAnalysisServicesInstance
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f $mockComputerName
                )

                { Connect-SQLAnalysis } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }

        Context 'When connecting to the default instance using a Analysis Service instance that does not exist' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = "Data Source=$mockComputerName"

                # Force the mock of Connect() method to throw 'Unable to connect.'
                $mockThrowInvalidOperation = $true

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.FailedToConnectToAnalysisServicesInstance
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f $mockComputerName
                )

                { Connect-SQLAnalysis } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter

                # Setting it back to the default so it does not disturb other tests.
                $mockThrowInvalidOperation = $false
            }
        }

        # This test is to test the mock so that it throws correct when data source is not the expected data source
        Context 'When connecting to the named instance using another data source then expected' {
            It 'Should throw the correct error' {
                $mockExpectedDataSource = 'Force wrong data source'

                $testParameters = @{
                    ServerName   = 'DummyHost'
                    InstanceName = $mockInstanceName
                }

                $mockLocalizedString = InModuleScope -ScriptBlock {
                    $script:localizedData.FailedToConnectToAnalysisServicesInstance
                }

                $mockErrorRecord = Get-InvalidOperationRecord -Message (
                    $mockLocalizedString -f "$($testParameters.ServerName)\$($testParameters.InstanceName)"
                )

                { Connect-SQLAnalysis @testParameters } | Should -Throw -ExpectedMessage ($mockErrorRecord.Exception.Message + '*')

                Should -Invoke -CommandName New-Object -Exactly -Times 1 -Scope It `
                    -ParameterFilter $mockNewObject_MicrosoftAnalysisServicesServer_ParameterFilter
            }
        }
    }
}
