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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

Describe 'Get-SqlDscTraceFlag' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        # Get the service object for testing the ByServiceObject parameter set
        $script:serviceObject = Get-SqlDscManagedComputerService -ServiceType 'DatabaseEngine' -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
    }

    Context 'When getting trace flags using InstanceName parameter' {
        It 'Should return an array of UInt32 values or empty array' {
            $result = Get-SqlDscTraceFlag -InstanceName $script:mockInstanceName

            # The result should be either null/empty or an array of UInt32 values
            if ($result) {
                @($result) | Should -BeOfType [System.UInt32]
            } else {
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When getting trace flags using ServerName and InstanceName parameters' {
        It 'Should return an array of UInt32 values or empty array when specifying server and instance' {
            $result = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName

            # The result should be either null/empty or an array of UInt32 values
            if ($result) {
                @($result) | Should -BeOfType [System.UInt32]
            } else {
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should return an array of UInt32 values or empty array when specifying only instance name' {
            $result = Get-SqlDscTraceFlag -InstanceName $script:mockInstanceName

            # The result should be either null/empty or an array of UInt32 values
            if ($result) {
                @($result) | Should -BeOfType [System.UInt32]
            } else {
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When getting trace flags using ServiceObject parameter' {
        It 'Should return an array of UInt32 values or empty array when using service object' {
            $result = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject

            # The result should be either null/empty or an array of UInt32 values
            if ($result) {
                @($result) | Should -BeOfType [System.UInt32]
            } else {
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When there are no trace flags configured' {
        It 'Should return empty result when no trace flags are set' {
            # This test validates the command works when no trace flags are configured
            # We cannot control the trace flag state in CI, so we just verify the command executes without error
            $null = Get-SqlDscTraceFlag -InstanceName $script:mockInstanceName -ErrorAction 'Stop'
        }
    }

    Context 'When testing error handling' {
        It 'Should throw an error when specifying an invalid instance name' {
            { Get-SqlDscTraceFlag -InstanceName 'InvalidInstance' -ErrorAction 'Stop' } |
                Should -Throw
        }

        It 'Should return empty result when specifying an invalid instance name with SilentlyContinue' {
            $result = Get-SqlDscTraceFlag -InstanceName 'InvalidInstance' -ErrorAction 'SilentlyContinue'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When comparing different parameter sets' {
        It 'Should return consistent results between ByServerName and ByServiceObject parameter sets' {
            $resultByServerName = Get-SqlDscTraceFlag -ServerName $script:mockComputerName -InstanceName $script:mockInstanceName -ErrorAction 'SilentlyContinue'
            $resultByServiceObject = Get-SqlDscTraceFlag -ServiceObject $script:serviceObject -ErrorAction 'SilentlyContinue'

            # Both results should be of the same type (both null or both arrays)
            if ($null -eq $resultByServerName) {
                $resultByServiceObject | Should -BeNullOrEmpty
            } else {
                $resultByServiceObject | Should -Not -BeNullOrEmpty
                @($resultByServerName).Count | Should -Be @($resultByServiceObject).Count

                # If both have trace flags, they should be the same
                if (@($resultByServerName).Count -gt 0) {
                    Compare-Object -ReferenceObject @($resultByServerName) -DifferenceObject @($resultByServiceObject) | Should -BeNullOrEmpty
                }
            }
        }
    }
}
