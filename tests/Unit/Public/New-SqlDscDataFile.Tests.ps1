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
    }

    Context 'Parameter validation' {
        BeforeAll {
            $commandInfo = Get-Command -Name 'New-SqlDscDataFile'
        }

        It 'Should have one parameter set' {
            $commandInfo.ParameterSets.Count | Should -Be 1
        }

        It 'Should have FileGroup as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['FileGroup']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have FileName as a mandatory parameter' {
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

        It 'Should have Force parameter' {
            $parameterInfo = $commandInfo.Parameters['Force']
            $parameterInfo | Should -Not -BeNullOrEmpty
        }

        It 'Should have ConfirmImpact set to High' {
            $commandInfo.ScriptBlock.Attributes | Where-Object { $_.TypeId.Name -eq 'CmdletBindingAttribute' } |
                ForEach-Object { $_.ConfirmImpact } | Should -Be 'High'
        }
    }
}

