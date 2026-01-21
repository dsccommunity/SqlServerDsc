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

Describe 'SqlServerDsc.Common\Connect-UncPath' -Tag 'ConnectUncPath' {
    BeforeAll {
        $mockSourcePathUNC = '\\server\share'

        $mockShareCredentialUserName = 'COMPANY\SqlAdmin'
        $mockShareCredentialPassword = 'dummyPassW0rd'
        $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
            $mockShareCredentialUserName,
            ($mockShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
        )

        $mockFqdnShareCredentialUserName = 'SqlAdmin@company.local'
        $mockFqdnShareCredentialPassword = 'dummyPassW0rd'
        $mockFqdnShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
            $mockFqdnShareCredentialUserName,
            ($mockFqdnShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
        )

        InModuleScope -ScriptBlock {
            # Stubs for cross-platform testing.
            function script:New-SmbMapping
            {
                [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'Suppressing this rule because parameter Password is used to mock the real command.')]
                [CmdletBinding()]
                param
                (
                    [Parameter()]
                    [System.String]
                    $RemotePath,

                    [Parameter()]
                    [System.String]
                    $UserName,

                    [Parameter()]
                    [System.String]
                    $Password
                )

                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }

            function script:Remove-SmbMapping
            {
                throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
            }
        }

        Mock -CommandName New-SmbMapping -MockWith {
            return @{
                RemotePath = $mockSourcePathUNC
            }
        }
    }

    AfterAll {
        InModuleScope -ScriptBlock {
            Remove-Item -Path 'function:/New-SmbMapping'
            Remove-Item -Path 'function:/Remove-SmbMapping'
        }
    }

    Context 'When connecting to a UNC path without credentials (using current credentials)' {
        It 'Should call the correct mocks' {
            $connectUncPathParameters = @{
                RemotePath = $mockSourcePathUNC
            }

            $null = Connect-UncPath @connectUncPathParameters -ErrorAction 'Stop'

            Should -Invoke -CommandName New-SmbMapping -ParameterFilter {
                <#
                    Due to issue https://github.com/pester/Pester/issues/1542
                    we must use `$null -ne $UserName` instead of
                    `$PSBoundParameters.ContainsKey('UserName') -eq $false`.
                #>
                $RemotePath -eq $mockSourcePathUNC `
                    -and $null -eq $UserName
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When connecting to a UNC path with specific credentials' {
        It 'Should call the correct mocks' {
            $connectUncPathParameters = @{
                RemotePath       = $mockSourcePathUNC
                SourceCredential = $mockShareCredential
            }

            $null = Connect-UncPath @connectUncPathParameters -ErrorAction 'Stop'

            Should -Invoke -CommandName New-SmbMapping -ParameterFilter {
                $RemotePath -eq $mockSourcePathUNC `
                    -and $UserName -eq $mockShareCredentialUserName
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When connecting using Fully Qualified Domain Name (FQDN)' {
        It 'Should call the correct mocks' {
            $connectUncPathParameters = @{
                RemotePath       = $mockSourcePathUNC
                SourceCredential = $mockFqdnShareCredential
            }

            $null = Connect-UncPath @connectUncPathParameters -ErrorAction 'Stop'

            Should -Invoke -CommandName New-SmbMapping -ParameterFilter {
                $RemotePath -eq $mockSourcePathUNC `
                    -and $UserName -eq $mockFqdnShareCredentialUserName
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When connecting to a UNC path and using parameter PassThru' {
        It 'Should return the correct MSFT_SmbMapping object' {
            $connectUncPathParameters = @{
                RemotePath       = $mockSourcePathUNC
                SourceCredential = $mockShareCredential
                PassThru         = $true
            }

            $connectUncPathResult = Connect-UncPath @connectUncPathParameters
            $connectUncPathResult.RemotePath | Should -Be $mockSourcePathUNC
        }
    }
}
