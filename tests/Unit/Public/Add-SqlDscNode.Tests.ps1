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

Describe 'Add-SqlDscNode' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-MediaPath] <string> [-InstanceName] <string> [[-UpdateSource] <string>] [[-PBEngSvcAccount] <string>] [[-PBEngSvcPassword] <securestring>] [[-PBEngSvcStartupType] <string>] [[-PBStartPortRange] <ushort>] [[-PBEndPortRange] <ushort>] [[-ProductKey] <string>] [[-AgtSvcAccount] <string>] [[-AgtSvcPassword] <securestring>] [[-ASSvcAccount] <string>] [[-ASSvcPassword] <securestring>] [[-SqlSvcAccount] <string>] [[-SqlSvcPassword] <securestring>] [[-ISSvcAccount] <string>] [[-ISSvcPassword] <securestring>] [[-RsInstallMode] <string>] [[-RSSvcAccount] <string>] [[-RSSvcPassword] <securestring>] [-FailoverClusterIPAddresses] <string[]> [[-Timeout] <uint>] -AcceptLicensingTerms [-IAcknowledgeEntCalLimits] [-Enu] [-UpdateEnabled] [-PBScaleOut] [-ConfirmIPDependencyChange] [-ProductCoveredBySA] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Add-SqlDscNode').ParameterSets |
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

    Context 'When setup action is ''AddNode''' {
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
                    InstanceName = 'INSTANCE'
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
                    Add-SqlDscNode -Confirm:$false @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=AddNode'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    Add-SqlDscNode -Force @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly '\/ACTION=AddNode'
                        $ArgumentList | Should -MatchExactly '\/IACCEPTSQLSERVERLICENSETERMS' # cspell: disable-line
                        $ArgumentList | Should -MatchExactly '\/INSTANCENAME="INSTANCE"' # cspell: disable-line

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    Add-SqlDscNode -WhatIf @mockDefaultParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When specifying optional parameters PBStartPortRange and PBEndPortRange' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                $addSqlDscNodeParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
                    FailoverClusterIPAddresses = @(
                        'IPv4;172.16.0.0;ClusterNetwork1;172.31.255.255',
                        'IPv6;2001:db8:23:1002:20f:1fff:feff:b3a3;ClusterNetwork2' # cspell: disable-line
                        'IPv6;DHCP;ClusterNetwork3'
                        'IPv4;DHCP;ClusterNetwork4'
                    )
                    Force = $true
                    PBStartPortRange = 16450
                    PBEndPortRange = 16460
                }
            }

            It 'Should call the mock with the correct argument string' {
                Add-SqlDscNode @addSqlDscNodeParameters

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
                MockParameterName = 'RsInstallMode'
                MockParameterValue = 'FilesOnlyMode'
                MockExpectedRegEx = '\/RSINSTALLMODE="FilesOnlyMode"' # cspell: disable-line
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
                    AcceptLicensingTerms = $true
                    MediaPath = '\SqlMedia'
                    InstanceName = 'INSTANCE'
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
                $addSqlDscNodeParameters = $mockDefaultParameters.Clone()
            }

            It 'Should call the mock with the correct argument string' {
                $addSqlDscNodeParameters.$MockParameterName = $MockParameterValue

                Add-SqlDscNode @addSqlDscNodeParameters

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                    # Return $true if none of the above throw.
                    $true
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}
