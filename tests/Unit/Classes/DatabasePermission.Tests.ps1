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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
}

Describe 'DatabasePermission' -Tag 'DatabasePermission' {
    Context 'When instantiating the class' {
        It 'Should not throw an error' {
            $script:mockDatabasePermissionInstance = InModuleScope -ScriptBlock {
                [DatabasePermission]::new()
            }
        }

        It 'Should be of the correct type' {
            $mockDatabasePermissionInstance | Should -Not -BeNullOrEmpty
            $mockDatabasePermissionInstance.GetType().Name | Should -Be 'DatabasePermission'
        }
    }

    Context 'When setting an reading values' {
        It 'Should be able to set value in instance' {
            $script:mockDatabasePermissionInstance = InModuleScope -ScriptBlock {
                $databasPermissionInstance = [DatabasePermission]::new()

                $databasPermissionInstance.State = [DatabasePermissionState]::Grant
                $databasPermissionInstance.Permission = 'select'

                return $databasPermissionInstance
            }
        }

        It 'Should be able read the values from instance' {
            $mockDatabasePermissionInstance.State | Should -Be 'Grant'
            $mockDatabasePermissionInstance.Permission = 'select'
        }
    }
}
