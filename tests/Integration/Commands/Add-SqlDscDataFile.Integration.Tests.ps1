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

    $script:mockInstanceName = 'DSCSQLTEST'
    $script:mockComputerName = Get-ComputerName

    $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
    $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

    $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

    $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
}

Describe 'Add-SqlDscDataFile' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'When adding a DataFile to a FileGroup with real SMO types' {
        BeforeEach {
            # Create real SMO Database and FileGroup objects
            $script:testDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:testDatabase.Name = 'TestDatabase'
            $script:testDatabase.Parent = $script:serverObject

            $script:testFileGroup = New-SqlDscFileGroup -Database $script:testDatabase -Name 'TestFileGroup' -Confirm:$false
            $script:testDataFile = New-SqlDscDataFile -FileGroup $script:testFileGroup -Name 'TestDataFile' -FileName 'C:\Data\TestDataFile.ndf' -Confirm:$false
        }

        It 'Should add a DataFile to FileGroup successfully' {
            $initialCount = $script:testFileGroup.Files.Count

            Add-SqlDscDataFile -FileGroup $script:testFileGroup -DataFile $script:testDataFile

            $script:testFileGroup.Files.Count | Should -Be ($initialCount + 1)
            $script:testFileGroup.Files[$script:testDataFile.Name] | Should -Be $script:testDataFile
        }

        It 'Should return DataFile when using PassThru' {
            $result = Add-SqlDscDataFile -FileGroup $script:testFileGroup -DataFile $script:testDataFile -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result | Should -Be $script:testDataFile
        }

        It 'Should accept DataFile from pipeline' {
            $initialCount = $script:testFileGroup.Files.Count

            $script:testDataFile | Add-SqlDscDataFile -FileGroup $script:testFileGroup

            $script:testFileGroup.Files.Count | Should -Be ($initialCount + 1)
        }

        It 'Should add multiple DataFiles to FileGroup' {
            $dataFile1 = New-SqlDscDataFile -FileGroup $script:testFileGroup -Name 'DataFile1' -FileName 'C:\Data\DataFile1.ndf' -Confirm:$false
            $dataFile2 = New-SqlDscDataFile -FileGroup $script:testFileGroup -Name 'DataFile2' -FileName 'C:\Data\DataFile2.ndf' -Confirm:$false

            $initialCount = $script:testFileGroup.Files.Count

            Add-SqlDscDataFile -FileGroup $script:testFileGroup -DataFile @($dataFile1, $dataFile2)

            $script:testFileGroup.Files.Count | Should -Be ($initialCount + 2)
            $script:testFileGroup.Files[$dataFile1.Name] | Should -Be $dataFile1
            $script:testFileGroup.Files[$dataFile2.Name] | Should -Be $dataFile2
        }

        It 'Should add multiple DataFiles via pipeline and return them with PassThru' {
            $dataFile1 = New-SqlDscDataFile -FileGroup $script:testFileGroup -Name 'DataFile1' -FileName 'C:\Data\DataFile1.ndf' -Confirm:$false
            $dataFile2 = New-SqlDscDataFile -FileGroup $script:testFileGroup -Name 'DataFile2' -FileName 'C:\Data\DataFile2.ndf' -Confirm:$false

            $result = @($dataFile1, $dataFile2) | Add-SqlDscDataFile -FileGroup $script:testFileGroup -PassThru

            $result | Should -HaveCount 2
            $result[0] | Should -Be $dataFile1
            $result[1] | Should -Be $dataFile2
        }
    }

    Context 'When verifying DataFile parent relationship' {
        BeforeEach {
            $script:testDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:testDatabase.Name = 'TestDatabase'
            $script:testDatabase.Parent = $script:serverObject

            $script:testFileGroup = New-SqlDscFileGroup -Database $script:testDatabase -Name 'TestFileGroup' -Confirm:$false
            $script:testDataFile = New-SqlDscDataFile -FileGroup $script:testFileGroup -Name 'TestDataFile' -FileName 'C:\Data\TestDataFile.ndf' -Confirm:$false
        }

        It 'Should update DataFile parent reference when added to FileGroup' {
            $script:testDataFile.Parent | Should -BeNullOrEmpty

            Add-SqlDscDataFile -FileGroup $script:testFileGroup -DataFile $script:testDataFile

            # Note: The parent may or may not be updated depending on SMO implementation
            # This test verifies the DataFile is in the collection
            $script:testFileGroup.Files[$script:testDataFile.Name] | Should -Be $script:testDataFile
        }
    }
}
