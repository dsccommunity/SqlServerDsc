[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
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

Describe 'Install-SqlDscServer' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'Install'
            # cSpell: disable-next
            MockExpectedParameters = '-Install -AcceptLicensingTerms -MediaPath <string> -InstanceName <string> -Features <string[]> [-SuppressPrivacyStatementNotice] [-IAcknowledgeEntCalLimits] [-Enu] [-UpdateEnabled] [-UpdateSource <string>] [-InstallSharedDir <string>] [-InstallSharedWowDir <string>] [-InstanceDir <string>] [-InstanceId <string>] [-PBEngSvcAccount <string>] [-PBEngSvcPassword <securestring>] [-PBEngSvcStartupType <string>] [-PBDMSSvcAccount <string>] [-PBDMSSvcPassword <securestring>] [-PBDMSSvcStartupType <string>] [-PBStartPortRange <ushort>] [-PBEndPortRange <ushort>] [-PBScaleOut] [-ProductKey <string>] [-AgtSvcAccount <string>] [-AgtSvcPassword <securestring>] [-AgtSvcStartupType <string>] [-ASBackupDir <string>] [-ASCollation <string>] [-ASConfigDir <string>] [-ASDataDir <string>] [-ASLogDir <string>] [-ASTempDir <string>] [-ASServerMode <string>] [-ASSvcAccount <string>] [-ASSvcPassword <securestring>] [-ASSvcStartupType <string>] [-ASSysAdminAccounts <string[]>] [-ASProviderMSOLAP] [-BrowserSvcStartupType <string>] [-EnableRanU] [-InstallSqlDataDir <string>] [-SqlBackupDir <string>] [-SecurityMode <string>] [-SAPwd <securestring>] [-SqlCollation <string>] [-SqlSvcAccount <string>] [-SqlSvcPassword <securestring>] [-SqlSvcStartupType <string>] [-SqlSysAdminAccounts <string[]>] [-SqlTempDbDir <string>] [-SqlTempDbLogDir <string>] [-SqlTempDbFileCount <ushort>] [-SqlTempDbFileSize <ushort>] [-SqlTempDbFileGrowth <ushort>] [-SqlTempDbLogFileSize <ushort>] [-SqlTempDbLogFileGrowth <ushort>] [-SqlUserDbDir <string>] [-SqlSvcInstantFileInit] [-SqlUserDbLogDir <string>] [-SqlMaxDop <ushort>] [-UseSqlRecommendedMemoryLimits] [-SqlMinMemory <uint>] [-SqlMaxMemory <uint>] [-FileStreamLevel <ushort>] [-FileStreamShareName <string>] [-ISSvcAccount <string>] [-ISSvcPassword <securestring>] [-ISSvcStartupType <string>] [-NpEnabled] [-TcpEnabled] [-RsInstallMode <string>] [-RSSvcAccount <string>] [-RSSvcPassword <securestring>] [-RSSvcStartupType <string>] [-MPYCacheDirectory <string>] [-MRCacheDirectory <string>] [-SqlInstJava] [-SqlJavaDir <string>] [-AzureSubscriptionId <string>] [-AzureResourceGroup <string>] [-AzureRegion <string>] [-AzureTenantId <string>] [-AzureServicePrincipal <string>] [-AzureServicePrincipalSecret <securestring>] [-AzureArcProxy <string>] [-SkipRules <string[]>] [-ProductCoveredBySA] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'InstallRole'
            # cSpell: disable-next
            MockExpectedParameters = '-Install -AcceptLicensingTerms -MediaPath <string> -Role <string> [-SuppressPrivacyStatementNotice] [-IAcknowledgeEntCalLimits] [-InstanceName <string>] [-Enu] [-UpdateEnabled] [-UpdateSource <string>] [-Features <string[]>] [-InstallSharedDir <string>] [-InstallSharedWowDir <string>] [-InstanceDir <string>] [-InstanceId <string>] [-PBEngSvcAccount <string>] [-PBEngSvcPassword <securestring>] [-PBEngSvcStartupType <string>] [-PBDMSSvcAccount <string>] [-PBDMSSvcPassword <securestring>] [-PBDMSSvcStartupType <string>] [-PBStartPortRange <ushort>] [-PBEndPortRange <ushort>] [-PBScaleOut] [-ProductKey <string>] [-AgtSvcAccount <string>] [-AgtSvcPassword <securestring>] [-AgtSvcStartupType <string>] [-ASBackupDir <string>] [-ASCollation <string>] [-ASConfigDir <string>] [-ASDataDir <string>] [-ASLogDir <string>] [-ASTempDir <string>] [-ASServerMode <string>] [-ASSvcAccount <string>] [-ASSvcPassword <securestring>] [-ASSvcStartupType <string>] [-ASSysAdminAccounts <string[]>] [-ASProviderMSOLAP] [-FarmAccount <string>] [-FarmPassword <securestring>] [-Passphrase <securestring>] [-FarmAdminiPort <ushort>] [-BrowserSvcStartupType <string>] [-EnableRanU] [-InstallSqlDataDir <string>] [-SqlBackupDir <string>] [-SecurityMode <string>] [-SAPwd <securestring>] [-SqlCollation <string>] [-AddCurrentUserAsSqlAdmin] [-SqlSvcAccount <string>] [-SqlSvcPassword <securestring>] [-SqlSvcStartupType <string>] [-SqlSysAdminAccounts <string[]>] [-SqlTempDbDir <string>] [-SqlTempDbLogDir <string>] [-SqlTempDbFileCount <ushort>] [-SqlTempDbFileSize <ushort>] [-SqlTempDbFileGrowth <ushort>] [-SqlTempDbLogFileSize <ushort>] [-SqlTempDbLogFileGrowth <ushort>] [-SqlUserDbDir <string>] [-SqlSvcInstantFileInit] [-SqlUserDbLogDir <string>] [-SqlMaxDop <ushort>] [-UseSqlRecommendedMemoryLimits] [-SqlMinMemory <uint>] [-SqlMaxMemory <uint>] [-FileStreamLevel <ushort>] [-FileStreamShareName <string>] [-ISSvcAccount <string>] [-ISSvcPassword <securestring>] [-ISSvcStartupType <string>] [-NpEnabled] [-TcpEnabled] [-RsInstallMode <string>] [-RSSvcAccount <string>] [-RSSvcPassword <securestring>] [-RSSvcStartupType <string>] [-MPYCacheDirectory <string>] [-MRCacheDirectory <string>] [-SqlInstJava] [-SqlJavaDir <string>] [-AzureSubscriptionId <string>] [-AzureResourceGroup <string>] [-AzureRegion <string>] [-AzureTenantId <string>] [-AzureServicePrincipal <string>] [-AzureServicePrincipalSecret <securestring>] [-AzureArcProxy <string>] [-SkipRules <string[]>] [-ProductCoveredBySA] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'InstallAzureArcAgent'
            # cSpell: disable-next
            MockExpectedParameters = '-Install -AcceptLicensingTerms -MediaPath <string> -AzureSubscriptionId <string> -AzureResourceGroup <string> -AzureRegion <string> -AzureTenantId <string> -AzureServicePrincipal <string> -AzureServicePrincipalSecret <securestring> [-AzureArcProxy <string>] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'UsingConfigurationFile'
            # cSpell: disable-next
            MockExpectedParameters = '-ConfigurationFile <string> -MediaPath <string> [-AgtSvcPassword <securestring>] [-ASSvcPassword <securestring>] [-SqlSvcPassword <securestring>] [-ISSvcPassword <securestring>] [-RSSvcPassword <securestring>] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'PrepareImage'
            # cSpell: disable-next
            MockExpectedParameters = '-PrepareImage -AcceptLicensingTerms -MediaPath <string> -Features <string[]> -InstanceId <string> [-IAcknowledgeEntCalLimits] [-Enu] [-UpdateEnabled] [-UpdateSource <string>] [-InstallSharedDir <string>] [-InstanceDir <string>] [-PBEngSvcAccount <string>] [-PBEngSvcPassword <securestring>] [-PBEngSvcStartupType <string>] [-PBStartPortRange <ushort>] [-PBEndPortRange <ushort>] [-PBScaleOut] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'Upgrade'
            # cSpell: disable-next
            MockExpectedParameters = '-Upgrade -AcceptLicensingTerms -MediaPath <string> -InstanceName <string> [-Enu] [-UpdateEnabled] [-UpdateSource <string>] [-InstanceDir <string>] [-InstanceId <string>] [-ProductKey <string>] [-BrowserSvcStartupType <string>] [-FTUpgradeOption <string>] [-ISSvcAccount <string>] [-ISSvcPassword <securestring>] [-ISSvcStartupType <string>] [-AllowUpgradeForSSRSSharePointMode] [-FailoverClusterRollOwnership <ushort>] [-ProductCoveredBySA] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'EditionUpgrade'
            # cSpell: disable-next
            MockExpectedParameters = '-EditionUpgrade -AcceptLicensingTerms -MediaPath <string> -InstanceName <string> -ProductKey <string> [-SkipRules <string[]>] [-ProductCoveredBySA] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'InstallFailoverCluster'
            # cSpell: disable-next
            MockExpectedParameters = '-InstallFailoverCluster -AcceptLicensingTerms -MediaPath <string> -InstanceName <string> -Features <string[]> -InstallSqlDataDir <string> -SqlSysAdminAccounts <string[]> -FailoverClusterNetworkName <string> -FailoverClusterIPAddresses <string[]> [-IAcknowledgeEntCalLimits] [-Enu] [-UpdateEnabled] [-UpdateSource <string>] [-InstallSharedDir <string>] [-InstallSharedWowDir <string>] [-InstanceDir <string>] [-InstanceId <string>] [-PBEngSvcAccount <string>] [-PBEngSvcPassword <securestring>] [-PBEngSvcStartupType <string>] [-PBStartPortRange <ushort>] [-PBEndPortRange <ushort>] [-PBScaleOut] [-ProductKey <string>] [-AgtSvcAccount <string>] [-AgtSvcPassword <securestring>] [-ASBackupDir <string>] [-ASCollation <string>] [-ASConfigDir <string>] [-ASDataDir <string>] [-ASLogDir <string>] [-ASTempDir <string>] [-ASServerMode <string>] [-ASSvcAccount <string>] [-ASSvcPassword <securestring>] [-ASSvcStartupType <string>] [-ASSysAdminAccounts <string[]>] [-ASProviderMSOLAP] [-SqlBackupDir <string>] [-SecurityMode <string>] [-SAPwd <securestring>] [-SqlCollation <string>] [-SqlSvcAccount <string>] [-SqlSvcPassword <securestring>] [-SqlSvcStartupType <string>] [-SqlTempDbDir <string>] [-SqlTempDbLogDir <string>] [-SqlTempDbFileCount <ushort>] [-SqlTempDbFileSize <ushort>] [-SqlTempDbFileGrowth <ushort>] [-SqlTempDbLogFileSize <ushort>] [-SqlTempDbLogFileGrowth <ushort>] [-SqlUserDbDir <string>] [-SqlUserDbLogDir <string>] [-FileStreamLevel <ushort>] [-FileStreamShareName <string>] [-ISSvcAccount <string>] [-ISSvcPassword <securestring>] [-ISSvcStartupType <string>] [-RsInstallMode <string>] [-RSSvcAccount <string>] [-RSSvcPassword <securestring>] [-RSSvcStartupType <string>] [-FailoverClusterGroup <string>] [-FailoverClusterDisks <string[]>] [-SkipRules <string[]>] [-ProductCoveredBySA] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'PrepareFailoverCluster'
            # cSpell: disable-next
            MockExpectedParameters = '-PrepareFailoverCluster -AcceptLicensingTerms -MediaPath <string> -InstanceName <string> -Features <string[]> [-IAcknowledgeEntCalLimits] [-Enu] [-UpdateEnabled] [-UpdateSource <string>] [-InstallSharedDir <string>] [-InstallSharedWowDir <string>] [-InstanceDir <string>] [-InstanceId <string>] [-PBEngSvcAccount <string>] [-PBEngSvcPassword <securestring>] [-PBEngSvcStartupType <string>] [-PBStartPortRange <ushort>] [-PBEndPortRange <ushort>] [-PBScaleOut] [-ProductKey <string>] [-AgtSvcAccount <string>] [-AgtSvcPassword <securestring>] [-ASSvcAccount <string>] [-ASSvcPassword <securestring>] [-SqlSvcAccount <string>] [-SqlSvcPassword <securestring>] [-FileStreamLevel <ushort>] [-FileStreamShareName <string>] [-ISSvcAccount <string>] [-ISSvcPassword <securestring>] [-ISSvcStartupType <string>] [-RsInstallMode <string>] [-RSSvcAccount <string>] [-RSSvcPassword <securestring>] [-RSSvcStartupType <string>] [-ProductCoveredBySA] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
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

    Context 'When setup action is ''Install''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    Install = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case.
                    Features = 'SqlEngine', 'AZUREEXTENSION'
                    SqlSysAdminAccounts = 'DOMAIN\User', 'COMPANY\SQL Administrators'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=Install'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "COMPANY\\SQL Administrators"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE,AZUREEXTENSION'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=Install'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "COMPANY\\SQL Administrators"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE,AZUREEXTENSION'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameters PBStartPortRange and PBEndPortRange' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $installSqlDscServerParameters = @{
                    Install = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case in the value.
                    Features = 'SqlEngine'
                    SqlSysAdminAccounts = 'DOMAIN\User'
                    Force = $true
                    PBStartPortRange = 16450
                    PBEndPortRange = 16460
                }
            }

            It 'Should call the mock with the correct argument string' {
                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly 'PBPORTRANGE=16450-16460' # cspell: disable-line

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'SuppressPrivacyStatementNotice'
                MockParameterValue = $true
                MockExpectedRegEx = '\/SUPPRESSPRIVACYSTATEMENTNOTICE\s*' # cspell: disable-line
            }
            @{
                MockParameterName = 'Enu'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ENU\s*'
            }
            @{
                MockParameterName = 'UpdateEnabled'
                MockParameterValue = $true
                MockExpectedRegEx = '\/UPDATEENABLED=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'UpdateSource'
                MockParameterValue = '\SqlMedia\Updates'
                MockExpectedRegEx = '\/UPDATESOURCE="\\SqlMedia\\Updates"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstallSharedDir'
                # This value intentionally ends with a backslash to test so that it is removed.
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\'
                MockExpectedRegEx = '\/INSTALLSHAREDDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstallSharedWOWDir'
                MockParameterValue = 'C:\Program Files (x86)\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTALLSHAREDWOWDIR="C:\\Program Files \(x86\)\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceDir'
                <#
                    This value intentionally has 'D:\' to validate that the backslash
                    is not removed and that the argument is passed without double-quotes.
                #>
                MockParameterValue = 'D:\'
                MockExpectedRegEx = '\/INSTANCEDIR=D:\\' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceId'
                MockParameterValue = 'Instance'
                MockExpectedRegEx = '\/INSTANCEID="Instance"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx = '\/PBENGSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/PBENGSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/PBENGSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBDMSSvcAccount' # cspell: disable-line
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx = '\/PBDMSSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBDMSSvcPassword' # cspell: disable-line
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/PBDMSSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBDMSSvcStartupType' # cspell: disable-line
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/PBDMSSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBScaleOut'
                MockParameterValue = $true
                MockExpectedRegEx = '\/PBSCALEOUT=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'ProductKey'
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID="22222-00000-00000-00000-00000"'
            }
            @{
                MockParameterName = 'AgtSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx = '\/AGTSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AgtSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/AGTSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AgtSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/AGTSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASBackupDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Backup'
                MockExpectedRegEx = '\/ASBACKUPDIR="C:\\MSOLAP13\.INST2016\\Backup"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASConfigDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Config'
                MockExpectedRegEx = '\/ASCONFIGDIR="C:\\MSOLAP13\.INST2016\\Config"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASDataDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Data'
                MockExpectedRegEx = '\/ASDATADIR="C:\\MSOLAP13\.INST2016\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASLogDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Log'
                MockExpectedRegEx = '\/ASLOGDIR="C:\\MSOLAP13\.INST2016\\Log"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASTempDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Temp'
                MockExpectedRegEx = '\/ASTEMPDIR="C:\\MSOLAP13\.INST2016\\Temp"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASCollation'
                MockParameterValue = 'latin1_general_100'
                MockExpectedRegEx = '\/ASCOLLATION="latin1_general_100"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASServerMode'
                MockParameterValue = 'Multidimensional'
                MockExpectedRegEx = '\/ASSERVERMODE=MULTIDIMENSIONAL' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/ASSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ASSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/ASSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASSysAdminAccounts'
                MockParameterValue = 'COMPANY\SQL Administrators', 'LocalUser'
                MockExpectedRegEx = '\/ASSYSADMINACCOUNTS="COMPANY\\SQL Administrators" "LocalUser"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASProviderMSOLAP'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ASPROVIDERMSOLAP=1' # cspell: disable-line
            }
            @{
                MockParameterName = 'BrowserSvcStartupType'
                MockParameterValue = 'Manual'
                MockExpectedRegEx = '\/BROWSERSVCSTARTUPTYPE="Manual"' # cspell: disable-line
            }
            @{
                MockParameterName = 'EnableRanU'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ENABLERANU' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstallSqlDataDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/INSTALLSQLDATADIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlBackupDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Backup'
                MockExpectedRegEx = '\/SQLBACKUPDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Backup"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/SQLTEMPDBDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbLogDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/SQLTEMPDBLOGDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlUserDbDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/SQLUSERDBDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlUserDbLogDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/SQLUSERDBLOGDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SecurityMode'
                MockParameterValue = 'SQL'
                MockExpectedRegEx = '\/SECURITYMODE="SQL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SAPwd'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/SAPWD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlCollation'
                MockParameterValue = 'SQL_Latin1_General_CP1_CI_AS'
                MockExpectedRegEx = '\/SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/SQLSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/SQLSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/SQLSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbFileCount'
                MockParameterValue = 8
                MockExpectedRegEx = '\/SQLTEMPDBFILECOUNT=8' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbFileSize'
                MockParameterValue = 100
                MockExpectedRegEx = '\/SQLTEMPDBFILESIZE=100' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbFileGrowth'
                MockParameterValue = 10
                MockExpectedRegEx = '\/SQLTEMPDBFILEGROWTH=10' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbLogFileSize'
                MockParameterValue = 100
                MockExpectedRegEx = '\/SQLTEMPDBLOGFILESIZE=100' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbLogFileGrowth'
                MockParameterValue = 10
                MockExpectedRegEx = '\/SQLTEMPDBLOGFILEGROWTH=10' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcInstantFileInit'
                MockParameterValue = $true
                MockExpectedRegEx = '\/SQLSVCINSTANTFILEINIT=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlMaxDop'
                MockParameterValue = 8
                MockExpectedRegEx = '\/SQLMAXDOP=8' # cspell: disable-line
            }
            @{
                MockParameterName = 'UseSqlRecommendedMemoryLimits'
                MockParameterValue = $true
                MockExpectedRegEx = '\/USESQLRECOMMENDEDMEMORYLIMITS' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlMinMemory'
                MockParameterValue = 1000
                MockExpectedRegEx = '\/SQLMINMEMORY=1000' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlMaxMemory'
                MockParameterValue = 2147483647
                MockExpectedRegEx = '\/SQLMAXMEMORY=2147483647' # cspell: disable-line
            }
            @{
                MockParameterName = 'FileStreamLevel'
                MockParameterValue = 2
                MockExpectedRegEx = '\/FILESTREAMLEVEL=2' # cspell: disable-line
            }
            @{
                MockParameterName = 'FileStreamShareName'
                MockParameterValue = 'ShareName'
                MockExpectedRegEx = '\/FILESTREAMSHARENAME="ShareName"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/ISSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ISSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/ISSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'NpEnabled'
                MockParameterValue = $true
                MockExpectedRegEx = '\/NPENABLED=1' # cspell: disable-line
            }
            @{
                MockParameterName = 'TcpEnabled'
                MockParameterValue = $true
                MockExpectedRegEx = '\/TCPENABLED=1' # cspell: disable-line
            }
            @{
                MockParameterName = 'RsInstallMode'
                MockParameterValue = 'FilesOnlyMode'
                MockExpectedRegEx = '\/RSINSTALLMODE="FilesOnlyMode"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/RSSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/RSSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/RSSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                # Argument is reserved for future use, see SQL Server documentation.
                MockParameterName = 'MPYCacheDirectory'
                MockParameterValue = 'C:\Temp'
                MockExpectedRegEx = '\/MPYCACHEDIRECTORY="C:\\Temp"' # cspell: disable-line
            }
            @{
                MockParameterName = 'MRCacheDirectory'
                MockParameterValue = 'C:\Temp'
                MockExpectedRegEx = '\/MRCACHEDIRECTORY="C:\\Temp"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlInstJava'
                MockParameterValue = $true
                MockExpectedRegEx = '\/SQL_INST_JAVA' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlJavaDir'
                MockParameterValue = 'C:\Java'
                MockExpectedRegEx = '\/SQLJAVADIR="C:\\Java"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AzureSubscriptionId'
                MockParameterValue = '5d19794a-89a4-4f0b-8d4e-58f213ea3546'
                MockExpectedRegEx = '\/AZURESUBSCRIPTIONID="5d19794a-89a4-4f0b-8d4e-58f213ea3546"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AzureResourceGroup'
                MockParameterValue = 'MyResourceGroup'
                MockExpectedRegEx = '\/AZURERESOURCEGROUP="MyResourceGroup"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AzureRegion'
                MockParameterValue = 'West-US'
                MockExpectedRegEx = '\/AZUREREGION="West-US"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AzureTenantId'
                MockParameterValue = '5d19794a-89a4-4f0b-8d4e-58f213ea3546'
                MockExpectedRegEx = '\/AZURETENANTID="5d19794a-89a4-4f0b-8d4e-58f213ea3546"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AzureServicePrincipal'
                MockParameterValue = 'MyServicePrincipal'
                MockExpectedRegEx = '\/AZURESERVICEPRINCIPAL="MyServicePrincipal"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AzureServicePrincipalSecret'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/AZURESERVICEPRINCIPALSECRET="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AzureArcProxy'
                MockParameterValue = 'proxy.company.local'
                MockExpectedRegEx = '\/AZUREARCPROXY="proxy\.company\.local"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SkipRules'
                MockParameterValue = 'Cluster_VerifyForErrors'
                MockExpectedRegEx = '\/SKIPRULES="Cluster_VerifyForErrors"' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    Install = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case in the value.
                    Features = 'SqlEngine'
                    SqlSysAdminAccounts = 'DOMAIN\User'
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying sensitive parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'PBEngSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/PBENGSVCPASSWORD="\*{8}"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBDMSSvcPassword' # cspell: disable-line
                MockParameterValue = ('jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force) # cspell: disable-line
                MockExpectedRegEx = '\/PBDMSSVCPASSWORD="\*{8}"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ProductKey' # cspell: disable-line
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID="\*{8}"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AgtSvcPassword' # cspell: disable-line
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/AGTSVCPASSWORD="\*{8}"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SAPwd'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/SAPWD="\*{8}"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/SQLSVCPASSWORD="\*{8}"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ISSVCPASSWORD="\*{8}"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/RSSVCPASSWORD="\*{8}"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AzureServicePrincipalSecret'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/AZURESERVICEPRINCIPALSECRET="\*{8}"' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Write-Verbose
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    Install = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case in the value.
                    Features = 'SqlEngine'
                    SqlSysAdminAccounts = 'DOMAIN\User'
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should obfuscate the value in the verbose string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                # Redirect all verbose stream to $null to ge no output from ShouldProcess.
                Install-SqlDscServer @installSqlDscServerParameters -Verbose 4> $null

                $mockVerboseMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Server_SetupArguments
                }

                Should -Invoke -CommandName Write-Verbose -ParameterFilter {
                    # Only test the command that output the string that should be tested.
                    $correctMessage = $Message -match $mockVerboseMessage

                    # Only test string if it is the correct verbose command
                    if ($correctMessage)
                    {
                        $Message | Should -MatchExactly $MockExpectedRegEx
                    }

                    # Return wether the correct command was called or not.
                    $correctMessage
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When setup action is ''Upgrade''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    Upgrade = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=Upgrade'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=Upgrade'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'Enu'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ENU\s*'
            }
            @{
                MockParameterName = 'UpdateEnabled'
                MockParameterValue = $true
                MockExpectedRegEx = '\/UPDATEENABLED=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'UpdateSource'
                MockParameterValue = '\SqlMedia\Updates'
                MockExpectedRegEx = '\/UPDATESOURCE="\\SqlMedia\\Updates"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTANCEDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceId'
                MockParameterValue = 'Instance'
                MockExpectedRegEx = '\/INSTANCEID="Instance"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ProductKey'
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID="22222-00000-00000-00000-00000"'
            }
            @{
                MockParameterName = 'BrowserSvcStartupType'
                MockParameterValue = 'Manual'
                MockExpectedRegEx = '\/BROWSERSVCSTARTUPTYPE="Manual"' # cspell: disable-line
            }
            @{
                MockParameterName = 'FTUpgradeOption'
                MockParameterValue = 'Reset'
                MockExpectedRegEx = '\/FTUPGRADEOPTION="Reset"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/ISSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ISSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/ISSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AllowUpgradeForSSRSSharePointMode'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ALLOWUPGRADEFORSSRSSHAREPOINTMODE=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'FailoverClusterRollOwnership'
                MockParameterValue = 2
                MockExpectedRegEx = '\/FAILOVERCLUSTERROLLOWNERSHIP=2' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    Upgrade = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case in the value.
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When setup action is ''InstallFailoverCluster''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    InstallFailoverCluster = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case.
                    Features = 'SqlEngine'
                    SqlSysAdminAccounts = 'DOMAIN\User', 'COMPANY\SQL Administrators'
                    InstallSqlDataDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                    FailoverClusterNetworkName = 'TESTCLU01A' # cspell: disable-line
                    FailoverClusterIPAddresses = @(
                        'IPv4;172.16.0.0;ClusterNetwork1;172.31.255.255',
                        'IPv6;2001:db8:23:1002:20f:1fff:feff:b3a3;ClusterNetwork2' # cspell: disable-line
                        'IPv6;DHCP;ClusterNetwork3'
                        'IPv4;DHCP;ClusterNetwork4'
                    )
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=InstallFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "COMPANY\\SQL Administrators"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTALLSQLDATADIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FAILOVERCLUSTERNETWORKNAME="TESTCLU01A"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly ([System.Text.RegularExpressions.Regex]::Escape('/FAILOVERCLUSTERIPADDRESSES="IPv4;172.16.0.0;ClusterNetwork1;172.31.255.255" "IPv6;2001:db8:23:1002:20f:1fff:feff:b3a3;ClusterNetwork2" "IPv6;DHCP;ClusterNetwork3" "IPv4;DHCP;ClusterNetwork4"')) # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=InstallFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "COMPANY\\SQL Administrators"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTALLSQLDATADIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FAILOVERCLUSTERNETWORKNAME="TESTCLU01A"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly ([System.Text.RegularExpressions.Regex]::Escape('/FAILOVERCLUSTERIPADDRESSES="IPv4;172.16.0.0;ClusterNetwork1;172.31.255.255" "IPv6;2001:db8:23:1002:20f:1fff:feff:b3a3;ClusterNetwork2" "IPv6;DHCP;ClusterNetwork3" "IPv4;DHCP;ClusterNetwork4"')) # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameters PBStartPortRange and PBEndPortRange' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $installSqlDscServerParameters = @{
                    InstallFailoverCluster = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case in the value.
                    Features = 'SqlEngine'
                    SqlSysAdminAccounts = 'DOMAIN\User', 'COMPANY\SQL Administrators'
                    InstallSqlDataDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                    FailoverClusterNetworkName = 'TESTCLU01A' # cspell: disable-line
                    FailoverClusterIPAddresses = '192.168.0.46'
                    Force = $true
                    PBStartPortRange = 16450
                    PBEndPortRange = 16460
                }
            }

            It 'Should call the mock with the correct argument string' {
                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly 'PBPORTRANGE=16450-16460' # cspell: disable-line

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'Enu'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ENU\s*'
            }
            @{
                MockParameterName = 'UpdateEnabled'
                MockParameterValue = $true
                MockExpectedRegEx = '\/UPDATEENABLED=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'UpdateSource'
                MockParameterValue = '\SqlMedia\Updates'
                MockExpectedRegEx = '\/UPDATESOURCE="\\SqlMedia\\Updates"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstallSharedDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTALLSHAREDDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstallSharedWOWDir'
                MockParameterValue = 'C:\Program Files (x86)\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTALLSHAREDWOWDIR="C:\\Program Files \(x86\)\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTANCEDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceId'
                MockParameterValue = 'Instance'
                MockExpectedRegEx = '\/INSTANCEID="Instance"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx = '\/PBENGSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/PBENGSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/PBENGSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBScaleOut'
                MockParameterValue = $true
                MockExpectedRegEx = '\/PBSCALEOUT=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'ProductKey'
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID="22222-00000-00000-00000-00000"'
            }
            @{
                MockParameterName = 'AgtSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx = '\/AGTSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AgtSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/AGTSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASBackupDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Backup'
                MockExpectedRegEx = '\/ASBACKUPDIR="C:\\MSOLAP13\.INST2016\\Backup"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASConfigDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Config'
                MockExpectedRegEx = '\/ASCONFIGDIR="C:\\MSOLAP13\.INST2016\\Config"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASDataDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Data'
                MockExpectedRegEx = '\/ASDATADIR="C:\\MSOLAP13\.INST2016\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASLogDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Log'
                MockExpectedRegEx = '\/ASLOGDIR="C:\\MSOLAP13\.INST2016\\Log"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASTempDir'
                MockParameterValue = 'C:\MSOLAP13.INST2016\Temp'
                MockExpectedRegEx = '\/ASTEMPDIR="C:\\MSOLAP13\.INST2016\\Temp"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASCollation'
                MockParameterValue = 'latin1_general_100'
                MockExpectedRegEx = '\/ASCOLLATION="latin1_general_100"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASServerMode'
                MockParameterValue = 'Multidimensional'
                MockExpectedRegEx = '\/ASSERVERMODE=MULTIDIMENSIONAL' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/ASSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ASSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/ASSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASSysAdminAccounts'
                MockParameterValue = 'COMPANY\SQL Administrators', 'LocalUser'
                MockExpectedRegEx = '\/ASSYSADMINACCOUNTS="COMPANY\\SQL Administrators" "LocalUser"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ASProviderMSOLAP'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ASPROVIDERMSOLAP=1' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlBackupDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Backup'
                MockExpectedRegEx = '\/SQLBACKUPDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Backup"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/SQLTEMPDBDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbLogDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/SQLTEMPDBLOGDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlUserDbDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/SQLUSERDBDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlUserDbLogDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                MockExpectedRegEx = '\/SQLUSERDBLOGDIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SecurityMode'
                MockParameterValue = 'SQL'
                MockExpectedRegEx = '\/SECURITYMODE="SQL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SAPwd'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/SAPWD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlCollation'
                MockParameterValue = 'SQL_Latin1_General_CP1_CI_AS'
                MockExpectedRegEx = '\/SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/SQLSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/SQLSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/SQLSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbFileCount'
                MockParameterValue = 8
                MockExpectedRegEx = '\/SQLTEMPDBFILECOUNT=8' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbFileSize'
                MockParameterValue = 100
                MockExpectedRegEx = '\/SQLTEMPDBFILESIZE=100' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbFileGrowth'
                MockParameterValue = 10
                MockExpectedRegEx = '\/SQLTEMPDBFILEGROWTH=10' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbLogFileSize'
                MockParameterValue = 100
                MockExpectedRegEx = '\/SQLTEMPDBLOGFILESIZE=100' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlTempDbLogFileGrowth'
                MockParameterValue = 10
                MockExpectedRegEx = '\/SQLTEMPDBLOGFILEGROWTH=10' # cspell: disable-line
            }
            @{
                MockParameterName = 'FileStreamLevel'
                MockParameterValue = 2
                MockExpectedRegEx = '\/FILESTREAMLEVEL=2' # cspell: disable-line
            }
            @{
                MockParameterName = 'FileStreamShareName'
                MockParameterValue = 'ShareName'
                MockExpectedRegEx = '\/FILESTREAMSHARENAME="ShareName"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/ISSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ISSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/ISSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RsInstallMode'
                MockParameterValue = 'FilesOnlyMode'
                MockExpectedRegEx = '\/RSINSTALLMODE="FilesOnlyMode"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/RSSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/RSSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/RSSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SkipRules'
                MockParameterValue = 'Cluster_VerifyForErrors'
                MockExpectedRegEx = '\/SKIPRULES="Cluster_VerifyForErrors"' # cspell: disable-line
            }
            @{
                MockParameterName = 'FailoverClusterGroup'
                MockParameterValue = 'TESTCLU01A' # cspell: disable-line
                MockExpectedRegEx = '\/FAILOVERCLUSTERGROUP="TESTCLU01A"' # cspell: disable-line
            }
            @{
                MockParameterName = 'FailoverClusterDisks'
                # This is the failover cluster resource name.
                MockParameterValue = @(
                    'SysData'
                )
                MockExpectedRegEx = '\/FAILOVERCLUSTERDISKS="SysData"' # cspell: disable-line
            }
            @{
                MockParameterName = 'FailoverClusterDisks'
                # This is the failover cluster resource names.
                MockParameterValue = @(
                    'Backup'
                    'SysData'
                    'TempDbData'
                    'TempDbLogs'
                    'UserData'
                    'UserLogs'
                )
                MockExpectedRegEx = '\/FAILOVERCLUSTERDISKS="Backup;SysData;TempDbData;TempDbLogs;UserData;UserLogs"' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    InstallFailoverCluster = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case in the value.
                    Features = 'SqlEngine'
                    SqlSysAdminAccounts = 'DOMAIN\User', 'COMPANY\SQL Administrators'
                    InstallSqlDataDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                    FailoverClusterNetworkName = 'TESTCLU01A' # cspell: disable-line
                    FailoverClusterIPAddresses = '192.168.0.46'
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When setup action is ''PrepareFailoverCluster''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    PrepareFailoverCluster = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case.
                    Features = 'SqlEngine'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=PrepareFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=PrepareFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameters PBStartPortRange and PBEndPortRange' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $installSqlDscServerParameters = @{
                    PrepareFailoverCluster = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case in the value.
                    Features = 'SqlEngine'
                    Force = $true
                    PBStartPortRange = 16450
                    PBEndPortRange = 16460
                }
            }

            It 'Should call the mock with the correct argument string' {
                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly 'PBPORTRANGE=16450-16460' # cspell: disable-line

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'Enu'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ENU\s*'
            }
            @{
                MockParameterName = 'UpdateEnabled'
                MockParameterValue = $true
                MockExpectedRegEx = '\/UPDATEENABLED=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'UpdateSource'
                MockParameterValue = '\SqlMedia\Updates'
                MockExpectedRegEx = '\/UPDATESOURCE="\\SqlMedia\\Updates"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstallSharedDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTALLSHAREDDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstallSharedWOWDir'
                MockParameterValue = 'C:\Program Files (x86)\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTALLSHAREDWOWDIR="C:\\Program Files \(x86\)\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTANCEDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceId'
                MockParameterValue = 'Instance'
                MockExpectedRegEx = '\/INSTANCEID="Instance"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx = '\/PBENGSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/PBENGSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/PBENGSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBScaleOut'
                MockParameterValue = $true
                MockExpectedRegEx = '\/PBSCALEOUT=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'ProductKey'
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID="22222-00000-00000-00000-00000"'
            }
            @{
                MockParameterName = 'AgtSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx = '\/AGTSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AgtSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/AGTSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/ASSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ASSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/SQLSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/SQLSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'FileStreamLevel'
                MockParameterValue = 2
                MockExpectedRegEx = '\/FILESTREAMLEVEL=2' # cspell: disable-line
            }
            @{
                MockParameterName = 'FileStreamShareName'
                MockParameterValue = 'ShareName'
                MockExpectedRegEx = '\/FILESTREAMSHARENAME="ShareName"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/ISSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ISSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/ISSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RsInstallMode'
                MockParameterValue = 'FilesOnlyMode'
                MockExpectedRegEx = '\/RSINSTALLMODE="FilesOnlyMode"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcAccount'
                MockParameterValue = 'DOMAIN\ServiceAccount$'
                MockExpectedRegEx = '\/RSSVCACCOUNT="DOMAIN\\ServiceAccount\$"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/RSSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/RSSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    PrepareFailoverCluster = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    # Intentionally using both upper- and lower-case in the value.
                    Features = 'SqlEngine'
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When using a ''ConfigurationFile''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'MyConfig\.ini'
            } -MockWith {
                return $true
            }

            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    ConfigurationFile = 'C:\MyConfig.ini'
                    MediaPath = '\SqlMedia'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        # cspell: disable-next
                        $ArgumentList | Should -MatchExactly '\/CONFIGURATIONFILE="C:\\MyConfig\.ini"'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        # cspell: disable-next
                        $ArgumentList | Should -MatchExactly '\/CONFIGURATIONFILE="C:\\MyConfig\.ini"'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'AgtSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/AGTSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'AsSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ASSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'SqlSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/SQLSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'ISSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/ISSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'RSSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/RSSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    ConfigurationFile = 'C:\MyConfig.ini'
                    MediaPath = '\SqlMedia'
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When setup action is ''EditionUpgrade''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    EditionUpgrade = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    ProductKey = '22222-00000-00000-00000-00000'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=EditionUpgrade'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/PID="22222-00000-00000-00000-00000"'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=EditionUpgrade'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/PID="22222-00000-00000-00000-00000"'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'SkipRules'
                MockParameterValue = 'Cluster_VerifyForErrors'
                MockExpectedRegEx = '\/SKIPRULES="Cluster_VerifyForErrors"' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    EditionUpgrade = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    ProductKey = 22222-00000-00000-00000-00000
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When setup action is ''PrepareImage''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    PrepareImage = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    # Intentionally using both upper- and lower-case.
                    Features = 'SqlEngine'
                    InstanceId = 'Instance'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=PrepareImage'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE'
                        $ArgumentList | Should -MatchExactly '\/INSTANCEID="Instance"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=PrepareImage'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE'
                        $ArgumentList | Should -MatchExactly '\/INSTANCEID="Instance"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'Enu'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ENU\s*'
            }
            @{
                MockParameterName = 'UpdateEnabled'
                MockParameterValue = $true
                MockExpectedRegEx = '\/UPDATEENABLED=True' # cspell: disable-line
            }
            @{
                MockParameterName = 'UpdateSource'
                MockParameterValue = '\SqlMedia\Updates'
                MockExpectedRegEx = '\/UPDATESOURCE="\\SqlMedia\\Updates"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstallSharedDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTALLSHAREDDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx = '\/INSTANCEDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName = 'InstanceId'
                MockParameterValue = 'Instance'
                MockExpectedRegEx = '\/INSTANCEID="Instance"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx = '\/PBENGSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx = '\/PBENGSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBEngSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/PBENGSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName = 'PBScaleOut'
                MockParameterValue = $true
                MockExpectedRegEx = '\/PBSCALEOUT=True' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    PrepareImage = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    # Intentionally using both upper- and lower-case.
                    Features = 'SqlEngine'
                    InstanceId = 'Instance'
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When setup action is ''Install'' for installing Azure Arc Agent (parameter set InstallAzureArcAgent)' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    Install = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    AzureSubscriptionId = '5d19794a-89a4-4f0b-8d4e-58f213ea3546'
                    AzureResourceGroup = 'MyResourceGroup'
                    AzureRegion = 'West-US'
                    AzureTenantId = '7e52fb9e-6aad-426c-98c4-7d2f11f7e94b'
                    AzureServicePrincipal = 'MyServicePrincipal'
                    AzureServicePrincipalSecret = ('jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force) # cspell: disable-line
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=Install'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURESUBSCRIPTIONID="5d19794a-89a4-4f0b-8d4e-58f213ea3546"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURERESOURCEGROUP="MyResourceGroup"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZUREREGION="West-US"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURETENANTID="7e52fb9e-6aad-426c-98c4-7d2f11f7e94b"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURESERVICEPRINCIPAL="MyServicePrincipal"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURESERVICEPRINCIPALSECRET="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=AZUREEXTENSION'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=Install'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURESUBSCRIPTIONID="5d19794a-89a4-4f0b-8d4e-58f213ea3546"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURERESOURCEGROUP="MyResourceGroup"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZUREREGION="West-US"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURETENANTID="7e52fb9e-6aad-426c-98c4-7d2f11f7e94b"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURESERVICEPRINCIPAL="MyServicePrincipal"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/AZURESERVICEPRINCIPALSECRET="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=AZUREEXTENSION'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscServer -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'AzureArcProxy'
                MockParameterValue = 'proxy.company.local'
                MockExpectedRegEx = '\/AZUREARCPROXY="proxy\.company\.local"' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    Install = $true
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    AzureSubscriptionId = '5d19794a-89a4-4f0b-8d4e-58f213ea3546'
                    AzureResourceGroup = 'MyResourceGroup'
                    AzureRegion = 'West-US'
                    AzureTenantId = '7e52fb9e-6aad-426c-98c4-7d2f11f7e94b'
                    AzureServicePrincipal = 'MyServicePrincipal'
                    AzureServicePrincipalSecret = ('jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force) # cspell: disable-line
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Install-SqlDscServer @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'When parameter set is ''InstallRole''' {
        BeforeAll {
            Mock -CommandName Assert-SetupActionProperties
            Mock -CommandName Assert-ElevatedUser
            Mock -CommandName Test-Path -ParameterFilter {
                $Path -match 'setup\.exe'
            } -MockWith {
                return $true
            }
        }

        Context 'When role is ''SPI_AS_NewFarm''' {
            Context 'When specifying only mandatory parameters' {
                BeforeAll {
                    Mock -CommandName Start-SqlSetupProcess -MockWith {
                        return 0
                    }

                    $mockDefaultParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia'
                        Role = 'SPI_AS_NewFarm'
                    }
                }

                Context 'When using parameter Confirm with value $false' {
                    It 'Should call the mock with the correct argument string' {
                        Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/ACTION=Install'
                            $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                            $ArgumentList | Should -MatchExactly '\/ROLE=SPI_AS_NEWFARM' # cspell: disable-line

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When using parameter Force' {
                    It 'Should call the mock with the correct argument string' {
                        Install-SqlDscServer -Force @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/ACTION=Install'
                            $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                            $ArgumentList | Should -MatchExactly '\/ROLE=SPI_AS_NEWFARM' # cspell: disable-line

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When using parameter WhatIf' {
                    It 'Should call the mock with the correct argument string' {
                        Install-SqlDscServer -WhatIf @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
                @{
                    MockParameterName = 'FarmAccount'
                    MockParameterValue = 'DOMAIN\User'
                    MockExpectedRegEx = '\/FARMACCOUNT="DOMAIN\\User"' # cspell: disable-line
                }
                @{
                    MockParameterName = 'FarmPassword'
                    MockParameterValue = ('jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force) # cspell: disable-line
                    MockExpectedRegEx = '\/FARMPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
                }
                @{
                    MockParameterName = 'Passphrase'
                    MockParameterValue = ('jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force) # cspell: disable-line
                    MockExpectedRegEx = '\/PASSPHRASE="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
                }
                @{
                    MockParameterName = 'FarmAdminiPort' # cspell: disable-line
                    MockParameterValue = '18000'
                    MockExpectedRegEx = '\/FARMADMINIPORT=18000' # cspell: disable-line
                }
            ) {
                BeforeAll {
                    Mock -CommandName Start-SqlSetupProcess -MockWith {
                        return 0
                    }

                    $mockDefaultParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia'
                        Role = 'SPI_AS_NewFarm'
                        Force = $true
                    }
                }

                BeforeEach {
                    $installSqlDscServerParameters = $mockDefaultParameters.Clone()
                }

                It 'Should call the mock with the correct argument string' {
                    $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                    Install-SqlDscServer @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When specifying sensitive parameter <MockParameterName>' -ForEach @(
                @{
                    MockParameterName = 'FarmPassword'
                    MockParameterValue = ('jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force) # cspell: disable-line
                    MockExpectedRegEx = '\/FARMPASSWORD="\*{8}"' # cspell: disable-line
                }
                @{
                    MockParameterName = 'Passphrase'
                    MockParameterValue = ('jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force) # cspell: disable-line
                    MockExpectedRegEx = '\/PASSPHRASE="\*{8}"' # cspell: disable-line
                }
            ) {
                BeforeAll {
                    Mock -CommandName Write-Verbose
                    Mock -CommandName Start-SqlSetupProcess -MockWith {
                        return 0
                    }

                    $mockDefaultParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia'
                        Role = 'SPI_AS_NewFarm'
                        Force = $true
                    }
                }

                BeforeEach {
                    $installSqlDscServerParameters = $mockDefaultParameters.Clone()
                }

                It 'Should obfuscate the value in the verbose string' {
                    $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                    # Redirect all verbose stream to $null to ge no output from ShouldProcess.
                    Install-SqlDscServer @installSqlDscServerParameters -Verbose 4> $null

                    $mockVerboseMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.Server_SetupArguments
                    }

                    Should -Invoke -CommandName Write-Verbose -ParameterFilter {
                        # Only test the command that output the string that should be tested.
                        $correctMessage = $Message -match $mockVerboseMessage

                        # Only test string if it is the correct verbose command
                        if ($correctMessage)
                        {
                            $Message | Should -MatchExactly $MockExpectedRegEx
                        }

                        # Return wether the correct command was called or not.
                        $correctMessage
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When role is ''AllFeatures_WithDefaults''' {
            Context 'When specifying only mandatory parameters' {
                BeforeAll {
                    Mock -CommandName Start-SqlSetupProcess -MockWith {
                        return 0
                    }

                    $mockDefaultParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia'
                        Role = 'AllFeatures_WithDefaults'
                    }
                }

                Context 'When using parameter Confirm with value $false' {
                    It 'Should call the mock with the correct argument string' {
                        Install-SqlDscServer -Confirm:$false @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/ACTION=Install'
                            $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                            $ArgumentList | Should -MatchExactly '\/ROLE=ALLFEATURES_WITHDEFAULTS' # cspell: disable-line

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When using parameter Force' {
                    It 'Should call the mock with the correct argument string' {
                        Install-SqlDscServer -Force @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/ACTION=Install'
                            $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                            $ArgumentList | Should -MatchExactly '\/ROLE=ALLFEATURES_WITHDEFAULTS' # cspell: disable-line

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When using parameter WhatIf' {
                    It 'Should call the mock with the correct argument string' {
                        Install-SqlDscServer -WhatIf @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                    }
                }
            }

            Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
                @{
                    MockParameterName = 'Features' # cspell: disable-line
                    MockParameterValue = 'SqlEngine', 'RS'
                    MockExpectedRegEx = '\/FEATURES=SQLENGINE,RS' # cspell: disable-line
                }
                @{
                    MockParameterName = 'AddCurrentUserAsSqlAdmin' # cspell: disable-line
                    MockParameterValue = $true
                    MockExpectedRegEx = '\/ADDCURRENTUSERASSQLADMIN=True' # cspell: disable-line
                }
            ) {
                BeforeAll {
                    Mock -CommandName Start-SqlSetupProcess -MockWith {
                        return 0
                    }

                    $mockDefaultParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia'
                        Role = 'AllFeatures_WithDefaults'
                        Force = $true
                    }
                }

                BeforeEach {
                    $installSqlDscServerParameters = $mockDefaultParameters.Clone()
                }

                It 'Should call the mock with the correct argument string' {
                    $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                    Install-SqlDscServer @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }
        }
    }
}
