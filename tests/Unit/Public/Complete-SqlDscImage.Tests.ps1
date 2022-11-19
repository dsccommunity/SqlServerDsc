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

Describe 'Complete-SqlDscImage' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [[-InstanceName] <string>] [[-InstanceId] <string>] [[-PBEngSvcAccount] <string>] [[-PBEngSvcPassword] <securestring>] [[-PBEngSvcStartupType] <string>] [[-PBStartPortRange] <ushort>] [[-PBEndPortRange] <ushort>] [[-ProductKey] <string>] [[-AgtSvcAccount] <string>] [[-AgtSvcPassword] <securestring>] [[-AgtSvcStartupType] <string>] [[-BrowserSvcStartupType] <string>] [[-InstallSqlDataDir] <string>] [[-SqlBackupDir] <string>] [[-SecurityMode] <string>] [[-SAPwd] <securestring>] [[-SqlCollation] <string>] [[-SqlSvcAccount] <string>] [[-SqlSvcPassword] <securestring>] [[-SqlSvcStartupType] <string>] [[-SqlSysAdminAccounts] <string[]>] [[-SqlTempDbDir] <string>] [[-SqlTempDbLogDir] <string>] [[-SqlTempDbFileCount] <ushort>] [[-SqlTempDbFileSize] <ushort>] [[-SqlTempDbFileGrowth] <ushort>] [[-SqlTempDbLogFileSize] <ushort>] [[-SqlTempDbLogFileGrowth] <ushort>] [[-SqlUserDbDir] <string>] [[-SqlUserDbLogDir] <string>] [[-FileStreamLevel] <ushort>] [[-FileStreamShareName] <string>] [[-RsInstallMode] <string>] [[-RSSvcAccount] <string>] [[-RSSvcPassword] <securestring>] [[-RSSvcStartupType] <string>] [[-Timeout] <uint>] -AcceptLicensingTerms [-Enu] [-PBScaleOut] [-EnableRanU] [-NpEnabled] [-TcpEnabled] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Complete-SqlDscImage').ParameterSets |
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

    Context 'When setup action is ''CompleteImage''' {
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
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Complete-SqlDscImage -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=CompleteImage'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Complete-SqlDscImage -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=CompleteImage'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Complete-SqlDscImage -WhatIf @mockDefaultParameters

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
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    Force = $true
                    PBStartPortRange = 16450
                    PBEndPortRange = 16460
                }
            }

            It 'Should call the mock with the correct argument string' {
                Complete-SqlDscImage @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly 'PBPORTRANGE=16450-16460' # cspell: disable-line

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'InstanceName'
                MockParameterValue = 'INSTANCE'
                MockExpectedRegEx = '\/INSTANCENAME="INSTANCE"*' # cspell: disable-line
            }
            @{
                MockParameterName = 'Enu'
                MockParameterValue = $true
                MockExpectedRegEx = '\/ENU\s*'
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
                MockParameterName = 'AgtSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx = '\/AGTSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
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
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Complete-SqlDscImage @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
