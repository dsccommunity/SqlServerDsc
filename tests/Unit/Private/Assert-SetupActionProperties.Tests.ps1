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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Assert-SetupActionProperties' -Tag 'Private' {
    Context 'When all properties are valid for setup action ''<MockSetupAction>''' -ForEach @(
        @{
            MockSetupAction = 'Install'
        }
        @{
            MockSetupAction = 'Uninstall'
        }
        @{
            MockSetupAction = 'InstallRole'
        }
        @{
            MockSetupAction = 'InstallAzureArcAgent'
        }
        @{
            MockSetupAction = 'UsingConfigurationFile'
        }
        @{
            MockSetupAction = 'PrepareImage'
        }
        @{
            MockSetupAction = 'CompleteImage'
        }
        @{
            MockSetupAction = 'Upgrade'
        }
        @{
            MockSetupAction = 'EditionUpgrade'
        }
        @{
            MockSetupAction = 'Repair'
        }
        @{
            MockSetupAction = 'RebuildDatabase'
        }
        @{
            MockSetupAction = 'InstallFailoverCluster'
        }
        @{
            MockSetupAction = 'PrepareFailoverCluster'
        }
        @{
            MockSetupAction = 'CompleteFailoverCluster'
        }
        @{
            MockSetupAction = 'AddNode'
        }
        @{
            MockSetupAction = 'RemoveNode'
        }
    ) {
        It 'Should not throw an exception' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        ValidProperty = 'Value'
                    } -SetupAction $MockSetupAction
                } | Should -Not -Throw
            }
        }
    }

    Context 'When passing only parameter ''<MockParameterName>''' -ForEach @(
        @{
            MockParameterName = 'PBStartPortRange'
        }
        @{
            MockParameterName = 'PBEndPortRange'
        }
     ) {
        It 'Should throw the correct error' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        $MockParameterName = 'Value'
                    } -SetupAction 'NotUsed'
                } | Should -Throw -ErrorId 'ARCP0001,Assert-RequiredCommandParameter' # cSpell: disable-line
            }
        }
    }

    Context 'When specifying role ''SPI_AS_NewFarm'' and required parameter ''<MockMissingParameterName>'' is missing' -ForEach @(
        @{
            MockParameters = @{
                FarmPassword = 'Value'
                Passphrase = 'Value'
                FarmAdminiPort  = 'Value' # cspell: disable-line
            }
            MockMissingParameterName = 'FarmAccount'
        }
        @{
            MockParameters = @{
                FarmAccount = 'Value'
                Passphrase = 'Value'
                FarmAdminiPort = 'Value' # cspell: disable-line
            }
            MockMissingParameterName = 'FarmPassword'
        }
        @{
            MockParameters = @{
                FarmAccount = 'Value'
                FarmPassword = 'Value'
                FarmAdminiPort = 'Value' # cspell: disable-line
            }
            MockMissingParameterName = 'Passphrase'
        }
        @{
            MockParameters = @{
                FarmAccount = 'Value'
                FarmPassword = 'Value'
                Passphrase = 'Value'
            }
            MockMissingParameterName = 'FarmAdminiPort' # cspell: disable-line
        }
     ) {
        It 'Should throw the correct error' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $MockParameters.Role = 'SPI_AS_NewFarm'

                    Assert-SetupActionProperties -Property $MockParameters -SetupAction 'NotUsed'
                } | Should -Throw -ErrorId 'ARCP0001,Assert-RequiredCommandParameter' # cSpell: disable-line
            }
        }
    }

    Context 'When specifying security mode ''SQL'' and required parameter ''SAPwd'' is missing' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        SecurityMode = 'SQL'
                    } -SetupAction 'NotUsed'
                } | Should -Throw -ErrorId 'ARCP0001,Assert-RequiredCommandParameter' # cSpell: disable-line
            }
        }
    }

    Context 'When file stream level is set to <_> and ''FileStreamShareName'' is missing' -ForEach @(0, 1) {
        It 'Should not throw an exception' {
            InModuleScope -Parameters @{
                MockFileStreamLevel = $_
            } -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        FileStreamLevel = $MockFileStreamLevel
                    } -SetupAction 'NotUsed'
                } | Should -Not -Throw
            }
        }
    }

    Context 'When file stream level is set to <_> and ''FileStreamShareName'' is missing' -ForEach @(2, 3) {
        It 'Should throw the correct error' {
            InModuleScope -Parameters @{
                MockFileStreamLevel = $_
            } -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        FileStreamLevel = $MockFileStreamLevel
                    } -SetupAction 'NotUsed'
                } | Should -Throw -ErrorId 'ARCP0001,Assert-RequiredCommandParameter' # cSpell: disable-line
            }
        }
    }

    Context 'When specifying an account-parameter without the corresponding password-parameter' -ForEach @(
        @{
            MockParameterName = 'PBEngSvcAccount'
        }
        @{
            MockParameterName = 'PBDMSSvcAccount' # cSpell: disable-line
        }
        @{
            MockParameterName = 'AgtSvcAccount'
        }
        @{
            MockParameterName = 'ASSvcAccount'
        }
        @{
            MockParameterName = 'FarmAccount'
        }
        @{
            MockParameterName = 'SqlSvcAccount'
        }
        @{
            MockParameterName = 'ISSvcAccount'
        }
        @{
            MockParameterName = 'RSSvcAccount'
        }
     ) {
        It 'Should throw the correct error' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        $MockParameterName = 'AccountName'
                    } -SetupAction 'NotUsed'
                } | Should -Throw -ErrorId 'ARCP0001,Assert-RequiredCommandParameter' # cSpell: disable-line
            }
        }
    }

    Context 'When specifying an account-parameter with the corresponding password-parameter' -ForEach @(
        @{
            MockParameterName = 'PBEngSvcAccount'
        }
        @{
            MockParameterName = 'PBDMSSvcAccount' # cSpell: disable-line
        }
        @{
            MockParameterName = 'AgtSvcAccount'
        }
        @{
            MockParameterName = 'ASSvcAccount'
        }
        @{
            MockParameterName = 'FarmAccount'
        }
        @{
            MockParameterName = 'SqlSvcAccount'
        }
        @{
            MockParameterName = 'ISSvcAccount'
        }
        @{
            MockParameterName = 'RSSvcAccount'
        }
     ) {
        It 'Should not throw an exception' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        $MockParameterName = 'AccountName'
                        ($MockParameterName -replace 'Account', 'Password') = 'Password'
                    } -SetupAction 'NotUsed'
                } | Should -Not -Throw
            }
        }
    }

    Context 'When specifying an account-parameter that specifies a (global) managed service account, virtual account, or built-in account' -ForEach @(
        @{
            MockParameterName = 'PBEngSvcAccount'
        }
        @{
            MockParameterName = 'PBDMSSvcAccount' # cSpell: disable-line
        }
        @{
            MockParameterName = 'AgtSvcAccount'
        }
        @{
            MockParameterName = 'ASSvcAccount'
        }
        @{
            MockParameterName = 'FarmAccount'
        }
        @{
            MockParameterName = 'SqlSvcAccount'
        }
        @{
            MockParameterName = 'ISSvcAccount'
        }
        @{
            MockParameterName = 'RSSvcAccount'
        }
     ) {
        BeforeAll {
            Mock -CommandName Test-AccountRequirePassword -MockWith {
                return $false
            }
        }

        It 'Should not throw an exception' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        $MockParameterName = 'myMSA$'
                    } -SetupAction 'NotUsed'
                } | Should -Not -Throw
            }
        }
    }

    Context 'When specifying feature ''AZUREEXTENSION'' and required parameter ''<MockMissingParameterName>'' is missing' -ForEach @(
        @{
            MockParameters = @{
                AzureResourceGroup = 'Value'
                AzureRegion  = 'Value'
                AzureTenantId = 'Value'
                AzureServicePrincipal = 'Value'
                AzureServicePrincipalSecret = 'Value'
            }
            MockMissingParameterName = 'AzureSubscriptionId'
        }
        @{
            MockParameters = @{
                AzureSubscriptionId = 'Value'
                AzureRegion  = 'Value'
                AzureTenantId = 'Value'
                AzureServicePrincipal = 'Value'
                AzureServicePrincipalSecret = 'Value'
            }
            MockMissingParameterName = 'AzureResourceGroup'
        }
        @{
            MockParameters = @{
                AzureSubscriptionId = 'Value'
                AzureResourceGroup = 'Value'
                AzureTenantId = 'Value'
                AzureServicePrincipal = 'Value'
                AzureServicePrincipalSecret = 'Value'
            }
            MockMissingParameterName = 'AzureRegion'
        }
        @{
            MockParameters = @{
                AzureSubscriptionId = 'Value'
                AzureResourceGroup = 'Value'
                AzureRegion  = 'Value'
                AzureServicePrincipal = 'Value'
                AzureServicePrincipalSecret = 'Value'
            }
            MockMissingParameterName = 'AzureTenantId' # cspell: disable-line
        }
        @{
            MockParameters = @{
                AzureSubscriptionId = 'Value'
                AzureResourceGroup = 'Value'
                AzureRegion  = 'Value'
                AzureTenantId = 'Value'
                AzureServicePrincipalSecret = 'Value'
            }
            MockMissingParameterName = 'AzureServicePrincipal'
        }
        @{
            MockParameters = @{
                AzureSubscriptionId = 'Value'
                AzureResourceGroup = 'Value'
                AzureRegion  = 'Value'
                AzureTenantId = 'Value'
                AzureServicePrincipal = 'Value'
            }
            MockMissingParameterName = 'AzureServicePrincipalSecret'
        }
     ) {
        BeforeAll {
            Mock -CommandName Assert-Feature

            # Required mock for mocking Assert-Feature above.
            Mock -CommandName Get-FileVersionInformation -MockWith {
                return @{
                    ProductVersion = 16
                }
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    $MockParameters.MediaPath = $TestDrive
                    $MockParameters.Features = @(
                        'SQLENGINE'
                        'AZUREEXTENSION'
                        'AS'
                    )

                    Assert-SetupActionProperties -Property $MockParameters -SetupAction 'NotUsed'
                } | Should -Throw -ErrorId 'ARCP0001,Assert-RequiredCommandParameter' # cSpell: disable-line
            }
        }
    }

    Context 'When setup action is ''<MockSetupAction>'' and feature is ''<MockFeature>'' but parameter ''<MockMissingParameterName>'' is missing' -ForEach @(
        @{
            MockSetupAction = 'CompleteImage'
            MockMissingParameterName = 'AgtSvcAccount'
            MockFeature = 'SQLENGINE'
        }
        @{
            MockSetupAction = 'InstallFailoverCluster'
            MockMissingParameterName = 'AgtSvcAccount'
            MockFeature = 'SQLENGINE'
        }
        @{
            MockSetupAction = 'InstallFailoverCluster'
            MockMissingParameterName = 'ASSvcAccount'
            MockFeature = 'AS'
        }
        @{
            MockSetupAction = 'InstallFailoverCluster'
            MockMissingParameterName = 'SqlSvcAccount'
            MockFeature = 'SQLENGINE'
        }
        @{
            MockSetupAction = 'InstallFailoverCluster'
            MockMissingParameterName = 'ISSvcAccount'
            MockFeature = 'IS'
        }
        @{
            MockSetupAction = 'InstallFailoverCluster'
            MockMissingParameterName = 'RSSvcAccount'
            MockFeature = 'RS'
        }
        @{
            MockSetupAction = 'PrepareFailoverCluster'
            MockMissingParameterName = 'AgtSvcAccount'
            MockFeature = 'SQLENGINE'
        }
        @{
            MockSetupAction = 'PrepareFailoverCluster'
            MockMissingParameterName = 'ASSvcAccount'
            MockFeature = 'AS'
        }
        @{
            MockSetupAction = 'PrepareFailoverCluster'
            MockMissingParameterName = 'SqlSvcAccount'
            MockFeature = 'SQLENGINE'
        }
        @{
            MockSetupAction = 'PrepareFailoverCluster'
            MockMissingParameterName = 'ISSvcAccount'
            MockFeature = 'IS'
        }
        @{
            MockSetupAction = 'PrepareFailoverCluster'
            MockMissingParameterName = 'RSSvcAccount'
            MockFeature = 'RS'
        }
        @{
            MockSetupAction = 'AddNode'
            MockMissingParameterName = 'AgtSvcAccount'
            MockFeature = 'SQLENGINE'
        }
        @{
            MockSetupAction = 'AddNode'
            MockMissingParameterName = 'ASSvcAccount'
            MockFeature = 'AS'
        }
        @{
            MockSetupAction = 'AddNode'
            MockMissingParameterName = 'SqlSvcAccount'
            MockFeature = 'SQLENGINE'
        }
        @{
            MockSetupAction = 'AddNode'
            MockMissingParameterName = 'ISSvcAccount'
            MockFeature = 'IS'
        }
        @{
            MockSetupAction = 'AddNode'
            MockMissingParameterName = 'RSSvcAccount'
            MockFeature = 'RS'
        }
        @{
            MockSetupAction = 'Install'
            MockFeature = 'AS'
            MockMissingParameterName = 'ASSysAdminAccounts'
        }
        @{
            MockSetupAction = 'Install'
            MockFeature = 'SQLENGINE'
            MockMissingParameterName = 'SqlSysAdminAccounts'
        }
    ) {
        BeforeAll {
            Mock -CommandName Assert-Feature

            # Required mock for mocking Assert-Feature above.
            Mock -CommandName Get-FileVersionInformation -MockWith {
                return @{
                    ProductVersion = 16
                }
            }
        }

        It 'Should throw an exception' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        MediaPath = $TestDrive
                        Features = $MockFeature
                    } -SetupAction $MockSetupAction
                } | Should -Throw -ErrorId 'ARCP0001,Assert-RequiredCommandParameter' # cSpell: disable-line
            }
        }
    }

    Context 'When setup action is ''<MockSetupAction>'' and also specifying analysis services server mode ''PowerPivot''' -ForEach @(
        @{
            MockSetupAction = 'InstallFailoverCluster'
        }
        @{
            MockSetupAction = 'CompleteFailoverCluster'
        }
    ) {
        It 'Should throw an exception' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        ASServerMode = 'PowerPivot'
                    } -SetupAction $MockSetupAction
                } | Should -Throw -ErrorId 'ASAP0001,Assert-SetupActionProperties' # cSpell: disable-line
            }
        }
    }

    Context 'When setup action is ''<MockSetupAction>'' and also specifying another reporting services install mode than ''FilesOnlyMode''' -ForEach @(
        @{
            MockSetupAction = 'AddNode'
        }
    ) {
        It 'Should throw an exception' {
            InModuleScope -Parameters $_ -ScriptBlock {
                {
                    Assert-SetupActionProperties -Property @{
                        RsInstallMode = 'DefaultNativeMode'
                    } -SetupAction $MockSetupAction
                } | Should -Throw -ErrorId 'ASAP0002,Assert-SetupActionProperties' # cSpell: disable-line
            }
        }
    }
}
