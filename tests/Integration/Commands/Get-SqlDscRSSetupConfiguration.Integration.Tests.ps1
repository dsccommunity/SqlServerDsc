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
            #Write-Verbose -Message ((reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /s) | Out-String) -Verbose

            # Get the SSRS configuration
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.InstallFolder | Should -Be 'C:\Program Files\SSRS'
            $result.ServiceName | Should -Be 'SQLServerReportingServices'
            $result.ErrorDumpDirectory | Should -Be 'C:\Program Files\SSRS\SSRS\LogFiles'
            [System.Version] $result.CurrentVersion | Should -BeGreaterOrEqual ([System.Version] '14.0.601.20')
            $result.ProductVersion | Should -BeNullOrEmpty
            $result.CustomerFeedback | Should -Be 1
            $result.EnableErrorReporting | Should -Be 1
            $result.VirtualRootServer | Should -Be 'ReportServer'
            $result.ConfigFilePath | Should -Be 'C:\Program Files\SSRS\SSRS\ReportServer\rsreportserver.config'
            $result.InstanceId | Should -Be 'SSRS'
            $result.EditionID | Should -Be 2176971986
            $result.EditionName | Should -Be 'SQL Server Developer'
            $result.IsSharePointIntegrated | Should -BeFalse
        }
    }

    Context 'When getting the configuration for SQL Server Reporting Services instance' -Tag @('Integration_SQL2019_RS') {
        It 'Should return the correct configuration for SSRS instance' {
            #Write-Verbose -Message ((reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /s) | Out-String) -Verbose

            # Get the SSRS configuration
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.InstallFolder | Should -Be 'C:\Program Files\SSRS'
            $result.ServiceName | Should -Be 'SQLServerReportingServices'
            $result.ErrorDumpDirectory | Should -Be 'C:\Program Files\SSRS\SSRS\LogFiles'
            [System.Version] $result.CurrentVersion | Should -BeGreaterOrEqual ([System.Version] '15.0.1103.41')
            [System.Version] $result.ProductVersion | Should -BeGreaterOrEqual ([System.Version] '15.0.9098.6826')
            $result.CustomerFeedback | Should -Be 1
            $result.EnableErrorReporting | Should -Be 1
            $result.VirtualRootServer | Should -Be 'ReportServer'
            $result.ConfigFilePath | Should -Be 'C:\Program Files\SSRS\SSRS\ReportServer\rsreportserver.config'
            $result.InstanceId | Should -Be 'SSRS'
            $result.EditionID | Should -Be 2176971986
            $result.EditionName | Should -Be 'SQL Server Developer'
            $result.IsSharePointIntegrated | Should -BeFalse
        }
    }

    Context 'When getting the configuration for SQL Server Reporting Services instance' -Tag @('Integration_SQL2022_RS') {
        It 'Should return the correct configuration for SSRS instance' {
            #Write-Verbose -Message ((reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /s) | Out-String) -Verbose

            # Get the SSRS configuration
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            $result.InstallFolder | Should -Be 'C:\Program Files\SSRS'
            $result.ServiceName | Should -Be 'SQLServerReportingServices'
            $result.ErrorDumpDirectory | Should -Be 'C:\Program Files\SSRS\SSRS\LogFiles'
            [System.Version] $result.CurrentVersion | Should -BeGreaterOrEqual ([System.Version] '16.0.1116.38')
            [System.Version] $result.ProductVersion | Should -BeGreaterOrEqual ([System.Version] '16.0.9101.19239')
            $result.CustomerFeedback | Should -Be 1
            $result.EnableErrorReporting | Should -Be 1
            $result.VirtualRootServer | Should -Be 'ReportServer'
            $result.ConfigFilePath | Should -Be 'C:\Program Files\SSRS\SSRS\ReportServer\rsreportserver.config'
            $result.InstanceId | Should -Be 'SSRS'
            $result.EditionID | Should -Be 2176971986
            $result.EditionName | Should -Be 'SQL Server Developer'
            $result.IsSharePointIntegrated | Should -BeFalse
        }
    }

    Context 'When getting the configuration for Power BI Report Server instance' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS rsreportserver
        It 'Should return the correct configuration for PBIRS instance' {
            #Write-Verbose -Message ((reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /s) | Out-String) -Verbose

            # Get the PBIRS configuration
            $result = Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS'

            # TODO: Remove this line when debug is no longer necessary
            Write-Verbose -Message ($result | Out-String) -Verbose

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'
            $result.InstallFolder | Should -Be 'C:\Program Files\PBIRS'
            $result.ServiceName | Should -Be 'PowerBIReportServer'
            $result.ErrorDumpDirectory | Should -Be 'C:\Program Files\PBIRS\PBIRS\LogFiles'
            [System.Version] $result.CurrentVersion | Should -BeGreaterOrEqual ([System.Version] '15.0.1117.98')
            [System.Version] $result.ProductVersion | Should -BeGreaterOrEqual ([System.Version] '1.22.9153.7886')
            $result.CustomerFeedback | Should -Be 1
            $result.EnableErrorReporting | Should -Be 1
            $result.VirtualRootServer | Should -Be 'ReportServer'
            $result.ConfigFilePath | Should -Be 'C:\Program Files\PBIRS\PBIRS\ReportServer\rsreportserver.config'
            $result.InstanceId | Should -Be 'PBIRS'
            $result.EditionID | Should -Be 1369084056
            $result.EditionName | Should -Be 'Power BI Report Server - Developer'
            $result.IsSharePointIntegrated | Should -BeFalse
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
