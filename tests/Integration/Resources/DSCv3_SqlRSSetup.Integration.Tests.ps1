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
                # Redirect all streams to $null, except the error stream (stream 3) to match other tests
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
        BeforeAll {
            # Get temporary folder for the test and make sure it exists, if not create it
            $tempFolder = Get-TemporaryFolder
            Write-Verbose -Message "Temporary folder is $tempFolder"
            if (-not (Test-Path -Path $tempFolder))
            {
                Write-Verbose -Message "Temporary folder did not exist, creating temporary folder $tempFolder"
                New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null
            }
        }

        It 'Should return the expected current state' {
            # Media file has already been saved to (Get-TemporaryFolder)\PowerBIReportServer.exe
            $desiredParameters = @{
                InstanceName = 'PBIRS'
                AcceptLicensingTerms = $true
                Action = 'Install'
                MediaPath = Join-Path -Path $tempFolder -ChildPath 'PowerBIReportServer.exe'
                InstallFolder = Join-Path -Path $env:ProgramFiles -ChildPath 'Microsoft Power BI Report Server'
                Edition = 'Developer'
                SuppressRestart = $true
                LogPath = Join-Path -Path $tempFolder -ChildPath 'PBIRS.log'
                VersionUpgrade = $true
            }

            # Capture DSC output so it can be inspected later in the test
            $result = dsc --trace-level trace resource get --resource SqlServerDsc/SqlRSSetup --output-format pretty-json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json | Out-String)" -Verbose
        }
    }

    Context 'When testing the current state of the resource' {
        BeforeAll {
            $tempFolder = Get-TemporaryFolder
        }

        It 'Should return false when the resource is not in the desired state' {
            $desiredParameters = @{
                InstanceName         = 'PBIRS'
                AcceptLicensingTerms = $true
                Action               = 'Install'
                MediaPath            = Join-Path -Path $tempFolder -ChildPath 'PowerBIReportServer.exe'
                InstallFolder        = Join-Path -Path $env:ProgramFiles -ChildPath 'Microsoft Power BI Report Server'
                Edition              = 'Developer'
                SuppressRestart      = $true
                LogPath              = Join-Path -Path $tempFolder -ChildPath 'PBIRS.log'
                VersionUpgrade       = $true
            }

            $result = dsc --trace-level trace resource test --resource SqlServerDsc/SqlRSSetup --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json | Out-String)" -Verbose

            $result.inDesiredState | Should -BeFalse
        }
    }

    Context 'When setting the current state of the resource' {
        BeforeAll {
            $tempFolder = Get-TemporaryFolder
        }

        It 'Should set the resource to the desired state' {
            $desiredParameters = @{
                InstanceName         = 'PBIRS'
                AcceptLicensingTerms = $true
                Action               = 'Install'
                MediaPath            = Join-Path -Path $tempFolder -ChildPath 'PowerBIReportServer.exe'
                InstallFolder        = Join-Path -Path $env:ProgramFiles -ChildPath 'Microsoft Power BI Report Server'
                Edition              = 'Developer'
                SuppressRestart      = $true
                LogPath              = Join-Path -Path $tempFolder -ChildPath 'PBIRS.log'
                VersionUpgrade       = $true
            }

            $result = dsc --trace-level trace resource set --resource SqlServerDsc/SqlRSSetup --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json | Out-String)" -Verbose
        }
    }

    Context 'When testing the current state of the resource after set' {
        BeforeAll {
            $tempFolder = Get-TemporaryFolder
        }

        It 'Should return true when the resource is in the desired state' {
            $desiredParameters = @{
                InstanceName         = 'PBIRS'
                AcceptLicensingTerms = $true
                Action               = 'Install'
                MediaPath            = Join-Path -Path $tempFolder -ChildPath 'PowerBIReportServer.exe'
                InstallFolder        = Join-Path -Path $env:ProgramFiles -ChildPath 'Microsoft Power BI Report Server'
                Edition              = 'Developer'
                SuppressRestart      = $true
                LogPath              = Join-Path -Path $tempFolder -ChildPath 'PBIRS.log'
                VersionUpgrade       = $true
            }

            $result = dsc --trace-level trace resource test --resource SqlServerDsc/SqlRSSetup --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json | Out-String)" -Verbose

            $result.inDesiredState | Should -BeTrue
        }
    }
}
