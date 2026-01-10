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

Describe 'Install-SqlDscFailoverCluster' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [-InstanceName] <string> [-Features] <string[]> [-InstallSqlDataDir] <string> [-SqlSysAdminAccounts] <string[]> [-FailoverClusterNetworkName] <string> [-FailoverClusterIPAddresses] <string[]> [[-UpdateSource] <string>] [[-InstallSharedDir] <string>] [[-InstallSharedWowDir] <string>] [[-InstanceDir] <string>] [[-InstanceId] <string>] [[-PBEngSvcAccount] <string>] [[-PBEngSvcPassword] <securestring>] [[-PBEngSvcStartupType] <string>] [[-PBStartPortRange] <ushort>] [[-PBEndPortRange] <ushort>] [[-ProductKey] <string>] [[-AgtSvcAccount] <string>] [[-AgtSvcPassword] <securestring>] [[-ASBackupDir] <string>] [[-ASCollation] <string>] [[-ASConfigDir] <string>] [[-ASDataDir] <string>] [[-ASLogDir] <string>] [[-ASTempDir] <string>] [[-ASServerMode] <string>] [[-ASSvcAccount] <string>] [[-ASSvcPassword] <securestring>] [[-ASSvcStartupType] <string>] [[-ASSysAdminAccounts] <string[]>] [[-SqlBackupDir] <string>] [[-SecurityMode] <string>] [[-SAPwd] <securestring>] [[-SqlCollation] <string>] [[-SqlSvcAccount] <string>] [[-SqlSvcPassword] <securestring>] [[-SqlSvcStartupType] <string>] [[-SqlTempDbDir] <string>] [[-SqlTempDbLogDir] <string>] [[-SqlTempDbFileCount] <ushort>] [[-SqlTempDbFileSize] <ushort>] [[-SqlTempDbFileGrowth] <ushort>] [[-SqlTempDbLogFileSize] <ushort>] [[-SqlTempDbLogFileGrowth] <ushort>] [[-SqlUserDbDir] <string>] [[-SqlUserDbLogDir] <string>] [[-FileStreamLevel] <ushort>] [[-FileStreamShareName] <string>] [[-ISSvcAccount] <string>] [[-ISSvcPassword] <securestring>] [[-ISSvcStartupType] <string>] [[-RsInstallMode] <string>] [[-RSSvcAccount] <string>] [[-RSSvcPassword] <securestring>] [[-RSSvcStartupType] <string>] [[-FailoverClusterGroup] <string>] [[-FailoverClusterDisks] <string[]>] [[-SkipRules] <string[]>] [[-Timeout] <uint>] -AcceptLicensingTerms [-IAcknowledgeEntCalLimits] [-Enu] [-UpdateEnabled] [-PBScaleOut] [-ASProviderMSOLAP] [-ProductCoveredBySA] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Install-SqlDscFailoverCluster').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name       = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name       = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
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
                    AcceptLicensingTerms         = $true
                    MediaPath                    = '\SqlMedia'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    InstallSqlDataDir            = 'C:\Program Files\Microsoft SQL Server'
                    SqlSysAdminAccounts          = 'DOMAIN\User', 'DOMAIN\SQLAdmins'
                    FailoverClusterNetworkName   = 'TestCluster01A'
                    FailoverClusterIPAddresses   = 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0'
                    Force                        = $true
                    ErrorAction                  = 'Stop'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscFailoverCluster -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=InstallFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="MSSQLSERVER"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE'
                        $ArgumentList | Should -MatchExactly '\/INSTALLSQLDATADIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "DOMAIN\\SQLAdmins"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FAILOVERCLUSTERNETWORKNAME="TestCluster01A"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FAILOVERCLUSTERIPADDRESSES="IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscFailoverCluster -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=InstallFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="MSSQLSERVER"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Install-SqlDscFailoverCluster -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    AcceptLicensingTerms         = $true
                    MediaPath                    = '\SqlMedia'
                    InstanceName                 = 'MSSQLSERVER'
                    Features                     = 'SQLENGINE'
                    InstallSqlDataDir            = 'C:\Program Files\Microsoft SQL Server'
                    SqlSysAdminAccounts          = 'DOMAIN\User'
                    FailoverClusterNetworkName   = 'TestCluster01A'
                    FailoverClusterIPAddresses   = 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0'
                    FailoverClusterGroup         = 'SQL Server (MSSQLSERVER)'
                    FailoverClusterDisks         = 'SysData', 'UserData', 'UserLogs'
                    Force                        = $true
                    ErrorAction                  = 'Stop'
                }
            }

            It 'Should call the mock with the correct argument string' {
                Install-SqlDscFailoverCluster @mockDefaultParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly '\/ACTION=InstallFailoverCluster'
                    $ArgumentList | Should -MatchExactly '\/FAILOVERCLUSTERGROUP="SQL Server \(MSSQLSERVER\)"' # cspell: disable-line
                    $ArgumentList | Should -MatchExactly '\/FAILOVERCLUSTERDISKS="SysData;UserData;UserLogs"' # cspell: disable-line

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
