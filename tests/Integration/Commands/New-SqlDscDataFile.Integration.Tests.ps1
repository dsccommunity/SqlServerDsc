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

    Context 'When creating a DataFile with a FileGroup object' {
        BeforeAll {
            # Create a real SMO Database object
            $script:mockDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:mockDatabase.Name = 'TestDatabase'
            $script:mockDatabase.Parent = $script:serverObject

            $script:mockFileGroup = New-SqlDscFileGroup -Database $script:mockDatabase -Name 'TestFileGroup' -Confirm:$false
        }

        It 'Should create a DataFile and add it to FileGroup without PassThru' {
            $initialFileCount = $script:mockFileGroup.Files.Count

            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'TestDataFile' -FileName 'C:\Data\TestDataFile.ndf' -Confirm:$false

            $result | Should -BeNullOrEmpty
            $script:mockFileGroup.Files.Count | Should -Be ($initialFileCount + 1)

            $addedFile = $script:mockFileGroup.Files | Where-Object -FilterScript { $_.Name -eq 'TestDataFile' }
            $addedFile | Should -Not -BeNullOrEmpty
            $addedFile.FileName | Should -Be 'C:\Data\TestDataFile.ndf'
        }

        It 'Should create a DataFile and return it with PassThru' {
            $initialFileCount = $script:mockFileGroup.Files.Count

            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'TestDataFile2' -FileName 'C:\Data\TestDataFile2.ndf' -PassThru -Confirm:$false

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'TestDataFile2'
            $result.FileName | Should -Be 'C:\Data\TestDataFile2.ndf'
            $result.Parent | Should -Be $script:mockFileGroup
            $script:mockFileGroup.Files.Count | Should -Be ($initialFileCount + 1)
        }

        It 'Should support Force parameter to bypass confirmation' {
            $initialFileCount = $script:mockFileGroup.Files.Count

            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'ForcedDataFile' -FileName 'C:\Data\ForcedDataFile.ndf' -PassThru -Force

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.DataFile'
            $result.Name | Should -Be 'ForcedDataFile'
            $result.Parent | Should -Be $script:mockFileGroup
            $script:mockFileGroup.Files.Count | Should -Be ($initialFileCount + 1)
        }

        It 'Should not add file when WhatIf is specified' {
            $initialFileCount = $script:mockFileGroup.Files.Count

            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'DeclinedDataFile' -FileName 'C:\Data\DeclinedDataFile.ndf' -Confirm:$false -WhatIf

            $result | Should -BeNullOrEmpty
            $script:mockFileGroup.Files.Count | Should -Be $initialFileCount
        }
    }

    Context 'When verifying DataFile properties' {
        BeforeAll {
            # Create a real SMO Database object
            $script:mockDatabase = [Microsoft.SqlServer.Management.Smo.Database]::new()
            $script:mockDatabase.Name = 'TestDatabase'
            $script:mockDatabase.Parent = $script:serverObject

            $script:mockFileGroup = New-SqlDscFileGroup -Database $script:mockDatabase -Name 'TestFileGroup' -Confirm:$false
        }

        It 'Should allow setting Size property on returned DataFile' {
            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'TestDataFile' -FileName 'C:\Data\TestDataFile.ndf' -PassThru -Confirm:$false
            $result.Size = 1024.0

            $result.Size | Should -Be 1024.0
        }

        It 'Should allow setting Growth property on returned DataFile' {
            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'TestDataFile' -FileName 'C:\Data\TestDataFile.ndf' -PassThru -Confirm:$false
            $result.Growth = 64.0

            $result.Growth | Should -Be 64.0
        }

        It 'Should allow setting GrowthType property on returned DataFile' {
            $result = New-SqlDscDataFile -FileGroup $script:mockFileGroup -Name 'TestDataFile' -FileName 'C:\Data\TestDataFile.ndf' -PassThru -Confirm:$false
            $result.GrowthType = [Microsoft.SqlServer.Management.Smo.FileGrowthType]::Percent

            $result.GrowthType | Should -Be 'Percent'
        }
    }
}
