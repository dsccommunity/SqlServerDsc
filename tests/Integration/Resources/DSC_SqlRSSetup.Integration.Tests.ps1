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

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'SqlRSSetup'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\TestHelpers\CommonTestHelper.psm1')

    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlRSSetup'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    # Download Microsoft SQL Server Reporting Services (October 2017) executable
    if (-not (Test-Path -Path $ConfigurationData.AllNodes.MediaPath))
    {
        # By switching to 'SilentlyContinue' should theoretically increase the download speed.
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2017')
        {
            $script:mockSourceMediaDisplayName = 'Microsoft SQL Server Reporting Services (October 2017)'
            $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/E/6/4/E6477A2A-9B58-40F7-8AD6-62BB8491EA78/SQLServerReportingServices.exe'
        }

        if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2019')
        {
            <#
                The version below is what the MS download page said, but the .exe is
                reporting 15.0.8434.2956 when used in the integration test.
            #>
            $script:mockSourceMediaDisplayName = 'Microsoft SQL Server 2019 Reporting Services (15.0.1102.1047 - 2/6/2023)'
            $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe'
        }

        if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2022')
        {
            <#
                The version below is what the MS download page said, but the .exe is
                reporting 15.0.7842.32355 when used in the integration test.
            #>
            $script:mockSourceMediaDisplayName = 'Microsoft SQL Server 2022 Reporting Services (16.0.1113.11 - 11/23/2022)'
            $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/8/3/2/832616ff-af64-42b5-a0b1-5eb07f71dec9/SQLServerReportingServices.exe'
        }

        if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_PowerBI')
        {
            # https://sqlserverbuilds.blogspot.com/2021/04/power-bi-report-server-versions.html
            $script:mockSourceMediaDisplayName = 'Power BI Report Server 15.0.1117.98 - 2025-01-22'
            $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/2/7/3/2739a88a-4769-4700-8748-1a01ddf60974/PowerBIReportServer.exe'
        }

        Write-Verbose -Message ('Start downloading the {1} executable at {0}.' -f (Get-Date -Format 'yyyy-MM-dd hh:mm:ss'), $script:mockSourceMediaDisplayName) -Verbose

        Invoke-WebRequest -Uri $script:mockSourceMediaUrl -OutFile $ConfigurationData.AllNodes.MediaPath

        Write-Verbose -Message ('{1} executable file has SHA1 hash ''{0}''.' -f (Get-FileHash -Path $ConfigurationData.AllNodes.MediaPath -Algorithm 'SHA1').Hash, $script:mockSourceMediaDisplayName) -Verbose

        $ProgressPreference = $previousProgressPreference

        # Double check that the Microsoft SQL Server Reporting Services (October 2017) was downloaded.
        if (-not (Test-Path -Path $ConfigurationData.AllNodes.MediaPath))
        {
            Write-Warning -Message ('{0} executable could not be downloaded, can not run the integration test.' -f $script:mockSourceMediaDisplayName)
            return
        }
        else
        {
            Write-Verbose -Message ('Finished downloading the {1} executable at {0}.' -f (Get-Date -Format 'yyyy-MM-dd hh:mm:ss'), $script:mockSourceMediaDisplayName) -Verbose
        }
    }
    else
    {
        Write-Verbose -Message ('{0} executable is already downloaded' -f $script:mockSourceMediaDisplayName) -Verbose
    }
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

<#
    Run only for standalone versions of Microsoft SQL Server Reporting Services.
    Older versions of Reporting Services (eg. 2016) are integration tested in
    separate tests (part of resource SqlSetup).
#>
Describe "$($script:dscResourceName)_Integration" -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI') -Skip:($env:APPVEYOR) {
    BeforeAll {
        $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
    }

    <#
        Skips on AppVeyor because the build image already has a different version
        of Microsoft SQL Server Reporting Services installed.
    #>
    Context ('When using configuration <_>') -Skip:($env:APPVEYOR) -ForEach @(
        "$($script:dscResourceName)_InstallReportingServicesAsUser_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $configurationParameters = @{
                OutputPath                       = $TestDrive
                # The variable $ConfigurationData was dot-sourced above.
                ConfigurationData                = $ConfigurationData
            }

            $null = & $configurationName @configurationParameters

            $startDscConfigurationParameters = @{
                Path         = $TestDrive
                ComputerName = 'localhost'
                Wait         = $true
                Verbose      = $true
                Force        = $true
                ErrorAction  = 'Stop'
            }

            $null = Start-DscConfiguration @startDscConfigurationParameters
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction 'Stop'
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                    -and $_.ResourceId -eq $resourceId
            }

            ## Uncomment this line to see the registry key values.
            #Write-Verbose -Message ((reg query "HKLM\SOFTWARE\Microsoft\Microsoft SQL Server" /s) | Out-String) -Verbose

            $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.InstallFolder | Should -Be $ConfigurationData.AllNodes.InstallFolder
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose -ErrorAction 'Stop' | Should -Be 'True'
        }
    }

    Context ('When using configuration <_>') -Skip:($env:APPVEYOR) -ForEach @(
        "$($script:dscResourceName)_StopReportingServicesInstance_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $configurationParameters = @{
                OutputPath        = $TestDrive
                # The variable $ConfigurationData was dot-sourced above.
                ConfigurationData = $ConfigurationData
            }

            $null = & $configurationName @configurationParameters

            $startDscConfigurationParameters = @{
                Path         = $TestDrive
                ComputerName = 'localhost'
                Wait         = $true
                Verbose      = $true
                Force        = $true
                ErrorAction  = 'Stop'
            }

            $null = Start-DscConfiguration @startDscConfigurationParameters
        }
    }
}
