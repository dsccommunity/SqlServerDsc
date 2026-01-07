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

<#
    .NOTES
        Initialize-SqlDscRS is a complex command that initializes a Reporting Services
        instance. This test is designed to be run in a CI environment where the
        instance may already be initialized. The test verifies the command can be
        called without throwing, even if initialization is already complete.
#>
Describe 'Initialize-SqlDscRS' {
    Context 'When initializing SQL Server 2017 Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Check if already initialized
            $script:isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'
        }

        It 'Should return initialization status' {
            $script:isInitialized | Should -BeOfType [System.Boolean]
        }

        It 'Should initialize or return already initialized' -Skip:$script:isInitialized {
            # Only run initialization if not already initialized
            $script:configuration | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
        }

        It 'Should return configuration when using PassThru on initialized instance' {
            # Re-initialize (should be idempotent)
            $result = $script:configuration | Initialize-SqlDscRS -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }

        It 'Should restart the service to ensure initialization is complete' {
            <#
                After initialization, the Reporting Services service must be restarted
                for the web services to be fully functional. This is consistent with
                the behavior in the SqlRS MOF resource.
            #>
            $script:configuration | Restart-SqlDscRSService -WaitTime 30 -Force -ErrorAction 'Stop'
        }
    }

    Context 'When initializing SQL Server 2019 Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $script:isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'
        }

        It 'Should return initialization status' {
            $script:isInitialized | Should -BeOfType [System.Boolean]
        }

        It 'Should initialize or return already initialized' -Skip:$script:isInitialized {
            $script:configuration | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
        }

        It 'Should return configuration when using PassThru on initialized instance' {
            $result = $script:configuration | Initialize-SqlDscRS -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }

        It 'Should restart the service to ensure initialization is complete' {
            <#
                After initialization, the Reporting Services service must be restarted
                for the web services to be fully functional. This is consistent with
                the behavior in the SqlRS MOF resource.
            #>
            $script:configuration | Restart-SqlDscRSService -WaitTime 30 -Force -ErrorAction 'Stop'
        }
    }

    Context 'When initializing SQL Server 2022 Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $script:isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'
        }

        It 'Should return initialization status' {
            $script:isInitialized | Should -BeOfType [System.Boolean]
        }

        It 'Should initialize or return already initialized' -Skip:$script:isInitialized {
            $script:configuration | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
        }

        It 'Should return configuration when using PassThru on initialized instance' {
            $result = $script:configuration | Initialize-SqlDscRS -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }

        It 'Should restart the service to ensure initialization is complete' {
            <#
                After initialization, the Reporting Services service must be restarted
                for the web services to be fully functional. This is consistent with
                the behavior in the SqlRS MOF resource.
            #>
            $script:configuration | Restart-SqlDscRSService -WaitTime 30 -Force -ErrorAction 'Stop'
        }
    }

    Context 'When initializing Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $script:isInitialized = $script:configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'
        }

        It 'Should return initialization status' {
            $script:isInitialized | Should -BeOfType [System.Boolean]
        }

        It 'Should initialize or return already initialized' -Skip:$script:isInitialized {
            $script:configuration | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
        }

        It 'Should return configuration when using PassThru on initialized instance' {
            $result = $script:configuration | Initialize-SqlDscRS -Force -PassThru -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'
        }

        It 'Should restart the service to ensure initialization is complete' {
            <#
                After initialization, the Reporting Services service must be restarted
                for the web services to be fully functional. This is consistent with
                the behavior in the SqlRS MOF resource.
            #>
            $script:configuration | Restart-SqlDscRSService -WaitTime 30 -Force -ErrorAction 'Stop'
        }
    }
}
