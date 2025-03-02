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

Describe 'Install-SqlDscReportingService' -Tag @('Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $script:temporaryFolder = Get-TemporaryFolder

        # Get the path to the Reporting Services executable
        $reportingServicesExecutable = Join-Path -Path $script:temporaryFolder -ChildPath 'SQLServerReportingServices.exe'
    }

    Context 'When installing SQL Server 2022 Reporting Services' {
        It 'Should run the command without throwing' {
            {
                # Set splatting parameters for Install-SqlDscReportingService
                $installSqlDscReportingServicesParameters = @{
                    AcceptLicensingTerms = $true
                    MediaPath            = $reportingServicesExecutable
                    Edition              = 'Developer'
                    LogPath              = Join-Path -Path $script:temporaryFolder -ChildPath 'SSRS_Install.log'
                    SuppressRestart      = $true
                    Verbose              = $true
                    Force                = $true
                }

                Install-SqlDscReportingService @installSqlDscReportingServicesParameters
            } | Should -Not -Throw
        }

        It 'Should have installed SQL Server 2022 Reporting Services' {
            # Validate the Reporting Services installation
            $reportServerService = Get-Service -Name 'SQLServerReportingServices'

            $reportServerService | Should -Not -BeNullOrEmpty
            $reportServerService.Status | Should -Be 'Running'
        }

        It 'Should stop the Reporting Services service' {
            # Stop the Reporting Services service to save memory on the build worker
            $stopServiceResult = Stop-Service -Name 'SQLServerReportingServices' -Force -PassThru -Verbose -ErrorAction 'Stop'

            write-verbose -Message ($stopServiceResult | Out-String) -Verbose

            $stopServiceResult.Status | Should -Be 'Stopped'
        }
    }
}
