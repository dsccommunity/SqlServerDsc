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

Describe 'Save-SqlDscSqlServerMedia' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[-Url] <string> [-DestinationPath] <FileInfo> [[-FileName] <string>] [[-Language] <string>] [-Quiet] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Save-SqlDscSqlServerMedia').ParameterSets |
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
        $DestinationPath = 'C:\Temp'
    }

    Context 'When the URL does not end with .exe' {
        It 'Should call Invoke-WebRequest to download the media file' {
            Save-SqlDscSqlServerMedia -Url $Url -DestinationPath $DestinationPath -Force

            Should -Invoke Invoke-WebRequest -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the URL ends with .exe' {
        BeforeAll {
            $Url = "$Url.exe"
        }

        It 'Should call Invoke-WebRequest to download the executable file' {
            Save-SqlDscSqlServerMedia -Url $Url -DestinationPath $DestinationPath -Force

            Should -Invoke Invoke-WebRequest -Exactly -Times 1 -Scope It
        }

        It 'Should call Start-Process to initiate download using the downloaded executable file' {
            Save-SqlDscSqlServerMedia -Url $Url -DestinationPath $DestinationPath -Force

            Should -Invoke Start-Process -Times 1 -Exactly
        }

        It 'Should call Remove-Item to remove the executable file' {
            Save-SqlDscSqlServerMedia -Url $Url -DestinationPath $DestinationPath -Force

            Should -Invoke Remove-Item -Times 1 -Exactly
        }

        It 'Should call Rename-Item to rename the downloaded ISO file to the specified name' {
            Save-SqlDscSqlServerMedia -Url $Url -DestinationPath $DestinationPath -Force

            Should -Invoke Rename-Item -Times 1 -Exactly
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
                $script:localizedData.SqlServerMedia_Save_InvalidDestinationFolder
            }

            { Save-SqlDscSqlServerMedia -Url $Url -DestinationPath $DestinationPath } | Should -Throw $mockErrorMessage
        }
    }
}
