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
    $script:dscResourceFriendlyName = 'SqlSetup'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"
}

BeforeAll {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\TestHelpers\CommonTestHelper.psm1')

    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlSetup'
    $script:dscResourceName = "DSC_$($script:dscResourceFriendlyName)"

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Integration'

    <#
    .SYNOPSIS
        This function will output the Setup Bootstrap Summary.txt log file.

    .DESCRIPTION
        This function will output the Summary.txt log file, this is to be
        able to debug any problems that potentially occurred during setup.
        This will pick up the newest Summary.txt log file, so any
        other log files will be ignored (AppVeyor build worker has
        SQL Server instances installed by default).
        This code is meant to work regardless what SQL Server
        major version is used for the integration test.
    #>
    function Show-SqlBootstrapLog
    {
        [CmdletBinding()]
        param
        (
        )

        $summaryLogPath = Get-ChildItem -Path 'C:\Program Files\Microsoft SQL Server\**\Setup Bootstrap\Log\Summary.txt' |
            Sort-Object -Property LastWriteTime -Descending |
            Select-Object -First 1

        $summaryLog = Get-Content $summaryLogPath

        Write-Verbose -Message $('-' * 80) -Verbose
        Write-Verbose -Message 'Summary.txt' -Verbose
        Write-Verbose -Message $('-' * 80) -Verbose

        $summaryLog | ForEach-Object -Process {
            Write-Verbose $_ -Verbose
        }

        Write-Verbose -Message $('-' * 80) -Verbose
    }

    <#
        This is used in both the configuration file and in this script file
        to run the correct tests depending of what version of SQL Server is
        being tested in the current job.

        The actual download URL can easiest be found in the browser download history.
    #>
    if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2022')
    {
        $script:sqlVersion = '160'
        $script:mockSourceDownloadExeUrl = 'https://download.microsoft.com/download/c/c/9/cc9c6797-383c-4b24-8920-dc057c1de9d3/SQL2022-SSEI-Dev.exe'
    }
    elseif (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2019')
    {
        $script:sqlVersion = '150'
        $script:mockSourceDownloadExeUrl = 'https://download.microsoft.com/download/d/a/2/da259851-b941-459d-989c-54a18a5d44dd/SQL2019-SSEI-Dev.exe'
    }
    elseif (Test-ContinuousIntegrationTaskCategory -Category 'Integration_SQL2017')
    {
        $script:sqlVersion = '140'
        $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU.iso'
    }
    else
    {
        $script:sqlVersion = '130'
        $script:mockSourceMediaUrl = 'https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SQLServer2016SP1-FullSlipstream-x64-ENU.iso'
    }

    Write-Verbose -Message ('Running integration tests for SQL Server version {0}' -f $script:sqlVersion) -Verbose

    $configFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:dscResourceName).config.ps1"
    . $configFile

    # Download SQL Server media
    if (-not (Test-Path -Path $ConfigurationData.AllNodes.ImagePath))
    {
        # By switching to 'SilentlyContinue' should theoretically increase the download speed.
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        Write-Verbose -Message "Start downloading the SQL Server media at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')" -Verbose

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        if ($script:mockSourceDownloadExeUrl)
        {
            # Download the EXE used to download the ISO
            Invoke-WebRequest -Uri $script:mockSourceDownloadExeUrl -OutFile $ConfigurationData.AllNodes.DownloadExePath | Out-Null

            # Download ISO using the EXE
            $imageDirectoryPath = Split-Path -Path $ConfigurationData.AllNodes.ImagePath -Parent
            $downloadExeArgumentList = '/ENU /Quiet /HideProgressBar /Action=Download /Language=en-US /MediaType=ISO /MediaPath={0}' -f $imageDirectoryPath
            Start-Process -FilePath $ConfigurationData.AllNodes.DownloadExePath `
                -ArgumentList $downloadExeArgumentList `
                -Wait

            # Rename the ISO to maintain consistency of names within integration tests
            Rename-Item -Path $ConfigurationData.AllNodes.DownloadIsoPath `
                -NewName $(Split-Path -Path $ConfigurationData.AllNodes.ImagePath -Leaf) | Out-Null
        }
        else
        {
            # Direct ISO download
            Invoke-WebRequest -Uri $script:mockSourceMediaUrl -OutFile $ConfigurationData.AllNodes.ImagePath
        }

        Write-Verbose -Message ('SQL Server media file has SHA1 hash ''{0}''' -f (Get-FileHash -Path $ConfigurationData.AllNodes.ImagePath -Algorithm 'SHA1').Hash) -Verbose

        $ProgressPreference = $previousProgressPreference

        # Double check that the SQL media was downloaded.
        if (-not (Test-Path -Path $ConfigurationData.AllNodes.ImagePath))
        {
            Write-Warning -Message ('SQL media could not be downloaded, can not run the integration test.')
            return
        }
        else
        {
            Write-Verbose -Message "Finished downloading the SQL Server media iso at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')" -Verbose
        }
    }
    else
    {
        Write-Verbose -Message 'SQL Server media is already downloaded' -Verbose
    }
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
            $null = & ({
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
            })
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_InstallSMOModule_Config"
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
            })
        }

        # Make sure the module was installed.
        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_InstallDatabaseEngineNamedInstanceAsSystem_Config"
    ) -Skip:$(if ($env:SKIP_DATABASE_ENGINE_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
            $script:itBlockError = @()
        }

        AfterAll {
            <#
                Check if previous It-block failed. If so output the
                SQL Server setup log file.
            #>
            if ( $itBlockError.Count -ne 0 )
            {
                Show-SqlBootstrapLog
            }

            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        } -ErrorVariable itBlockError

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

            $resourceCurrentState.Action                     | Should-Be 'Install'
            $resourceCurrentState.AgtSvcAccount              | Should-BeFalsy
            $resourceCurrentState.AgtSvcAccountUsername      | Should-Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlAgentServicePrimaryAccountUserName -Leaf))
            $resourceCurrentState.AgtSvcStartupType          | Should-Be 'Automatic'
            $resourceCurrentState.ASServerMode               | Should-BeFalsy
            $resourceCurrentState.ASBackupDir                | Should-BeFalsy
            $resourceCurrentState.ASCollation                | Should-BeFalsy
            $resourceCurrentState.ASConfigDir                | Should-BeFalsy
            $resourceCurrentState.ASDataDir                  | Should-BeFalsy
            $resourceCurrentState.ASLogDir                   | Should-BeFalsy
            $resourceCurrentState.ASTempDir                  | Should-BeFalsy
            $resourceCurrentState.ASSvcAccount               | Should-BeFalsy
            $resourceCurrentState.ASSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.ASSysAdminAccounts         | Should-BeFalsy
            $resourceCurrentState.BrowserSvcStartupType      | Should-BeFalsy
            $resourceCurrentState.ErrorReporting             | Should-BeFalsy
            $resourceCurrentState.FailoverClusterGroupName   | Should-BeFalsy
            $resourceCurrentState.FailoverClusterIPAddress   | Should-BeFalsy
            $resourceCurrentState.FailoverClusterNetworkName | Should-BeFalsy
            $resourceCurrentState.Features                   | Should-Be $ConfigurationData.AllNodes.DatabaseEngineNamedInstanceFeatures
            $resourceCurrentState.ForceReboot                | Should-BeFalsy
            $resourceCurrentState.FTSvcAccount               | Should-BeFalsy
            $resourceCurrentState.FTSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.InstallSharedDir           | Should-Be $ConfigurationData.AllNodes.InstallSharedDir
            $resourceCurrentState.InstallSharedWOWDir        | Should-Be $ConfigurationData.AllNodes.InstallSharedWOWDir
            $resourceCurrentState.InstallSQLDataDir          | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSQLDataDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\MSSQL")
            $resourceCurrentState.InstanceDir                | Should-Be $ConfigurationData.AllNodes.InstanceDir
            $resourceCurrentState.InstanceID                 | Should-Be $ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName
            $resourceCurrentState.InstanceName               | Should-Be $ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName
            $resourceCurrentState.ISSvcAccount               | Should-BeFalsy
            $resourceCurrentState.ISSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.ProductKey                 | Should-BeFalsy
            $resourceCurrentState.RSSvcAccount               | Should-BeFalsy
            $resourceCurrentState.RSSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.SAPwd                      | Should-BeFalsy
            $resourceCurrentState.SecurityMode               | Should-Be 'SQL'
            $resourceCurrentState.SetupProcessTimeout        | Should-BeFalsy
            $resourceCurrentState.SourceCredential           | Should-BeFalsy
            $resourceCurrentState.SourcePath                 | Should-Be "$($ConfigurationData.AllNodes.DriveLetter):\"
            $resourceCurrentState.SQLCollation               | Should-Be $ConfigurationData.AllNodes.Collation
            $resourceCurrentState.SQLSvcAccount              | Should-BeFalsy
            $resourceCurrentState.SQLSvcAccountUsername      | Should-Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName -Leaf))
            $resourceCurrentState.SqlSvcStartupType          | Should-Be 'Automatic'
            $resourceCurrentState.SQLTempDBDir               | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSQLDataDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)\MSSQL\Data")
            $resourceCurrentState.SqlTempDbFileCount         | Should-Be $ConfigurationData.AllNodes.SqlTempDbFileCount
            $resourceCurrentState.SqlTempDbFileSize          | Should-Be $ConfigurationData.AllNodes.SqlTempDbFileSize
            $resourceCurrentState.SqlTempDbFileGrowth        | Should-Be $ConfigurationData.AllNodes.SqlTempDbFileGrowth
            $resourceCurrentState.SQLTempDbLogDir            | Should-BeFalsy
            $resourceCurrentState.SqlTempDbLogFileSize       | Should-Be $ConfigurationData.AllNodes.SqlTempDbLogFileSize
            $resourceCurrentState.SqlTempDbLogFileGrowth     | Should-Be $ConfigurationData.AllNodes.SqlTempDbLogFileGrowth
            $resourceCurrentState.SQLUserDBDir               | Should-Be $ConfigurationData.AllNodes.SQLUserDBDir
            $resourceCurrentState.SQLUserDBLogDir            | Should-Be $ConfigurationData.AllNodes.SQLUserDBLogDir
            $resourceCurrentState.SQLBackupDir               | Should-Be $ConfigurationData.AllNodes.SQLBackupDir
            $resourceCurrentState.SQMReporting               | Should-BeFalsy
            $resourceCurrentState.SuppressReboot             | Should-BeFalsy
            $resourceCurrentState.UpdateEnabled              | Should-BeFalsy
            $resourceCurrentState.UpdateSource               | Should-BeFalsy
            $resourceCurrentState.UseEnglish                 | Should-BeTrue

            # Verify all the accounts are returned in the property SQLSysAdminAccounts.
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ($ConfigurationData.AllNodes.SqlAdministratorAccountUserName)
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ($ConfigurationData.AllNodes.SqlInstallAccountUserName)
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ("NT SERVICE\MSSQL`$$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)")
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ("NT SERVICE\SQLAgent`$$($ConfigurationData.AllNodes.DatabaseEngineNamedInstanceName)")
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ('NT SERVICE\SQLWriter')
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ('NT SERVICE\Winmgmt')
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ('sa')
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_StopServicesInstance_Config"
    ) -Skip:$(if ($env:SKIP_DATABASE_ENGINE_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_InstallDatabaseEngineDefaultInstanceAsUser_Config"
    ) -Skip:$(if ($env:SKIP_DATABASE_ENGINE_DEFAULT_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
            $script:itBlockError = @()
        }

        AfterAll {
            <#
                Check if previous It-block failed. If so output the
                SQL Server setup log file.
            #>
            if ( $itBlockError.Count -ne 0 )
            {
                Show-SqlBootstrapLog
            }

            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        } -ErrorVariable itBlockError

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

            $resourceCurrentState.Action                     | Should-Be 'Install'
            $resourceCurrentState.AgtSvcAccount              | Should-BeFalsy
            $resourceCurrentState.AgtSvcAccountUsername      | Should-Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlAgentServicePrimaryAccountUserName -Leaf))
            $resourceCurrentState.ASServerMode               | Should-BeFalsy
            $resourceCurrentState.ASBackupDir                | Should-BeFalsy
            $resourceCurrentState.ASCollation                | Should-BeFalsy
            $resourceCurrentState.ASConfigDir                | Should-BeFalsy
            $resourceCurrentState.ASDataDir                  | Should-BeFalsy
            $resourceCurrentState.ASLogDir                   | Should-BeFalsy
            $resourceCurrentState.ASTempDir                  | Should-BeFalsy
            $resourceCurrentState.ASSvcAccount               | Should-BeFalsy
            $resourceCurrentState.ASSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.ASSysAdminAccounts         | Should-BeFalsy
            $resourceCurrentState.BrowserSvcStartupType      | Should-BeFalsy
            $resourceCurrentState.ErrorReporting             | Should-BeFalsy
            $resourceCurrentState.FailoverClusterGroupName   | Should-BeFalsy
            $resourceCurrentState.FailoverClusterIPAddress   | Should-BeFalsy
            $resourceCurrentState.FailoverClusterNetworkName | Should-BeFalsy
            $resourceCurrentState.Features                   | Should-Be $ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceFeatures
            $resourceCurrentState.ForceReboot                | Should-BeFalsy
            $resourceCurrentState.FTSvcAccount               | Should-BeFalsy
            $resourceCurrentState.FTSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.InstallSharedDir           | Should-Be $ConfigurationData.AllNodes.InstallSharedDir
            $resourceCurrentState.InstallSharedWOWDir        | Should-Be $ConfigurationData.AllNodes.InstallSharedWOWDir
            $resourceCurrentState.InstallSQLDataDir          | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL")
            $resourceCurrentState.InstanceDir                | Should-Be $ConfigurationData.AllNodes.InstallSharedDir
            $resourceCurrentState.InstanceID                 | Should-Be $ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName
            $resourceCurrentState.InstanceName               | Should-Be $ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName
            $resourceCurrentState.ISSvcAccount               | Should-BeFalsy
            $resourceCurrentState.ISSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.ProductKey                 | Should-BeFalsy
            $resourceCurrentState.RSSvcAccount               | Should-BeFalsy
            $resourceCurrentState.RSSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.SAPwd                      | Should-BeFalsy
            $resourceCurrentState.SecurityMode               | Should-BeFalsy
            $resourceCurrentState.SetupProcessTimeout        | Should-BeFalsy
            $resourceCurrentState.SourceCredential           | Should-BeFalsy
            $resourceCurrentState.SourcePath                 | Should-Be "$($ConfigurationData.AllNodes.DriveLetter):\"
            $resourceCurrentState.SQLBackupDir               | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL\Backup")
            $resourceCurrentState.SQLCollation               | Should-Be $ConfigurationData.AllNodes.Collation
            $resourceCurrentState.SQLSvcAccount              | Should-BeFalsy
            $resourceCurrentState.SQLSvcAccountUsername      | Should-Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName -Leaf))
            $resourceCurrentState.SQLTempDBDir               | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL\Data")
            $resourceCurrentState.SQLTempDBLogDir            | Should-BeFalsy
            $resourceCurrentState.SQMReporting               | Should-BeFalsy
            $resourceCurrentState.SuppressReboot             | Should-BeFalsy
            $resourceCurrentState.UpdateEnabled              | Should-BeFalsy
            $resourceCurrentState.UpdateSource               | Should-BeFalsy
            $resourceCurrentState.UseEnglish                 | Should-BeFalse

            # Regression test for issue #1287
            $resourceCurrentState.SQLUserDBDir               | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL\DATA\")
            $resourceCurrentState.SQLUserDBLogDir            | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.SqlServerInstanceIdPrefix).$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)\MSSQL\DATA\")

            # Verify all the accounts are returned in the property SQLSysAdminAccounts.
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ($ConfigurationData.AllNodes.SqlAdministratorAccountUserName)
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ($ConfigurationData.AllNodes.SqlInstallAccountUserName)
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ("NT SERVICE\$($ConfigurationData.AllNodes.DatabaseEngineDefaultInstanceName)")
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ('NT SERVICE\SQLSERVERAGENT')
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ('NT SERVICE\SQLWriter')
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ('NT SERVICE\Winmgmt')
            $resourceCurrentState.SQLSysAdminAccounts | Should-ContainCollection ('sa')
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_StopSqlServerDefaultInstance_Config"
    ) -Skip:$(if ($env:SKIP_DATABASE_ENGINE_DEFAULT_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_InstallMultiDimensionalAnalysisServicesAsSystem_Config"
    ) -Skip:$(if ($env:SKIP_ANALYSIS_MULTI_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
            $script:itBlockError = @()
        }

        AfterAll {
            <#
                Check if previous It-block failed. If so output the
                SQL Server setup log file.
            #>
            if ( $itBlockError.Count -ne 0 )
            {
                Show-SqlBootstrapLog
            }

            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        } -ErrorVariable itBlockError

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

            $resourceCurrentState.Action                     | Should-Be 'Install'
            $resourceCurrentState.AgtSvcAccount              | Should-BeFalsy
            $resourceCurrentState.AgtSvcAccountUsername      | Should-BeFalsy
            $resourceCurrentState.ASServerMode               | Should-Be $ConfigurationData.AllNodes.AnalysisServicesMultiServerMode
            $resourceCurrentState.ASBackupDir                | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesMultiInstanceName)\OLAP\Backup")
            $resourceCurrentState.ASCollation                | Should-Be $ConfigurationData.AllNodes.Collation
            $resourceCurrentState.ASConfigDir                | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesMultiInstanceName)\OLAP\Config")
            $resourceCurrentState.ASDataDir                  | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesMultiInstanceName)\OLAP\Data")
            $resourceCurrentState.ASLogDir                   | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesMultiInstanceName)\OLAP\Log")
            $resourceCurrentState.ASTempDir                  | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesMultiInstanceName)\OLAP\Temp")
            $resourceCurrentState.ASSvcAccount               | Should-BeFalsy
            $resourceCurrentState.ASSvcAccountUsername       | Should-Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName -Leaf))
            $resourceCurrentState.ASSysAdminAccounts         | Should-Be @(
                $ConfigurationData.AllNodes.SqlAdministratorAccountUserName,
                "NT SERVICE\SSASTELEMETRY`$$($ConfigurationData.AllNodes.AnalysisServicesMultiInstanceName)"
            )
            $resourceCurrentState.BrowserSvcStartupType      | Should-BeFalsy
            $resourceCurrentState.ErrorReporting             | Should-BeFalsy
            $resourceCurrentState.FailoverClusterGroupName   | Should-BeFalsy
            $resourceCurrentState.FailoverClusterIPAddress   | Should-BeFalsy
            $resourceCurrentState.FailoverClusterNetworkName | Should-BeFalsy

            if ($script:sqlVersion -in (160))
            {
                <#
                    The features CONN, BC, SDK is no longer supported after SQL Server 2019.
                    Thus they are not installed with the Database Engine instance DSCSQLTEST
                    in prior test, so this test do not find them already installed.
                #>
                $resourceCurrentState.Features | Should-Be 'AS'
            }
            else
            {
                $resourceCurrentState.Features | Should-Be 'AS,CONN,BC,SDK'
            }

            $resourceCurrentState.ForceReboot                | Should-BeFalsy
            $resourceCurrentState.FTSvcAccount               | Should-BeFalsy
            $resourceCurrentState.FTSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.InstallSharedDir           | Should-Be $ConfigurationData.AllNodes.InstallSharedDir
            $resourceCurrentState.InstallSharedWOWDir        | Should-Be $ConfigurationData.AllNodes.InstallSharedWOWDir
            $resourceCurrentState.InstallSQLDataDir          | Should-BeFalsy
            $resourceCurrentState.InstanceDir                | Should-BeFalsy
            $resourceCurrentState.InstanceID                 | Should-BeFalsy
            $resourceCurrentState.InstanceName               | Should-Be $ConfigurationData.AllNodes.AnalysisServicesMultiInstanceName
            $resourceCurrentState.ISSvcAccount               | Should-BeFalsy
            $resourceCurrentState.ISSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.ProductKey                 | Should-BeFalsy
            $resourceCurrentState.RSSvcAccount               | Should-BeFalsy
            $resourceCurrentState.RSSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.SAPwd                      | Should-BeFalsy
            $resourceCurrentState.SecurityMode               | Should-BeFalsy
            $resourceCurrentState.SetupProcessTimeout        | Should-BeFalsy
            $resourceCurrentState.SourceCredential           | Should-BeFalsy
            $resourceCurrentState.SourcePath                 | Should-Be "$($ConfigurationData.AllNodes.DriveLetter):\"
            $resourceCurrentState.SQLBackupDir               | Should-BeFalsy
            $resourceCurrentState.SQLCollation               | Should-BeFalsy
            $resourceCurrentState.SQLSvcAccount              | Should-BeFalsy
            $resourceCurrentState.SQLSvcAccountUsername      | Should-BeFalsy
            $resourceCurrentState.SQLSysAdminAccounts        | Should-BeFalsy
            $resourceCurrentState.SQLTempDBDir               | Should-BeFalsy
            $resourceCurrentState.SQLTempDBLogDir            | Should-BeFalsy
            $resourceCurrentState.SQLUserDBDir               | Should-BeFalsy
            $resourceCurrentState.SQLUserDBLogDir            | Should-BeFalsy
            $resourceCurrentState.SQMReporting               | Should-BeFalsy
            $resourceCurrentState.SuppressReboot             | Should-BeFalsy
            $resourceCurrentState.UpdateEnabled              | Should-BeFalsy
            $resourceCurrentState.UpdateSource               | Should-BeFalsy
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_StopMultiDimensionalAnalysisServices_Config"
    ) -Skip:$(if ($env:SKIP_ANALYSIS_MULTI_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_InstallTabularAnalysisServicesAsSystem_Config"
    ) -Skip:$(if ($env:SKIP_ANALYSIS_TABULAR_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
            $script:itBlockError = @()
        }

        AfterAll {
            <#
                Check if previous It-block failed. If so output the
                SQL Server setup log file.
            #>
            if ( $itBlockError.Count -ne 0 )
            {
                Show-SqlBootstrapLog
            }

            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        } -ErrorVariable itBlockError

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

            $resourceCurrentState.Action                     | Should-Be 'Install'
            $resourceCurrentState.AgtSvcAccount              | Should-BeFalsy
            $resourceCurrentState.AgtSvcAccountUsername      | Should-BeFalsy
            $resourceCurrentState.ASServerMode               | Should-Be $ConfigurationData.AllNodes.AnalysisServicesTabularServerMode
            $resourceCurrentState.ASBackupDir                | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Backup")
            $resourceCurrentState.ASCollation                | Should-Be $ConfigurationData.AllNodes.Collation
            $resourceCurrentState.ASConfigDir                | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Config")
            $resourceCurrentState.ASDataDir                  | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Data")
            $resourceCurrentState.ASLogDir                   | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Log")
            $resourceCurrentState.ASTempDir                  | Should-Be (Join-Path -Path $ConfigurationData.AllNodes.InstallSharedDir -ChildPath "$($ConfigurationData.AllNodes.AnalysisServiceInstanceIdPrefix).$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)\OLAP\Temp")
            $resourceCurrentState.ASSvcAccount               | Should-BeFalsy
            $resourceCurrentState.ASSvcAccountUsername       | Should-Be ('.\{0}' -f (Split-Path -Path $ConfigurationData.AllNodes.SqlServicePrimaryAccountUserName -Leaf))
            $resourceCurrentState.ASSysAdminAccounts         | Should-Be @(
                $ConfigurationData.AllNodes.SqlAdministratorAccountUserName,
                "NT SERVICE\SSASTELEMETRY`$$($ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName)"
            )
            $resourceCurrentState.BrowserSvcStartupType      | Should-BeFalsy
            $resourceCurrentState.ErrorReporting             | Should-BeFalsy
            $resourceCurrentState.FailoverClusterGroupName   | Should-BeFalsy
            $resourceCurrentState.FailoverClusterIPAddress   | Should-BeFalsy
            $resourceCurrentState.FailoverClusterNetworkName | Should-BeFalsy

            if ($script:sqlVersion -in (160))
            {
                <#
                    The features CONN, BC, SDK is no longer supported after SQL Server 2019.
                    Thus they are not installed with the Database Engine instance DSCSQLTEST
                    in prior test, so this test do not find them already installed.
                #>
                $resourceCurrentState.Features | Should-Be 'AS'
            }
            else
            {
                $resourceCurrentState.Features | Should-Be 'AS,CONN,BC,SDK'
            }

            $resourceCurrentState.ForceReboot                | Should-BeFalsy
            $resourceCurrentState.FTSvcAccount               | Should-BeFalsy
            $resourceCurrentState.FTSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.InstallSharedDir           | Should-Be $ConfigurationData.AllNodes.InstallSharedDir
            $resourceCurrentState.InstallSharedWOWDir        | Should-Be $ConfigurationData.AllNodes.InstallSharedWOWDir
            $resourceCurrentState.InstallSQLDataDir          | Should-BeFalsy
            $resourceCurrentState.InstanceDir                | Should-BeFalsy
            $resourceCurrentState.InstanceID                 | Should-BeFalsy
            $resourceCurrentState.InstanceName               | Should-Be $ConfigurationData.AllNodes.AnalysisServicesTabularInstanceName
            $resourceCurrentState.ISSvcAccount               | Should-BeFalsy
            $resourceCurrentState.ISSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.ProductKey                 | Should-BeFalsy
            $resourceCurrentState.RSSvcAccount               | Should-BeFalsy
            $resourceCurrentState.RSSvcAccountUsername       | Should-BeFalsy
            $resourceCurrentState.SAPwd                      | Should-BeFalsy
            $resourceCurrentState.SecurityMode               | Should-BeFalsy
            $resourceCurrentState.SetupProcessTimeout        | Should-BeFalsy
            $resourceCurrentState.SourceCredential           | Should-BeFalsy
            $resourceCurrentState.SourcePath                 | Should-Be "$($ConfigurationData.AllNodes.DriveLetter):\"
            $resourceCurrentState.SQLBackupDir               | Should-BeFalsy
            $resourceCurrentState.SQLCollation               | Should-BeFalsy
            $resourceCurrentState.SQLSvcAccount              | Should-BeFalsy
            $resourceCurrentState.SQLSvcAccountUsername      | Should-BeFalsy
            $resourceCurrentState.SQLSysAdminAccounts        | Should-BeFalsy
            $resourceCurrentState.SQLTempDBDir               | Should-BeFalsy
            $resourceCurrentState.SQLTempDBLogDir            | Should-BeFalsy
            $resourceCurrentState.SQLUserDBDir               | Should-BeFalsy
            $resourceCurrentState.SQLUserDBLogDir            | Should-BeFalsy
            $resourceCurrentState.SQMReporting               | Should-BeFalsy
            $resourceCurrentState.SuppressReboot             | Should-BeFalsy
            $resourceCurrentState.UpdateEnabled              | Should-BeFalsy
            $resourceCurrentState.UpdateSource               | Should-BeFalsy
        }

        It 'Should return $true when Test-DscConfiguration is run' {
            Test-DscConfiguration -Verbose | Should-Be 'True'
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_StopTabularAnalysisServices_Config"
    ) -Skip:$(if ($env:SKIP_ANALYSIS_TABULAR_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        }
    }

    Context ('When using configuration <_>') -ForEach @(
        "$($script:dscResourceName)_StartServicesInstance_Config"
    ) -Skip:$(if ($env:SKIP_DATABASE_ENGINE_INSTANCE) { $true } else { $false }) {
        BeforeAll {
            $configurationName = $_
        }

        AfterEach {
            Wait-ForIdleLcm
        }

        It 'Should compile and apply the MOF without throwing' {
            $null = & ({
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
            })
        }
    }
}
