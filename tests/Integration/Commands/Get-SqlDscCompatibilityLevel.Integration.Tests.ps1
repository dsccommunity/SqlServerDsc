[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

# cSpell: ignore DSCSQLTEST
Describe 'Get-SqlDscCompatibilityLevel' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'
    }

    AfterAll {
        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject -ErrorAction 'Stop'
    }

    Context 'When getting compatibility levels' {
        BeforeAll {
            # Determine expected compatibility levels based on server major version
            switch ($script:serverObject.VersionMajor)
            {
                14 # SQL Server 2017
                {
                    $script:expectedLevels = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140')
                }
                15 # SQL Server 2019
                {
                    $script:expectedLevels = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150')
                }
                16 # SQL Server 2022
                {
                    $script:expectedLevels = @('Version100', 'Version110', 'Version120', 'Version130', 'Version140', 'Version150', 'Version160')
                }
                default
                {
                    throw "Unsupported SQL Server version: $($script:serverObject.VersionMajor)"
                }
            }
        }

        It 'Should return the correct compatibility levels based on server version' {
            $result = Get-SqlDscCompatibilityLevel -ServerObject $script:serverObject

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.String]

            # All results should match Version pattern
            foreach ($compatLevel in $result)
            {
                $compatLevel | Should -Match '^Version\d+$'
            }

            # Verify the result matches expected compatibility levels
            $result | Should -HaveCount $script:expectedLevels.Count
            foreach ($expectedLevel in $script:expectedLevels)
            {
                $result | Should -Contain $expectedLevel
            }
        }

        It 'Should return the correct compatibility levels when using Version parameter' {
            $serverVersion = [System.Version]::new($script:serverObject.VersionMajor, 0)

            $result = Get-SqlDscCompatibilityLevel -Version $serverVersion

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.String]

            # Verify the result matches expected compatibility levels
            $result | Should -HaveCount $script:expectedLevels.Count
            foreach ($expectedLevel in $script:expectedLevels)
            {
                $result | Should -Contain $expectedLevel
            }
        }
    }
}
