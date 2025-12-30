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
    $script:moduleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'ConvertFrom-SqlDscServerPermission' -Tag 'Public' {
    BeforeAll {
        $mockPermission = InModuleScope -ScriptBlock {
            [ServerPermission] @{
                State      = 'Grant'
                Permission = @(
                    'ConnectSql'
                    'AlterAnyAvailabilityGroup'
                )
            }
        }
    }

    It 'Should return the correct values' {
        $mockResult = ConvertFrom-SqlDscServerPermission -Permission $mockPermission

        $mockResult.ConnectSql | Should -BeTrue
        $mockResult.AlterAnyAvailabilityGroup | Should -BeTrue
        $mockResult.AlterAnyLogin | Should -BeFalse
    }

    Context 'When passing ServerPermissionInfo over the pipeline' {
        It 'Should return the correct values' {
            $mockResult = $mockPermission | ConvertFrom-SqlDscServerPermission

            $mockResult.ConnectSql | Should -BeTrue
            $mockResult.AlterAnyAvailabilityGroup | Should -BeTrue
            $mockResult.AlterAnyLogin | Should -BeFalse
        }
    }
}
