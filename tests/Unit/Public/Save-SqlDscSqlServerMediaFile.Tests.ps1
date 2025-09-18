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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

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

Describe 'Save-SqlDscSqlServerMediaFile' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-Url] <string> [-DestinationPath] <FileInfo> [[-FileName] <string>] [[-Language] <string>] [-Quiet] [-Force] [-SkipExecution] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Save-SqlDscSqlServerMediaFile').ParameterSets |
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

    BeforeAll {
        # Mock the Invoke-WebRequest cmdlet to prevent actual downloads during testing
        Mock -CommandName Invoke-WebRequest

        # Mock the Start-Process cmdlet to prevent actual process execution during testing
        Mock -CommandName  Start-Process

        # Mock the Remove-Item cmdlet to prevent actual file deletion during testing
        Mock -CommandName  Remove-Item

        # Mock the Rename-Item cmdlet to prevent actual file renaming during testing
        Mock -CommandName  Rename-Item

        <#
            Mock the Get-Item cmdlet to simulate both that there is no presence
            of a file in the destination path (Count property), and then that we
            successfully downloaded a file to the destination path (FullName property).
        #>
        Mock -CommandName  Get-Item -MockWith {
            return @{
                Count = 0
                FullName = 'C:\Temp\media.iso'
            }
        }

        # Define parameters for the function
        $Url = 'http://example.com/media.iso'
        $DestinationPath = $TestDrive
    }

    Context 'When the URL does not end with .exe' {
        It 'Should call Invoke-WebRequest to download the media file' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the URL ends with .exe' {
        BeforeAll {
            $Url = "$Url.exe"

            Mock -CommandName Test-Path -MockWith {
                return $false
            } -ParameterFilter {
                $Path -eq (Join-Path -Path $DestinationPath -ChildPath 'media.iso')
            }
        }

        It 'Should call Invoke-WebRequest to download the executable file' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1 -Scope It
        }

        It 'Should call Start-Process to initiate download using the downloaded executable file' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should call Remove-Item to remove the executable file' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
        }

        It 'Should call Rename-Item to rename the downloaded ISO file to the specified name' {
            Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false

            Should -Invoke -CommandName Rename-Item -Exactly -Times 1 -Scope It
        }
    }

    Context 'When file is already present and should be overridden' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            } -ParameterFilter {
                $Path -eq (Join-Path -Path $DestinationPath -ChildPath 'media.iso')
            }
        }

        It 'Should remove the existing file' {
            Mock -CommandName Invoke-WebRequest
            Mock -CommandName Remove-Item

            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.iso' -DestinationPath $TestDrive -Force

            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-Item -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the Force parameter is used' {
        It 'Should force the download of the media file' {
            Mock -CommandName Invoke-WebRequest

            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.iso' -DestinationPath $TestDrive -Force

            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the Quiet parameter is used' {
        It 'Should download the media file silently' {
            Mock -CommandName Invoke-WebRequest

            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.iso' -DestinationPath $TestDrive -Quiet  -Confirm:$false

            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the Language parameter is used' {
        It 'Should download the media file in the specified language' {
            Mock -CommandName Invoke-WebRequest
            Mock -CommandName Start-Process

            Save-SqlDscSqlServerMediaFile -Url 'https://example.com/media.exe' -DestinationPath $TestDrive -Language 'fr-FR'  -Confirm:$false

            Should -Invoke -CommandName Invoke-WebRequest -Times 1 -Exactly
            Should -Invoke -CommandName Start-Process -Times 1 -Exactly
        }
    }

    Context 'When there is already an ISO file in the destination path' {
        BeforeAll {
            Mock -CommandName Get-Item -MockWith {
                return @{
                    Count = 1
                }
            }
        }

        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.SqlServerMediaFile_Save_InvalidDestinationFolder
            }

            { Save-SqlDscSqlServerMediaFile -Url $Url -DestinationPath $DestinationPath -Confirm:$false } | Should -Throw $mockErrorMessage
        }
    }
}
