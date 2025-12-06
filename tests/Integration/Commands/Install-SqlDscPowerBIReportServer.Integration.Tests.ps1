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

Describe 'Install-SqlDscPowerBIReportServer' -Tag @('Integration_PowerBI') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $script:temporaryFolder = Get-TemporaryFolder

        # Get the path to the Power BI Report Server executable
        $powerBIReportServerExecutable = Join-Path -Path $script:temporaryFolder -ChildPath 'PowerBIReportServer.exe'
    }

    Context 'When installing Power BI Report Server' {
        # cSpell: ignore PBIRS
        It 'Should run the command without throwing' {
            # Set splatting parameters for Install-SqlDscPowerBIReportServer
            $installSqlDscBIReportServerParameters = @{
                AcceptLicensingTerms = $true
                MediaPath            = $powerBIReportServerExecutable
                InstallFolder        = 'C:\Program Files\PBIRS'
                Edition              = 'Developer'
                LogPath              = Join-Path -Path $script:temporaryFolder -ChildPath 'PowerBIReportServer_Install.log'
                SuppressRestart      = $true
                Verbose              = $true
                Force                = $true
            }

            $null = Install-SqlDscPowerBIReportServer @installSqlDscBIReportServerParameters -ErrorAction 'Stop'
        }

        It 'Should have installed Power BI Report Server' {
            # Validate the Power BI Report Server installation
            $reportServerService = Get-Service -Name 'PowerBIReportServer'

            $reportServerService | Should -Not -BeNullOrEmpty
            $reportServerService.Status | Should -Be 'Running'
        }

        It 'Should stop the Power BI Report Server service' {
            # Stop the Power BI Report Server service to save memory on the build worker
            $stopServiceResult = Stop-Service -Name 'PowerBIReportServer' -Force -PassThru -Verbose -ErrorAction 'Stop'

            write-verbose -Message ($stopServiceResult | Out-String) -Verbose

            $stopServiceResult.Status | Should -Be 'Stopped'
        }
    }
}
