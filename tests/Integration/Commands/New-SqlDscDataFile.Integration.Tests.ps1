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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    # Import the SMO module to ensure real SMO types are available
    Import-SqlDscPreferredModule
}

Describe 'New-SqlDscDataFile' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'When creating a standalone DataFile with real SMO types' {
        It 'Should create a standalone DataFile successfully' {
            $result = New-SqlDscDataFile -Name 'TestDataFile'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'TestDataFile'
            $result.Parent | Should -BeNullOrEmpty
        }

        It 'Should create a standalone DataFile with FileName' {
            $result = New-SqlDscDataFile -Name 'TestDataFile' -FileName 'C:\Data\TestDataFile.ndf'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'TestDataFile'
            $result.FileName | Should -Be 'C:\Data\TestDataFile.ndf'
            $result.Parent | Should -BeNullOrEmpty
        }
    }

    Context 'When creating a DataFile with a FileGroup object' {
        BeforeAll {
            # Create a real SMO FileGroup object (not connected to SQL Server)
            $script:mockFileGroup = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()
            $script:mockFileGroup.Name = 'TestFileGroup'
        }

        It 'Should create a DataFile with FileGroup successfully' {
            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'TestDataFile'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'TestDataFile'
            $result.Parent | Should -Be $script:mockFileGroup
        }

        It 'Should create a DataFile with FileGroup and FileName' {
            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'TestDataFile2' -FileName 'C:\Data\TestDataFile2.ndf'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'TestDataFile2'
            $result.FileName | Should -Be 'C:\Data\TestDataFile2.ndf'
            $result.Parent | Should -Be $script:mockFileGroup
        }

        It 'Should accept FileGroup parameter from pipeline' {
            $result = $script:mockFileGroup | New-SqlDscDataFile -Name 'PipelineDataFile'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'PipelineDataFile'
            $result.Parent | Should -Be $script:mockFileGroup
        }
    }

    Context 'When verifying DataFile properties' {
        It 'Should allow setting Size property' {
            $result = New-SqlDscDataFile -Name 'TestDataFile'
            $result.Size = 1024.0

            $result.Size | Should -Be 1024.0
        }

        It 'Should allow setting Growth property' {
            $result = New-SqlDscDataFile -Name 'TestDataFile'
            $result.Growth = 64.0

            $result.Growth | Should -Be 64.0
        }

        It 'Should allow setting GrowthType property' {
            $result = New-SqlDscDataFile -Name 'TestDataFile'
            $result.GrowthType = [Microsoft.SqlServer.Management.Smo.FileGrowthType]::Percent

            $result.GrowthType | Should -Be 'Percent'
        }
    }
}
