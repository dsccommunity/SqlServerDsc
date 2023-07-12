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

Describe 'Complete-SqlDscFailoverCluster' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [-InstanceName] <string> [[-ProductKey] <string>] [[-ASBackupDir] <string>] [[-ASCollation] <string>] [[-ASConfigDir] <string>] [[-ASDataDir] <string>] [[-ASLogDir] <string>] [[-ASTempDir] <string>] [[-ASServerMode] <string>] [[-ASSysAdminAccounts] <string[]>] [-InstallSqlDataDir] <string> [[-SqlBackupDir] <string>] [[-SecurityMode] <string>] [[-SAPwd] <securestring>] [[-SqlCollation] <string>] [-SqlSysAdminAccounts] <string[]> [[-SqlTempDbDir] <string>] [[-SqlTempDbLogDir] <string>] [[-SqlTempDbFileCount] <ushort>] [[-SqlTempDbFileSize] <ushort>] [[-SqlTempDbFileGrowth] <ushort>] [[-SqlTempDbLogFileSize] <ushort>] [[-SqlTempDbLogFileGrowth] <ushort>] [[-SqlUserDbDir] <string>] [[-SqlUserDbLogDir] <string>] [[-RsInstallMode] <string>] [[-FailoverClusterGroup] <string>] [[-FailoverClusterDisks] <string[]>] [-FailoverClusterNetworkName] <string> [-FailoverClusterIPAddresses] <string[]> [[-Timeout] <uint>] [-Enu] [-ASProviderMSOLAP] [-ConfirmIPDependencyChange] [-ProductCoveredBySA] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Complete-SqlDscFailoverCluster').ParameterSets |
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

    Context 'When setup action is ''CompleteFailoverCluster''' {
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
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
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
                    Complete-SqlDscFailoverCluster -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=CompleteFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "COMPANY\\SQL Administrators"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTALLSQLDATADIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
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
                    Complete-SqlDscFailoverCluster -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=CompleteFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "COMPANY\\SQL Administrators"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTALLSQLDATADIR="C:\\Program Files\\Microsoft SQL Server\\MSSQL13.INST2016\\MSSQL\\Data"' # cspell: disable-line
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
                    Complete-SqlDscFailoverCluster -WhatIf @mockDefaultParameters

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
                MockParameterName = 'ProductKey'
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID="22222-00000-00000-00000-00000"'
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
                MockParameterName = 'RsInstallMode'
                MockParameterValue = 'FilesOnlyMode'
                MockExpectedRegEx = '\/RSINSTALLMODE="FilesOnlyMode"' # cspell: disable-line
            }
            @{
                MockParameterName = 'FailoverClusterGroup'
                MockParameterValue = 'TESTCLU01A' # cspell: disable-line
                MockExpectedRegEx = '\/FAILOVERCLUSTERGROUP="TESTCLU01A"' # cspell: disable-line
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
            @{
                MockParameterName = 'ConfirmIPDependencyChange'
                MockParameterValue = $true
                MockExpectedRegEx = '\/CONFIRMIPDEPENDENCYCHANGE=1' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    SqlSysAdminAccounts = 'DOMAIN\User', 'COMPANY\SQL Administrators'
                    InstallSqlDataDir = 'C:\Program Files\Microsoft SQL Server\MSSQL13.INST2016\MSSQL\Data'
                    FailoverClusterNetworkName = 'TESTCLU01A' # cspell: disable-line
                    FailoverClusterIPAddresses = @(
                        'IPv4;172.16.0.0;ClusterNetwork1;172.31.255.255',
                        'IPv6;2001:db8:23:1002:20f:1fff:feff:b3a3;ClusterNetwork2' # cspell: disable-line
                        'IPv6;DHCP;ClusterNetwork3'
                        'IPv4;DHCP;ClusterNetwork4'
                    )
                    Force = $true
                }
            }

            BeforeEach {
                $completeSqlDscFailoverClusterParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $completeSqlDscFailoverClusterParameters.$MockParameterName = $MockParameterValue

                Complete-SqlDscFailoverCluster @completeSqlDscFailoverClusterParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
