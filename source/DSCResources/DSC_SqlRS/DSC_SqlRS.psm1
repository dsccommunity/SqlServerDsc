$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Gets the SQL Reporting Services initialization status.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.

    .PARAMETER Encrypt
        Specifies how encryption should be enforced. There are currently no
        difference between using `Mandatory` or `Strict`.
#>
function Get-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification = 'Neither command is needed for this function since it uses CIM methods when calling Get-SqlDscRSConfiguration')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseInstanceName,

        [Parameter()]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    Write-Verbose -Message (
        $script:localizedData.GetConfiguration -f $InstanceName
    )

    $getTargetResourceResult = @{
        InstanceName                 = $InstanceName
        DatabaseServerName           = $DatabaseServerName
        DatabaseInstanceName         = $DatabaseInstanceName
        ReportServerVirtualDirectory = $null
        ReportsVirtualDirectory      = $null
        ReportServerReservedUrl      = $null
        ReportsReservedUrl           = $null
        UseSsl                       = $false
        IsInitialized                = $false
        Encrypt                      = $Encrypt
    }

    $rsConfiguration = Get-SqlDscRSConfiguration -InstanceName $InstanceName -ErrorAction 'SilentlyContinue'

    if ($null -ne $rsConfiguration)
    {
        if ($rsConfiguration.DatabaseServerName.Contains('\'))
        {
            $getTargetResourceResult.DatabaseServerName = $rsConfiguration.DatabaseServerName.Split('\')[0]
            $getTargetResourceResult.DatabaseInstanceName = $rsConfiguration.DatabaseServerName.Split('\')[1]
        }
        else
        {
            $getTargetResourceResult.DatabaseServerName = $rsConfiguration.DatabaseServerName
            $getTargetResourceResult.DatabaseInstanceName = 'MSSQLSERVER'
        }

        $isInitialized = $rsConfiguration | Test-SqlDscRSInitialized

        [System.Boolean] $getTargetResourceResult.IsInitialized = $isInitialized

        if ($isInitialized)
        {
            if ($rsConfiguration.SecureConnectionLevel)
            {
                $getTargetResourceResult.UseSsl = $true
            }
            else
            {
                $getTargetResourceResult.UseSsl = $false
            }

            $getTargetResourceResult.ReportServerVirtualDirectory = $rsConfiguration.VirtualDirectoryReportServer
            $getTargetResourceResult.ReportsVirtualDirectory = $rsConfiguration.VirtualDirectoryReportManager

            $reservedUrls = $rsConfiguration | Get-SqlDscRSUrlReservation -ErrorAction 'SilentlyContinue'

            $reportServerReservedUrl = @()
            $reportsReservedUrl = @()

            $rsSetupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName $InstanceName -ErrorAction 'SilentlyContinue'
            $reportsApplicationName = $rsSetupConfiguration | Get-SqlDscRSWebPortalApplicationName -ErrorAction 'SilentlyContinue'

            for ($i = 0; $i -lt $reservedUrls.Application.Count; ++$i)
            {
                if ($reservedUrls.Application[$i] -eq 'ReportServerWebService')
                {
                    $reportServerReservedUrl += $reservedUrls.UrlString[$i]
                }

                if ($reservedUrls.Application[$i] -eq $reportsApplicationName)
                {
                    $reportsReservedUrl += $reservedUrls.UrlString[$i]
                }
            }

            $getTargetResourceResult.ReportServerReservedUrl = $reportServerReservedUrl
            $getTargetResourceResult.ReportsReservedUrl = $reportsReservedUrl
        }
        else
        {
            <#
                Make sure the value returned is false, if the value returned was
                either empty, $null or $false. Fix for issue #822.
            #>
            [System.Boolean] $getTargetResourceResult.IsInitialized = $false
        }
    }
    else
    {
        $errorMessage = $script:localizedData.ReportingServicesNotFound -f $InstanceName

        New-ObjectNotFoundException -Message $errorMessage
    }

    return $getTargetResourceResult
}

<#
    .SYNOPSIS
        Initializes SQL Reporting Services.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.

    .PARAMETER ReportServerVirtualDirectory
        Report Server Web Service virtual directory. Optional.

    .PARAMETER ReportsVirtualDirectory
        Report Manager/Report Web App virtual directory name. Optional.

    .PARAMETER ReportServerReservedUrl
        Report Server URL reservations. Optional. If not specified,
        'http://+:80' URL reservation will be used.

    .PARAMETER ReportsReservedUrl
        Report Manager/Report Web App URL reservations. Optional.
        If not specified, 'http://+:80' URL reservation will be used.

    .PARAMETER UseSsl
        If connections to the Reporting Services must use SSL. If this
        parameter is not assigned a value, the default is that Reporting
        Services does not use SSL.

    .PARAMETER SuppressRestart
        Reporting Services need to be restarted after initialization or
        settings change. If this parameter is set to $true, Reporting Services
        will not be restarted, even after initialization.

    .PARAMETER RestartTimeout
        The number of seconds to wait after restarting Reporting Services before
        continuing with configuration. This is useful on resource-constrained
        systems where the service may take longer to fully initialize. If not
        specified, no additional wait time is applied after service restart.

    .PARAMETER Encrypt
        Specifies how encryption should be enforced. There are currently no
        difference between using `Mandatory` or `Strict`.

    .NOTES
        To find out the parameter names for the methods in the class
        MSReportServer_ConfigurationSetting it's easy to list them using the
        following code. Example for listing

        ```
        $methodName = 'ReserveUrl'
        $instanceName = 'SQL2016'
        $sqlMajorVersion = '13'
        $getCimClassParameters = @{
            ClassName = 'MSReportServer_ConfigurationSetting'
            Namespace = "root\Microsoft\SQLServer\ReportServer\RS_$instanceName\v$sqlMajorVersion\Admin"
        }
        (Get-CimClass @getCimClassParameters).CimClassMethods[$methodName].Parameters
        ```

        Or run the following using the Get-SqlDscRSConfiguration command.

        ```
        $methodName = 'ReserveUrl'
        $instanceName = 'SQL2016'
        $rsConfiguration = Get-SqlDscRSConfiguration -InstanceName $InstanceName
        $rsConfiguration.CimClass.CimClassMethods[$methodName].Parameters
        ```

        SecureConnectionLevel (the parameter UseSsl):
        The SecureConnectionLevel value can be 0,1,2 or 3, but since
        SQL Server 2008 R2 this was changed. So we are just setting it to 0 (off)
        and 1 (on).

        "In SQL Server 2008 R2, SecureConnectionLevel is made an on/off
        switch, default value is 0. For any value greater than or equal
        to 1 passed through SetSecureConnectionLevel method API, SSL
        is considered on..."
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setsecureconnectionlevel
#>
function Set-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification = 'Because the code throws based on an prior expression')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseInstanceName,

        [Parameter()]
        [System.String]
        $ReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $ReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [Parameter()]
        [System.String[]]
        $ReportsReservedUrl,

        [Parameter()]
        [System.Boolean]
        $UseSsl,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout,

        [Parameter()]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    $rsConfiguration = Get-SqlDscRSConfiguration -InstanceName $InstanceName -ErrorAction 'SilentlyContinue'

    if ($null -ne $rsConfiguration)
    {
        $rsSetupConfiguration = Get-SqlDscRSSetupConfiguration -InstanceName $InstanceName -ErrorAction 'SilentlyContinue'
        $sqlVersion = $rsSetupConfiguration | Get-SqlDscRSVersion -ErrorAction 'SilentlyContinue'
        $reportsApplicationName = $rsSetupConfiguration | Get-SqlDscRSWebPortalApplicationName -ErrorAction 'SilentlyContinue'

        if ($sqlVersion.Major -ge 14)
        {
            if ([System.String]::IsNullOrEmpty($ReportServerVirtualDirectory))
            {
                $ReportServerVirtualDirectory = 'ReportServer'
            }

            if ([System.String]::IsNullOrEmpty($ReportsVirtualDirectory))
            {
                $ReportsVirtualDirectory = 'Reports'
            }

            $reportingServicesServiceName = $rsConfiguration.ServiceName

            if ([System.String]::IsNullOrEmpty($reportingServicesServiceName))
            {
                $errorMessage = $script:localizedData.ServiceNameIsNullOrEmpty -f $InstanceName

                New-InvalidOperationException -Message $errorMessage
            }

            $reportingServicesDatabaseName = 'ReportServer'
        }
        elseif ($InstanceName -eq 'MSSQLSERVER')
        {
            if ( [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) )
            {
                $ReportServerVirtualDirectory = 'ReportServer'
            }

            if ( [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) )
            {
                $ReportsVirtualDirectory = 'Reports'
            }

            $reportingServicesServiceName = 'ReportServer'
            $reportingServicesDatabaseName = 'ReportServer'
        }
        else
        {
            if ( [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) )
            {
                $ReportServerVirtualDirectory = "ReportServer_$InstanceName"
            }

            if ( [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) )
            {
                $ReportsVirtualDirectory = "Reports_$InstanceName"
            }

            $reportingServicesServiceName = "ReportServer`$$InstanceName"
            $reportingServicesDatabaseName = "ReportServer`$$InstanceName"
        }

        # cSpell: ignore cimv2
        $wmiOperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Namespace 'root/cimv2' -ErrorAction SilentlyContinue
        if ( $null -eq $wmiOperatingSystem )
        {
            throw 'Unable to find WMI object Win32_OperatingSystem.'
        }

        $language = $wmiOperatingSystem.OSLanguage
        $restartReportingService = $false

        if (-not ($rsConfiguration | Test-SqlDscRSInitialized))
        {
            Write-Verbose -Message "Initializing Reporting Services on $DatabaseServerName\$DatabaseInstanceName."

            # We will restart Reporting Services after initialization (unless SuppressRestart is set)
            $restartReportingService = $true

            # If no Report Server reserved URLs have been specified, use the default one.
            if ( $null -eq $ReportServerReservedUrl )
            {
                $ReportServerReservedUrl = @('http://+:80')
            }

            # If no Report Manager/Report Web App reserved URLs have been specified, use the default one.
            if ( $null -eq $ReportsReservedUrl )
            {
                $ReportsReservedUrl = @('http://+:80')
            }

            if ($rsConfiguration.VirtualDirectoryReportServer -ne $ReportServerVirtualDirectory)
            {
                Write-Verbose -Message "Setting report server virtual directory on $DatabaseServerName\$DatabaseInstanceName to '$ReportServerVirtualDirectory'."

                # cSpell: ignore Lcid
                $rsConfiguration | Set-SqlDscRSVirtualDirectory -Application 'ReportServerWebService' -VirtualDirectory $ReportServerVirtualDirectory -Lcid $language -Force -ErrorAction 'Stop'

                $ReportServerReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Adding report server URL reservation on $DatabaseServerName\$DatabaseInstanceName`: $_."

                    $rsConfiguration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $_ -Lcid $language -Force -ErrorAction 'Stop'
                }
            }

            if ($rsConfiguration.VirtualDirectoryReportManager -ne $ReportsVirtualDirectory)
            {
                Write-Verbose -Message "Setting reports virtual directory on $DatabaseServerName\$DatabaseInstanceName to '$ReportServerVirtualDirectory'."

                $rsConfiguration | Set-SqlDscRSVirtualDirectory -Application $reportsApplicationName -VirtualDirectory $ReportsVirtualDirectory -Lcid $language -Force -ErrorAction 'Stop'

                $ReportsReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Adding reports URL reservation on $DatabaseServerName\$DatabaseInstanceName`: $_."

                    $rsConfiguration | Add-SqlDscRSUrlReservation -Application $reportsApplicationName -UrlString $_ -Lcid $language -Force -ErrorAction 'Stop'
                }
            }

            Write-Verbose -Message "Generate database creation script on $DatabaseServerName\$DatabaseInstanceName for database '$reportingServicesDatabaseName'."

            $reportingServicesDatabaseScript = $rsConfiguration | Request-SqlDscRSDatabaseScript -DatabaseName $reportingServicesDatabaseName -Lcid $language -ErrorAction 'Stop'

            # The WindowsServiceIdentityActual property contains the actual account name actively used by the service.
            $reportingServicesServiceAccountUserName = $rsConfiguration.WindowsServiceIdentityActual

            Write-Verbose -Message "Generate database rights script on $DatabaseServerName\$DatabaseInstanceName for database '$reportingServicesDatabaseName' and user '$reportingServicesServiceAccountUserName'."

            $reportingServicesDatabaseRightsScript = $rsConfiguration | Request-SqlDscRSDatabaseRightsScript -DatabaseName $reportingServicesDatabaseName -UserName $reportingServicesServiceAccountUserName -ErrorAction 'Stop'

            Import-SqlDscPreferredModule

            $invokeSqlDscQueryParameters = @{
                ServerName   = $DatabaseServerName
                InstanceName = $DatabaseInstanceName
                DatabaseName = 'master'
                Force        = $true
                Verbose      = $VerbosePreference
                ErrorAction  = 'Stop'
            }

            if ($PSBoundParameters.ContainsKey('Encrypt') -and $Encrypt -ne 'Optional')
            {
                $invokeSqlDscQueryParameters.Encrypt = $true
            }

            Invoke-SqlDscQuery @invokeSqlDscQueryParameters -Query $reportingServicesDatabaseScript
            Invoke-SqlDscQuery @invokeSqlDscQueryParameters -Query $reportingServicesDatabaseRightsScript

            Write-Verbose -Message "Set database connection on $DatabaseServerName\$DatabaseInstanceName to database '$reportingServicesDatabaseName'."

            $setSqlDscRSDatabaseConnectionParameters = @{
                ServerName   = $DatabaseServerName
                DatabaseName = $reportingServicesDatabaseName
                Type         = 'ServiceAccount'
                Force        = $true
                ErrorAction  = 'Stop'
            }

            if ($DatabaseInstanceName -ne 'MSSQLSERVER')
            {
                $setSqlDscRSDatabaseConnectionParameters.InstanceName = $DatabaseInstanceName
            }

            $rsConfiguration | Set-SqlDscRSDatabaseConnection @setSqlDscRSDatabaseConnectionParameters

            <#
                When initializing SSRS 2019, the call to InitializeReportServer
                always fails, even if IsInitialized flag is $false.
                It also seems that simply restarting SSRS at this point initializes
                it.

                This has since been change to always restart Reporting Services service
                for all versions to initialize the Reporting Services. If still not
                initialized after restart, the CIM method InitializeReportServer will
                also run after.

                We will ignore $SuppressRestart here.
            #>
            Write-Verbose -Message $script:localizedData.RestartToFinishInitialization

            Restart-SqlDscRSService -ServiceName $reportingServicesServiceName -WaitTime 30 -Force

            <#
                Wait for the service to be fully ready after restart before attempting
                to get reporting services data or initialize. This is especially important
                on resource-constrained systems where the service may take longer to
                fully initialize (e.g., Windows Server 2025 in CI environments).
            #>
            if ($PSBoundParameters.ContainsKey('RestartTimeout'))
            {
                Write-Verbose -Message ($script:localizedData.WaitingForServiceReady -f $RestartTimeout)
                Start-Sleep -Seconds $RestartTimeout
            }

            $restartReportingService = $false

            # Refresh the configuration after restart
            $rsConfiguration = Get-SqlDscRSConfiguration -InstanceName $InstanceName -ErrorAction 'Stop'

            <#
                Only execute InitializeReportServer if SetDatabaseConnection hasn't
                initialized Reporting Services already. Otherwise, executing
                InitializeReportServer will fail on SQL Server Standard and
                lower editions.
            #>
            if (-not ($rsConfiguration | Test-SqlDscRSInitialized))
            {
                Write-Verbose -Message "Did not help restarting the Reporting Services service, running the CIM method to initialize report server on $DatabaseServerName\$DatabaseInstanceName for instance ID '$($rsConfiguration.InstallationID)'."

                <#
                    Add an additional wait before calling InitializeReportServer to give
                    the WMI provider more time to be fully ready. This is especially
                    important on resource-constrained systems.
                #>
                if ($PSBoundParameters.ContainsKey('RestartTimeout'))
                {
                    Write-Verbose -Message ($script:localizedData.WaitingForServiceReady -f $RestartTimeout)
                    Start-Sleep -Seconds $RestartTimeout
                }

                $restartReportingService = $true

                $rsConfiguration | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
            }
            else
            {
                Write-Verbose -Message "Reporting Services on $DatabaseServerName\$DatabaseInstanceName is initialized."
            }

            if ( $PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $rsConfiguration.SecureConnectionLevel )
            {
                Write-Verbose -Message "Changing value for using SSL to '$UseSsl'."

                $restartReportingService = $true

                if ($UseSsl)
                {
                    $rsConfiguration | Enable-SqlDscRsSecureConnection -Force -ErrorAction 'Stop'
                }
                else
                {
                    $rsConfiguration | Disable-SqlDscRsSecureConnection -Force -ErrorAction 'Stop'
                }
            }
        }
        else
        {
            $getTargetResourceParameters = @{
                InstanceName         = $InstanceName
                DatabaseServerName   = $DatabaseServerName
                DatabaseInstanceName = $DatabaseInstanceName
            }

            $currentConfig = Get-TargetResource @getTargetResourceParameters

            <#
                SQL Server Reporting Services virtual directories (both
                Report Server and Report Manager/Report Web App) are a
                part of SQL Server Reporting Services URL reservations.

                The default SQL Server Reporting Services URL reservations are:
                http://+:80/ReportServer/ (for Report Server)
                and
                http://+:80/Reports/ (for Report Manager/Report Web App)

                You can get them by running 'netsh http show urlacl' from
                command line.

                In order to change a virtual directory, we first need to remove
                existing URL reservations, change the appropriate virtual directory
                setting and re-add URL reservations, which will then contain the
                new virtual directory.

                cSpell: ignore netsh urlacl
            #>

            if ( -not [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory) )
            {
                Write-Verbose -Message "Setting report server virtual directory on $DatabaseServerName\$DatabaseInstanceName to $ReportServerVirtualDirectory."

                $restartReportingService = $true

                $currentConfig.ReportServerReservedUrl | ForEach-Object -Process {
                    $rsConfiguration | Remove-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $_ -Lcid $language -Force -ErrorAction 'Stop'
                }

                $rsConfiguration | Set-SqlDscRSVirtualDirectory -Application 'ReportServerWebService' -VirtualDirectory $ReportServerVirtualDirectory -Lcid $language -Force -ErrorAction 'Stop'

                $currentConfig.ReportServerReservedUrl | ForEach-Object -Process {
                    $rsConfiguration | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $_ -Lcid $language -Force -ErrorAction 'Stop'
                }
            }

            if ( -not [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory) )
            {
                Write-Verbose -Message "Setting reports virtual directory on $DatabaseServerName\$DatabaseInstanceName to $ReportServerVirtualDirectory."

                $restartReportingService = $true

                $currentConfig.ReportsReservedUrl | ForEach-Object -Process {
                    $rsConfiguration | Remove-SqlDscRSUrlReservation -Application $reportsApplicationName -UrlString $_ -Lcid $language -Force -ErrorAction 'Stop'
                }

                $rsConfiguration | Set-SqlDscRSVirtualDirectory -Application $reportsApplicationName -VirtualDirectory $ReportsVirtualDirectory -Lcid $language -Force -ErrorAction 'Stop'

                $currentConfig.ReportsReservedUrl | ForEach-Object -Process {
                    $rsConfiguration | Add-SqlDscRSUrlReservation -Application $reportsApplicationName -UrlString $_ -Lcid $language -Force -ErrorAction 'Stop'
                }
            }

            $compareParameters = @{
                ReferenceObject  = $currentConfig.ReportServerReservedUrl
                DifferenceObject = $ReportServerReservedUrl
            }

            if ( ($null -ne $ReportServerReservedUrl) -and ($null -ne (Compare-Object @compareParameters)) )
            {
                Write-Verbose -Message "Updating report server URL reservations on $DatabaseServerName\$DatabaseInstanceName."

                $restartReportingService = $true

                $rsConfiguration | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $ReportServerReservedUrl -Lcid $language -Force -ErrorAction 'Stop'
            }

            $compareParameters = @{
                ReferenceObject  = $currentConfig.ReportsReservedUrl
                DifferenceObject = $ReportsReservedUrl
            }

            if ( ($null -ne $ReportsReservedUrl) -and ($null -ne (Compare-Object @compareParameters)) )
            {
                Write-Verbose -Message "Updating reports URL reservations on $DatabaseServerName\$DatabaseInstanceName."

                $restartReportingService = $true

                $rsConfiguration | Set-SqlDscRSUrlReservation -Application $reportsApplicationName -UrlString $ReportsReservedUrl -Lcid $language -Force -ErrorAction 'Stop'
            }

            if ( $PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $currentConfig.UseSsl )
            {
                Write-Verbose -Message "Changing value for using SSL to '$UseSsl'."

                $restartReportingService = $true

                if ($UseSsl)
                {
                    $rsConfiguration | Enable-SqlDscRsSecureConnection -Force -ErrorAction 'Stop'
                }
                else
                {
                    $rsConfiguration | Disable-SqlDscRsSecureConnection -Force -ErrorAction 'Stop'
                }
            }
        }

        if ( $restartReportingService -and $SuppressRestart )
        {
            Write-Warning -Message $script:localizedData.SuppressRestart
        }
        elseif ( $restartReportingService -and (-not $SuppressRestart) )
        {
            Write-Verbose -Message $script:localizedData.Restart
            Restart-SqlDscRSService -ServiceName $reportingServicesServiceName -WaitTime 30 -Force

            <#
                Wait for the service to be fully ready after restart before attempting
                to test the configuration. This is especially important on resource-constrained
                systems where the service may take longer to fully initialize.
            #>
            if ($PSBoundParameters.ContainsKey('RestartTimeout'))
            {
                Write-Verbose -Message ($script:localizedData.WaitingForServiceReady -f $RestartTimeout)
                Start-Sleep -Seconds $RestartTimeout
            }
        }
    }

    if ( -not (Test-TargetResource @PSBoundParameters) )
    {
        $errorMessage = $script:localizedData.TestFailedAfterSet
        New-InvalidResultException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Tests the SQL Reporting Services initialization status.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.

    .PARAMETER ReportServerVirtualDirectory
        Report Server Web Service virtual directory. Optional.

    .PARAMETER ReportsVirtualDirectory
        Report Manager/Report Web App virtual directory name. Optional.

    .PARAMETER ReportServerReservedUrl
        Report Server URL reservations. Optional. If not specified,
        http://+:80' URL reservation will be used.

    .PARAMETER ReportsReservedUrl
        Report Manager/Report Web App URL reservations. Optional.
        If not specified, 'http://+:80' URL reservation will be used.

    .PARAMETER UseSsl
        If connections to the Reporting Services must use SSL. If this
        parameter is not assigned a value, the default is that Reporting
        Services does not use SSL.

    .PARAMETER SuppressRestart
        Reporting Services need to be restarted after initialization or
        settings change. If this parameter is set to $true, Reporting Services
        will not be restarted, even after initialization.

    .PARAMETER RestartTimeout
        Not used in Test-TargetResource.

    .PARAMETER Encrypt
        Specifies how encryption should be enforced. There are currently no
        difference between using `Mandatory` or `Strict`.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification = 'Neither command is needed for this function since it uses CIM methods implicitly when calling Get-TargetResource')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseInstanceName,

        [Parameter()]
        [System.String]
        $ReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $ReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $ReportServerReservedUrl,

        [Parameter()]
        [System.String[]]
        $ReportsReservedUrl,

        [Parameter()]
        [System.Boolean]
        $UseSsl,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart,

        [Parameter()]
        [System.UInt32]
        $RestartTimeout,

        [Parameter()]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    $result = $true

    $getTargetResourceParameters = @{
        InstanceName         = $InstanceName
        DatabaseServerName   = $DatabaseServerName
        DatabaseInstanceName = $DatabaseInstanceName
    }

    if ($PSBoundParameters.ContainsKey('Encrypt'))
    {
        $getTargetResourceParameters.Encrypt = $Encrypt
    }

    $currentConfig = Get-TargetResource @getTargetResourceParameters

    if (-not $currentConfig.IsInitialized)
    {
        Write-Verbose -Message "Reporting services $DatabaseServerName\$DatabaseInstanceName are not initialized."
        $result = $false
    }

    if (-not [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory))
    {
        Write-Verbose -Message "Report server virtual directory on $DatabaseServerName\$DatabaseInstanceName is $($currentConfig.ReportServerVirtualDir), should be $ReportServerVirtualDirectory."
        $result = $false
    }

    if (-not [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory))
    {
        Write-Verbose -Message "Reports virtual directory on $DatabaseServerName\$DatabaseInstanceName is $($currentConfig.ReportsVirtualDir), should be $ReportsVirtualDirectory."
        $result = $false
    }

    if ($PSBoundParameters.ContainsKey('ReportServerReservedUrl'))
    {
        if ($null -eq $currentConfig.ReportServerReservedUrl)
        {
            Write-Verbose -Message "Report server reserved URLs on $DatabaseServerName\$DatabaseInstanceName are missing, should be $($ReportServerReservedUrl -join ', ')."
            $result = $false
        }
        else
        {
            $compareParameters = @{
                ReferenceObject  = $currentConfig.ReportServerReservedUrl
                DifferenceObject = $ReportServerReservedUrl
            }

            if ($null -ne (Compare-Object @compareParameters))
            {
                Write-Verbose -Message "Report server reserved URLs on $DatabaseServerName\$DatabaseInstanceName are $($currentConfig.ReportServerReservedUrl -join ', '), should be $($ReportServerReservedUrl -join ', ')."
                $result = $false
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('ReportsReservedUrl'))
    {
        if ($null -eq $currentConfig.ReportsReservedUrl)
        {
            Write-Verbose -Message "Reports reserved URLs on $DatabaseServerName\$DatabaseInstanceName are missing, should be $($ReportsReservedUrl -join ', ')."
            $result = $false
        }
        else
        {
            $compareParameters = @{
                ReferenceObject  = $currentConfig.ReportsReservedUrl
                DifferenceObject = $ReportsReservedUrl
            }

            if ($null -ne (Compare-Object @compareParameters))
            {
                Write-Verbose -Message "Reports reserved URLs on $DatabaseServerName\$DatabaseInstanceName are $($currentConfig.ReportsReservedUrl -join ', ')), should be $($ReportsReservedUrl -join ', ')."
                $result = $false
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $currentConfig.UseSsl)
    {
        Write-Verbose -Message "The value for using SSL are not in desired state. Should be '$UseSsl', but was '$($currentConfig.UseSsl)'."
        $result = $false
    }

    $result
}
