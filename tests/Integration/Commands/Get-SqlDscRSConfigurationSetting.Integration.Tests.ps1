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

Describe 'Get-SqlDscRSConfigurationSetting' {
    Context 'When getting the configuration settings for SQL Server Reporting Services instance' -Tag @('Integration_SQL2017_RS') {
        It 'Should return the correct configuration settings for SSRS instance' {
            # Get the SSRS configuration settings
            $result = Get-SqlDscRSConfigurationSetting -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            [System.Version] $result.Version | Should -BeGreaterOrEqual ([System.Version] '14.0.601.20')
            $result.PathName | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\rsreportserver.config'
            $result.InstallationID | Should -Not -BeNullOrEmpty
            $result.IsInitialized | Should -BeFalse
            $result.IsSharePointIntegrated | Should -BeFalse
            $result.IsWebServiceEnabled | Should -BeTrue
            $result.IsWindowsServiceEnabled | Should -BeTrue
            $result.IsTlsConfigured | Should -BeFalse
            $result.DatabaseServerName | Should -BeNullOrEmpty
            $result.DatabaseName | Should -BeNullOrEmpty
            $result.DatabaseLogonType | Should -Be 2
            $result.DatabaseLogonAccount | Should -BeNullOrEmpty
            $result.ServiceAccount | Should -Be 'NT SERVICE\SQLServerReportingServices'
            $result.WebServiceApplicationName | Should -Be 'ReportServerWebService'
            $result.WebServiceVirtualDirectory | Should -BeNullOrEmpty
            $result.WebPortalApplicationName | Should -Be 'ReportServerWebApp'
            $result.WebPortalVirtualDirectory | Should -BeNullOrEmpty
        }
    }

    Context 'When getting the configuration settings for SQL Server Reporting Services instance' -Tag @('Integration_SQL2019_RS') {
        It 'Should return the correct configuration settings for SSRS instance' {
            # Get the SSRS configuration settings
            $result = Get-SqlDscRSConfigurationSetting -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            [System.Version] $result.Version | Should -BeGreaterOrEqual ([System.Version] '15.0.1103.41')
            $result.PathName | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\rsreportserver.config'
            $result.InstallationID | Should -Not -BeNullOrEmpty
            $result.IsInitialized | Should -BeTrue
            $result.IsSharePointIntegrated | Should -BeFalse
            $result.IsWebServiceEnabled | Should -BeTrue
            $result.IsWindowsServiceEnabled | Should -BeTrue
            $result.IsTlsConfigured | Should -BeFalse
            $result.DatabaseServerName | Should -BeNullOrEmpty
            $result.DatabaseName | Should -BeNullOrEmpty
            $result.DatabaseLogonType | Should -Be 2
            $result.DatabaseLogonAccount | Should -BeNullOrEmpty
            $result.ServiceAccount | Should -Be 'NT SERVICE\SQLServerReportingServices'
            $result.WebServiceApplicationName | Should -Be 'ReportServerWebService'
            $result.WebServiceVirtualDirectory | Should -BeNullOrEmpty
            $result.WebPortalApplicationName | Should -Be 'ReportServerWebApp'
            $result.WebPortalVirtualDirectory | Should -BeNullOrEmpty
        }
    }

    Context 'When getting the configuration settings for SQL Server Reporting Services instance' -Tag @('Integration_SQL2022_RS') {
        It 'Should return the correct configuration settings for SSRS instance' {
            # Get the SSRS configuration settings
            $result = Get-SqlDscRSConfigurationSetting -InstanceName 'SSRS' -ErrorAction 'Stop'

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
            [System.Version] $result.Version | Should -BeGreaterOrEqual ([System.Version] '16.0.1116.38')
            $result.PathName | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer\rsreportserver.config'
            $result.InstallationID | Should -Not -BeNullOrEmpty
            $result.IsInitialized | Should -BeTrue
            $result.IsSharePointIntegrated | Should -BeFalse
            $result.IsWebServiceEnabled | Should -BeTrue
            $result.IsWindowsServiceEnabled | Should -BeTrue
            $result.IsTlsConfigured | Should -BeFalse
            $result.DatabaseServerName | Should -BeNullOrEmpty
            $result.DatabaseName | Should -BeNullOrEmpty
            $result.DatabaseLogonType | Should -Be 2
            $result.DatabaseLogonAccount | Should -BeNullOrEmpty
            $result.ServiceAccount | Should -Be 'NT SERVICE\SQLServerReportingServices'
            $result.WebServiceApplicationName | Should -Be 'ReportServerWebService'
            $result.WebServiceVirtualDirectory | Should -BeNullOrEmpty
            $result.WebPortalApplicationName | Should -Be 'ReportServerWebApp'
            $result.WebPortalVirtualDirectory | Should -BeNullOrEmpty
        }
    }

    Context 'When getting all Reporting Services instances' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should return configuration settings for all instances' {
            # Get all SSRS configuration settings
            $result = Get-SqlDscRSConfigurationSetting

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [System.Array]

            # Verify each instance has required properties
            foreach ($instance in $result)
            {
                $instance.InstanceName | Should -Not -BeNullOrEmpty
                $instance.Version | Should -Not -BeNullOrEmpty
                $instance.PathName | Should -Not -BeNullOrEmpty
                $instance.InstallationID | Should -Not -BeNullOrEmpty
                $instance.IsInitialized | Should -BeOfType [System.Boolean]
                $instance.IsSharePointIntegrated | Should -BeOfType [System.Boolean]
                $instance.IsWebServiceEnabled | Should -BeOfType [System.Boolean]
                $instance.IsWindowsServiceEnabled | Should -BeOfType [System.Boolean]
                $instance.IsTlsConfigured | Should -BeOfType [System.Boolean]
                $instance.ServiceAccount | Should -Not -BeNullOrEmpty
                $instance.WebServiceApplicationName | Should -Be 'ReportServerWebService'
                $instance.WebPortalApplicationName | Should -Be 'ReportServerWebApp'
            }
        }
    }
}
