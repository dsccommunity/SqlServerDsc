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

Describe 'Get-SqlDscRSPackage' {
    Context 'When getting package information for a non-existing file' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
        It 'Should throw an error when the file does not exist' {
            { Get-SqlDscRSPackage -FilePath 'C:\NonExistent\SQLServerReportingServices.exe' -ErrorAction 'Stop' } | Should -Throw
        }
    }

    Context 'When getting package information for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        BeforeAll {
            $script:temporaryFolder = Get-TemporaryFolder
            $script:reportingServicesExecutable = Join-Path -Path $script:temporaryFolder -ChildPath 'SQLServerReportingServices.exe'
        }

        It 'Should return the package information for SSRS' {
            $result = Get-SqlDscRSPackage -FilePath $script:reportingServicesExecutable -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.ProductName | Should -Be 'Microsoft SQL Server Reporting Services'
            $result.FileVersion | Should -Not -BeNullOrEmpty
            $result.ProductVersion | Should -Not -BeNullOrEmpty
        }
    }

    # cSpell: ignore PBIRS
    Context 'When getting package information for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:temporaryFolder = Get-TemporaryFolder
            $script:powerBIReportServerExecutable = Join-Path -Path $script:temporaryFolder -ChildPath 'PowerBIReportServer.exe'
        }

        It 'Should return the package information for PBIRS' {
            $result = Get-SqlDscRSPackage -FilePath $script:powerBIReportServerExecutable -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.ProductName | Should -Be 'Microsoft Power BI Report Server'
            $result.FileVersion | Should -Not -BeNullOrEmpty
            $result.ProductVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When file has an invalid product name' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
        It 'Should throw an error without Force parameter' {
            # Use an executable that exists but has a different product name
            { Get-SqlDscRSPackage -FilePath 'C:\Windows\System32\notepad.exe' -ErrorAction 'Stop' } | Should -Throw
        }

        It 'Should return version information with Force parameter' {
            $result = Get-SqlDscRSPackage -FilePath 'C:\Windows\System32\notepad.exe' -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.FileVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using Force parameter to bypass validation' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        BeforeAll {
            $script:temporaryFolder = Get-TemporaryFolder
            $script:reportingServicesExecutable = Join-Path -Path $script:temporaryFolder -ChildPath 'SQLServerReportingServices.exe'
        }

        It 'Should return file version information with Force parameter' {
            $result = Get-SqlDscRSPackage -FilePath $script:reportingServicesExecutable -Force -ErrorAction 'Stop'

            $result | Should -Not -BeNullOrEmpty
            $result.FileVersion | Should -Not -BeNullOrEmpty
        }
    }
}
