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

Describe 'Get-SqlDscRSPackage' {
    Context 'When getting package information for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should return the package information for SSRS' {
            $result = Get-SqlDscRSPackage -Package 'SSRS' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.ProductName | Should -Be 'Microsoft SQL Server Reporting Services'
            $result.FileVersion | Should -Not -BeNullOrEmpty
            $result.ProductVersion | Should -Not -BeNullOrEmpty
        }

        It 'Should return the same result when using FilePath parameter' {
            # Get the install folder from the setup configuration
            $setupConfig = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            $executablePath = Join-Path -Path $setupConfig.InstallFolder -ChildPath 'RSHostingService/ReportingServicesService.exe'

            $result = Get-SqlDscRSPackage -FilePath $executablePath -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.ProductName | Should -Be 'Microsoft SQL Server Reporting Services'
            $result.FileVersion | Should -Not -BeNullOrEmpty
            $result.ProductVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When getting package information for Power BI Report Server' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        It 'Should return the package information for PBIRS' {
            $result = Get-SqlDscRSPackage -Package 'PBIRS' -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.ProductName | Should -Be 'Microsoft Power BI Report Server'
            $result.FileVersion | Should -Not -BeNullOrEmpty
            $result.ProductVersion | Should -Not -BeNullOrEmpty
        }

        It 'Should return the same result when using FilePath parameter' {
            # Get the install folder from the setup configuration
            $setupConfig = Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            $executablePath = Join-Path -Path $setupConfig.InstallFolder -ChildPath 'RSHostingService/ReportingServicesService.exe'

            $result = Get-SqlDscRSPackage -FilePath $executablePath -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.ProductName | Should -Be 'Microsoft Power BI Report Server'
            $result.FileVersion | Should -Not -BeNullOrEmpty
            $result.ProductVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When getting package information for a non-existing package' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
        It 'Should throw an error when the package is not installed' {
            # PBIRS is not installed in the SSRS CI environment and vice versa
            # We can test this by checking which one is installed
            $ssrsInstalled = Test-SqlDscRSInstalled -InstanceName 'SSRS'

            if ($ssrsInstalled)
            {
                # SSRS is installed, so PBIRS should not be
                { Get-SqlDscRSPackage -Package 'PBIRS' -ErrorAction 'Stop' } | Should -Throw
            }
            else
            {
                # PBIRS is installed, so SSRS should not be
                { Get-SqlDscRSPackage -Package 'SSRS' -ErrorAction 'Stop' } | Should -Throw
            }
        }
    }

    Context 'When using Force parameter to bypass validation' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should return file version information for any executable with Force parameter' {
            # Get the install folder from the setup configuration
            $setupConfig = Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'

            $executablePath = Join-Path -Path $setupConfig.InstallFolder -ChildPath 'RSHostingService/ReportingServicesService.exe'

            # Using Force should work and return the file version info
            $result = Get-SqlDscRSPackage -FilePath $executablePath -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.FileVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using Force parameter to bypass validation' -Tag @('Integration_PowerBI') {
        It 'Should return file version information for any executable with Force parameter' {
            # Get the install folder from the setup configuration
            $setupConfig = Get-SqlDscRSSetupConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            $executablePath = Join-Path -Path $setupConfig.InstallFolder -ChildPath 'RSHostingService/ReportingServicesService.exe'

            # Using Force should work and return the file version info
            $result = Get-SqlDscRSPackage -FilePath $executablePath -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.FileVersion | Should -Not -BeNullOrEmpty
        }
    }
}
