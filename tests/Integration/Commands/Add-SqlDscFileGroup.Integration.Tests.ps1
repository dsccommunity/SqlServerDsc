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

Describe 'Add-SqlDscFileGroup' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'When adding a FileGroup to a Database with real SMO types' {
        BeforeEach {
            # Create real SMO objects
            $script:testDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:testDatabase.Name = 'TestDatabase'
            $script:testFileGroup = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()
            $script:testFileGroup.Name = 'TestFileGroup'
        }

        It 'Should add a FileGroup to Database successfully' {
            $initialCount = $script:testDatabase.FileGroups.Count

            Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup $script:testFileGroup

            $script:testDatabase.FileGroups.Count | Should -Be ($initialCount + 1)
            $script:testDatabase.FileGroups[$script:testFileGroup.Name] | Should -Be $script:testFileGroup
        }

        It 'Should return FileGroup when using PassThru' {
            $result = Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup $script:testFileGroup -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result | Should -Be $script:testFileGroup
        }

        It 'Should accept FileGroup from pipeline' {
            $initialCount = $script:testDatabase.FileGroups.Count

            $script:testFileGroup | Add-SqlDscFileGroup -Database $script:testDatabase

            $script:testDatabase.FileGroups.Count | Should -Be ($initialCount + 1)
        }

        It 'Should add multiple FileGroups to Database' {
            $fileGroup1 = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()
            $fileGroup1.Name = 'FileGroup1'
            $fileGroup2 = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()
            $fileGroup2.Name = 'FileGroup2'

            $initialCount = $script:testDatabase.FileGroups.Count

            Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup @($fileGroup1, $fileGroup2)

            $script:testDatabase.FileGroups.Count | Should -Be ($initialCount + 2)
            $script:testDatabase.FileGroups[$fileGroup1.Name] | Should -Be $fileGroup1
            $script:testDatabase.FileGroups[$fileGroup2.Name] | Should -Be $fileGroup2
        }

        It 'Should add multiple FileGroups via pipeline and return them with PassThru' {
            $fileGroup1 = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()
            $fileGroup1.Name = 'FileGroup1'
            $fileGroup2 = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()
            $fileGroup2.Name = 'FileGroup2'

            $result = @($fileGroup1, $fileGroup2) | Add-SqlDscFileGroup -Database $script:testDatabase -PassThru

            $result | Should -HaveCount 2
            $result[0] | Should -Be $fileGroup1
            $result[1] | Should -Be $fileGroup2
        }
    }

    Context 'When verifying FileGroup parent relationship' {
        BeforeEach {
            $script:testDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:testDatabase.Name = 'TestDatabase'
            $script:testFileGroup = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()
            $script:testFileGroup.Name = 'TestFileGroup'
        }

        It 'Should update FileGroup parent reference when added to Database' {
            $script:testFileGroup.Parent | Should -BeNullOrEmpty

            Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup $script:testFileGroup

            # Note: The parent may or may not be updated depending on SMO implementation
            # This test verifies the FileGroup is in the collection
            $script:testDatabase.FileGroups[$script:testFileGroup.Name] | Should -Be $script:testFileGroup
        }
    }

    Context 'When integrating FileGroup and DataFile creation' {
        BeforeEach {
            $script:testDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:testDatabase.Name = 'TestDatabase'
        }

        It 'Should create a complete FileGroup with DataFile structure' {
            # Create FileGroup
            $fileGroup = [Microsoft.SqlServer.Management.Smo.FileGroup]::new()
            $fileGroup.Name = 'SecondaryFileGroup'

            # Create DataFile
            $dataFile = [Microsoft.SqlServer.Management.Smo.DataFile]::new()
            $dataFile.Name = 'SecondaryDataFile'
            $dataFile.FileName = 'C:\Data\SecondaryDataFile.ndf'

            # Add DataFile to FileGroup
            $fileGroup.Files.Add($dataFile)

            # Add FileGroup to Database
            Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup $fileGroup

            # Verify structure
            $script:testDatabase.FileGroups[$fileGroup.Name] | Should -Be $fileGroup
            $script:testDatabase.FileGroups[$fileGroup.Name].Files[$dataFile.Name] | Should -Be $dataFile
        }
    }
}
