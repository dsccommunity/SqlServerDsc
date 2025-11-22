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

Describe 'ConvertTo-SqlDscDataFile' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
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

    Context 'When converting a DatabaseFileSpec to a DataFile with real SMO types' {
        BeforeAll {
            $script:testDatabaseName = 'TestDB_{0}' -f (Get-Random)

            # Create a test database for the file group context
            $script:testDatabase = New-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Confirm:$false
        }

        AfterAll {
            # Clean up the test database
            if ($script:testDatabase)
            {
                Remove-SqlDscDatabase -ServerObject $script:serverObject -Name $script:testDatabaseName -Confirm:$false
            }
        }

        BeforeEach {
            $script:mockFileGroup = New-SqlDscFileGroup -Database $script:testDatabase -Name 'TestFileGroup' -Confirm:$false
        }

        It 'Should convert a minimal DatabaseFileSpec to a DataFile object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup -DatabaseFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DataFile]
            $result.Name | Should -Be 'TestFile'
            $result.FileName | Should -Be 'C:\Data\TestFile.ndf'
        }

        It 'Should convert a DatabaseFileSpec with Size to a DataFile object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -Size 100 -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup -DatabaseFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result.Size | Should -Be 100
        }

        It 'Should convert a DatabaseFileSpec with MaxSize to a DataFile object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -MaxSize 1000 -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup -DatabaseFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result.MaxSize | Should -Be 1000
        }

        It 'Should convert a DatabaseFileSpec with Growth to a DataFile object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -Growth 10 -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup -DatabaseFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result.Growth | Should -Be 10
        }

        It 'Should convert a DatabaseFileSpec with GrowthType to a DataFile object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -GrowthType 'Percent' -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup -DatabaseFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result.GrowthType | Should -Be 'Percent'
        }

        It 'Should convert a DatabaseFileSpec with IsPrimaryFile to a DataFile object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.mdf' -IsPrimaryFile $true -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup -DatabaseFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result.IsPrimaryFile | Should -Be $true
        }

        It 'Should convert a DatabaseFileSpec with all optional properties to a DataFile object' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -Size 100 -MaxSize 1000 -Growth 10 -GrowthType 'Percent' -AsSpec

            $result = ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup -DatabaseFileSpec $fileSpec

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestFile'
            $result.FileName | Should -Be 'C:\Data\TestFile.ndf'
            $result.Size | Should -Be 100
            $result.MaxSize | Should -Be 1000
            $result.Growth | Should -Be 10
            $result.GrowthType | Should -Be 'Percent'
        }

        It 'Should accept DatabaseFileSpec from pipeline' {
            $fileSpec = New-SqlDscDataFile -Name 'TestFile' -FileName 'C:\Data\TestFile.ndf' -AsSpec

            $result = $fileSpec | ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Microsoft.SqlServer.Management.Smo.DataFile]
            $result.Name | Should -Be 'TestFile'
        }

        It 'Should convert multiple DatabaseFileSpecs from pipeline' {
            $fileSpec1 = New-SqlDscDataFile -Name 'TestFile1' -FileName 'C:\Data\TestFile1.ndf' -AsSpec
            $fileSpec2 = New-SqlDscDataFile -Name 'TestFile2' -FileName 'C:\Data\TestFile2.ndf' -AsSpec

            $result = @($fileSpec1, $fileSpec2) | ConvertTo-SqlDscDataFile -FileGroup $script:mockFileGroup

            $result | Should -HaveCount 2
            $result[0].Name | Should -Be 'TestFile1'
            $result[1].Name | Should -Be 'TestFile2'
        }
    }
}
