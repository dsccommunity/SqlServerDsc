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

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

Describe 'Assert-SqlDscLogin' -Tag 'Public' {
    Context 'When a login exists' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            Mock -CommandName 'Test-SqlDscIsLogin' -MockWith { return $true }
        }

        It 'Should not throw an error when the login exists' {
            Assert-SqlDscLogin -ServerObject $mockServerObject -Name 'TestLogin'
        }

        It 'Should call Test-SqlDscIsLogin with correct parameters' {
            Assert-SqlDscLogin -ServerObject $mockServerObject -Name 'TestLogin'

            Should -Invoke -CommandName 'Test-SqlDscIsLogin' -ParameterFilter {
                $ServerObject.InstanceName -eq 'TestInstance' -and
                $Name -eq 'TestLogin'
            } -Exactly -Times 1
        }

        It 'Should accept ServerObject from pipeline' {
            $mockServerObject | Assert-SqlDscLogin -Name 'TestLogin'
        }
    }

    Context 'When a login does not exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject | Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -Force

            Mock -CommandName 'Test-SqlDscIsLogin' -MockWith { return $false }
        }

        It 'Should throw a terminating error when the login does not exist' {
            { Assert-SqlDscLogin -ServerObject $mockServerObject -Name 'NonExistentLogin' } | Should -Throw -ExpectedMessage "*does not exist as a login*"
        }

        It 'Should throw an error with the correct error category' {
            try
            {
                Assert-SqlDscLogin -ServerObject $mockServerObject -Name 'NonExistentLogin'
            }
            catch
            {
                $_.CategoryInfo.Category | Should -Be 'ObjectNotFound'
                $_.FullyQualifiedErrorId | Should -Be 'ASDL0001,Assert-SqlDscLogin'
            }
        }

        It 'Should include the principal name in the error message' {
            { Assert-SqlDscLogin -ServerObject $mockServerObject -Name 'NonExistentLogin' } | Should -Throw -ExpectedMessage "*NonExistentLogin*"
        }

        It 'Should include the instance name in the error message' {
            { Assert-SqlDscLogin -ServerObject $mockServerObject -Name 'NonExistentLogin' } | Should -Throw -ExpectedMessage "*TestInstance*"
        }

        It 'Should call Test-SqlDscIsLogin with correct parameters' {
            { Assert-SqlDscLogin -ServerObject $mockServerObject -Name 'NonExistentLogin' } | Should -Throw

            Should -Invoke -CommandName 'Test-SqlDscIsLogin' -ParameterFilter {
                $ServerObject.InstanceName -eq 'TestInstance' -and
                $Name -eq 'NonExistentLogin'
            } -Exactly -Times 1
        }
    }

    Context 'When validating parameters' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
        }

        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Assert-SqlDscLogin').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Assert-SqlDscLogin').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept ServerObject from pipeline' {
            $parameterInfo = (Get-Command -Name 'Assert-SqlDscLogin').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
            @{
                MockParameterSetName = '__AllParameterSets'
                MockExpectedParameters = '[-ServerObject] <Server> [-Name] <string> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Assert-SqlDscLogin').ParameterSets |
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
}
