Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

<#
    Run only for standalone versions of Microsoft SQL Server Reporting Services.
    Older versions of Reporting Services (eg. 2016) are integration tested in
    separate tests (part of resource SqlSetup).
#>
if (-not (Test-BuildCategory -Type 'Integration' -Category @('Integration_SQL2017', 'Integration_SQL2019')))
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlRSSetup'
$script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

try
{
    Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
}
catch [System.IO.FileNotFoundException]
{
    throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
}

$script:testEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -ResourceType 'Mof' `
    -TestType 'Integration'

try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    # Download Microsoft SQL Server Reporting Services (October 2017) executable
    if (-not (Test-Path -Path $ConfigurationData.AllNodes.SourcePath))
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
                reporting 15.0.7842.32355 when used in the integration test.
            #>
            $script:mockSourceMediaDisplayName = 'Microsoft SQL Server 2019 Reporting Services (15.0.1102.911 - 6/24/2021)'
            $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe'
        }

        Write-Verbose -Message ('Start downloading the {1} executable at {0}.' -f (Get-Date -Format 'yyyy-MM-dd hh:mm:ss'), $script:mockSourceMediaDisplayName) -Verbose

        Invoke-WebRequest -Uri $script:mockSourceMediaUrl -OutFile $ConfigurationData.AllNodes.SourcePath

        Write-Verbose -Message ('{1} executable file has SHA1 hash ''{0}''.' -f (Get-FileHash -Path $ConfigurationData.AllNodes.SourcePath -Algorithm 'SHA1').Hash, $script:mockSourceMediaDisplayName) -Verbose

        $ProgressPreference = $previousProgressPreference

        # Double check that the Microsoft SQL Server Reporting Services (October 2017) was downloaded.
        if (-not (Test-Path -Path $ConfigurationData.AllNodes.SourcePath))
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

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_InstallReportingServicesAsUser_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath        = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }

            It 'Should be able to call Get-DscConfiguration without throwing' {
                {
                    $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should have set the resource and all the parameters should match' {
                $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                    $_.ConfigurationName -eq $configurationName `
                        -and $_.ResourceId -eq $resourceId
                }

                $resourceCurrentState.InstanceName | Should -Be $ConfigurationData.AllNodes.InstanceName
                $resourceCurrentState.InstallFolder | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services'
                $resourceCurrentState.ServiceName | Should -Be 'SQLServerReportingServices'
                $resourceCurrentState.ErrorDumpDirectory | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'

                if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2017')
                {
                    $resourceCurrentState.CurrentVersion | Should -BeGreaterThan ([System.Version] '14.0.0.0')
                }

                if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2019')
                {
                    $resourceCurrentState.CurrentVersion | Should -BeGreaterThan ([System.Version] '15.0.0.0')
                }
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }
        }

        $configurationName = "$($script:dscResourceName)_StopReportingServicesInstance_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath        = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData = $ConfigurationData
                    }

                    & $configurationName @configurationParameters

                    $startDscConfigurationParameters = @{
                        Path         = $TestDrive
                        ComputerName = 'localhost'
                        Wait         = $true
                        Verbose      = $true
                        Force        = $true
                        ErrorAction  = 'Stop'
                    }

                    Start-DscConfiguration @startDscConfigurationParameters
                } | Should -Not -Throw
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}
