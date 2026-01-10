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

Describe 'Initialize-SqlDscFailoverCluster' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [-InstanceName] <string> [-Features] <string[]> [[-UpdateSource] <string>] [[-InstallSharedDir] <string>] [[-InstallSharedWowDir] <string>] [[-InstanceDir] <string>] [[-InstanceId] <string>] [[-PBEngSvcAccount] <string>] [[-PBEngSvcPassword] <securestring>] [[-PBEngSvcStartupType] <string>] [[-PBStartPortRange] <ushort>] [[-PBEndPortRange] <ushort>] [[-ProductKey] <string>] [[-AgtSvcAccount] <string>] [[-AgtSvcPassword] <securestring>] [[-ASSvcAccount] <string>] [[-ASSvcPassword] <securestring>] [[-SqlSvcAccount] <string>] [[-SqlSvcPassword] <securestring>] [[-FileStreamLevel] <ushort>] [[-FileStreamShareName] <string>] [[-ISSvcAccount] <string>] [[-ISSvcPassword] <securestring>] [[-ISSvcStartupType] <string>] [[-RsInstallMode] <string>] [[-RSSvcAccount] <string>] [[-RSSvcPassword] <securestring>] [[-RSSvcStartupType] <string>] [[-Timeout] <uint>] -AcceptLicensingTerms [-IAcknowledgeEntCalLimits] [-Enu] [-UpdateEnabled] [-PBScaleOut] [-ProductCoveredBySA] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Initialize-SqlDscFailoverCluster').ParameterSets |
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
                    AcceptLicensingTerms = $true
                    MediaPath            = '\SqlMedia'
                    InstanceName         = 'MSSQLSERVER'
                    Features             = 'SQLENGINE'
                    Force                = $true
                    ErrorAction          = 'Stop'
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscFailoverCluster -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=PrepareFailoverCluster'
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="MSSQLSERVER"' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/FEATURES=SQLENGINE'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscFailoverCluster -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=PrepareFailoverCluster'

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Initialize-SqlDscFailoverCluster -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName  = 'Enu'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/ENU\s*'
            }
            @{
                MockParameterName  = 'UpdateEnabled'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/UPDATEENABLED=True'
            }
            @{
                MockParameterName  = 'UpdateSource'
                MockParameterValue = 'C:\Updates'
                MockExpectedRegEx  = '\/UPDATESOURCE="C:\\Updates"'
            }
            @{
                MockParameterName  = 'InstallSharedDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx  = '\/INSTALLSHAREDDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'InstallSharedWowDir'
                MockParameterValue = 'C:\Program Files (x86)\Microsoft SQL Server'
                MockExpectedRegEx  = '\/INSTALLSHAREDWOWDIR="C:\\Program Files \(x86\)\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'InstanceDir'
                MockParameterValue = 'C:\Program Files\Microsoft SQL Server'
                MockExpectedRegEx  = '\/INSTANCEDIR="C:\\Program Files\\Microsoft SQL Server"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'InstanceId'
                MockParameterValue = 'INSTANCE'
                MockExpectedRegEx  = '\/INSTANCEID="INSTANCE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'PBEngSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx  = '\/PBENGSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'PBEngSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx  = '\/PBENGSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'PBEngSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx  = '\/PBENGSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'PBScaleOut'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/PBSCALEOUT=True' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ProductKey'
                MockParameterValue = '12345-12345-12345-12345-12345'
                MockExpectedRegEx  = '\/PID="12345-12345-12345-12345-12345"'
            }
            @{
                MockParameterName  = 'AgtSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx  = '\/AGTSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'AgtSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx  = '\/AGTSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ASSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx  = '\/ASSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ASSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx  = '\/ASSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'SqlSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx  = '\/SQLSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'SqlSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx  = '\/SQLSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'FileStreamLevel'
                MockParameterValue = 2
                MockExpectedRegEx  = '\/FILESTREAMLEVEL=2' # cspell: disable-line
            }
            @{
                MockParameterName  = 'FileStreamShareName'
                MockParameterValue = 'MyShare'
                MockExpectedRegEx  = '\/FILESTREAMSHARENAME="MyShare"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ISSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx  = '\/ISSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ISSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx  = '\/ISSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ISSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx  = '\/ISSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'RsInstallMode'
                MockParameterValue = 'DefaultNativeMode'
                MockExpectedRegEx  = '\/RSINSTALLMODE="DefaultNativeMode"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'RSSvcAccount'
                MockParameterValue = 'NT Authority\NETWORK SERVICE'
                MockExpectedRegEx  = '\/RSSVCACCOUNT="NT Authority\\NETWORK SERVICE"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'RSSvcPassword'
                MockParameterValue = 'jT7ELPbD2GGuvLmjABDL' | ConvertTo-SecureString -AsPlainText -Force # cspell: disable-line
                MockExpectedRegEx  = '\/RSSVCPASSWORD="jT7ELPbD2GGuvLmjABDL"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'RSSvcStartupType'
                MockParameterValue = 'Automatic'
                MockExpectedRegEx  = '\/RSSVCSTARTUPTYPE="Automatic"' # cspell: disable-line
            }
            @{
                MockParameterName  = 'ProductCoveredBySA'
                MockParameterValue = $true
                MockExpectedRegEx  = '\/PRODUCTCOVEREDBYSA\b' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $initializeSqlDscFailoverClusterParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath            = '\SqlMedia'
                    InstanceName         = 'MSSQLSERVER'
                    Features             = 'SQLENGINE'
                    Force                = $true
                }
            }

            It 'Should call the mock with the correct argument string' {
                $initializeSqlDscFailoverClusterParameters.$MockParameterName = $MockParameterValue

                Initialize-SqlDscFailoverCluster @initializeSqlDscFailoverClusterParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
