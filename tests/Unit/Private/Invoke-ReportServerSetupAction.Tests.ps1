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

    # Adding these mocks to handle the ValidateScript blocks
    Mock -CommandName Test-Path -ParameterFilter {
        $Path -match 'setup\.exe'
    } -MockWith {
        return $true
    }

    Mock -CommandName Test-Path -ParameterFilter {
        $PathType -eq 'Container'
    } -MockWith {
        return $true
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Invoke-ReportServerSetupAction' -Tag 'Private' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = 'Install'
            # cSpell: disable-next
            MockExpectedParameters = '-Install -AcceptLicensingTerms -MediaPath <string> [-ProductKey <string>] [-EditionUpgrade] [-Edition <string>] [-LogPath <string>] [-InstallFolder <string>] [-SuppressRestart] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'Uninstall'
            # cSpell: disable-next
            MockExpectedParameters = '-Uninstall -MediaPath <string> [-LogPath <string>] [-SuppressRestart] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'Repair'
            # cSpell: disable-next
            MockExpectedParameters = '-Repair -AcceptLicensingTerms -MediaPath <string> [-ProductKey <string>] [-EditionUpgrade] [-Edition <string>] [-LogPath <string>] [-InstallFolder <string>] [-SuppressRestart] [-Timeout <uint>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            $result = (Get-Command -Name 'Invoke-ReportServerSetupAction').ParameterSets |
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

    Context 'When passing no existent path to parameter MediaPath' {
        BeforeAll {
            Mock -CommandName Assert-ElevatedUser

            InModuleScope -ScriptBlock {
                $script:mockDefaultParameters = @{
                    Install = $true
                    AcceptLicensingTerms = $true
                    # Invalid path to test error handling
                    MediaPath = $TestDrive
                    Force = $true
                }
            }
        }

        It 'Should throw an error when the MediaPath does not exist' {
            InModuleScope -ScriptBlock {
                { Invoke-ReportServerSetupAction @mockDefaultParameters } |
                    Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'MediaPath'. The specified executable does not exist."
            }
        }
    }

    Context 'When passing no existent path to parameter InstallFolder' {
        BeforeAll {
            Mock -CommandName Assert-ElevatedUser

            # Create the file "$TestDrive/ssrs.exe"
            New-Item -Path "$TestDrive/ssrs.exe" -ItemType File -Force | Out-Null

            InModuleScope -ScriptBlock {
                $script:mockDefaultParameters = @{
                    Install = $true
                    AcceptLicensingTerms = $true
                    MediaPath = "$TestDrive/ssrs.exe"
                    # Invalid path to test error handling
                    InstallFolder = "$TestDrive/MissingFolder2/SSRS"
                    Force = $true
                }
            }
        }

        It 'Should throw an error when the InstallFolder does not exist' {
            InModuleScope -ScriptBlock {
                { Invoke-ReportServerSetupAction @mockDefaultParameters } |
                    Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'InstallFolder'. The parent of the specified install folder does not exist."
            }
        }
    }

    Context 'When setup action is ''Install''' {
        BeforeAll {
            Mock -CommandName Assert-ElevatedUser
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                InModuleScope -ScriptBlock {
                    $script:mockDefaultParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                    }
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -Confirm:$false @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/quiet \/IAcceptLicenseTerms'

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -Force @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/quiet \/IAcceptLicenseTerms'

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -WhatIf @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                    }
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'ProductKey'
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID=22222-00000-00000-00000-00000'
            }
            @{
                MockParameterName = 'Edition'
                MockParameterValue = 'Evaluation'
                MockExpectedRegEx = '\/Edition=Eval'
            }
            @{
                MockParameterName = 'LogPath'
                MockParameterValue = 'C:\Temp\Log.txt'
                MockExpectedRegEx = '\/log "C:\\Temp\\Log\.txt"'
            }
            @{
                MockParameterName = 'InstallFolder'
                MockParameterValue = 'C:\Program Files\ReportServer'
                MockExpectedRegEx = '\/InstallFolder="C:\\Program Files\\ReportServer"'
            }
            @{
                MockParameterName = 'SuppressRestart'
                MockParameterValue = $true
                MockExpectedRegEx = '\/norestart'
            }
        ) {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                InModuleScope -ScriptBlock {
                    $script:mockDefaultParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:installSqlDscServerParameters = $mockDefaultParameters.Clone()
                }
            }

            It 'Should call the mock with the correct argument string' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                    Invoke-ReportServerSetupAction @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter EditionUpgrade' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'
            }

            It 'Should throw the correct error message when missing either parameter Edition or ProductKey' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                        EditionUpgrade = $true
                    }

                    { Invoke-ReportServerSetupAction @installSqlDscServerParameters } |
                        Should -Throw -ErrorId 'ARCP0002,Assert-RequiredCommandParameter'
                }
            }

            It 'Should require the parameter Edition' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                        EditionUpgrade = $true
                        Edition = 'Evaluation'
                    }

                    Invoke-ReportServerSetupAction @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                }
            }

            It 'Should require the parameter ProductKey' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                        EditionUpgrade = $true
                        ProductKey = '22222-00000-00000-00000-00000'
                    }

                    Invoke-ReportServerSetupAction @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When specifying sensitive parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'ProductKey' # cspell: disable-line
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID=\*{8}' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Write-Verbose
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                InModuleScope -ScriptBlock {
                    $script:mockDefaultParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:installSqlDscServerParameters = $mockDefaultParameters.Clone()
                }
            }

            It 'Should obfuscate the value in the verbose string' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                    # Redirect all verbose stream to $null to ge no output from ShouldProcess.
                    Invoke-ReportServerSetupAction @installSqlDscServerParameters -Verbose 4> $null

                    $mockVerboseMessage = $script:localizedData.ReportServerSetupAction_SetupArguments

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
    }

    Context 'When setup action is ''Uninstall''' {
        BeforeAll {
            Mock -CommandName Assert-ElevatedUser
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                InModuleScope -ScriptBlock {
                    $script:mockDefaultParameters = @{
                        Uninstall = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                    }
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -Confirm:$false @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/quiet \/IAcceptLicenseTerms \/uninstall'

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -Force @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/quiet \/IAcceptLicenseTerms \/uninstall'

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -WhatIf @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                    }
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'LogPath'
                MockParameterValue = 'C:\Temp\Log.txt'
                MockExpectedRegEx = '\/log "C:\\Temp\\Log\.txt"'
            }
        ) {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                InModuleScope -ScriptBlock {
                    $script:mockDefaultParameters = @{
                        Uninstall = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:installSqlDscServerParameters = $mockDefaultParameters.Clone()
                }
            }

            It 'Should call the mock with the correct argument string' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                    Invoke-ReportServerSetupAction @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }
        }
    }

    Context 'When setup action is ''Repair''' {
        BeforeAll {
            Mock -CommandName Assert-ElevatedUser
        }

        Context 'When specifying only mandatory parameters' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                InModuleScope -ScriptBlock {
                    $script:mockDefaultParameters = @{
                        Repair = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                    }
                }
            }

            Context 'When using parameter Confirm with value $false' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -Confirm:$false @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/quiet \/IAcceptLicenseTerms \/repair'

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When using parameter Force' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -Force @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $ArgumentList | Should -MatchExactly '\/quiet \/IAcceptLicenseTerms \/repair'

                            # Return $true if none of the above throw.
                            $true
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When using parameter WhatIf' {
                It 'Should call the mock with the correct argument string' {
                    InModuleScope -ScriptBlock {
                        Invoke-ReportServerSetupAction -WhatIf @mockDefaultParameters

                        Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 0 -Scope It
                    }
                }
            }
        }

        Context 'When specifying optional parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'ProductKey'
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID=22222-00000-00000-00000-00000'
            }
            @{
                MockParameterName = 'Edition'
                MockParameterValue = 'Evaluation'
                MockExpectedRegEx = '\/Edition=Eval'
            }
            @{
                MockParameterName = 'LogPath'
                MockParameterValue = 'C:\Temp\Log.txt'
                MockExpectedRegEx = '\/log "C:\\Temp\\Log\.txt"'
            }
            @{
                MockParameterName = 'InstallFolder'
                MockParameterValue = 'C:\Program Files\ReportServer'
                MockExpectedRegEx = '\/InstallFolder="C:\\Program Files\\ReportServer"'
            }
        ) {
            BeforeAll {
                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                InModuleScope -ScriptBlock {
                    $script:mockDefaultParameters = @{
                        Repair = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:installSqlDscServerParameters = $mockDefaultParameters.Clone()
                }
            }

            It 'Should call the mock with the correct argument string' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                    Invoke-ReportServerSetupAction @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $ArgumentList | Should -MatchExactly $MockExpectedRegEx

                        # Return $true if none of the above throw.
                        $true
                    } -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When specifying optional parameter EditionUpgrade' {
            BeforeAll {
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'
            }

            It 'Should throw the correct error message when missing either parameter Edition or ProductKey' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters = @{
                        Repair = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                        EditionUpgrade = $true
                    }

                    { Invoke-ReportServerSetupAction @installSqlDscServerParameters } |
                        Should -Throw -ErrorId 'ARCP0002,Assert-RequiredCommandParameter'
                }
            }

            It 'Should require the parameter Edition' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters = @{
                        Repair = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                        EditionUpgrade = $true
                        Edition = 'Evaluation'
                    }

                    Invoke-ReportServerSetupAction @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                }
            }

            It 'Should require the parameter ProductKey' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters = @{
                        Repair = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                        EditionUpgrade = $true
                        ProductKey = '22222-00000-00000-00000-00000'
                    }

                    Invoke-ReportServerSetupAction @installSqlDscServerParameters

                    Should -Invoke -CommandName Start-SqlSetupProcess -Exactly -Times 1 -Scope It
                }
            }
        }

        Context 'When specifying sensitive parameter <MockParameterName>' -ForEach @(
            @{
                MockParameterName = 'ProductKey' # cspell: disable-line
                MockParameterValue = '22222-00000-00000-00000-00000'
                MockExpectedRegEx = '\/PID=\*{8}' # cspell: disable-line
            }
        ) {
            BeforeAll {
                Mock -CommandName Write-Verbose
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    return 0
                } -RemoveParameterValidation 'FilePath'

                InModuleScope -ScriptBlock {
                    $script:mockDefaultParameters = @{
                        Repair = $true
                        AcceptLicensingTerms = $true
                        MediaPath = '\SqlMedia\setup.exe' # Added setup.exe to match the Test-Path mock
                        Force = $true
                    }
                }
            }

            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:installSqlDscServerParameters = $mockDefaultParameters.Clone()
                }
            }

            It 'Should obfuscate the value in the verbose string' {
                InModuleScope -Parameters $_ -ScriptBlock {
                    $installSqlDscServerParameters.$MockParameterName = $MockParameterValue

                    # Redirect all verbose stream to $null to ge no output from ShouldProcess.
                    Invoke-ReportServerSetupAction @installSqlDscServerParameters -Verbose 4> $null

                    $mockVerboseMessage = $script:localizedData.ReportServerSetupAction_SetupArguments

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
    }
}
