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

Describe 'ConvertTo-SqlDscFileGroup' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
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

    Context 'When converting a DatabaseFileGroupSpec to a FileGroup with real SMO types' {
        BeforeAll {
            $script:testDatabaseName = 'TestDB_{0}' -f (Get-Random)

            # Create a test database for the conversion context
            $script:testDatabase = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Confirm:$false
        }

        AfterAll {
            # Clean up the test database
            if ($script:testDatabase)
            {
                Remove-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Confirm:$false
            }
        }

        It 'Should convert a minimal DatabaseFileGroupSpec to a FileGroup object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -AsSpec
            $fileGroupSpec = New-SqlDscFileGroup -Name 'TestFileGroup' -Files @($fileSpec) -AsSpec

            $result = ConvertTo-SqlDscFileGroup -DatabaseObject $script:testDatabase -FileGroupSpec $fileGroupSpec

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.FileGroup]
            $result.Name | Should -Be 'TestFileGroup'
            $result.Files.Count | Should -Be 1
            $result.Files[0].Name | Should -Be 'TestFile'
        }

        It 'Should convert a DatabaseFileGroupSpec with multiple files to a FileGroup object' {
            $fileSpec1 = New-SqlDscDataFile -Name 'TestFile1' -FileName 'C:\Data\TestFile1.ndf' -AsSpec
            $fileSpec2 = New-SqlDscDataFile -Name 'TestFile2' -FileName 'C:\Data\TestFile2.ndf' -AsSpec
            $fileGroupSpec = New-SqlDscFileGroup -Name 'TestFileGroup' -Files @($fileSpec1, $fileSpec2) -AsSpec

            $result = ConvertTo-SqlDscFileGroup -DatabaseObject $script:testDatabase -FileGroupSpec $fileGroupSpec

            $result | Should -Not -BeNullOrEmpty
            $result.Files.Count | Should -Be 2
            $result.Files[0].Name | Should -Be 'TestFile1'
            $result.Files[1].Name | Should -Be 'TestFile2'
        }

        It 'Should convert a DatabaseFileGroupSpec with ReadOnly to a FileGroup object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -AsSpec
            $fileGroupSpec = New-SqlDscFileGroup -Name 'TestFileGroup' -Files @($fileSpec) -ReadOnly $true -AsSpec

            $result = ConvertTo-SqlDscFileGroup -DatabaseObject $script:testDatabase -FileGroupSpec $fileGroupSpec

            $result | Should -Not -BeNullOrEmpty
            $result.ReadOnly | Should -Be $true
        }

        It 'Should convert a DatabaseFileGroupSpec with IsDefault to a FileGroup object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -AsSpec
            $fileGroupSpec = New-SqlDscFileGroup -Name 'TestFileGroup' -Files @($fileSpec) -IsDefault $true -AsSpec

            $result = ConvertTo-SqlDscFileGroup -DatabaseObject $script:testDatabase -FileGroupSpec $fileGroupSpec

            $result | Should -Not -BeNullOrEmpty
            $result.IsDefault | Should -Be $true
        }

        It 'Should convert a DatabaseFileGroupSpec with all optional properties to a FileGroup object' {
            $fileSpec1 = New-SqlDscDataFile -Name 'TestFile1' -FileName 'C:\Data\TestFile1.ndf' -Size 100 -MaxSize 1000 -AsSpec
            $fileSpec2 = New-SqlDscDataFile -Name 'TestFile2' -FileName 'C:\Data\TestFile2.ndf' -Growth 10 -GrowthType 'Percent' -AsSpec
            $fileGroupSpec = New-SqlDscFileGroup -Name 'TestFileGroup' -Files @($fileSpec1, $fileSpec2) -ReadOnly $false -IsDefault $false -AsSpec

            $result = ConvertTo-SqlDscFileGroup -DatabaseObject $script:testDatabase -FileGroupSpec $fileGroupSpec

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestFileGroup'
            $result.Files.Count | Should -Be 2
            $result.Files[0].Size | Should -Be 100
            $result.Files[0].MaxSize | Should -Be 1000
            $result.Files[1].Growth | Should -Be 10
            $result.Files[1].GrowthType | Should -Be 'Percent'
            $result.ReadOnly | Should -Be $false
            $result.IsDefault | Should -Be $false
        }

        It 'Should preserve file properties when converting FileGroup with complex file configurations' {
            $primaryFile = New-SqlDscDataFile -Name 'PrimaryFile' -FileName 'C:\Data\Primary.mdf' -IsPrimaryFile $true -Size 200 -MaxSize 2000 -Growth 20 -GrowthType 'KB' -AsSpec
            $secondaryFile = New-SqlDscDataFile -Name 'SecondaryFile' -FileName 'C:\Data\Secondary.ndf' -Size 100 -MaxSize 1000 -Growth 10 -GrowthType 'Percent' -AsSpec
            $fileGroupSpec = New-SqlDscFileGroup -Name 'ComplexFileGroup' -Files @($primaryFile, $secondaryFile) -AsSpec

            $result = ConvertTo-SqlDscFileGroup -DatabaseObject $script:testDatabase -FileGroupSpec $fileGroupSpec

            $result | Should -Not -BeNullOrEmpty
            $result.Files.Count | Should -Be 2

            # Verify primary file properties
            $result.Files[0].Name | Should -Be 'PrimaryFile'
            $result.Files[0].IsPrimaryFile | Should -Be $true
            $result.Files[0].Size | Should -Be 200
            $result.Files[0].MaxSize | Should -Be 2000
            $result.Files[0].Growth | Should -Be 20
            $result.Files[0].GrowthType | Should -Be 'KB'

            # Verify secondary file properties
            $result.Files[1].Name | Should -Be 'SecondaryFile'
            $result.Files[1].Size | Should -Be 100
            $result.Files[1].MaxSize | Should -Be 1000
            $result.Files[1].Growth | Should -Be 10
            $result.Files[1].GrowthType | Should -Be 'Percent'
        }
    }
}
