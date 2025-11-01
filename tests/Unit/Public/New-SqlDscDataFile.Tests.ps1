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

Describe 'New-SqlDscDataFile' -Tag 'Public' {
    Context 'When creating a new DataFile' {
        BeforeAll {
            $mockDatabaseObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Database'
            $mockDatabaseObject.Name = 'TestDatabase'

            $mockFileGroupObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup' -ArgumentList $mockDatabaseObject, 'PRIMARY'
        }

        It 'Should create a DataFile successfully' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'MyDataFile' -FileName 'C:\Data\MyDataFile.mdf' -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
                $result.Name | Should -Be 'MyDataFile'
                $result.FileName | Should -Be 'C:\Data\MyDataFile.mdf'
                $result.Parent | Should -Be $mockFileGroupObject
            }
        }

        It 'Should create a sparse file for database snapshot' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'MySnapshot_Data' -FileName 'C:\Snapshots\MySnapshot_Data.ss' -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'MySnapshot_Data'
                $result.FileName | Should -Be 'C:\Snapshots\MySnapshot_Data.ss'
                $result.Parent | Should -Be $mockFileGroupObject
            }
        }

        It 'Should accept FileGroup parameter from pipeline' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $result = $mockFileGroupObject | New-SqlDscDataFile -Name 'PipelineDataFile' -FileName 'C:\Data\PipelineDataFile.ndf' -Confirm:$false

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'PipelineDataFile'
                $result.FileName | Should -Be 'C:\Data\PipelineDataFile.ndf'
                $result.Parent | Should -Be $mockFileGroupObject
            }
        }

        It 'Should support Force parameter to bypass confirmation' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'ForcedDataFile' -FileName 'C:\Data\ForcedDataFile.mdf' -Force

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'ForcedDataFile'
                $result.FileName | Should -Be 'C:\Data\ForcedDataFile.mdf'
                $result.Parent | Should -Be $mockFileGroupObject
            }
        }

        It 'Should return null when WhatIf is specified' {
            InModuleScope -Parameters @{
                mockFileGroupObject = $mockFileGroupObject
            } -ScriptBlock {
                param ($mockFileGroupObject)

                $result = New-SqlDscDataFile -FileGroup $mockFileGroupObject -Name 'WhatIfDataFile' -FileName 'C:\Data\WhatIfDataFile.mdf' -WhatIf

                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When creating a standalone DataFile' {
            It 'Should create a DataFile without FileGroup successfully' {
                $result = New-SqlDscDataFile -Name 'StandaloneDataFile' -FileName 'C:\Data\StandaloneDataFile.mdf'

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
                $result.Name | Should -Be 'StandaloneDataFile'
                $result.FileName | Should -Be 'C:\Data\StandaloneDataFile.mdf'
                $result.Parent | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Parameter validation' {
        BeforeAll {
            $commandInfo = Get-Command -Name 'New-SqlDscDataFile'
        }

        It 'Should have two parameter sets' {
            $commandInfo.ParameterSets.Count | Should -Be 2
        }

        It 'Should have parameter set WithFileGroup' {
            $commandInfo.ParameterSets.Name | Should -Contain 'WithFileGroup'
        }

        It 'Should have parameter set Standalone' {
            $commandInfo.ParameterSets.Name | Should -Contain 'Standalone'
        }

        It 'Should have Standalone as the default parameter set' {
            $defaultParameterSet = $commandInfo.ParameterSets | Where-Object { $_.IsDefault }
            $defaultParameterSet.Name | Should -Be 'Standalone'
        }

        It 'Should have FileGroup as a mandatory parameter in WithFileGroup set' {
            $parameterInfo = $commandInfo.Parameters['FileGroup']
            $withFileGroupAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [Parameter] -and $_.ParameterSetName -eq 'WithFileGroup' }
            $withFileGroupAttribute.Mandatory | Should -BeTrue
        }

        It 'Should not have FileGroup parameter in Standalone set' {
            $parameterInfo = $commandInfo.Parameters['FileGroup']
            $standaloneAttribute = $parameterInfo.Attributes | Where-Object { $_ -is [Parameter] -and $_.ParameterSetName -eq 'Standalone' }
            $standaloneAttribute | Should -BeNullOrEmpty
        }

        It 'Should have Name as a mandatory parameter in both parameter sets' {
            $parameterInfo = $commandInfo.Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have FileName as a mandatory parameter in both parameter sets' {
            $parameterInfo = $commandInfo.Parameters['FileName']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have FileGroup parameter accept pipeline input' {
            $parameterInfo = $commandInfo.Parameters['FileGroup']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should support ShouldProcess' {
            $commandInfo.Parameters.ContainsKey('WhatIf') | Should -BeTrue
            $commandInfo.Parameters.ContainsKey('Confirm') | Should -BeTrue
        }

        It 'Should have Force parameter only in WithFileGroup parameter set' {
            $parameterInfo = $commandInfo.Parameters['Force']
            $parameterInfo | Should -Not -BeNullOrEmpty
            $parameterInfo.ParameterSets.Keys | Should -Contain 'WithFileGroup'
            $parameterInfo.ParameterSets.Keys | Should -Not -Contain 'Standalone'
        }

        It 'Should have ConfirmImpact set to High' {
            $commandInfo.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                ForEach-Object { $_.ConfirmImpact } | Should -Be 'High'
        }
    }
}

