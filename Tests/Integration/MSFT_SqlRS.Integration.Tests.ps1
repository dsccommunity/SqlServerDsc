# This is used to make sure the integration test run in the correct order.
[Microsoft.DscResourceKit.IntegrationTest(OrderNumber = 3)]
param()

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Integration' -Category 'Integration_SQL2016')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceFriendlyName = 'SqlRS'
$script:dscResourceName = "MSFT_$($script:dscResourceFriendlyName)"

#region HEADER
# Integration Test Template Version: 1.3.2
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath 'DscResource.Tests'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Integration
#endregion

# Using try/finally to always cleanup.
try
{
    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    Describe "$($script:dscResourceName)_Integration" {
        BeforeAll {
            $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
        }

        $configurationName = "$($script:dscResourceName)_CreateDependencies_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath                         = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData                  = $ConfigurationData
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

        $configurationName = "$($script:dscResourceName)_InstallReportingServices_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath                         = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData                  = $ConfigurationData
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
                $resourceCurrentState.DatabaseServerName | Should -Be $ConfigurationData.AllNodes.DatabaseServerName
                $resourceCurrentState.DatabaseInstanceName | Should -Be $ConfigurationData.AllNodes.DatabaseInstanceName
                $resourceCurrentState.IsInitialized | Should -Be $true
                $resourceCurrentState.UseSsl | Should -Be $false
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }

            It 'Should be able to access the ReportServer site without any error' {
                $reportServerUri = 'http://{0}/ReportServer_{1}' -f $env:COMPUTERNAME, $ConfigurationData.AllNodes.InstanceName

                try
                {
                    $webRequestReportServer = Invoke-WebRequest -Uri $reportServerUri -UseDefaultCredentials
                    # if the request finishes successfully this should return status code 200.
                    $webRequestStatusCode = $webRequestReportServer.StatusCode -as [int]
                }
                catch
                {
                    <#
                        If the request generated an exception i.e. "HTTP Error 503. The service is unavailable."
                        we can pull the status code from the Exception.Response property.
                    #>
                    $webRequestResponse = $_.Exception.Response
                    $webRequestStatusCode = $webRequestResponse.StatusCode -as [int]
                }

                $webRequestStatusCode | Should -BeExactly 200
            }

            It 'Should be able to access the Reports site without any error' {
                $reportsUri = 'http://{0}/Reports_{1}' -f $env:COMPUTERNAME, $ConfigurationData.AllNodes.InstanceName

                try
                {
                    $webRequestReportServer = Invoke-WebRequest -Uri $reportsUri -UseDefaultCredentials
                    # if the request finishes successfully this should return status code 200.
                    $webRequestStatusCode = $webRequestReportServer.StatusCode -as [int]
                }
                catch
                {
                    <#
                        If the request generated an exception i.e. "HTTP Error 503. The service is unavailable."
                        we can pull the status code from the Exception.Response property.
                    #>
                    $webRequestResponse = $_.Exception.Response
                    $webRequestStatusCode = $webRequestResponse.StatusCode -as [int]
                }

                $webRequestStatusCode | Should -BeExactly 200
            }
        }

        $configurationName = "$($script:dscResourceName)_InstallReportingServices_ConfigureSsl_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath                         = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData                  = $ConfigurationData
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

                $resourceCurrentState.UseSsl | Should -Be $true
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }

            <#
                We expect this to throw any error. Usually 'Unable to connect to the remote server' but it
                can also throw and 'The underlying connection was closed: An unexpected error occurred on a send'.
                When we support SSL fully with this resource, this should not throw at all. So leaving this
                as this without testing for the correct error message on purpose.
            #>
            It 'Should not be able to access the ReportServer site and throw an error message' {
                $reportServerUri = 'http://{0}/ReportServer_{1}' -f $env:COMPUTERNAME, $ConfigurationData.AllNodes.InstanceName

                { Invoke-WebRequest -Uri $reportServerUri -UseDefaultCredentials } | Should -Throw
            }
        }

        $configurationName = "$($script:dscResourceName)_InstallReportingServices_RestoreToNoSsl_Config"

        Context ('When using configuration {0}' -f $configurationName) {
            It 'Should compile and apply the MOF without throwing' {
                {
                    $configurationParameters = @{
                        OutputPath                         = $TestDrive
                        # The variable $ConfigurationData was dot-sourced above.
                        ConfigurationData                  = $ConfigurationData
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

                $resourceCurrentState.UseSsl | Should -Be $false
            }

            It 'Should return $true when Test-DscConfiguration is run' {
                Test-DscConfiguration -Verbose | Should -Be 'True'
            }

            It 'Should be able to access the ReportServer site without any error' {
                $reportServerUri = 'http://{0}/ReportServer_{1}' -f $env:COMPUTERNAME, $ConfigurationData.AllNodes.InstanceName

                try
                {
                    $webRequestReportServer = Invoke-WebRequest -Uri $reportServerUri -UseDefaultCredentials
                    # if the request finishes successfully this should return status code 200.
                    $webRequestStatusCode = $webRequestReportServer.StatusCode -as [int]
                }
                catch
                {
                    <#
                        If the request generated an exception i.e. "HTTP Error 503. The service is unavailable."
                        we can pull the status code from the Exception.Response property.
                    #>
                    $webRequestResponse = $_.Exception.Response
                    $webRequestStatusCode = $webRequestResponse.StatusCode -as [int]
                }

                $webRequestStatusCode | Should -BeExactly 200
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
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
