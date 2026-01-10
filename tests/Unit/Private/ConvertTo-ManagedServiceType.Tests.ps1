[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'ConvertTo-ManagedServiceType' -Tag 'Private' {
    Context 'When translating to managed service types' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    MockServiceType  = 'DatabaseEngine'
                    MockExpectedType = 'SqlServer'
                }

                @{
                    MockServiceType  = 'SqlServerAgent'
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

                $managedServiceType | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType'
                $managedServiceType | Should -Be $MockExpectedType
            }
        }
    }

    Context 'When converting a type that is not supported' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $mockErrorMessage = 'Cannot validate argument on parameter ''ServiceType''. The argument "UnknownType" does not belong to the set "DatabaseEngine,SQLServerAgent,Search,IntegrationServices,AnalysisServices,ReportingServices,SQLServerBrowser,NotificationServices" specified by the ValidateSet attribute. Supply an argument that is in the set and then try the command again.'

                { ConvertTo-ManagedServiceType -ServiceType 'UnknownType' -ErrorAction 'Stop' } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }
}
