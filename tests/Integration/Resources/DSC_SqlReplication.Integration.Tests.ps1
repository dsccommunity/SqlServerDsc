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
    $script:dscResourceFriendlyName = 'SqlReplication'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlReplication'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile
}

AfterAll {
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Describe "$($script:dscResourceName)_Integration" -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $resourceId = "[$($script:dscResourceFriendlyName)]Integration_Test"
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Prerequisites_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
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
            })
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddDistributor_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
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
            })
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            $null = & ({
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            })
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.Ensure | Should-Be 'Present'
            $resourceCurrentState.InstanceName | Should-Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DistributorMode | Should-Be 'Local'
            $resourceCurrentState.DistributionDBName | Should-Be 'MyDistribution'
            $resourceCurrentState.RemoteDistributor | Should-Be ('{0}\DSCSQLTEST' -f $env:COMPUTERNAME)
            $resourceCurrentState.WorkingDirectory | Should-Be 'C:\Temp'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_AddPublisher_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
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
            })
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            $null = & ({
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            })
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.Ensure | Should-Be 'Present'
            $resourceCurrentState.InstanceName | Should-Be $ConfigurationData.AllNodes.DefaultInstanceName
            $resourceCurrentState.DistributorMode | Should-Be 'Remote'
            $resourceCurrentState.DistributionDBName | Should-Be 'MyDistribution'
            $resourceCurrentState.RemoteDistributor | Should-Be ('{0}\{1}' -f $env:COMPUTERNAME, $ConfigurationData.AllNodes.InstanceName)
            $resourceCurrentState.WorkingDirectory | Should-Be 'C:\Temp'
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemovePublisher_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
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
            })
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            $null = & ({
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            })
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.Ensure | Should-Be 'Absent'
            $resourceCurrentState.InstanceName | Should-Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DistributorMode | Should-BeFalsy
            $resourceCurrentState.DistributionDBName | Should-BeFalsy
            $resourceCurrentState.RemoteDistributor | Should-BeFalsy
            $resourceCurrentState.WorkingDirectory | Should-BeFalsy
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_RemoveDistributor_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
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
            })
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            $null = & ({
                $script:currentConfiguration = Get-DscConfiguration -Verbose -ErrorAction Stop
            })
        }

        It 'Should have set the resource and all the parameters should match' {
            $resourceCurrentState = $script:currentConfiguration | Where-Object -FilterScript {
                $_.ConfigurationName -eq $configurationName `
                -and $_.ResourceId -eq $resourceId
            }

            $resourceCurrentState.Ensure | Should-Be 'Absent'
            $resourceCurrentState.InstanceName | Should-Be $ConfigurationData.AllNodes.InstanceName
            $resourceCurrentState.DistributorMode | Should-BeFalsy
            $resourceCurrentState.DistributionDBName | Should-BeFalsy
            $resourceCurrentState.RemoteDistributor | Should-BeFalsy
            $resourceCurrentState.WorkingDirectory | Should-BeFalsy
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_Cleanup_Config"
    ) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
                $configurationParameters = @{
                    OutputPath           = $TestDrive
                    # The variable $ConfigurationData was dot-sourced above.
                    ConfigurationData    = $ConfigurationData
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
            })
        }
    }
}
