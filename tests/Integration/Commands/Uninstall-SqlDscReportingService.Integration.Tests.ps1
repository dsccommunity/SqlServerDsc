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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Uninstall-SqlDscReportingService' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Starting the Power BI Report Server service prior to running tests.
        Start-Service -Name 'SQLServerReportingServices' -Verbose -ErrorAction 'Stop'

        $script:temporaryFolder = Get-TemporaryFolder

        # Get the path to the Reporting Services executable
        $reportingServicesExecutable = Join-Path -Path $script:temporaryFolder -ChildPath 'SQLServerReportingServices.exe'
    }

    It 'Should have the Reporting Services service running' {
        $getServiceResult = Get-Service -Name 'SQLServerReportingServices' -ErrorAction 'Stop'

        $getServiceResult.Status | Should -Be 'Running'
    }

    Context 'When uninstalling Reporting Services' {
        It 'Should run the command without throwing' {
            {
                # Set splatting parameters for Uninstall-SqlDscReportingService
                $uninstallSqlDscReportingServiceParameters = @{
                    MediaPath       = $reportingServicesExecutable
                    LogPath         = Join-Path -Path $script:temporaryFolder -ChildPath 'SSRS_Uninstall.log'
                    SuppressRestart = $true
                    Verbose         = $true
                    ErrorAction     = 'Stop'
                    Force           = $true
                }

                Uninstall-SqlDscReportingService @uninstallSqlDscReportingServiceParameters
            } | Should -Not -Throw
        }

        It 'Should not have a SQL Server Reporting Services service' {
            Get-Service -Name 'SQLServerReportingServices' -ErrorAction 'Ignore' | Should -BeNullOrEmpty
        }
    }
}
