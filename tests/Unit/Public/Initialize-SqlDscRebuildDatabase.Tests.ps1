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

Describe 'Initialize-SqlDscRebuildDatabase' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [-InstanceName] <string> [[-SAPwd] <securestring>] [[-SqlCollation] <string>] [-SqlSysAdminAccounts] <string[]> [[-SqlTempDbDir] <string>] [[-SqlTempDbLogDir] <string>] [[-SqlTempDbFileCount] <ushort>] [[-SqlTempDbFileSize] <ushort>] [[-SqlTempDbFileGrowth] <ushort>] [[-SqlTempDbLogFileSize] <ushort>] [[-SqlTempDbLogFileGrowth] <ushort>] [[-Timeout] <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Initialize-SqlDscRebuildDatabase').ParameterSets |
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

    Context 'When setup action is ''RebuildDatabase''' {
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
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscRebuildDatabase -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=RebuildDatabase'
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "COMPANY\\SQL Administrators"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscRebuildDatabase -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=RebuildDatabase'
                        $ArgumentList | Should -MatchExactly '\/SQLSYSADMINACCOUNTS="DOMAIN\\User" "COMPANY\\SQL Administrators"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscRebuildDatabase -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
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
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $mockDefaultParameters = @{
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    SqlSysAdminAccounts = 'DOMAIN\User'
                    Force = $true
                }
            }

            BeforeEach {
                $installSqlDscServerParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                Initialize-SqlDscRebuildDatabase @installSqlDscServerParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
