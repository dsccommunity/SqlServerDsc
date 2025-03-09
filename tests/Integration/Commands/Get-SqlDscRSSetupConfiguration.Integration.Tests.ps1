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

Describe 'Get-SqlDscRSSetupConfiguration' {
    Context 'When getting the configuration for SQL Server Reporting Services instance' -Tag @('Integration_SQL2017_RS') {
        It 'Should return the correct configuration for SSRS instance' {
            Write-Verbose -Message ((reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /s) | Out-String) -Verbose

            # Get the SSRS configuration
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.InstallFolder | Should -Be 'C:\Program Files\SSRS'
            $result.ServiceName | Should -Be 'SQLServerReportingServices'
            $result.ErrorDumpDirectory | Should -Be 'C:\Program Files\SSRS\SSRS\LogFiles'
            $result.CurrentVersion | Should -Be '14.0.601.20'
            $result.ProductVersion | Should -Be '16.0.9101.19239'
            $result.CustomerFeedback | Should -Be 1
            $result.EnableErrorReporting | Should -Be 1
            $result.VirtualRootServer | Should -Be 'ReportServer'
            $result.ConfigFilePath | Should -Be 'C:\Program Files\SSRS\SSRS\ReportServer\rsreportserver.config'
        }
    }

    Context 'When getting the configuration for SQL Server Reporting Services instance' -Tag @('Integration_SQL2019_RS') {
        It 'Should return the correct configuration for SSRS instance' {
            Write-Verbose -Message ((reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /s) | Out-String) -Verbose

            # Get the SSRS configuration
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.InstallFolder | Should -Be 'C:\Program Files\SSRS'
            $result.ServiceName | Should -Be 'SQLServerReportingServices'
            $result.ErrorDumpDirectory | Should -Be 'C:\Program Files\SSRS\SSRS\LogFiles'
            $result.CurrentVersion | Should -Be '15.0.1103.41'
            $result.ProductVersion | Should -Be '16.0.9101.19239'
            $result.CustomerFeedback | Should -Be 1
            $result.EnableErrorReporting | Should -Be 1
            $result.VirtualRootServer | Should -Be 'ReportServer'
            $result.ConfigFilePath | Should -Be 'C:\Program Files\SSRS\SSRS\ReportServer\rsreportserver.config'
        }
    }

    Context 'When getting the configuration for SQL Server Reporting Services instance' -Tag @('Integration_SQL2022_RS') {
        It 'Should return the correct configuration for SSRS instance' {
            Write-Verbose -Message ((reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /s) | Out-String) -Verbose

            # Get the SSRS configuration
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.InstallFolder | Should -Be 'C:\Program Files\SSRS'
            $result.ServiceName | Should -Be 'SQLServerReportingServices'
            $result.ErrorDumpDirectory | Should -Be 'C:\Program Files\SSRS\SSRS\LogFiles'
            $result.CurrentVersion | Should -Be '16.0.1116.38'
            $result.ProductVersion | Should -Be '16.0.9101.19239'
            $result.CustomerFeedback | Should -Be 1
            $result.EnableErrorReporting | Should -Be 1
            $result.VirtualRootServer | Should -Be 'ReportServer'
            $result.ConfigFilePath | Should -Be 'C:\Program Files\SSRS\SSRS\ReportServer\rsreportserver.config'
        }
    }

    Context 'When getting the configuration for Power BI Report Server instance' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS rsreportserver
        It 'Should return the correct configuration for PBIRS instance' {
            # Get the PBIRS configuration
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'
            $result.InstallFolder | Should -Be 'C:\Program Files\PBIRS'
            $result.ServiceName | Should -Be 'PowerBIReportServer'
            $result.ErrorDumpDirectory | Should -Be 'C:\Program Files\PBIRS\PBIRS\LogFiles'
            $result.CurrentVersion | Should -Be '15.0.1117.98'
            $result.ProductVersion | Should -Be '1.22.9153.7886'
            $result.CustomerFeedback | Should -Be 1
            $result.EnableErrorReporting | Should -Be 1
            $result.VirtualRootServer | Should -Be 'ReportServer'
            $result.ConfigFilePath | Should -Be 'C:\Program Files\PBIRS\PBIRS\ReportServer\rsreportserver.config'
        }
    }

    Context 'When getting all Reporting Services configurations' {
        It 'Should return configurations for all installed instances' {
            # Get all configurations
            $result = Get-SqlDscRSSetupConfiguration

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
