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

Describe 'ConvertFrom-SqlDscDatabasePermission' -Tag 'Public' {
    BeforeAll {
        $mockPermission = InModuleScope -ScriptBlock {
            [DatabasePermission] @{
                State      = 'Grant'
                Permission = @(
                    'Connect'
                    'Alter'
                )
            }
        }
    }

    It 'Should return the correct values' {
        $mockResult = ConvertFrom-SqlDscDatabasePermission -Permission $mockPermission

        $mockResult.Connect | Should -BeTrue
        $mockResult.Alter | Should -BeTrue
        $mockResult.Update | Should -BeFalse
    }

    Context 'When passing DatabasePermissionInfo over the pipeline' {
        It 'Should return the correct values' {
            $mockResult = $mockPermission | ConvertFrom-SqlDscDatabasePermission

            $mockResult.Connect | Should -BeTrue
            $mockResult.Alter | Should -BeTrue
            $mockResult.Update | Should -BeFalse
        }
    }
}
