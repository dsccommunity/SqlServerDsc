<#
    .SYNOPSIS
        Unit test for helper functions in module SqlServerDsc.Common.

    .NOTES
        SMO stubs
        ---------
        These are loaded at the start so that it is known that they are left in the
        session after test finishes, and will spill over to other tests. There does
        not exist a way to unload assemblies. It is possible to load these in a
        InModuleScope but the classes are still present in the parent scope when
        Pester has ran.

        SqlServer/SQLPS stubs
        ---------------------
        These are imported using Import-SqlModuleStub in a BeforeAll-block in only
        a test that requires them, and must be removed in an AfterAll-block using
        Remove-SqlModuleStub so the stub cmdlets does not spill over to another
        test.
#>

# Suppressing this rule because ConvertTo-SecureString is used to simplify the tests.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:subModuleName = 'SqlServerDsc.Common'

    $script:parentModule = Get-Module -Name $script:moduleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\TestHelpers\CommonTestHelper.psm1')

    # Loading SMO stubs.
    if (-not ('Microsoft.SqlServer.Management.Smo.Server' -as [Type]))
    {
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')
    }

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

# Tests only the parts of the code that does not already get tested thru the other tests.
Describe 'SqlServerDsc.Common\Copy-ItemWithRobocopy' -Tag 'CopyItemWithRobocopy' {
    BeforeAll {
        $mockRobocopyExecutableName = 'Robocopy.exe'
        $mockRobocopyExecutableVersionWithoutUnbufferedIO = '6.2.9200.00000'
        $mockRobocopyExecutableVersionWithUnbufferedIO = '6.3.9600.16384'
        $mockRobocopyExecutableVersion = ''     # Set dynamically during runtime
        $mockRobocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
        $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
        $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'
        $mockRobocopyArgumentUseUnbufferedIO = '/J'
        $mockRobocopyArgumentSourcePath = 'C:\Source\SQL2016'
        $mockRobocopyArgumentDestinationPath = 'D:\Temp'
        $mockRobocopyArgumentSourcePathWithSpaces = 'C:\Source\SQL2016 STD SP1'
        $mockRobocopyArgumentDestinationPathWithSpaces = 'D:\Temp\DSC SQL2016'

        $mockGetCommand = {
            return @(
                (
                    New-Object -TypeName Object |
                        Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockRobocopyExecutableName -PassThru |
                        Add-Member -MemberType ScriptProperty -Name FileVersionInfo -Value {
                            return @( ( New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ProductVersion' -Value $mockRobocopyExecutableVersion -PassThru -Force
                                    ) )
                            } -PassThru -Force
                )
            )
        }

        $mockStartSqlSetupProcessExpectedArgument = ''  # Set dynamically during runtime
        $mockStartSqlSetupProcessExitCode = 0  # Set dynamically during runtime

        $mockStartSqlSetupProcess_Robocopy = {
            if ( $ArgumentList -cne $mockStartSqlSetupProcessExpectedArgument )
            {
                throw "Expected arguments was not the same as the arguments in the function call.`nExpected: '$mockStartSqlSetupProcessExpectedArgument' `n But was: '$ArgumentList'"
            }

            return New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value 0 -PassThru -Force
        }

        $mockStartSqlSetupProcess_Robocopy_WithExitCode = {
            return New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value $mockStartSqlSetupProcessExitCode -PassThru -Force
        }
    }

    Context 'When Copy-ItemWithRobocopy is called it should return the correct arguments' {
        BeforeEach {
            Mock -CommandName Get-Command -MockWith $mockGetCommand
            Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy
            $mockRobocopyArgumentSourcePathQuoted = '"{0}"' -f $mockRobocopyArgumentSourcePath
            $mockRobocopyArgumentDestinationPathQuoted = '"{0}"' -f $mockRobocopyArgumentDestinationPath
        }


        It 'Should use Unbuffered IO when copying' {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

            $mockStartSqlSetupProcessExpectedArgument =
            $mockRobocopyArgumentSourcePathQuoted,
            $mockRobocopyArgumentDestinationPathQuoted,
            $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty,
            $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
            $mockRobocopyArgumentUseUnbufferedIO,
            $mockRobocopyArgumentSilent -join ' '

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $null = Copy-ItemWithRobocopy @copyItemWithRobocopyParameter -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should not use Unbuffered IO when copying' {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithoutUnbufferedIO

            $mockStartSqlSetupProcessExpectedArgument =
            $mockRobocopyArgumentSourcePathQuoted,
            $mockRobocopyArgumentDestinationPathQuoted,
            $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty,
            $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
            '',
            $mockRobocopyArgumentSilent -join ' '

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $null = Copy-ItemWithRobocopy @copyItemWithRobocopyParameter -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }
    }

    Context 'When Copy-ItemWithRobocopy throws an exception it should return the correct error messages' {
        BeforeAll {
            $mockRobocopyArgumentSourcePath = 'C:\Source\SQL2016'
            $mockRobocopyArgumentDestinationPath = 'D:\Temp\DSCSQL2016'
            $mockRobocopyExecutableName = 'Robocopy.exe'
            $mockRobocopyExecutableVersion = ''     # Set dynamically during runtime
        }

        BeforeEach {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

            Mock -CommandName Get-Command -MockWith {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockRobocopyExecutableName -PassThru |
                            Add-Member -MemberType ScriptProperty -Name FileVersionInfo -Value {
                                return @( ( New-Object -TypeName Object |
                                            Add-Member -MemberType NoteProperty -Name 'ProductVersion' -Value $mockRobocopyExecutableVersion -PassThru -Force
                                        ) )
                                } -PassThru -Force
                    )
                )
            }

            Mock -CommandName Start-Process -MockWith {
                return New-Object -TypeName Object |
                    Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value $mockStartSqlSetupProcessExitCode -PassThru -Force
            }
        }

        It 'Should throw the correct error message when error code is 8' {
            $mockStartSqlSetupProcessExitCode = 8

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.RobocopyErrorCopying
            }

            $mockErrorMessage = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $mockStartSqlSetupProcessExitCode
            )

            $mockErrorMessage.Exception.Message | Should -Not -BeNullOrEmpty

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw -ExpectedMessage $mockErrorMessage

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should throw the correct error message when error code is 16' {
            $mockStartSqlSetupProcessExitCode = 16

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }


            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.RobocopyErrorCopying
            }

            $mockErrorMessage = Get-InvalidOperationRecord -Message (
                $mockLocalizedString -f $mockStartSqlSetupProcessExitCode
            )

            $mockErrorMessage.Exception.Message | Should -Not -BeNullOrEmpty

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw -ExpectedMessage $mockErrorMessage

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should throw the correct error message when error code is greater than 7 (but not 8 or 16)' {
            $mockStartSqlSetupProcessExitCode = 9

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.RobocopyFailuresCopying
            }

            $mockErrorMessage = Get-InvalidResultRecord -Message (
                $mockLocalizedString -f $mockStartSqlSetupProcessExitCode
            )

            $mockErrorMessage | Should -Not -BeNullOrEmpty

            { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw -ExpectedMessage $mockErrorMessage

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }
    }

    Context 'When Copy-ItemWithRobocopy is called and finishes successfully it should return the correct exit code' {
        BeforeEach {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

            Mock -CommandName Get-Command -MockWith $mockGetCommand
            Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy_WithExitCode
        }

        AfterEach {
            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should finish successfully with exit code 1' {
            $mockStartSqlSetupProcessExitCode = 1

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $null = Copy-ItemWithRobocopy @copyItemWithRobocopyParameter -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should finish successfully with exit code 2' {
            $mockStartSqlSetupProcessExitCode = 2

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $null = Copy-ItemWithRobocopy @copyItemWithRobocopyParameter -ErrorAction 'Stop'

            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should finish successfully with exit code 3' {
            $mockStartSqlSetupProcessExitCode = 3

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePath
                DestinationPath = $mockRobocopyArgumentDestinationPath
            }

            $null = Copy-ItemWithRobocopy @copyItemWithRobocopyParameter -ErrorAction 'Stop'
        }
    }

    Context 'When Copy-ItemWithRobocopy is called with spaces in paths and finishes successfully it should return the correct exit code' {
        BeforeEach {
            $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

            Mock -CommandName Get-Command -MockWith $mockGetCommand
            Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy_WithExitCode
        }

        AfterEach {
            Should -Invoke -CommandName Get-Command -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Process -Exactly -Times 1 -Scope It
        }

        It 'Should finish successfully with exit code 1' {
            $mockStartSqlSetupProcessExitCode = 1

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePathWithSpaces
                DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
            }

            $null = Copy-ItemWithRobocopy @copyItemWithRobocopyParameter -ErrorAction 'Stop'
        }

        It 'Should finish successfully with exit code 2' {
            $mockStartSqlSetupProcessExitCode = 2

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePathWithSpaces
                DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
            }

            $null = Copy-ItemWithRobocopy @copyItemWithRobocopyParameter -ErrorAction 'Stop'
        }

        It 'Should finish successfully with exit code 3' {
            $mockStartSqlSetupProcessExitCode = 3

            $copyItemWithRobocopyParameter = @{
                Path            = $mockRobocopyArgumentSourcePathWithSpaces
                DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
            }

            $null = Copy-ItemWithRobocopy @copyItemWithRobocopyParameter -ErrorAction 'Stop'
        }
    }
}
