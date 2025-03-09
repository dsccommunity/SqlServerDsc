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

Describe 'Uninstall-SqlDscBIReportServer' -Tag @('Integration_PowerBI') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Starting the Power BI Report Server service prior to running tests.
        Start-Service -Name 'PowerBIReportServer' -Verbose -ErrorAction 'Stop'

        $script:temporaryFolder = Get-TemporaryFolder

        # Get the path to the Power BI Report Server executable
        $powerBIReportServerExecutable = Join-Path -Path $script:temporaryFolder -ChildPath 'PowerBIReportServer.exe'
    }

    It 'Should have the BI Report Server service running' {
        $getServiceResult = Get-Service -Name 'PowerBIReportServer' -ErrorAction 'Stop'

        $getServiceResult.Status | Should -Be 'Running'
    }

    Context 'When uninstalling BI Report Server' {
        It 'Should run the command without throwing' {
            {
                # Set splatting parameters for Uninstall-SqlDscBIReportServer
                $uninstallSqlDscBIReportServerParameters = @{
                    MediaPath       = $powerBIReportServerExecutable
                    LogPath         = Join-Path -Path $script:temporaryFolder -ChildPath 'SSRS_Uninstall.log'
                    SuppressRestart = $true
                    Verbose         = $true
                    ErrorAction     = 'Stop'
                    Force           = $true
                }

                Uninstall-SqlDscBIReportServer @uninstallSqlDscBIReportServerParameters
            } | Should -Not -Throw
        }

        It 'Should not have a Power BI Report Server service' {
            Get-Service -Name 'PowerBIReportServer' -ErrorAction 'Ignore' | Should -BeNullOrEmpty
        }
    }
}
