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

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    $env:SqlServerDscCI = $true

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'BackupFileSpec' -Tag 'BackupFileSpec' {
    Context 'When instantiating the class' {
        It 'Should be able to instantiate with default constructor and be of the correct type' {
            $mockBackupFileSpecInstance = InModuleScope -ScriptBlock {
                [BackupFileSpec]::new()
            }

            $mockBackupFileSpecInstance | Should -Not -BeNullOrEmpty
            $mockBackupFileSpecInstance.GetType().Name | Should -Be 'BackupFileSpec'
        }

        It 'Should be able to instantiate with all parameters and be of the correct type' {
            $mockBackupFileSpecInstanceWithParams = InModuleScope -ScriptBlock {
                [BackupFileSpec]::new('MyDatabase', 'C:\Data\MyDatabase.mdf', 'D', 'PRIMARY', 10485760, 1073741824)
            }

            $mockBackupFileSpecInstanceWithParams | Should -Not -BeNullOrEmpty
            $mockBackupFileSpecInstanceWithParams.GetType().Name | Should -Be 'BackupFileSpec'
        }
    }

    Context 'When setting properties using the parameterized constructor' {
        It 'Should set all properties correctly' {
            InModuleScope -ScriptBlock {
                $instance = [BackupFileSpec]::new(
                    'MyLogFile',
                    'L:\Logs\MyLogFile.ldf',
                    'L',
                    '',
                    5242880,
                    536870912
                )

                $instance.LogicalName | Should -Be 'MyLogFile'
                $instance.PhysicalName | Should -Be 'L:\Logs\MyLogFile.ldf'
                $instance.Type | Should -Be 'L'
                $instance.FileGroupName | Should -Be ''
                $instance.Size | Should -Be 5242880
                $instance.MaxSize | Should -Be 536870912
            }
        }
    }

    Context 'When setting properties individually' {
        It 'Should allow setting all properties' {
            InModuleScope -ScriptBlock {
                $instance = [BackupFileSpec]::new()
                $instance.LogicalName = 'DataFile1'
                $instance.PhysicalName = 'C:\Data\DataFile1.ndf'
                $instance.Type = 'D'
                $instance.FileGroupName = 'SECONDARY'
                $instance.Size = 20971520
                $instance.MaxSize = 2147483648

                $instance.LogicalName | Should -Be 'DataFile1'
                $instance.PhysicalName | Should -Be 'C:\Data\DataFile1.ndf'
                $instance.Type | Should -Be 'D'
                $instance.FileGroupName | Should -Be 'SECONDARY'
                $instance.Size | Should -Be 20971520
                $instance.MaxSize | Should -Be 2147483648
            }
        }
    }

    Context 'When using default property values' {
        It 'Should have default values for all properties' {
            InModuleScope -ScriptBlock {
                $instance = [BackupFileSpec]::new()

                $instance.LogicalName | Should -BeNullOrEmpty
                $instance.PhysicalName | Should -BeNullOrEmpty
                $instance.Type | Should -BeNullOrEmpty
                $instance.FileGroupName | Should -BeNullOrEmpty
                $instance.Size | Should -Be 0
                $instance.MaxSize | Should -Be 0
            }
        }
    }
}
