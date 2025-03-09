[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Get-SqlDscInstalledInstance' {
    Context 'When getting all SQL Server instances' -Tag @('Integration_PowerBI') {
        It 'Should not throw an exception' {
            { Get-SqlDscInstalledInstance } | Should -Not -Throw
        }

        It 'Should return an array of objects' {
            $result = Get-SqlDscInstalledInstance

            $result | Should -BeOfType ([System.Object[]])
        }
    }

    Context 'When getting a specific SQL Server instance by name' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        It 'Should return the specified instance when it exists' {
            $result = Get-SqlDscInstalledInstance -InstanceName 'PBIRS'

            $result.InstanceName | Should -Be 'PBIRS'
        }

        It 'Should return an empty array when the instance does not exist' {
            $result = Get-SqlDscInstalledInstance -InstanceName 'NonExistentInstance'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When filtering by service type' -Tag @('Integration_PowerBI') {
        It 'Should filter instances by DatabaseEngine service type' {
            $result = Get-SqlDscInstalledInstance -ServiceType 'ReportingServices'

            $result.InstanceName | Should -Be 'PBIRS'
            $result.ServiceType | Should -Be 'ReportingServices'
        }

        It 'Should filter instances by multiple service types' {
            $result = Get-SqlDscInstalledInstance -ServiceType @('DatabaseEngine', 'AnalysisServices')

            # All returned instances should be of specified types
            foreach ($instance in $result)
            {
                $instance.ServiceType | Should -BeIn @('DatabaseEngine', 'AnalysisServices')
            }
        }
    }

    Context 'When using both instance name and service type parameters' -Tag @('Integration_PowerBI') {
        It 'Should filter instances by DatabaseEngine service type' {
            $result = Get-SqlDscInstalledInstance -InstanceName 'PBIRS' -ServiceType 'ReportingServices'

            $result.InstanceName | Should -Be 'PBIRS'
            $result.ServiceType | Should -Be 'ReportingServices'
        }

        It 'Should return empty when instance name and service type do not match' {
            $result = Get-SqlDscInstalledInstance -InstanceName 'PBIRS' -ServiceType 'DatabaseEngine'

            $result | Should -BeNullOrEmpty
        }
    }
}
