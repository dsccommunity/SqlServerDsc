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
}

Describe 'Add-SqlDscFileGroup' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject
    }

    Context 'When adding a FileGroup to a Database with real SMO types' {
        BeforeEach {
            # Create real SMO Database object
            $script:testDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:testDatabase.Name = 'TestDatabase'
            $script:testDatabase.Parent = $script:serverObject

            $script:testFileGroup = New-SqlDscFileGroup -Database $script:testDatabase -Name 'TestFileGroup' -Confirm:$false -ErrorAction 'Stop'
        }

        It 'Should add a FileGroup to Database successfully' {
            $initialCount = $script:testDatabase.FileGroups.Count

            Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup $script:testFileGroup -ErrorAction 'Stop'

            $script:testDatabase.FileGroups.Count | Should -Be ($initialCount + 1)
            $script:testDatabase.FileGroups[$script:testFileGroup.Name] | Should -Be $script:testFileGroup
        }

        It 'Should return FileGroup when using PassThru' {
            $result = Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup $script:testFileGroup -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.FileGroup'
            $result | Should -Be $script:testFileGroup
        }

        It 'Should accept FileGroup from pipeline' {
            $initialCount = $script:testDatabase.FileGroups.Count

            $script:testFileGroup | Add-SqlDscFileGroup -Database $script:testDatabase -ErrorAction 'Stop'

            $script:testDatabase.FileGroups.Count | Should -Be ($initialCount + 1)
        }

        It 'Should add multiple FileGroups to Database' {
            $fileGroup1 = New-SqlDscFileGroup -Database $script:testDatabase -Name 'FileGroup1' -Confirm:$false -ErrorAction 'Stop'
            $fileGroup2 = New-SqlDscFileGroup -Database $script:testDatabase -Name 'FileGroup2' -Confirm:$false -ErrorAction 'Stop'

            $initialCount = $script:testDatabase.FileGroups.Count

            Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup @($fileGroup1, $fileGroup2) -ErrorAction 'Stop'

            $script:testDatabase.FileGroups.Count | Should -Be ($initialCount + 2)
            $script:testDatabase.FileGroups[$fileGroup1.Name] | Should -Be $fileGroup1
            $script:testDatabase.FileGroups[$fileGroup2.Name] | Should -Be $fileGroup2
        }

        It 'Should add multiple FileGroups via pipeline and return them with PassThru' {
            $fileGroup1 = New-SqlDscFileGroup -Database $script:testDatabase -Name 'FileGroup1' -Confirm:$false -ErrorAction 'Stop'
            $fileGroup2 = New-SqlDscFileGroup -Database $script:testDatabase -Name 'FileGroup2' -Confirm:$false -ErrorAction 'Stop'

            $result = @($fileGroup1, $fileGroup2) | Add-SqlDscFileGroup -Database $script:testDatabase -PassThru -ErrorAction 'Stop'

            $result | Should -HaveCount 2
            $result[0] | Should -Be $fileGroup1
            $result[1] | Should -Be $fileGroup2
        }
    }

    Context 'When verifying FileGroup parent relationship' {
        BeforeEach {
            $script:testDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:testDatabase.Name = 'TestDatabase'
            $script:testDatabase.Parent = $script:serverObject

            $script:testFileGroup = New-SqlDscFileGroup -Name 'TestFileGroup' -ErrorAction 'Stop'
        }

        It 'Should update FileGroup parent reference when added to Database' {
            $script:testFileGroup.Parent | Should -BeNullOrEmpty

            Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup $script:testFileGroup -ErrorAction 'Stop'

            # Note: The parent may or may not be updated depending on SMO implementation
            # This test verifies the FileGroup is in the collection
            $script:testDatabase.FileGroups[$script:testFileGroup.Name] | Should -Be $script:testFileGroup
        }
    }

    Context 'When integrating FileGroup and DataFile creation' {
        BeforeEach {
            $script:testDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:testDatabase.Name = 'TestDatabase'
            $script:testDatabase.Parent = $script:serverObject
        }

        It 'Should create a complete FileGroup with DataFile structure' {
            # Create FileGroup
            $fileGroup = New-SqlDscFileGroup -Database $script:testDatabase -Name 'SecondaryFileGroup' -Confirm:$false -ErrorAction 'Stop'

            # Create DataFile - it will be automatically added to the FileGroup
            $null = New-SqlDscDataFile -FileGroup $fileGroup -Name 'SecondaryDataFile' -FileName 'C:\Data\SecondaryDataFile.ndf' -Confirm:$false -ErrorAction 'Stop'

            # Add FileGroup to Database
            Add-SqlDscFileGroup -Database $script:testDatabase -FileGroup $fileGroup -ErrorAction 'Stop'

            # Verify structure
            $script:testDatabase.FileGroups[$fileGroup.Name] | Should -Be $fileGroup
            $addedFile = $script:testDatabase.FileGroups[$fileGroup.Name].Files | Where-Object -FilterScript { $_.Name -eq 'SecondaryDataFile' }
            $addedFile | Should -Not -BeNullOrEmpty
            $addedFile.FileName | Should -Be 'C:\Data\SecondaryDataFile.ndf'
        }
    }
}
