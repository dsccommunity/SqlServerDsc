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

    Import-Module -Name $script:dscModuleName

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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
}

Describe 'Install-SqlDscServer' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'Install'
            MockExpectedParameters = '-Install -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> -Features <string> -SqlSysAdminAccounts <string[]> [-Enu] [-UpdateEnabled] [-UpdateSource <string>] [-InstallSharedDir <string>] [-InstallSharedWowDir <string>] [-InstanceDir <string>] [-InstanceId <string>] [-PBEngSvcAccount <string>] [-PBEngSvcPassword <pscredential>] [-PBEngSvcStartupType <string>] [-PBDMSSvcAccount <string>] [-PBDMSSvcPassword <pscredential>] [-PBDMSSvcStartupType <string>] [-PBPortRange <string>] [-PBScaleOut] [-ProductKey <string>] [-AgtSvcAccount <string>] [-AgtSvcPassword <pscredential>] [-AgtSvcStartupType <string>] [-ASBackupDir <string>] [-ASCollation <string>] [-ASConfigDir <string>] [-ASDataDir <string>] [-ASLogDir <string>] [-ASTempDir <string>] [-ASServerMode <string>] [-ASSvcAccount <string>] [-ASSvcPassword <pscredential>] [-ASSvcStartupType <string>] [-ASSysAdminAccounts <string>] [-ASProviderMSOLAP <string>] [-BrowserSvcStartupType <string>] [-EnableRanU] [-InstallSqlDataDir <string>] [-SqlBackupDir <string>] [-SecurityMode <string>] [-SAPwd <pscredential>] [-SqlCollation <string>] [-SqlSvcAccount <string>] [-SqlSvcPassword <pscredential>] [-SqlSvcStartupType <string>] [-SqlTempDbDir <string>] [-SqlTempDbLogDir <string>] [-SqlTempDbFileCount <string>] [-SqlTempDbFileSize <string>] [-SqlTempDbFileGrowth <string>] [-SqlTempDbLogFileSize <string>] [-SqlTempDbLogFileGrowth <string>] [-SqlUserDbDir <string>] [-SqlSvcInstantFileInit] [-SqlUserDbLogDir <string>] [-SqlMaxDop <short>] [-UseSqlRecommendedMemoryLimits] [-SqlMinMemory <int>] [-SqlMaxMemory <int>] [-FileStreamLevel <short>] [-FileStreamShareName <string>] [-ISSvcAccount <string>] [-ISSvcPassword <pscredential>] [-ISSvcStartupType <string>] [-NpEnabled] [-TcpEnabled] [-RsInstallMode] [-RSSvcAccount <string>] [-RSSvcPassword <pscredential>] [-RSSvcStartupType <string>] [-MPYCacheDirectory <string>] [-MRCacheDirectory <string>] [-SqlInstJava] [-SqlJavaDir <string>] [-AzureSubscriptionId <string>] [-AzureResourceGroup <string>] [-AzureRegion <string>] [-AzureTenantId <string>] [-AzureServicePrincipal <string>] [-AzureServicePrincipalSecret <pscredential>] [-AzureArcProxy <string>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'InstallAzureArcAgent'
            MockExpectedParameters = '-Install -AcceptTermAndNotices -MediaPath <string> -AzureSubscriptionId <string> -AzureResourceGroup <string> -AzureRegion <string> -AzureTenantId <string> -AzureServicePrincipal <string> -AzureServicePrincipalSecret <pscredential> [-AzureArcProxy <string>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'UsingConfigurationFile'
            MockExpectedParameters = '-ConfigurationFile <string> -MediaPath <string> [-AcceptTermAndNotices] [-AgtSvcPassword <pscredential>] [-ASSvcPassword <pscredential>] [-SqlSvcPassword <pscredential>] [-ISSvcPassword <pscredential>] [-RSSvcPassword <pscredential>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }

        @{
            MockParameterSetName = 'Uninstall'
            MockExpectedParameters = '-Uninstall -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'PrepareImage'
            MockExpectedParameters = '-PrepareImage -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> -Features <string> -InstanceId <string> [-Enu] [-UpdateEnabled] [-UpdateSource <string>] [-InstallSharedDir <string>] [-InstanceDir <string>] [-PBEngSvcAccount <string>] [-PBEngSvcPassword <pscredential>] [-PBEngSvcStartupType <string>] [-PBPortRange <string>] [-PBScaleOut] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'CompleteImage'
            MockExpectedParameters = '-CompleteImage -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'Upgrade'
            MockExpectedParameters = '-Upgrade -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'EditionUpgrade'
            MockExpectedParameters = '-EditionUpgrade -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'Repair'
            MockExpectedParameters = '-Repair -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'RebuildDatabase'
            MockExpectedParameters = '-RebuildDatabase -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'InstallFailoverCluster'
            MockExpectedParameters = '-InstallFailoverCluster -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'PrepareFailoverCluster'
            MockExpectedParameters = '-PrepareFailoverCluster -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'CompleteFailoverCluster'
            MockExpectedParameters = '-CompleteFailoverCluster -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'AddNode'
            MockExpectedParameters = '-AddNode -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'RemoveNode'
            MockExpectedParameters = '-RemoveNode -AcceptTermAndNotices -MediaPath <string> -InstanceName <string> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Install-SqlDscServer').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }
}
