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

Describe 'Test-SqlDscIsRole' -Tag 'Public' {
    Context 'When the instance does not have the specified principal' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                    return @{
                        'JuniorDBA' = New-Object -TypeName Object |
                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'JuniorDBA' -PassThru -Force
                    }
                } -PassThru -Force
        }

        It 'Should return $false' {
            $result = Test-SqlDscIsRole -ServerObject $mockServerObject -Name 'UnknownUser'

            $result | Should -BeFalse
        }
    }

    Context 'When the instance have the specified principal' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' |
                Add-Member -MemberType 'ScriptProperty' -Name 'Roles' -Value {
                    return @{
                        'JuniorDBA' = New-Object -TypeName Object |
                            Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'JuniorDBA' -PassThru -Force
                    }
                } -PassThru -Force
        }

        It 'Should return $true' {
            $result = Test-SqlDscIsRole -ServerObject $mockServerObject -Name 'JuniorDBA'

            $result | Should -BeTrue
        }

        Context 'When passing ServerObject over the pipeline' {
            It 'Should return $true' {
                $result = $mockServerObject | Test-SqlDscIsRole -Name 'JuniorDBA'

                $result | Should -BeTrue
            }
        }
    }
}
