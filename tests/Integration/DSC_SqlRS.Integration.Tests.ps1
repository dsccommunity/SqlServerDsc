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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscResourceFriendlyName = 'SqlRS'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlRS'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    <#
        This is used in both the configuration file and in this script file
        to run the correct tests depending of what version of SQL Server is
        being tested in the current job.
    #>
    if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2022')
    {
        $script:sqlVersion = '160'
    }
    elseif (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2019')
    {
        $script:sqlVersion = '150'
    }
    elseif (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2017')
    {
        $script:sqlVersion = '140'
    }
    else
    {
        $script:sqlVersion = '130'
    }

    Write-Verbose -Message ('Running integration tests for SSRS version {0}' -f $script:sqlVersion) -Verbose

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe "$($script:dscResourceName)_Integration" -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_CreateDependencies_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

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

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_ConfigureReportingServices_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

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
            $resourceCurrentState.ReportServerReservedUrl | Should -Contain 'http://+:80'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should -Be 'True'
        }

        It 'Should be able to access the ReportServer site without any error' {
            # Wait for 1 minute for the ReportServer to be ready.
            Start-Sleep -Seconds 30

            if ($script:sqlVersion -in @('140', '150', '160'))
            {
                # SSRS 2017 and 2019 do not support multiple instances
                $reportServerUri = 'http://{0}/ReportServer' -f $env:COMPUTERNAME
            }
            else
            {
                $reportServerUri = 'http://{0}/ReportServer_{1}' -f $env:COMPUTERNAME, $ConfigurationData.AllNodes.InstanceName
            }

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
            if ($script:sqlVersion -in @('140', '150', '160'))
            {
                # SSRS 2017 and 2019 do not support multiple instances
                $reportsUri = 'http://{0}/Reports' -f $env:COMPUTERNAME
            }
            else
            {
                $reportsUri = 'http://{0}/Reports_{1}' -f $env:COMPUTERNAME, $ConfigurationData.AllNodes.InstanceName
            }

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

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_StopReportingServicesInstance_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

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
