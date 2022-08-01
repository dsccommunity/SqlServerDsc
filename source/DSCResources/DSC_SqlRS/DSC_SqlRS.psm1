$script:sqlServerDscHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SqlServerDsc.Common'
$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:sqlServerDscHelperModulePath
Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Gets the SQL Server Reporting Services properties.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.

    .PARAMETER EncryptionKeyBackupPath
        The path where the encryption key will be backed up to.

    .PARAMETER EncryptionKeyBackupPathCredential
        The credential which is used to access the path specified in EncryptionKeyBackupPath.
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
        [System.String]
        $EncryptionKeyBackupPath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $EncryptionKeyBackupPathCredential
    )

    Write-Verbose -Message (
        $script:localizedData.GetConfiguration -f $InstanceName
    )

    $getTargetResourceResult = @{
        InstanceName                 = $InstanceName
        DatabaseServerName           = $null
        DatabaseInstanceName         = $null
        DatabaseName                 = $null
        ReportServerVirtualDirectory = $null
        ReportsVirtualDirectory      = $null
        ReportServerReservedUrl      = $null
        ReportsReservedUrl           = $null
        HttpsCertificateThumbprint   = $null
        HttpsIPAddress               = $null
        HttpsPort                    = $null
        UseSsl                       = $false
        IsInitialized                = $false
        ServiceName                  = $null
        ServiceAccountName           = $null
        EncryptionKeyBackupFile      = $null
    }

    $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName

    if ( $null -ne $reportingServicesData.Configuration )
    {
        #region Get Operating System Information
        try
        {
            $wmiOperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Namespace 'root/cimv2' -ErrorAction Stop
        }
        catch
        {
            New-ObjectNotFoundException -Message ( $script:localizedData.GetOperatingSystemClassError ) -ErrorRecord $_
        }

        $language = $wmiOperatingSystem.OSLanguage
        #endregion Get Operating System Information

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
        $getTargetResourceResult.IsInitialized = [System.Boolean] $isInitialized
        $getTargetResourceResult.ServiceName = $reportingServicesData.Configuration.ServiceName
        $getTargetResourceResult.ServiceAccountName = $reportingServicesData.Configuration.WindowsServiceIdentityActual
        $getTargetResourceResult.DatabaseName = $reportingServicesData.Configuration.DatabaseName

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

        #region Get Reserved URLs
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
        #endregion Get Reserved URLs

        #region Get SSL Certificate Bindings
        $invokeRsCimMethodListSSLCertificateBindingsParameters = @{
            CimInstance = $reportingServicesData.Configuration
            MethodName  = 'ListSSLCertificateBindings'
            Arguments = @{
                LCID = $language
            }
        }
        $sslCertificateBindings = Invoke-RsCimMethod @invokeRsCimMethodListSSLCertificateBindingsParameters

        $getTargetResourceResult.HttpsCertificateThumbprint = $sslCertificateBindings | Select-Object -ExpandProperty CertificateHash -Unique -ErrorAction SilentlyContinue
        $getTargetResourceResult.HttpsIPAddress = $sslCertificateBindings | Select-Object -ExpandProperty IPAddress -Unique -ErrorAction SilentlyContinue
        $getTargetResourceResult.HttpsPort = $sslCertificateBindings | Select-Object -ExpandProperty Port -Unique -ErrorAction SilentlyContinue
        #endregion Get SSL Certificate Bindings

        #region Get Encryption Key Backup
        if ( $PSBoundParameters.ContainsKey('EncryptionKeyBackupPath') )
        {
            $EncryptionKeyBackupPath = [Environment]::ExpandEnvironmentVariables($EncryptionKeyBackupPath)

            if ( $EncryptionKeyBackupPath -match '^\\\\')
            {
                $encryptionKeyBackupPathIsUnc = $true
            }
            else
            {
                $encryptionKeyBackupPathIsUnc = $false
            }

            if ( $encryptionKeyBackupPathIsUnc -and $PSBoundParameters.ContainsKey('EncryptionKeyBackupPathCredential') )
            {
                Connect-UncPath -RemotePath $EncryptionKeyBackupPath -SourceCredential $EncryptionKeyBackupPathCredential
            }

            $encryptionKeyBackupFileName = "$($env:ComputerName)-$InstanceName.snk"
            $encryptionKeyBackupFile = Join-Path -Path $EncryptionKeyBackupPath -ChildPath $encryptionKeyBackupFileName

            $getTargetResourceResult.EncryptionKeyBackupFile = ( Get-Item -Path $encryptionKeyBackupFile -ErrorAction SilentlyContinue ).Name

            if ( $encryptionKeyBackupPathIsUnc -and $PSBoundParameters.ContainsKey('EncryptionKeyBackupPathCredential') )
            {
                Disconnect-UncPath -RemotePath $EncryptionKeyBackupPath
            }
        }
        #endregion Get Encryption Key Backup
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
        Configures SQL Server Reporting Services.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.

    .PARAMETER DatabaseName
        Name of the the Reporting Services database. Default is "ReportServer".

    .PARAMETER LocalServiceAccountType
        Name of the local account which the service will run as. This is
        ignored if the _ServiceAccount_ parameter is supplied.. Default is
        "VirtualAccount".

    .PARAMETER ServiceAccount
        The service account that should be used when running the Windows
        service.

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

    .PARAMETER HttpsCertificateThumbprint
        The thumbprint of the certificate used to secure SSL communication.

    .PARAMETER HttpsIPAddress
        The IP address to bind the certificate specified in the
        CertificateThumbprint parameter to. Default is `0.0.0.0` which binds to
        all IP addresses.

    .PARAMETER HttpsPort
        The port used for SSL communication. Default is `443`.

    .PARAMETER UseSsl
        If connections to the Reporting Services must use SSL. If this
        parameter is not assigned a value, the default is that Reporting
        Services does not use SSL.

    .PARAMETER SuppressRestart
        Reporting Services need to be restarted after initialization or
        settings change. If this parameter is set to $true, Reporting Services
        will not be restarted, even after initialization.

    .PARAMETER EncryptionKeyBackupPath
        The path where the encryption key will be backed up to.

    .PARAMETER EncryptionKeyBackupPathCredential
        The credential which is used to access the path specified in
        "EncryptionKeyBackupPath".

    .PARAMETER EncryptionKeyBackupCredential
        The credential which should be used to backup the encryption key. If no
        credential is supplied, a randomized value will be generated for
        internal use during runtime.

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
        The SecureConnectionLevel value can be 0, 1, 2, or 3, but since
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
        $DatabaseName = 'ReportServer',

        [Parameter()]
        [ValidateSet(
            'LocalService',
            'NetworkService',
            'System',
            'VirtualAccount'
        )]
        [System.String]
        $LocalServiceAccountType = 'VirtualAccount',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter()]
        [System.String]
        $ReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $ReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $ReportServerReservedUrl = @('http://+:80'),

        [Parameter()]
        [System.String[]]
        $ReportsReservedUrl = @('http://+:80'),

        [Parameter()]
        [System.String]
        $HttpsCertificateThumbprint,

        [Parameter()]
        [System.String]
        $HttpsIPAddress = '0.0.0.0',

        [Parameter()]
        [System.Int32]
        $HttpsPort = 443,

        [Parameter()]
        [System.Boolean]
        $UseSsl,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart,

        [Parameter()]
        [System.String]
        $EncryptionKeyBackupPath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $EncryptionKeyBackupPathCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $EncryptionKeyBackupCredential
    )

    $defaultInstanceNames = @(
        'MSSQLSERVER'
        'PBIRS'
        'SSRS'
    )

    Import-SQLPSModule

    $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName

    if ( $null -ne $reportingServicesData.Configuration )
    {
        $restartReportingService = $false
        $executeDatabaseRightsScript = $false

        $getTargetResourceParameters = @{
            InstanceName         = $InstanceName
            DatabaseServerName   = $DatabaseServerName
            DatabaseInstanceName = $DatabaseInstanceName
        }

        $currentConfig = Get-TargetResource @getTargetResourceParameters

        #region Get Operating System Information
        try
        {
            $wmiOperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Namespace 'root/cimv2' -ErrorAction Stop
        }
        catch
        {
            New-ObjectNotFoundException -Message ( $script:localizedData.GetOperatingSystemClassError ) -ErrorRecord $_
        }

        $language = $wmiOperatingSystem.OSLanguage
        #endregion Get Operating System Information

        #region Backup Encryption Key
        Write-Verbose -Message ( $script:localizedData.ReportingServicesIsIntialized -f $DatabaseServerName, $DatabaseInstanceName ) -Verbose
        if ( $currentConfig.IsInitialized )
        {
            if ( -not $PSBoundParameters.ContainsKey('EncryptionKeyBackupCredential') )
            {
                Write-Verbose -Message $script:localizedData.EncryptionKeyBackupCredentialNotSpecified -Verbose

                $characterSet = ( @(33..126) | Foreach-Object -Process { [System.Char][System.Byte]$_ } )
                $encryptionKeyBackupPassword = [System.Security.SecureString]::new()
                for ( $loop=1; $loop -le 16; $loop++ )
                {
                    $encryptionKeyBackupPassword.InsertAt(($loop - 1), ($CharacterSet | Get-Random))
                }

                $EncryptionKeyBackupCredential = [System.Management.Automation.PSCredential]::new('BackupUser', $encryptionKeyBackupPassword)
            }
            Write-Verbose -Message ( $script:localizedData.EncryptionKeyBackupCredentialUserName -f $EncryptionKeyBackupCredential.UserName ) -Verbose

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'BackupEncryptionKey'
                Arguments   = @{
                    Password = $EncryptionKeyBackupCredential.GetNetworkCredential().Password
                }
            }
            $backupEncryptionKeyResult = Invoke-RsCimMethod @invokeRsCimMethodParameters

            if ( $PSBoundParameters.ContainsKey('EncryptionKeyBackupPath') )
            {
                $EncryptionKeyBackupPath = [Environment]::ExpandEnvironmentVariables($EncryptionKeyBackupPath)

                $encryptionKeyBackupPathIsUnc = $false
                if ( $EncryptionKeyBackupPath -match '^\\\\')
                {
                    $encryptionKeyBackupPathIsUnc = $true
                }

                if ( $encryptionKeyBackupPathIsUnc -and $PSBoundParameters.ContainsKey('EncryptionKeyBackupPathCredential') )
                {
                    Connect-UncPath -RemotePath $EncryptionKeyBackupPath -SourceCredential $EncryptionKeyBackupPathCredential
                }

                if ( -not ( Test-Path -Path $EncryptionKeyBackupPath ) )
                {
                    New-Item -Path $EncryptionKeyBackupPath -ItemType Directory
                }

                $encryptionKeyBackupFileName = "$($env:ComputerName)-$($currentConfig.InstanceName).snk"
                $encryptionKeyBackupFile = Join-Path -Path $EncryptionKeyBackupPath -ChildPath $encryptionKeyBackupFileName
                Write-Verbose -Message ($script:localizedData.BackupEncryptionKey -f $encryptionKeyBackupFile) -Verbose

                $setContentParameters = @{
                    Path = $encryptionKeyBackupFile
                    Value = $backupEncryptionKeyResult.KeyFile
                }

                if ( $PSVersionTable.PSVersion.Major -gt 5 )
                {
                    $setContentParameters.AsByteStream = $true
                }
                else
                {
                    $setContentParameters.Encoding = 'Byte'
                }

                Set-Content @setContentParameters

                if ( $encryptionKeyBackupPathIsUnc -and $PSBoundParameters.ContainsKey('EncryptionKeyBackupCredential') )
                {
                    Disconnect-UncPath -RemotePath $EncryptionKeyBackupPath
                }
            }
        }
        #endregion Backup Encryption Key

        #region Set the service account
        $setServiceAccount = $false

        if ( $PSBoundParameters.ContainsKey('ServiceAccount') -and ( $ServiceAccount.UserName -ne $currentConfig.ServiceAccountName) )
        {
            $setServiceAccount = $true

            $invokeRsCimMethodSetWindowsServiceIdentityParameterArguments = @{
                Account           = $ServiceAccount.UserName
                Password          = $ServiceAccount.GetNetworkCredential().Password
                UseBuiltInAccount = $false
            }
        }
        else
        {
            $getLocalServiceAccountNameParameters = @{
                LocalServiceAccountType = $LocalServiceAccountType
                ServiceName = $currentConfig.ServiceName
            }
            $localServiceAccountName = Get-LocalServiceAccountName @getLocalServiceAccountNameParameters

            if ( $localServiceAccountName -ne $currentConfig.ServiceAccountName )
            {
                $setServiceAccount = $true

                # SQL 2017+ cannot use NT AUTHORITY\SYSTEM or NT AUTHORITY\LocalService as the service account
                if ( $reportingServicesData.SqlVersion -ge 14 -and $LocalServiceAccountType -in @('LocalService', 'System') )
                {
                    $localServiceAccountUnsupportedException = $script:localizedData.LocalServiceAccountUnsupportedException -f $LocalServiceAccountType, $reportingServicesData.SqlVersion
                    New-InvalidArgumentException -Message $localServiceAccountUnsupportedException -ArgumentName $LocalServiceAccountType
                }

                $invokeRsCimMethodSetWindowsServiceIdentityParameterArguments = @{
                    Account           = $localServiceAccountName
                    Password          = ''
                    UseBuiltInAccount = $false
                }
            }
        }

        if ( $setServiceAccount )
        {
            Write-Verbose -Message (
                $script:localizedData.SetServiceAccount -f @(
                    $invokeRsCimMethodSetWindowsServiceIdentityParameterArguments.Account
                    $currentConfig.ServiceAccountName
                )
            ) -Verbose

            $invokeRsCimMethodSetWindowsServiceIdentityParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'SetWindowsServiceIdentity'
                Arguments   = $invokeRsCimMethodSetWindowsServiceIdentityParameterArguments
            }

            Invoke-RsCimMethod @invokeRsCimMethodSetWindowsServiceIdentityParameters > $null

            $restartReportingService = $true
            $executeDatabaseRightsScript = $true

            # Get the current configuration since it changed the reserved URLs
            $currentConfig = Get-TargetResource @getTargetResourceParameters
            Write-Verbose -Message ( $script:localizedData.ReportingServicesIsIntialized -f $DatabaseServerName, $DatabaseInstanceName ) -Verbose
        }
        #endregion Set the service account

        #region Database
        if ( $DatabaseInstanceName -eq 'MSSQLSERVER' )
        {
            $reportingServicesConnection = $DatabaseServerName
        }
        else
        {
            $reportingServicesConnection = "$DatabaseServerName\$DatabaseInstanceName"
        }

        # Generate the database creation script
        if ( $currentConfig.DatabaseName -ne $DatabaseName )
        {
            Write-Verbose -Message ( $script:localizedData.TestDatabaseName -f $currentConfig.DatabaseName, $DatabaseName ) -Verbose
            Write-Verbose -Message ( $script:localizedData.GenerateDatabaseCreateScript -f @(
                $DatabaseServerName
                $DatabaseInstanceName
                $DatabaseName
            )) -Verbose

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'GenerateDatabaseCreationScript'
                Arguments   = @{
                    DatabaseName     = $DatabaseName
                    IsSharePointMode = $false
                    Lcid             = $language
                }
            }

            $reportingServicesDatabaseScript = Invoke-RsCimMethod @invokeRsCimMethodParameters
            Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseScript.Script
        }

        # Generate the database rights script
        if (
            $executeDatabaseRightsScript -or
            $currentConfig.DatabaseName -ne $DatabaseName -or
            $currentConfig.DatabaseServerName -ne $DatabaseServerName -or
            $currentConfig.DatabaseInstanceName -ne $DatabaseInstanceName
        )
        {
            Write-Verbose -Message ( $script:localizedData.GenerateDatabaseRightsScript -f @(
                $DatabaseServerName
                $DatabaseInstanceName
                $DatabaseName
            )) -Verbose

            #region Determine if the database is local or remote

            # Get the local computer properties
            $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -Namespace 'root/cimv2'

            # Define an array of hostnames and IP addresses which identify the local computer
            $localServerIdentifiers = @(
                '.'
                '(local)'
                'LOCAL'
                'localhost'
                $computerSystem.DNSHostName
                "$($computerSystem.DNSHostName).$($computerSystem.Domain)"
            ) + ( Get-NetIPAddress | Select-Object -ExpandProperty IPAddress )

            $localServerIdentifiersRegex = $localServerIdentifiers | Foreach-Object -Process { [System.Text.RegularExpressions.Regex]::Escape($_) }
            $databaseServerIsRemote = $DatabaseServerName -notmatch "^$( $localServerIdentifiersRegex -join '|' )$"
            Write-Verbose -Message ( $script:localizedData.DatabaseServerIsRemote -f $DatabaseServerName, $databaseServerIsRemote ) -Verbose
            #endregion Determine if the database is local or remote

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'GenerateDatabaseRightsScript'
                Arguments   = @{
                    DatabaseName  = $DatabaseName
                    UserName      = $currentConfig.ServiceAccountName
                    IsRemote      = $databaseServerIsRemote
                    IsWindowsUser = $true
                }
            }

            $reportingServicesDatabaseRightsScript = Invoke-RsCimMethod @invokeRsCimMethodParameters
            Invoke-Sqlcmd -ServerInstance $reportingServicesConnection -Query $reportingServicesDatabaseRightsScript.Script
        }

        # Set the database connection
        if (
            $currentConfig.DatabaseName -ne $DatabaseName -or
            $currentConfig.DatabaseServerName -ne $DatabaseServerName -or
            $currentConfig.DatabaseInstanceName -ne $DatabaseInstanceName
        )
        {
            Write-Verbose -Message ( $script:localizedData.SetDatabaseConnection -f @(
                $DatabaseServerName
                $DatabaseInstanceName
                $DatabaseName
            )) -Verbose

            $invokeRsCimMethodParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'SetDatabaseConnection'
                Arguments   = @{
                    Server          = $reportingServicesConnection
                    DatabaseName    = $DatabaseName
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

            # Get the current configuration since the database connection was updated
            $currentConfig = Get-TargetResource @getTargetResourceParameters
            Write-Verbose -Message ( $script:localizedData.ReportingServicesIsIntialized -f $DatabaseServerName, $DatabaseInstanceName ) -Verbose
        }

        #endregion Database

        #region Virtual Directories
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

        if ( [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) -and $InstanceName -notin $defaultInstanceNames )
        {
            $ReportServerVirtualDirectory = "ReportServer_$InstanceName"
        }
        elseif ( [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) )
        {
            $ReportServerVirtualDirectory = 'ReportServer'
        }

        if ( [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) -and $InstanceName -notin $defaultInstanceNames )
        {
            $ReportsVirtualDirectory = "Reports_$InstanceName"
        }
        elseif ( [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) )
        {
            $ReportsVirtualDirectory = 'Reports'
        }

        if ( -not [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory) )
        {
            Write-Verbose -Message (
                $script:localizedData.SetReportServerVirtualDirectory -f @(
                    $DatabaseServerName
                    $DatabaseInstanceName
                    $ReportServerVirtualDirectory
                )
            ) -Verbose

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

            # Get the current configuration since it changed the virtual directories
            $currentConfig = Get-TargetResource @getTargetResourceParameters
            Write-Verbose -Message ( $script:localizedData.ReportingServicesIsIntialized -f $DatabaseServerName, $DatabaseInstanceName ) -Verbose
        }

        if ( -not [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory) )
        {
            Write-Verbose -Message (
                $script:localizedData.SetReportsVirtualDirectory -f @(
                    $DatabaseServerName
                    $DatabaseInstanceName
                    $ReportServerVirtualDirectory
                )
            ) -Verbose

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

            # Get the current configuration since it changed the virtual directories
            $currentConfig = Get-TargetResource @getTargetResourceParameters
            Write-Verbose -Message ( $script:localizedData.ReportingServicesIsIntialized -f $DatabaseServerName, $DatabaseInstanceName ) -Verbose
        }
        #endregion Virtual Directories

        #region Reserved URLs
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
                Write-Verbose -Message (
                    $script:localizedData.AddReportsUrlReservation -f @(
                        $DatabaseServerName
                        $DatabaseInstanceName
                        $_
                    )
                )

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
        #endregion Reserved URLs

        #region SSL Certificate Bindings
        $invokeRsCimMethodListSSLCertificateBindingsParameters = @{
            CimInstance = $reportingServicesData.Configuration
            MethodName  = 'ListSSLCertificateBindings'
            Arguments = @{
                LCID = $language
            }
        }
        $sslCertificateBindings = Invoke-RsCimMethod @invokeRsCimMethodListSSLCertificateBindingsParameters

        # Create a PSObject of the binding information to make it easier to work with
        $sslCertificateBindingObjects = @()
        for ( $i = 0; $i -lt $sslCertificateBindings.Application.Count; $i++ )
        {
            $sslCertificateBindingObjects += [PSCustomObject] @{
                Application = $sslCertificateBindings.Application[$i]
                CertificateHash = $sslCertificateBindings.CertificateHash[$i]
                IPAddress = $sslCertificateBindings.IPAddress[$i]
                Port = $sslCertificateBindings.Port[$i]
            }
        }

        if ( $sslCertificateBindingObjects.Count -gt 1 )
        {
            # Get the bindings to remove
            $sslCertificateBindingsToRemove = $sslCertificateBindingObjects | Where-Object -FilterScript {
                $_.CertificateHash -ne $HttpsCertificateThumbprint -or
                $_.IPAddress -ne $HttpsIPAddress -or
                $_.Port -ne $HttpsPort
            }

            $invokeRsCimMethodRemoveSSLCertificateBindingsParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'RemoveSSLCertificateBindings'
                Arguments = $null
            }

            foreach ( $sslCertificateBindingToRemove in $sslCertificateBindingsToRemove )
            {
                $invokeRsCimMethodRemoveSSLCertificateBindingsParameterArguments = @{
                    Application = $sslCertificateBindingToRemove.Application
                    CertificateHash = $sslCertificateBindingToRemove.CertificateHash
                    IPAddress = $sslCertificateBindingToRemove.IPAddress
                    Port = $sslCertificateBindingToRemove.Port
                    lcid = $language
                }
                $invokeRsCimMethodRemoveSSLCertificateBindingsParameters.Arguments = $invokeRsCimMethodRemoveSSLCertificateBindingsParameterArguments

                $removeSslCertficateBindingResult = Invoke-RsCimMethod @invokeRsCimMethodRemoveSSLCertificateBindingsParameters

                if ( $removeSslCertficateBindingResult.HRESULT -ne 0 )
                {
                    $removeSslCertficateBindingErrorArguments = @(
                        $invokeRsCimMethodRemoveSSLCertificateBindingsParameterArguments.Application
                        $invokeRsCimMethodRemoveSSLCertificateBindingsParameterArguments.CertificateHash
                        $invokeRsCimMethodRemoveSSLCertificateBindingsParameterArguments.IPAddress
                        $invokeRsCimMethodRemoveSSLCertificateBindingsParameterArguments.Port
                    )
                    New-InvalidResultException -Message ( $script:localizedData.RemoveSslCertficateBindingError -f $removeSslCertficateBindingErrorArguments ) -ErrorRecord $removeSslCertficateBindingResult.Error
                }
            }
        }

        if ( $PSBoundParameters.ContainsKey('HttpsCertificateThumbprint') )
        {
            $applicationNames = @(
                'ReportServerWebApp'
                'ReportServerWebService'

                # I thought I saw other app names being used, but I can't seem to find them
                #'PowerBIWebApp'
                #'OfficeWebApp'
            )

            $invokeRsCimMethodCreateSSLCertificateBindingParameters = @{
                CimInstance = $reportingServicesData.Configuration
                MethodName  = 'CreateSSLCertificateBinding'
                Arguments = $null
            }

            foreach ( $applicationName in $applicationNames )
            {
                $sslCertificateBindingExists = $sslCertificateBindingObjects |
                    Where-Object -Property Application -EQ -Value $applicationName |
                    Where-Object -Property CertificateHash -EQ -Value $HttpsCertificateThumbprint |
                    Where-Object -Property IPAddress -EQ -Value $HttpsIPAddress |
                    Where-Object -Property Port -EQ -Value $HttpsPort

                if ( -not $sslCertificateBindingExists )
                {
                    $invokeRsCimMethodCreateSSLCertificateBindingParameterArguments = @{
                        Application = $applicationName
                        CertificateHash = $HttpsCertificateThumbprint.ToLower()
                        IPAddress = $HttpsIPAddress
                        Port = $HttpsPort
                        Lcid = $language
                    }
                    $invokeRsCimMethodCreateSSLCertificateBindingParameters.Arguments = $invokeRsCimMethodCreateSSLCertificateBindingParameterArguments

                    Invoke-RsCimMethod @invokeRsCimMethodCreateSSLCertificateBindingParameters > $null
                }
            }
        }
        #endregion SSL Certificate Bindings

        #region Initialize
        Write-Verbose -Message ( $script:localizedData.InitializeReportingServices -f $DatabaseServerName, $DatabaseInstanceName ) -Verbose

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

        Restart-ReportingServicesService -ServiceName $currentConfig.ServiceName -WaitTime 30

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
            Write-Verbose -Message (
                $script:localizedData.RestartDidNotHelp -f @(
                    $DatabaseServerName
                    $DatabaseInstanceName
                    $reportingServicesData.Configuration.InstallationID
                )
            )

            $restartReportingService = $true
            $restoreKey = $false
            $reportingServicesInitialized = $reportingServicesData.Configuration.IsInitialized

            do
            {
                if ( $restoreKey )
                {
                    Write-Verbose -Message ( $script:localizedData.EncryptionKeyBackupCredentialUserName -f $EncryptionKeyBackupCredential.UserName ) -Verbose

                    try
                    {
                        $EncryptionKeyBackupCredential.GetNetworkCredential()
                    }
                    catch
                    {
                        throw 'Failed getting the network credential.'
                    }

                    $invokeRsCimMethodRestoreEncryptionKeyParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'RestoreEncryptionKey'
                        Arguments   = @{
                            KeyFile = $backupEncryptionKeyResult.KeyFile
                            Length = $restoreEncryptionKeyResult.Length
                            Password = $EncryptionKeyBackupCredential.GetNetworkCredential().Password
                        }
                    }

                    $restoreEncryptionKeyResult = Invoke-RsCimMethod @invokeRsCimMethodRestoreEncryptionKeyParameters
                }

                try
                {
                    $invokeRsCimMethodInitializeReportServerParameters = @{
                        CimInstance = $reportingServicesData.Configuration
                        MethodName  = 'InitializeReportServer'
                        Arguments   = @{
                            InstallationId = $reportingServicesData.Configuration.InstallationID
                        }
                    }

                    $initializeReportServerResult = Invoke-RsCimMethod @invokeRsCimMethodInitializeReportServerParameters
                    $reportingServicesInitialized = $initializeReportServerResult.ReturnValue
                    Write-Verbose -Message "Reporting Services Initialized: $reportingServicesInitialized" -Verbose
                }
                catch [System.Management.Automation.RuntimeException]
                {
                    if ( $_.Exception -match 'The report server was unable to validate the integrity of encrypted data in the database' )
                    {
                        Write-Verbose -Message $_.Exception -Verbose

                        # Restore the encryption key before trying again
                        $restoreKey = $true
                    }
                    else
                    {
                        throw $_
                    }
                }
            }
            while ( -not $reportingServicesInitialized )

            # Refresh the reportingServicesData
            $reportingServicesData = Get-ReportingServicesData -InstanceName $InstanceName
        }
        else
        {
            Write-Verbose -Message ( $script:localizedData.ReportingServicesIsIntialized -f $DatabaseServerName, $DatabaseInstanceName ) -Verbose
            Write-Verbose -Message (
                $script:localizedData.ReportingServicesInitialized -f @(
                    $DatabaseServerName
                    $DatabaseInstanceName
                )
            )
        }
        #endregion Initialize

        #region Use SSL
        if ( $PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $currentConfig.UseSsl )
        {
            Write-Verbose -Message ( $script:localizedData.SetUseSsl -f $UseSsl ) -Verbose

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
        #endregion Use SSL

        #region Restart
        if ( $restartReportingService -and $SuppressRestart )
        {
            Write-Warning -Message $script:localizedData.SuppressRestart
        }
        elseif ( $restartReportingService -and (-not $SuppressRestart) )
        {
            Write-Verbose -Message $script:localizedData.Restart
            Restart-ReportingServicesService -ServiceName $currentConfig.ServiceName -WaitTime 30
        }
        #endregion Restart
    }

    if ( -not (Test-TargetResource @PSBoundParameters) )
    {
        $errorMessage = $script:localizedData.TestFailedAfterSet
        New-InvalidResultException -Message $errorMessage
    }
}

<#
    .SYNOPSIS
        Tests the SQL Server Reporting Services to determine if it is in the
        desired state.

    .PARAMETER InstanceName
        Name of the SQL Server Reporting Services instance to be configured.

    .PARAMETER DatabaseServerName
        Name of the SQL Server to host the Reporting Service database.

    .PARAMETER DatabaseInstanceName
        Name of the SQL Server instance to host the Reporting Service database.

    .PARAMETER DatabaseName
        Name of the the Reporting Services database. Default is "ReportServer".

    .PARAMETER LocalServiceAccountType
        Name of the local account which the service will run as. This is
        ignored if the _ServiceAccount_ parameter is supplied.. Default is
        "VirtualAccount".

    .PARAMETER ServiceAccount
        The service account that should be used when running the Windows
        service.

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

    .PARAMETER HttpsCertificateThumbprint
        The thumbprint of the certificate used to secure SSL communication.

    .PARAMETER HttpsIPAddress
        The IP address to bind the certificate specified in the
        CertificateThumbprint parameter to. Default is `0.0.0.0` which binds to
        all IP addresses.

    .PARAMETER HttpsPort
        The port used for SSL communication. Default is `443`.

    .PARAMETER UseSsl
        If connections to the Reporting Services must use SSL. If this
        parameter is not assigned a value, the default is that Reporting
        Services does not use SSL.

    .PARAMETER SuppressRestart
        Reporting Services need to be restarted after initialization or
        settings change. If this parameter is set to $true, Reporting Services
        will not be restarted, even after initialization.

    .PARAMETER EncryptionKeyBackupPath
        The path where the encryption key will be backed up to.

    .PARAMETER EncryptionKeyBackupPathCredential
        The credential which is used to access the path specified in
        "EncryptionKeyBackupPath".

    .PARAMETER EncryptionKeyBackupCredential
        The credential which should be used to backup the encryption key. If no
        credential is supplied, a randomized value will be generated for
        internal use during runtime.
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
        $DatabaseName = 'ReportServer',

        [Parameter()]
        [ValidateSet(
            'LocalService',
            'NetworkService',
            'System',
            'VirtualAccount'
        )]
        [System.String]
        $LocalServiceAccountType = 'VirtualAccount',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ServiceAccount,

        [Parameter()]
        [System.String]
        $ReportServerVirtualDirectory,

        [Parameter()]
        [System.String]
        $ReportsVirtualDirectory,

        [Parameter()]
        [System.String[]]
        $ReportServerReservedUrl = @('http://+:80'),

        [Parameter()]
        [System.String[]]
        $ReportsReservedUrl = @('http://+:80'),

        [Parameter()]
        [System.String]
        $HttpsCertificateThumbprint,

        [Parameter()]
        [System.String]
        $HttpsIPAddress = '0.0.0.0',

        [Parameter()]
        [System.Int32]
        $HttpsPort = 443,

        [Parameter()]
        [System.Boolean]
        $UseSsl,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart,

        [Parameter()]
        [System.String]
        $EncryptionKeyBackupPath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $EncryptionKeyBackupPathCredential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $EncryptionKeyBackupCredential
    )

    $result = $true

    $getTargetResourceParameters = @{
        InstanceName         = $InstanceName
        DatabaseServerName   = $DatabaseServerName
        DatabaseInstanceName = $DatabaseInstanceName
    }

    if ( $PSBoundParameters.ContainsKey('EncryptionKeyBackupPath') )
    {
        $getTargetResourceParameters.EncryptionKeyBackupPath = $EncryptionKeyBackupPath
    }

    if ( $PSBoundParameters.ContainsKey('EncryptionKeyBackupPathCredential') )
    {
        $getTargetResourceParameters.EncryptionKeyBackupPathCredential = $EncryptionKeyBackupPathCredential
    }

    $currentConfig = Get-TargetResource @getTargetResourceParameters

    if (-not $currentConfig.IsInitialized)
    {
        Write-Verbose -Message ( $script:localizedData.TestNotInitialized -f $DatabaseServerName, $DatabaseInstanceName ) -Verbose
        $result = $false
    }

    if ( $DatabaseName -ne $currentConfig.DatabaseName )
    {
        Write-Verbose -Message ( $script:localizedData.TestDatabaseName -f $currentConfig.DatabaseName, $DatabaseName ) -Verbose
        $result = $false
    }

    if (-not [System.String]::IsNullOrEmpty($ReportServerVirtualDirectory) -and ($ReportServerVirtualDirectory -ne $currentConfig.ReportServerVirtualDirectory))
    {
        Write-Verbose -Message (
            $script:localizedData.TestReportServerVirtualDirectory -f @(
                $DatabaseServerName
                $DatabaseInstanceName
                $currentConfig.ReportServerVirtualDir
                $ReportServerVirtualDirectory
            )
        ) -Verbose
        $result = $false
    }

    if (-not [System.String]::IsNullOrEmpty($ReportsVirtualDirectory) -and ($ReportsVirtualDirectory -ne $currentConfig.ReportsVirtualDirectory))
    {
        Write-Verbose -Message (
            $script:localizedData.TestReportsVirtualDirectory -f @(
                $DatabaseServerName
                $DatabaseInstanceName
                $currentConfig.ReportsVirtualDir
                $ReportsVirtualDirectory
            )
        ) -Verbose
        $result = $false
    }

    if ( $null -eq $currentConfig.ReportServerReservedUrl )
    {
         Write-Verbose -Message (
            $script:localizedData.ReportServerReservedUrlNotInDesiredState -f $DatabaseServerName, $DatabaseInstanceName, '', ( $ReportServerReservedUrl -join ', ' )
        ) -Verbose
        $result = $false
    }
    else
    {
        $compareParameters = @{
            ReferenceObject  = $currentConfig.ReportServerReservedUrl
            DifferenceObject = $ReportServerReservedUrl
        }

        if ( $null -ne ( Compare-Object @compareParameters ) )
        {
            Write-Verbose -Message (
                $script:localizedData.ReportServerReservedUrlNotInDesiredState -f $DatabaseServerName, $DatabaseInstanceName, $($currentConfig.ReportServerReservedUrl -join ', '), ( $ReportServerReservedUrl -join ', ' )
            ) -Verbose
            $result = $false
        }
    }

    if ( $null -eq $currentConfig.ReportsReservedUrl )
    {
        Write-Verbose -Message (
            $script:localizedData.ReportsReservedUrlNotInDesiredState -f $DatabaseServerName, $DatabaseInstanceName, '', ( $ReportsReservedUrl -join ', ' )
        ) -Verbose
        $result = $false
    }
    else
    {
        $compareParameters = @{
            ReferenceObject  = $currentConfig.ReportsReservedUrl
            DifferenceObject = $ReportsReservedUrl
        }

        if ( $null -ne ( Compare-Object @compareParameters ) )
        {
            Write-Verbose -Message (
                $script:localizedData.ReportsReservedUrlNotInDesiredState -f $DatabaseServerName, $DatabaseInstanceName, ( $currentConfig.ReportsReservedUrl -join ', ' ), ( $ReportsReservedUrl -join ', ' )
            ) -Verbose
            $result = $false
        }
    }

    if ($PSBoundParameters.ContainsKey('UseSsl') -and $UseSsl -ne $currentConfig.UseSsl)
    {
        Write-Verbose -Message (
            $script:localizedData.TestUseSsl -f @(
                $UseSsl
                $currentConfig.UseSsl
            )
        ) -Verbose
        $result = $false
    }

    if ( $PSBoundParameters.ContainsKey('ServiceAccount') )
    {
        if ( $ServiceAccount.UserName -ne $currentConfig.ServiceAccountName )
        {
            Write-Verbose -Message (
                $script:localizedData.TestServiceAccount -f @(
                    $ServiceAccount.UserName
                    $currentConfig.ServiceAccountName
                )
            ) -Verbose
            $result = $false
        }
    }
    else
    {
        $getLocalServiceAccountNameParameters = @{
            LocalServiceAccountType = $LocalServiceAccountType
            ServiceName = $currentConfig.ServiceName
        }
        $localServiceAccountName = Get-LocalServiceAccountName @getLocalServiceAccountNameParameters

        if ( $localServiceAccountName -ne $currentConfig.ServiceAccountName )
        {
            Write-Verbose -Message (
                $script:localizedData.TestServiceAccount -f @(
                    $localServiceAccountName
                    $currentConfig.ServiceAccountName
                )
            ) -Verbose
            $result = $false
        }
    }

    if ( $PSBoundParameters.ContainsKey('EncryptionKeyBackupPath') -and [System.String]::IsNullOrEmpty($currentConfig.EncryptionKeyBackupFile) )
    {
        $result = $false
    }

    if ( $PSBoundParameters.ContainsKey('HttpsCertificateThumbprint') -and $HttpsCertificateThumbprint -ne $currentConfig.HttpsCertificateThumbprint )
    {
        Write-Verbose -Message ( $script:localizedData.HttpsCertificateThumbprintNotInDesiredState -f ( $currentConfig.HttpsCertificateThumbprint -join ', ' ), $HttpsCertificateThumbprint ) -Verbose
        $result = $false
    }

    if ( $PSBoundParameters.ContainsKey('HttpsCertificateThumbprint') -and $HttpsIPAddress -ne $currentConfig.HttpsIPAddress )
    {
        Write-Verbose -Message ( $script:localizedData.HttpsIPAddressNotInDesiredState -f ( $currentConfig.HttpsIPAddress -join ', ' ), $HttpsIPAddress ) -Verbose
        $result = $false
    }

    if ( $PSBoundParameters.ContainsKey('HttpsCertificateThumbprint') -and $HttpsPort -ne $currentConfig.HttpsPort )
    {
        Write-Verbose -Message ( $script:localizedData.HttpsPortNotInDesiredState -f ( $currentConfig.HttpsPort -join ', '), $HttpsPort ) -Verbose
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
            # Get the SQL Server 2017+ SSRS and PBIRS version
            $sqlVersion = [System.Int32] ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\CurrentVersion" -Name 'CurrentVersion').CurrentVersion).Split('.')[0]
        }
        else
        {
            # Get the SQL Server 2016 and older version
            $sqlVersion = [System.Int32] ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instanceId\Setup" -Name 'Version').Version).Split('.')[0]
        }

        $reportingServicesConfiguration = Get-CimInstance -ClassName MSReportServer_ConfigurationSetting -Namespace "root\Microsoft\SQLServer\ReportServer\RS_$InstanceName\v$sqlVersion\Admin" |
            Where-Object -Property InstanceName -EQ -Value $InstanceName

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

    return @{
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
        The arguments that should be supplied to the CIM Method.
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

        throw (
            $script:localizedData.InvokeRsCimMethodError -f @(
                $MethodName
                $errorMessage
                $invokeCimMethodResult.HRESULT
            )
        )
    }

    return $invokeCimMethodResult
}

<#
    .SYNOPSIS
        Convert the local service account type to a local service account name.

    .PARAMETER LocalServiceAccountType
        The type name of the local service account.

    .PARAMETER ServiceName
        The name of the service that is running reporting services.
#>
function Get-LocalServiceAccountName
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'LocalService',
            'NetworkService',
            'System',
            'VirtualAccount'
        )]
        [System.String]
        $LocalServiceAccountType,

        [Parameter()]
        [System.String]
        $ServiceName
    )

    if ( $LocalServiceAccountType -eq 'VirtualAccount' -and [System.String]::IsNullOrEmpty($ServiceName) )
    {
        $newInvalidArgumentException = @{
            Message = $script:localizedData.GetLocalServiceAccountNameServiceNotSpecified -f $LocalServiceAccountType
            ArgumentName = 'ServiceName'
        }
        New-InvalidArgumentException @newInvalidArgumentException
    }

    $serviceAccountLookupTable = @{
        LocalService = 'NT AUTHORITY\LocalService'
        NetworkService = 'NT AUTHORITY\NetworkService'
        System = 'NT AUTHORITY\System'
        VirtualAccount = "NT SERVICE\$ServiceName"
    }

    $localServiceAccountName = $serviceAccountLookupTable.$LocalServiceAccountType
    Write-Verbose -Message ( $script:localizedData.GetLocalServiceAccountName -f $localServiceAccountName, $LocalServiceAccountType ) -Verbose
    return $localServiceAccountName
}
