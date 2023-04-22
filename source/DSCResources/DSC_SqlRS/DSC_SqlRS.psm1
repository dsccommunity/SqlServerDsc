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
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='Neither command is needed for this function since it uses CIM methods when calling Get-ReportingServicesData')]
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

    $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName

    if ( $null -ne $reportingServicesData.Configuration )
    {
        if ( $reportingServicesData.Configuration.DatabaseServerName.Contains('\') )
        {
            $getTargetResourceResult.DatabaseServerName = $reportingServicesData.Configuration.DatabaseServerName.Split('\')[0]
            $getTargetResourceResult.DatabaseInstanceName = $reportingServicesData.Configuration.DatabaseServerName.Split('\')[1]
        }
        else
        {
            $getTargetResourceResult.DatabaseServerName = $reportingServicesData.Configuration.DatabaseServerName
            $getTargetResourceResult.DatabaseInstanceName = 'MSSQLSERVER'
        }

        $isInitialized = $reportingServicesData.Configuration.IsInitialized

        [System.Boolean] $getTargetResourceResult.IsInitialized = $isInitialized

        if ( $isInitialized )
        {
            if ( $reportingServicesData.Configuration.SecureConnectionLevel )
            {
                $getTargetResourceResult.UseSsl = $true
            }
            else
            {
                $getTargetResourceResult.UseSsl = $false
            }

            $getTargetResourceResult.ReportServerVirtualDirectory = $reportingServicesData.Configuration.VirtualDirectoryReportServer
            $getTargetResourceResult.ReportsVirtualDirectory = $reportingServicesData.Configuration.VirtualDirectoryReportManager

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'ListReservedUrls'
            }

            $reservedUrls = Invoke-RsCimMethod @invokeRsCimMethodParameters

            $reportServerReservedUrl = @()
            $reportsReservedUrl = @()

            for ( $i = 0; $i -lt $reservedUrls.Application.Count; ++$i )
            {
                if ( $reservedUrls.Application[$i] -eq 'ReportServerWebService' )
                {
                    $reportServerReservedUrl += $reservedUrls.UrlString[$i]
                }

                if ( $reservedUrls.Application[$i] -eq $reportingServicesData.ReportsApplicationName )
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
                either empty, $null or $false. Fic for issue #822.
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

        Or run the following using the helper function in this code. Make sure
        to have the helper function loaded in the session.

        ```
        $methodName = 'ReserveUrl'
        $instanceName = 'SQL2016'
        $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName
        $reportingServicesData.Configuration.CimClass.CimClassMethods[$methodName].Parameters
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
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification='Because the code throws based on an prior expression')]
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
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName

    if ( $null -ne $reportingServicesData.Configuration )
    {
        if ( $reportingServicesData.SqlVersion -ge 14 )
        {
            if ( [string]::IsNullOrEmpty($ReportServerVirtualDirectory) )
            {
                $ReportServerVirtualDirectory = 'ReportServer'
            }

            if ( [string]::IsNullOrEmpty($ReportsVirtualDirectory) )
            {
                $ReportsVirtualDirectory = 'Reports'
            }

            $reportingServicesServiceName = 'SQLServerReportingServices'
            $reportingServicesDatabaseName = 'ReportServer'
        }
        elseif ( $InstanceName -eq 'MSSQLSERVER' )
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

        $wmiOperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Namespace 'root/cimv2' -ErrorAction SilentlyContinue
        if ( $null -eq $wmiOperatingSystem )
        {
            throw 'Unable to find WMI object Win32_OperatingSystem.'
        }

        $language = $wmiOperatingSystem.OSLanguage
        $restartReportingService = $false

        if ( -not $reportingServicesData.Configuration.IsInitialized )
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

            if ( $reportingServicesData.Configuration.VirtualDirectoryReportServer -ne $ReportServerVirtualDirectory )
            {
                Write-Verbose -Message "Setting report server virtual directory on $DatabaseServerName\$DatabaseInstanceName to '$ReportServerVirtualDirectory'."

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'SetVirtualDirectory'
                    Arguments   = @{
                        Application      = 'ReportServerWebService'
                        VirtualDirectory = $ReportServerVirtualDirectory
                        Lcid             = $language
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters

                $ReportServerReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Adding report server URL reservation on $DatabaseServerName\$DatabaseInstanceName`: $_."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'ReserveUrl'
                        Arguments   = @{
                            Application = 'ReportServerWebService'
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $reportingServicesData.Configuration.VirtualDirectoryReportManager -ne $ReportsVirtualDirectory )
            {
                Write-Verbose -Message "Setting reports virtual directory on $DatabaseServerName\$DatabaseInstanceName to '$ReportServerVirtualDirectory'."

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'SetVirtualDirectory'
                    Arguments   = @{
                        Application      = $reportingServicesData.ReportsApplicationName
                        VirtualDirectory = $ReportsVirtualDirectory
                        Lcid             = $language
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters

                $ReportsReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Adding reports URL reservation on $DatabaseServerName\$DatabaseInstanceName`: $_."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'ReserveUrl'
                        Arguments   = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            Write-Verbose -Message "Generate database creation script on $DatabaseServerName\$DatabaseInstanceName for database '$reportingServicesDatabaseName'."

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'GenerateDatabaseCreationScript'
                Arguments   = @{
                    DatabaseName     = $reportingServicesDatabaseName
                    IsSharePointMode = $false
                    Lcid             = $language
                }
            }

            $reportingServicesDatabaseScript = Invoke-RsCimMethod @invokeRsCimMethodParameters

            # Determine RS service account
            $reportingServicesServiceAccountUserName = (Get-CimInstance -ClassName Win32_Service | Where-Object -FilterScript {
                    $_.Name -eq $reportingServicesServiceName
                }).StartName

            Write-Verbose -Message "Generate database rights script on $DatabaseServerName\$DatabaseInstanceName for database '$reportingServicesDatabaseName' and user '$reportingServicesServiceAccountUserName'."

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'GenerateDatabaseRightsScript'
                Arguments   = @{
                    DatabaseName  = $reportingServicesDatabaseName
                    UserName      = $reportingServicesServiceAccountUserName
                    IsRemote      = $false
                    IsWindowsUser = $true
                }
            }

            $reportingServicesDatabaseRightsScript = Invoke-RsCimMethod @invokeRsCimMethodParameters

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

            Invoke-SqlDscQuery @invokeSqlDscQueryParameters -Query $reportingServicesDatabaseScript.Script
            Invoke-SqlDscQuery @invokeSqlDscQueryParameters -Query $reportingServicesDatabaseRightsScript.Script

            Write-Verbose -Message "Set database connection on $DatabaseServerName\$DatabaseInstanceName to database '$reportingServicesDatabaseName'."

            if ( $DatabaseInstanceName -eq 'MSSQLSERVER' )
            {
                $reportingServicesConnection = $DatabaseServerName
            }
            else
            {
                $reportingServicesConnection = "$DatabaseServerName\$DatabaseInstanceName"
            }

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'SetDatabaseConnection'
                Arguments   = @{
                    Server          = $reportingServicesConnection
                    DatabaseName    = $reportingServicesDatabaseName
                    Username        = ''
                    Password        = ''

                    <#
                        Can be set to either:
                        0 = Windows
                        1 = Sql Server
                        2 = Windows Service (Integrated Security)

                        When set to 2 the Reporting Server Web service will use
                        either the ASP.NET account or an application pool’s account
                        and the Windows service account to access the report server
                        database.

                        See more in the article
                        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setdatabaseconnection#remarks

                    #>
                    CredentialsType = 2
                }
            }

            Invoke-RsCimMethod @invokeRsCimMethodParameters

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

            Restart-ReportingServicesService -InstanceName $InstanceName -WaitTime 30

            $restartReportingService = $false

            $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName

            <#
                Only execute InitializeReportServer if SetDatabaseConnection hasn't
                initialized Reporting Services already. Otherwise, executing
                InitializeReportServer will fail on SQL Server Standard and
                lower editions.
            #>
            if ( -not $reportingServicesData.Configuration.IsInitialized )
            {
                Write-Verbose -Message "Did not help restarting the Reporting Services service, running the CIM method to initialize report server on $DatabaseServerName\$DatabaseInstanceName for instance ID '$($reportingServicesData.Configuration.InstallationID)'."

                $restartReportingService = $true

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'InitializeReportServer'
                    Arguments   = @{
                        InstallationId = $reportingServicesData.Configuration.InstallationID
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
            else
            {
                Write-Verbose -Message "Reporting Services on $DatabaseServerName\$DatabaseInstanceName is initialized."
            }

            if ( $PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $reportingServicesData.Configuration.SecureConnectionLevel )
            {
                Write-Verbose -Message "Changing value for using SSL to '$UseSsl'."

                $restartReportingService = $true

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'SetSecureConnectionLevel'
                    Arguments   = @{
                        Level = @(0, 1)[$UseSsl]
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters
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
            #>

            if ( -not [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory) )
            {
                Write-Verbose -Message "Setting report server virtual directory on $DatabaseServerName\$DatabaseInstanceName to $ReportServerVirtualDirectory."

                $restartReportingService = $true

                $currentConfig.ReportServerReservedUrl | ForEach-Object -Process {
                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'RemoveURL'
                        Arguments   = @{
                            Application = 'ReportServerWebService'
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'SetVirtualDirectory'
                    Arguments   = @{
                        Application      = 'ReportServerWebService'
                        VirtualDirectory = $ReportServerVirtualDirectory
                        Lcid             = $language
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters

                $currentConfig.ReportServerReservedUrl | ForEach-Object -Process {
                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'ReserveUrl'
                        Arguments   = @{
                            Application = 'ReportServerWebService'
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( -not [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory) )
            {
                Write-Verbose -Message "Setting reports virtual directory on $DatabaseServerName\$DatabaseInstanceName to $ReportServerVirtualDirectory."

                $restartReportingService = $true

                $currentConfig.ReportsReservedUrl | ForEach-Object -Process {
                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'RemoveURL'
                        Arguments   = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'SetVirtualDirectory'
                    Arguments   = @{
                        Application      = $reportingServicesData.ReportsApplicationName
                        VirtualDirectory = $ReportsVirtualDirectory
                        Lcid             = $language
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters

                $currentConfig.ReportsReservedUrl | ForEach-Object -Process {
                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'ReserveUrl'
                        Arguments   = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            $compareParameters = @{
                ReferenceObject  = $currentConfig.ReportServerReservedUrl
                DifferenceObject = $ReportServerReservedUrl
            }

            if ( ($null -ne $ReportServerReservedUrl) -and ($null -ne (Compare-Object @compareParameters)) )
            {
                $restartReportingService = $true

                $currentConfig.ReportServerReservedUrl | ForEach-Object -Process {
                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'RemoveURL'
                        Arguments   = @{
                            Application = 'ReportServerWebService'
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }

                $ReportServerReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Adding report server URL reservation on $DatabaseServerName\$DatabaseInstanceName`: $_."
                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'ReserveUrl'
                        Arguments   = @{
                            Application = 'ReportServerWebService'
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            $compareParameters = @{
                ReferenceObject  = $currentConfig.ReportsReservedUrl
                DifferenceObject = $ReportsReservedUrl
            }

            if ( ($null -ne $ReportsReservedUrl) -and ($null -ne (Compare-Object @compareParameters)) )
            {
                $restartReportingService = $true

                $currentConfig.ReportsReservedUrl | ForEach-Object -Process {
                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'RemoveURL'
                        Arguments   = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }

                $ReportsReservedUrl | ForEach-Object -Process {
                    Write-Verbose -Message "Adding reports URL reservation on $DatabaseServerName\$DatabaseInstanceName`: $_."

                    $invokeRsCimMethodParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'ReserveUrl'
                        Arguments   = @{
                            Application = $reportingServicesData.ReportsApplicationName
                            UrlString   = $_
                            Lcid        = $language
                        }
                    }

                    Invoke-RsCimMethod @invokeRsCimMethodParameters
                }
            }

            if ( $PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $currentConfig.UseSsl )
            {
                Write-Verbose -Message "Changing value for using SSL to '$UseSsl'."

                $restartReportingService = $true

                $invokeRsCimMethodParameters = @{
                    CimInstance = $reportingServicesData.Configuration
                    MethodName  = 'SetSecureConnectionLevel'
                    Arguments   = @{
                        Level = @(0, 1)[$UseSsl]
                    }
                }

                Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
        }

        if ( $restartReportingService -and $SuppressRestart )
        {
            Write-Warning -Message $script:localizedData.SuppressRestart
        }
        elseif ( $restartReportingService -and (-not $SuppressRestart) )
        {
            Write-Verbose -Message $script:localizedData.Restart
            Restart-ReportingServicesService -InstanceName $InstanceName -WaitTime 30
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

    .PARAMETER Encrypt
        Specifies how encryption should be enforced. There are currently no
        difference between using `Mandatory` or `Strict`.
#>
function Test-TargetResource
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('SqlServerDsc.AnalyzerRules\Measure-CommandsNeededToLoadSMO', '', Justification='Neither command is needed for this function since it uses CIM methods implicitly when calling Get-TargetResource')]
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

<#
    .SYNOPSIS
        Returns SQL Reporting Services data: configuration object used to initialize and configure
        SQL Reporting Services and the name of the Reports Web application name (changed in SQL 2016)

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance for which the data is being retrieved.
#>
function Get-ReportingServicesData
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $instanceNamesRegistryKey = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

    if (Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName -ErrorAction SilentlyContinue)
    {
        $instanceId = (Get-ItemProperty -Path $instanceNamesRegistryKey -Name $InstanceName).$InstanceName

        if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\MSSQLServer\CurrentVersion")
        {
            # SQL Server 2017 and 2019 SSRS stores current SQL Server version to a different Registry path.
            $sqlVersion = [int]((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\CurrentVersion" -Name 'CurrentVersion').CurrentVersion).Split('.')[0]
        }
        else
        {
            $sqlVersion = [int]((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup" -Name 'Version').Version).Split('.')[0]
        }

        $reportingServicesConfiguration = Get-CimInstance -ClassName MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$InstanceName\v$sqlVersion\Admin"
        $reportingServicesConfiguration = $reportingServicesConfiguration | Where-Object -FilterScript {
            $_.InstanceName -eq $InstanceName
        }

        <#
            SQL Server Reporting Services Web Portal application name changed
            in SQL Server 2016.
            https://docs.microsoft.com/en-us/sql/reporting-services/breaking-changes-in-sql-server-reporting-services-in-sql-server-2016
        #>
        if ($sqlVersion -ge 13)
        {
            $reportsApplicationName = 'ReportServerWebApp'
        }
        else
        {
            $reportsApplicationName = 'ReportManager'
        }
    }

    @{
        Configuration          = $reportingServicesConfiguration
        ReportsApplicationName = $reportsApplicationName
        SqlVersion             = $sqlVersion
    }
}

<#
    .SYNOPSIS
        A wrapper for Invoke-CimMethod to be able to handle errors in one place.

    .PARAMETER CimInstance
        The CIM instance object that contains the method to call.

    .PARAMETER MethodName
        The method to call in the CIM Instance object.

    .PARAMETER Arguments
        The arguments that should be
#>
function Invoke-RsCimMethod
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification='Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimMethodResult])]
    param
    (

        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $CimInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MethodName,

        [Parameter()]
        [System.Collections.Hashtable]
        $Arguments
    )

    $invokeCimMethodParameters = @{
        MethodName  = $MethodName
        ErrorAction = 'Stop'
    }

    if ($PSBoundParameters.ContainsKey('Arguments'))
    {
        $invokeCimMethodParameters['Arguments'] = $Arguments
    }

    $invokeCimMethodResult = $CimInstance | Invoke-CimMethod @invokeCimMethodParameters
    <#
        Successfully calling the method returns $invokeCimMethodResult.HRESULT -eq 0.
        If an general error occur in the Invoke-CimMethod, like calling a method
        that does not exist, returns $null in $invokeCimMethodResult.
    #>
    if ($invokeCimMethodResult -and $invokeCimMethodResult.HRESULT -ne 0)
    {
        if ($invokeCimMethodResult | Get-Member -Name 'ExtendedErrors')
        {
            <#
                The returned object property ExtendedErrors is an array
                so that needs to be concatenated.
            #>
            $errorMessage = $invokeCimMethodResult.ExtendedErrors -join ';'
        }
        else
        {
            $errorMessage = $invokeCimMethodResult.Error
        }

        throw 'Method {0}() failed with an error. Error: {1} (HRESULT:{2})' -f @(
            $MethodName
            $errorMessage
            $invokeCimMethodResult.HRESULT
        )
    }

    return $invokeCimMethodResult
}
