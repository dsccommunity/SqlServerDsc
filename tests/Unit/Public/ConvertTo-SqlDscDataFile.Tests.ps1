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

    # Loading mocked classes BEFORE importing the module (required for classes that reference SMO types)
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

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

Describe 'ConvertTo-SqlDscDataFile' -Tag 'Public' {
    Context 'When converting a DatabaseFileSpec to SMO DataFile' {
        BeforeAll {
            # Create mock FileGroup
            $mockFileGroup = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $mockFileGroup | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value 'PRIMARY' -Force
        }

        It 'Should convert a basic file spec with only required properties' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\SQLData\TestFile.mdf' -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroupObject $mockFileGroup -DataFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'TestFile'
            $result.FileName | Should -Be 'C:\SQLData\TestFile.mdf'
        }

        It 'Should convert a file spec with all optional properties set' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\SQLData\TestFile.mdf' `
                -Size 102400 -MaxSize 512000 -Growth 10240 -GrowthType 'KB' -IsPrimaryFile -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroupObject $mockFileGroup -DataFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestFile'
            $result.FileName | Should -Be 'C:\SQLData\TestFile.mdf'
            $result.Size | Should -Be 102400
            $result.MaxSize | Should -Be 512000
            $result.Growth | Should -Be 10240
            $result.GrowthType | Should -Be 'KB'
            $result.IsPrimaryFile | Should -Be $true
        }

        It 'Should convert a file spec with Size property' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\SQLData\TestFile.mdf' -Size 204800 -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroupObject $mockFileGroup -DataFileSpec $fileSpec

            $result.Size | Should -Be 204800
        }

        It 'Should convert a file spec with MaxSize property' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\SQLData\TestFile.mdf' -MaxSize 1024000 -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroupObject $mockFileGroup -DataFileSpec $fileSpec

            $result.MaxSize | Should -Be 1024000
        }

        It 'Should convert a file spec with Growth property' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\SQLData\TestFile.mdf' -Growth 20480 -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroupObject $mockFileGroup -DataFileSpec $fileSpec

            $result.Growth | Should -Be 20480
        }

        It 'Should convert a file spec with GrowthType property set to Percent' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\SQLData\TestFile.mdf' -GrowthType 'Percent' -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroupObject $mockFileGroup -DataFileSpec $fileSpec

            $result.GrowthType | Should -Be 'Percent'
        }

        It 'Should convert a file spec with IsPrimaryFile property' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\SQLData\TestFile.mdf' -IsPrimaryFile -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroupObject $mockFileGroup -DataFileSpec $fileSpec

            $result.IsPrimaryFile | Should -Be $true
        }
    }

    Context 'Parameter validation' {
        BeforeAll {
            $commandInfo = Get-Command -Name 'ConvertTo-SqlDscDataFile'
        }

        It 'Should have FileGroupObject as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['FileGroupObject']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have DataFileSpec as a mandatory parameter' {
            $parameterInfo = $commandInfo.Parameters['DataFileSpec']
            $parameterInfo.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should have OutputType set to Microsoft.SqlServer.Management.Smo.DataFile' {
            $commandInfo.OutputType.Name | Should -Contain 'Microsoft.SqlServer.Management.Smo.DataFile'
        }
    }
}
