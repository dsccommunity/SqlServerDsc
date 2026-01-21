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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs') -ChildPath 'SMO.cs')
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


Describe 'SqlServerDsc.Common\Invoke-InstallationMediaCopy' -Tag 'InvokeInstallationMediaCopy' {
    BeforeAll {
        $mockSourcePathGuid = 'cc719562-0f46-4a16-8605-9f8a47c70402'
        $mockDestinationPath = 'C:\Users\user\AppData\Local\Temp'

        $mockShareCredentialUserName = 'COMPANY\SqlAdmin'
        $mockShareCredentialPassword = 'dummyPassW0rd'
        $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
            $mockShareCredentialUserName,
            ($mockShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
        )

        $mockGetTemporaryFolder = {
            return $mockDestinationPath
        }

        $mockNewGuid = {
            return New-Object -TypeName Object |
                Add-Member -MemberType NoteProperty -Name 'Guid' -Value $mockSourcePathGuid -PassThru -Force
        }

        Mock -CommandName Connect-UncPath
        Mock -CommandName Disconnect-UncPath
        Mock -CommandName Copy-ItemWithRobocopy
        Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder
        Mock -CommandName New-Guid -MockWith $mockNewGuid
    }

    Context 'When invoking installation media copy, using SourcePath containing leaf' {
        BeforeAll {
            $mockSourcePathUNCWithLeaf = '\\server\share\leaf'

            Mock -CommandName Join-Path -MockWith {
                return $mockDestinationPath + '\leaf'
            }
        }

        It 'Should call the correct mocks' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath       = $mockSourcePathUNCWithLeaf
                SourceCredential = $mockShareCredential
            }

            $null = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters -ErrorAction 'Stop'

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Guid -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Copy-ItemWithRobocopy -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
        }

        It 'Should return the correct destination path' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath       = $mockSourcePathUNCWithLeaf
                SourceCredential = $mockShareCredential
                PassThru         = $true
            }

            $invokeInstallationMediaCopyResult = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters

            $invokeInstallationMediaCopyResult | Should -Be ('{0}\leaf' -f $mockDestinationPath)
        }
    }

    Context 'When invoking installation media copy, using SourcePath containing a second leaf' {
        BeforeAll {
            $mockSourcePathUNCWithLeaf = '\\server\share\leaf\secondleaf'

            Mock -CommandName Join-Path -MockWith {
                return $mockDestinationPath + '\secondleaf'
            }
        }

        It 'Should call the correct mocks' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath       = $mockSourcePathUNCWithLeaf
                SourceCredential = $mockShareCredential
            }

            $null = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters -ErrorAction 'Stop'

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Guid -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Copy-ItemWithRobocopy -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
        }

        It 'Should return the correct destination path' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath       = $mockSourcePathUNCWithLeaf
                SourceCredential = $mockShareCredential
                PassThru         = $true
            }

            $invokeInstallationMediaCopyResult = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters

            $invokeInstallationMediaCopyResult | Should -Be ('{0}\secondleaf' -f $mockDestinationPath)
        }
    }

    Context 'When invoking installation media copy, using SourcePath without a leaf' {
        BeforeAll {
            $mockSourcePathUNC = '\\server\share'

            Mock -CommandName Join-Path -MockWith {
                return $mockDestinationPath + '\' + $mockSourcePathGuid
            }
        }

        It 'Should call the correct mocks' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath       = $mockSourcePathUNC
                SourceCredential = $mockShareCredential
            }

            $null = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters -ErrorAction 'Stop'

            Should -Invoke -CommandName Connect-UncPath -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName New-Guid -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Copy-ItemWithRobocopy -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope It
        }

        It 'Should return the correct destination path' {
            $invokeInstallationMediaCopyParameters = @{
                SourcePath       = $mockSourcePathUNC
                SourceCredential = $mockShareCredential
                PassThru         = $true
            }

            $invokeInstallationMediaCopyResult = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
            $invokeInstallationMediaCopyResult | Should -Be ('{0}\{1}' -f $mockDestinationPath, $mockSourcePathGuid)
        }
    }
}
