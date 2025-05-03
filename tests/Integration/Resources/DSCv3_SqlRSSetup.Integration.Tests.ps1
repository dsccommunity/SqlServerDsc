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

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'SqlRSSetup'
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlRSSetup'
}

<#
    Run only for standalone versions of Microsoft SQL Server Reporting Services
    and Power BI Report Server. Older versions of Reporting Services (eg. 2016)
    are integration tested in separate tests (part of resource SqlSetup).
#>
Describe "$($script:dscResourceFriendlyName)_Integration" -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI') {
    Context 'When getting the current state of the resource' {
        It 'Should return the expected current state' {
            # Media file has already been saved to (Get-TemporaryFolder)\PowerBIReportServer.exe
            $desiredParameters = @{
                InstanceName = 'PBIRS'
                AcceptLicensingTerms = $true
                Action = 'Install'
                MediaPath = Join-Path -Path (Get-TemporaryFolder) -ChildPath 'PowerBIReportServer.exe'
                InstallFolder = Join-Path -Path $env:ProgramFiles -ChildPath 'Microsoft Power BI Report Server'
                Edition = 'Developer'
                SuppressRestart = $true
                LogPath = Join-Path -Path (Get-TemporaryFolder) -ChildPath 'PBIRS.log'
                VersionUpgrade = $true
            }

            dsc --trace-level trace resource get --resource SqlServerDsc/SqlRSSetup --output-format pretty-json --input ($desiredParameters | ConvertTo-Json -Compress)

            if ($LASTEXITCODE -ne 0)
            {
                throw 'Failed to get the current state of the resource.'
            }
        }
    }
}
