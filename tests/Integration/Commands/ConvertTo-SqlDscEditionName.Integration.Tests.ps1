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

Describe 'ConvertTo-SqlDscEditionName' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Define expected edition mappings for validation
        $script:expectedEditionMappings = @{
            2176971986 = @{
                EditionId = 2176971986
                Edition = 'Developer'
                EditionName = 'SQL Server Developer'
            }
            2017617798 = @{
                EditionId = 2017617798
                Edition = 'Developer'
                EditionName = 'Power BI Report Server - Developer'
            }
            1369084056 = @{
                EditionId = 1369084056
                Edition = 'Evaluation'
                EditionName = 'Power BI Report Server - Evaluation'
            }
        }
    }

    Context 'When converting known EditionId values' {
        It 'Should return correct mapping for SQL Server Developer edition ID (2176971986)' {
            $result = ConvertTo-SqlDscEditionName -Id 2176971986 -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.EditionId | Should -Be $script:expectedEditionMappings[2176971986].EditionId
            $result.Edition | Should -Be $script:expectedEditionMappings[2176971986].Edition
            $result.EditionName | Should -Be $script:expectedEditionMappings[2176971986].EditionName
        }

        It 'Should return correct mapping for Power BI Report Server Developer edition ID (2017617798)' {
            $result = ConvertTo-SqlDscEditionName -Id 2017617798 -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.EditionId | Should -Be $script:expectedEditionMappings[2017617798].EditionId
            $result.Edition | Should -Be $script:expectedEditionMappings[2017617798].Edition
            $result.EditionName | Should -Be $script:expectedEditionMappings[2017617798].EditionName
        }

        It 'Should return correct mapping for Power BI Report Server Evaluation edition ID (1369084056)' {
            $result = ConvertTo-SqlDscEditionName -Id 1369084056 -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.EditionId | Should -Be $script:expectedEditionMappings[1369084056].EditionId
            $result.Edition | Should -Be $script:expectedEditionMappings[1369084056].Edition
            $result.EditionName | Should -Be $script:expectedEditionMappings[1369084056].EditionName
        }
    }

    Context 'When converting unknown EditionId values' {
        It 'Should return Unknown for an unknown EditionId (99999)' {
            $result = ConvertTo-SqlDscEditionName -Id 99999 -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.EditionId | Should -Be 99999
            $result.Edition | Should -Be 'Unknown'
            $result.EditionName | Should -Be 'Unknown'
        }

        It 'Should return Unknown for another unknown EditionId (0)' {
            $result = ConvertTo-SqlDscEditionName -Id 0 -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.EditionId | Should -Be 0
            $result.Edition | Should -Be 'Unknown'
            $result.EditionName | Should -Be 'Unknown'
        }

        It 'Should return Unknown for a large unknown EditionId (4294967295)' {
            $result = ConvertTo-SqlDscEditionName -Id 4294967295 -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.EditionId | Should -Be 4294967295
            $result.Edition | Should -Be 'Unknown'
            $result.EditionName | Should -Be 'Unknown'
        }
    }

    Context 'When validating output object properties' {
        It 'Should return PSCustomObject with correct properties' {
            $result = ConvertTo-SqlDscEditionName -Id 2176971986 -ErrorAction 'Stop'

            $result | Should -BeOfType ([System.Management.Automation.PSCustomObject])
            $result.PSObject.Properties.Name | Should -Contain 'EditionId'
            $result.PSObject.Properties.Name | Should -Contain 'Edition'
            $result.PSObject.Properties.Name | Should -Contain 'EditionName'
            $result.PSObject.Properties.Name | Should -HaveCount 3
        }

        It 'Should return consistent object types for all EditionId values' {
            $resultKnown = ConvertTo-SqlDscEditionName -Id 2176971986 -ErrorAction 'Stop'
            $resultUnknown = ConvertTo-SqlDscEditionName -Id 99999 -ErrorAction 'Stop'

            $resultKnown.GetType() | Should -Be $resultUnknown.GetType()

            # Verify both have the same property structure
            $resultKnown.PSObject.Properties.Name | Should -Be $resultUnknown.PSObject.Properties.Name
        }

        It 'Should return EditionId as UInt32 type' {
            $result = ConvertTo-SqlDscEditionName -Id 2176971986 -ErrorAction 'Stop'

            $result.EditionId | Should -BeOfType ([System.UInt32])
        }

        It 'Should return Edition and EditionName as String types' {
            $result = ConvertTo-SqlDscEditionName -Id 2176971986 -ErrorAction 'Stop'

            $result.Edition | Should -BeOfType ([System.String])
            $result.EditionName | Should -BeOfType ([System.String])
        }
    }

    Context 'When testing parameter validation' {
        It 'Should accept minimum UInt32 value (0)' {
            $null = ConvertTo-SqlDscEditionName -Id 0 -ErrorAction 'Stop'
        }

        It 'Should accept maximum UInt32 value (4294967295)' {
            $null = ConvertTo-SqlDscEditionName -Id 4294967295 -ErrorAction 'Stop'
        }
    }
}
