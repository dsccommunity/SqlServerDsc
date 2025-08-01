[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Assert-SqlLogin' -Tag 'Public' {
    Context 'When a login exists' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -PassThru |
                Add-Member -MemberType 'ScriptProperty' -Name 'Logins' -Value {
                    return @{
                        'TestLogin' = New-Object -TypeName Object |
                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'TestLogin' -PassThru -Force
                    }
                } -PassThru -Force
        }

        It 'Should not throw an error when the login exists' {
            { Assert-SqlLogin -ServerObject $mockServerObject -Principal 'TestLogin' } | Should -Not -Throw
        }

        It 'Should accept ServerObject from pipeline' {
            { $mockServerObject | Assert-SqlLogin -Principal 'TestLogin' } | Should -Not -Throw
        }
    }

    Context 'When a login does not exist' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'NoteProperty' -Name 'InstanceName' -Value 'TestInstance' -PassThru |
                Add-Member -MemberType 'ScriptProperty' -Name 'Logins' -Value {
                    return @{
                        'ExistingLogin' = New-Object -TypeName Object |
                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'ExistingLogin' -PassThru -Force
                    }
                } -PassThru -Force
        }

        It 'Should throw a terminating error when the login does not exist' {
            { Assert-SqlLogin -ServerObject $mockServerObject -Principal 'NonExistentLogin' } | Should -Throw -ExpectedMessage "*does not exist as a login*"
        }

        It 'Should throw an error with the correct error category' {
            try
            {
                Assert-SqlLogin -ServerObject $mockServerObject -Principal 'NonExistentLogin'
            }
            catch
            {
                $_.CategoryInfo.Category | Should -Be 'ObjectNotFound'
                $_.FullyQualifiedErrorId | Should -Be 'ASL0001'
            }
        }

        It 'Should include the principal name in the error message' {
            { Assert-SqlLogin -ServerObject $mockServerObject -Principal 'NonExistentLogin' } | Should -Throw -ExpectedMessage "*NonExistentLogin*"
        }

        It 'Should include the instance name in the error message' {
            { Assert-SqlLogin -ServerObject $mockServerObject -Principal 'NonExistentLogin' } | Should -Throw -ExpectedMessage "*TestInstance*"
        }
    }

    Context 'When validating parameters' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
        }

        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Assert-SqlLogin').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Principal as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Assert-SqlLogin').Parameters['Principal']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept ServerObject from pipeline' {
            $parameterInfo = (Get-Command -Name 'Assert-SqlLogin').Parameters['ServerObject']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }
    }
}