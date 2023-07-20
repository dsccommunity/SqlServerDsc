$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Returns the value of the provided Name parameter at the registry
        location provided in the Path parameter.

    .PARAMETER Path
        Specifies the path in the registry to the property name.

    .PARAMETER PropertyName
        Specifies the the name of the property to return the value for.
#>
function Get-RegistryPropertyValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $getItemPropertyParameters = @{
        Path = $Path
        Name = $Name
    }

    <#
        Using a try/catch block instead of 'SilentlyContinue' to be
        able to unit test a failing registry path.
    #>
    try
    {
        $getItemPropertyResult = (Get-ItemProperty @getItemPropertyParameters -ErrorAction 'Stop').$Name
    }
    catch
    {
        $getItemPropertyResult = $null
    }

    return $getItemPropertyResult
}

<#
    .SYNOPSIS
        Returns the value of the provided in the Name parameter, at the registry
        location provided in the Path parameter.

    .PARAMETER Path
        String containing the path in the registry to the property name.

    .PARAMETER PropertyName
        String containing the name of the property for which the value is returned.
#>
function Format-Path
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $TrailingSlash
    )

    # Remove trailing slash ('\') from path.
    if ($TrailingSlash.IsPresent)
    {
        <#
            Trim backslash, but only if the path contains a full path and
            not just a qualifier.
        #>
        if ($Path -notmatch '^[a-zA-Z]:\\$')
        {
            $Path = $Path.TrimEnd('\')
        }

        <#
            If the path only contains a qualifier but no backslash ('M:'),
            then a backslash is added ('M:\').
        #>
        if ($Path -match '^[a-zA-Z]:$')
        {
            $Path = '{0}\' -f $Path
        }
    }

    return $Path
}

<#
    .SYNOPSIS
        Copy folder structure using Robocopy. Every file and folder, including empty ones are copied.

    .PARAMETER Path
        Source path to be copied.

    .PARAMETER DestinationPath
        The path to the destination.
#>
function Copy-ItemWithRobocopy
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DestinationPath
    )

    $quotedPath = '"{0}"' -f $Path
    $quotedDestinationPath = '"{0}"' -f $DestinationPath
    $robocopyExecutable = Get-Command -Name "Robocopy.exe" -ErrorAction Stop

    $robocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
    $robocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
    $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'

    if ([System.Version]$robocopyExecutable.FileVersionInfo.ProductVersion -ge [System.Version]'6.3.9600.16384')
    {
        Write-Verbose -Message $script:localizedData.RobocopyUsingUnbufferedIo -Verbose

        $robocopyArgumentUseUnbufferedIO = '/J'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.RobocopyNotUsingUnbufferedIo -Verbose
    }

    $robocopyArgumentList = '{0} {1} {2} {3} {4} {5}' -f @(
        $quotedPath,
        $quotedDestinationPath,
        $robocopyArgumentCopySubDirectoriesIncludingEmpty,
        $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
        $robocopyArgumentUseUnbufferedIO,
        $robocopyArgumentSilent
    )

    $robocopyStartProcessParameters = @{
        FilePath     = $robocopyExecutable.Name
        ArgumentList = $robocopyArgumentList
    }

    Write-Verbose -Message ($script:localizedData.RobocopyArguments -f $robocopyArgumentList) -Verbose
    $robocopyProcess = Start-Process @robocopyStartProcessParameters -Wait -NoNewWindow -PassThru

    switch ($($robocopyProcess.ExitCode))
    {
        { $_ -in 8, 16 }
        {
            $errorMessage = $script:localizedData.RobocopyErrorCopying -f $_
            New-InvalidOperationException -Message $errorMessage
        }

        { $_ -gt 7 }
        {
            $errorMessage = $script:localizedData.RobocopyFailuresCopying -f $_
            New-InvalidResultException -Message $errorMessage
        }

        1
        {
            Write-Verbose -Message $script:localizedData.RobocopySuccessful -Verbose
        }

        2
        {
            Write-Verbose -Message $script:localizedData.RobocopyRemovedExtraFilesAtDestination -Verbose
        }

        3
        {
            Write-Verbose -Message (
                '{0} {1}' -f $script:localizedData.RobocopySuccessful, $script:localizedData.RobocopyRemovedExtraFilesAtDestination
            ) -Verbose
        }

        { $_ -eq 0 -or $null -eq $_ }
        {
            Write-Verbose -Message $script:localizedData.RobocopyAllFilesPresent -Verbose
        }
    }
}

<#
    .SYNOPSIS
        Connects to the source using the provided credentials and then uses
        robocopy to download the installation media to a local temporary folder.

    .PARAMETER SourcePath
        Source path to be copied.

    .PARAMETER SourceCredential
        The credentials to access the SourcePath.

    .PARAMETER PassThru
        If used, returns the destination path as string.

    .OUTPUTS
        Returns the destination path (when used with the parameter PassThru).
#>
function Invoke-InstallationMediaCopy
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourcePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    Connect-UncPath -RemotePath $SourcePath -SourceCredential $SourceCredential

    $SourcePath = $SourcePath.TrimEnd('/\')
    <#
        Create a destination folder so the media files aren't written
        to the root of the Temp folder.
    #>
    $serverName, $shareName, $leafs = ($SourcePath -replace '\\\\') -split '\\'
    if ($leafs)
    {
        $mediaDestinationFolder = $leafs | Select-Object -Last 1
    }
    else
    {
        $mediaDestinationFolder = New-Guid | Select-Object -ExpandProperty Guid
    }

    $mediaDestinationPath = Join-Path -Path (Get-TemporaryFolder) -ChildPath $mediaDestinationFolder

    Write-Verbose -Message ($script:localizedData.RobocopyIsCopying -f $SourcePath, $mediaDestinationPath) -Verbose
    Copy-ItemWithRobocopy -Path $SourcePath -DestinationPath $mediaDestinationPath

    Disconnect-UncPath -RemotePath $SourcePath

    if ($PassThru.IsPresent)
    {
        return $mediaDestinationPath
    }
}

<#
    .SYNOPSIS
        Connects to the UNC path provided in the parameter SourcePath.
        Optionally connects using the provided credentials.

    .PARAMETER SourcePath
        Source path to connect to.

    .PARAMETER SourceCredential
        The credentials to access the path provided in SourcePath.

    .PARAMETER PassThru
        If used, returns a MSFT_SmbMapping object that represents the newly
        created SMB mapping.

    .OUTPUTS
        Returns a MSFT_SmbMapping object that represents the newly created
        SMB mapping (ony when used with parameter PassThru).
#>
function Connect-UncPath
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemotePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    $newSmbMappingParameters = @{
        RemotePath = $RemotePath
    }

    if ($PSBoundParameters.ContainsKey('SourceCredential'))
    {
        $newSmbMappingParameters['UserName'] = $SourceCredential.UserName
        $newSmbMappingParameters['Password'] = $SourceCredential.GetNetworkCredential().Password
    }

    $newSmbMappingResult = New-SmbMapping @newSmbMappingParameters

    if ($PassThru.IsPresent)
    {
        return $newSmbMappingResult
    }
}

<#
    .SYNOPSIS
        Disconnects from the UNC path provided in the parameter SourcePath.

    .PARAMETER SourcePath
        Source path to disconnect from.
#>
function Disconnect-UncPath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemotePath
    )

    Remove-SmbMapping -RemotePath $RemotePath -Force
}

<#
    .SYNOPSIS
        Queries the registry and returns $true if there is a pending reboot.

    .OUTPUTS
        Returns $true if there is a pending reboot, otherwise it returns $false.
#>
function Test-PendingRestart
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
    )

    $getRegistryPropertyValueParameters = @{
        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        Name = 'PendingFileRenameOperations'
    }

    <#
        If the key 'PendingFileRenameOperations' does not exist then if should
        return $false, otherwise it should return $true.
    #>
    return $null -ne (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
}

<#
    .SYNOPSIS
        Starts the SQL setup process.

    .PARAMETER FilePath
        String containing the path to setup.exe.

    .PARAMETER ArgumentList
        The arguments that should be passed to setup.exe.

    .PARAMETER Timeout
        The timeout in seconds to wait for the process to finish.
#>
function Start-SqlSetupProcess
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter()]
        [System.String]
        $ArgumentList,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Timeout
    )

    $startProcessParameters = @{
        FilePath     = $FilePath
        ArgumentList = $ArgumentList
    }

    $sqlSetupProcess = Start-Process @startProcessParameters -PassThru -NoNewWindow -ErrorAction Stop

    Write-Verbose -Message ($script:localizedData.StartSetupProcess -f $sqlSetupProcess.Id, $startProcessParameters.FilePath, $Timeout) -Verbose

    Wait-Process -InputObject $sqlSetupProcess -Timeout $Timeout -ErrorAction Stop

    return $sqlSetupProcess.ExitCode
}

<#
    .SYNOPSIS
        Connect to a SQL Server Database Engine and return the server object.

    .PARAMETER ServerName
        String containing the host name of the SQL Server to connect to.
        Default value is the current computer name.

    .PARAMETER InstanceName
        String containing the SQL Server Database Engine instance to connect to.
        Default value is 'MSSQLSERVER'.

    .PARAMETER SetupCredential
        The credentials to use to impersonate a user when connecting to the
        SQL Server Database Engine instance. If this parameter is left out, then
        the current user will be used to connect to the SQL Server Database Engine
        instance using Windows Integrated authentication.

    .PARAMETER LoginType
        Specifies which type of logon credential should be used. The valid types
        are 'WindowsUser' or 'SqlLogin'. Default value is 'WindowsUser'
        If set to 'WindowsUser' then the it will impersonate using the Windows
        login specified in the parameter SetupCredential.
        If set to 'WindowsUser' then the it will impersonate using the native SQL
        login specified in the parameter SetupCredential.

    .PARAMETER StatementTimeout
        Set the query StatementTimeout in seconds. Default 600 seconds (10 minutes).

    .PARAMETER Encrypt
        Specifies if encryption should be used.

    .EXAMPLE
        Connect-SQL

        Connects to the default instance on the local server.

    .EXAMPLE
        Connect-SQL -InstanceName 'MyInstance'

        Connects to the instance 'MyInstance' on the local server.

    .EXAMPLE
        Connect-SQL ServerName 'sql.company.local' -InstanceName 'MyInstance' -ErrorAction 'Stop'

        Connects to the instance 'MyInstance' on the server 'sql.company.local'.
#>
function Connect-SQL
{
    [CmdletBinding(DefaultParameterSetName = 'SqlServer')]
    param
    (
        [Parameter(ParameterSetName = 'SqlServer')]
        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateNotNull()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter(ParameterSetName = 'SqlServer')]
        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateNotNull()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter(ParameterSetName = 'SqlServerWithCredential', Mandatory = $true)]
        [ValidateNotNull()]
        [Alias('SetupCredential', 'DatabaseCredential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = 'SqlServerWithCredential')]
        [ValidateSet('WindowsUser', 'SqlLogin')]
        [System.String]
        $LoginType = 'WindowsUser',

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Encrypt
    )

    Import-SqlDscPreferredModule

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $databaseEngineInstance = $ServerName
    }
    else
    {
        $databaseEngineInstance = '{0}\{1}' -f $ServerName, $InstanceName
    }

    $sqlServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
    $sqlConnectionContext = $sqlServerObject.ConnectionContext
    $sqlConnectionContext.ServerInstance = $databaseEngineInstance
    $sqlConnectionContext.StatementTimeout = $StatementTimeout
    $sqlConnectionContext.ConnectTimeout = $StatementTimeout
    $sqlConnectionContext.ApplicationName = 'SqlServerDsc'

    if ($Encrypt.IsPresent)
    {
        $sqlConnectionContext.EncryptConnection = $true
    }

    if ($PSCmdlet.ParameterSetName -eq 'SqlServer')
    {
        <#
            This is only used for verbose messaging and not for the connection
            string since this is using Integrated Security=true (SSPI).
        #>
        $connectUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        Write-Verbose -Message (
            $script:localizedData.ConnectingUsingIntegrated -f $connectUsername
        ) -Verbose
    }
    else
    {
        $connectUserName = $Credential.UserName

        Write-Verbose -Message (
            $script:localizedData.ConnectingUsingImpersonation -f $connectUsername, $LoginType
        ) -Verbose

        if ($LoginType -eq 'SqlLogin')
        {
            $sqlConnectionContext.LoginSecure = $false
            $sqlConnectionContext.Login = $connectUserName
            $sqlConnectionContext.SecurePassword = $Credential.Password
        }

        if ($LoginType -eq 'WindowsUser')
        {
            $sqlConnectionContext.LoginSecure = $true
            $sqlConnectionContext.ConnectAsUser = $true
            $sqlConnectionContext.ConnectAsUserName = $connectUserName
            $sqlConnectionContext.ConnectAsUserPassword = $Credential.GetNetworkCredential().Password
        }
    }

    try
    {
        $onlineStatus = 'Online'
        $connectTimer = [System.Diagnostics.StopWatch]::StartNew()
        $sqlConnectionContext.Connect()

        <#
            The addition of the ConnetTimeout property to the ConnectionContext will force the
            Connect() method to block until successful.  THe SMO object's Status property may not
            report 'Online' immediately eventhough the Connect() was successful.  The loop is to
            ensure the SMO's Status property was been updated.
        #>
        $sleepInSeconds = 2
        do
        {
            $instanceStatus = $sqlServerObject.Status
            if ([System.String]::IsNullOrEmpty($instanceStatus))
            {
                $instanceStatus = 'Unknown'
            }
            else
            {
                # Property Status is of type Enum ServerStatus, we return the string equivalent.
                $instanceStatus = $instanceStatus.ToString()
            }

            if ($instanceStatus -eq $onlineStatus)
            {
                break
            }

            Write-Debug -Message (
                $script:localizedData.WaitForDatabaseEngineInstanceStatus -f $instanceStatus, $onlineStatus, $sleepInSeconds
            )

            Start-Sleep -Seconds $sleepInSeconds
            $sqlServerObject.Refresh()
        } while ($connectTimer.Elapsed.TotalSeconds -lt $StatementTimeout)

        if ($instanceStatus -match '^Online$')
        {
            Write-Verbose -Message (
                $script:localizedData.ConnectedToDatabaseEngineInstance -f $databaseEngineInstance
            ) -Verbose

            return $sqlServerObject
        }
        else
        {
            $errorMessage = $script:localizedData.DatabaseEngineInstanceNotOnline -f @(
                $databaseEngineInstance,
                $instanceStatus
            )

            $invalidOperationException = New-Object -TypeName 'InvalidOperationException' -ArgumentList @($errorMessage)

            $newObjectParameters = @{
                TypeName     = 'System.Management.Automation.ErrorRecord'
                ArgumentList = @(
                    $invalidOperationException,
                    'CS0001',
                    'InvalidOperation',
                    $databaseEngineInstance
                )
            }

            $errorRecordToThrow = New-Object @newObjectParameters

            Write-Error -ErrorRecord $errorRecordToThrow
        }
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToConnectToDatabaseEngineInstance -f $databaseEngineInstance

        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' -ArgumentList @($errorMessage, $_.Exception)

        $newObjectParameters = @{
            TypeName     = 'System.Management.Automation.ErrorRecord'
            ArgumentList = @(
                $invalidOperationException,
                'CS0002',
                'InvalidOperation',
                $databaseEngineInstance
            )
        }

        $errorRecordToThrow = New-Object @newObjectParameters

        Write-Error -ErrorRecord $errorRecordToThrow
    }
    finally
    {
        $connectTimer.Stop()
        <#
            Connect will ensure we actually can connect, but we need to disconnect
            from the session so we don't have anything hanging. If we need run a
            method on the returned $sqlServerObject it will automatically open a
            new session and then close, therefore we don't need to keep this
            session open.
        #>
        $sqlConnectionContext.Disconnect()
    }
}

<#
    .SYNOPSIS
        Connect to a SQL Server Analysis Service and return the server object.

    .PARAMETER ServerName
        String containing the host name of the SQL Server to connect to.

    .PARAMETER InstanceName
        String containing the SQL Server Analysis Service instance to connect to.

    .PARAMETER SetupCredential
        PSCredential object with the credentials to use to impersonate a user when
        connecting. If this is not provided then the current user will be used to
        connect to the SQL Server Analysis Service instance.
#>
function Connect-SQLAnalysis
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName = (Get-ComputerName),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SetupCredential,

        [Parameter()]
        [System.String[]]
        $FeatureFlag
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $analysisServiceInstance = $ServerName
    }
    else
    {
        $analysisServiceInstance = "$ServerName\$InstanceName"
    }

    if ($SetupCredential)
    {
        $userName = $SetupCredential.UserName
        $password = $SetupCredential.GetNetworkCredential().Password

        $analysisServicesDataSource = "Data Source=$analysisServiceInstance;User ID=$userName;Password=$password"
    }
    else
    {
        $analysisServicesDataSource = "Data Source=$analysisServiceInstance"
    }

    try
    {
        if ((Test-FeatureFlag -FeatureFlag $FeatureFlag -TestFlag 'AnalysisServicesConnection'))
        {
            Import-SqlDscPreferredModule

            $analysisServicesObject = New-Object -TypeName 'Microsoft.AnalysisServices.Server'

            if ($analysisServicesObject)
            {
                $analysisServicesObject.Connect($analysisServicesDataSource)
            }

            if ((-not $analysisServicesObject) -or ($analysisServicesObject -and $analysisServicesObject.Connected -eq $false))
            {
                $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance

                New-InvalidOperationException -Message $errorMessage
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.ConnectedToAnalysisServicesInstance -f $analysisServiceInstance) -Verbose
            }
        }
        else
        {
            $null = Import-Assembly -Name 'Microsoft.AnalysisServices' -LoadWithPartialName

            $analysisServicesObject = New-Object -TypeName 'Microsoft.AnalysisServices.Server'

            if ($analysisServicesObject)
            {
                $analysisServicesObject.Connect($analysisServicesDataSource)
            }
            else
            {
                $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance

                New-InvalidOperationException -Message $errorMessage
            }

            Write-Verbose -Message ($script:localizedData.ConnectedToAnalysisServicesInstance -f $analysisServiceInstance) -Verbose
        }
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToConnectToAnalysisServicesInstance -f $analysisServiceInstance

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    return $analysisServicesObject
}

<#
    .SYNOPSIS
        Imports the assembly into the session.

    .DESCRIPTION
        Imports the assembly into the session and returns a reference to the
        assembly.

    .PARAMETER Name
        Specifies the name of the assembly to load.

    .PARAMETER LoadWithPartialName
        Specifies if the imported assembly should be the first found in GAC,
        regardless of version.

    .OUTPUTS
        [System.Reflection.Assembly]

        Returns a reference to the assembly object.

    .EXAMPLE
        Import-Assembly -Name "Microsoft.SqlServer.ConnectionInfo, Version=$SqlMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

    .EXAMPLE
        Import-Assembly -Name 'Microsoft.AnalysisServices' -LoadWithPartialName

    .NOTES
        This should normally work using Import-Module and New-Object instead of
        using the method [System.Reflection.Assembly]::Load(). But due to a
        missing assembly in the module SqlServer this is still needed.

        Import-Module SqlServer
        $connectionInfo = New-Object -TypeName 'Microsoft.SqlServer.Management.Common.ServerConnection' -ArgumentList @('testclu01a\SQL2014')
        # Missing assembly 'Microsoft.SqlServer.Rmo' in module SqlServer prevents this call from working.
        $replication = New-Object -TypeName 'Microsoft.SqlServer.Replication.ReplicationServer' -ArgumentList @($connectionInfo)
#>
function Import-Assembly
{
    [CmdletBinding()]
    [OutputType([System.Reflection.Assembly])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $LoadWithPartialName
    )

    try
    {
        if ($LoadWithPartialName.IsPresent)
        {
            $assemblyInformation = [System.Reflection.Assembly]::LoadWithPartialName($Name)
        }
        else
        {
            $assemblyInformation = [System.Reflection.Assembly]::Load($Name)
        }

        Write-Verbose -Message (
            $script:localizedData.LoadedAssembly -f $assemblyInformation.FullName
        )
    }
    catch
    {
        $errorMessage = $script:localizedData.FailedToLoadAssembly -f $Name

        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }

    return $assemblyInformation
}


<#
    .SYNOPSIS
        Returns the major SQL version for the specific instance.

    .PARAMETER InstanceName
        String containing the name of the SQL instance to be configured. Default
        value is 'MSSQLSERVER'.

    .OUTPUTS
        System.UInt16. Returns the SQL Server major version number.
#>
function Get-SqlInstanceMajorVersion
{
    [CmdletBinding()]
    [OutputType([System.UInt16])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName
    )

    $sqlInstanceId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$InstanceName
    $sqlVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$sqlInstanceId\Setup").Version

    if (-not $sqlVersion)
    {
        $errorMessage = $script:localizedData.SqlServerVersionIsInvalid -f $InstanceName
        New-InvalidResultException -Message $errorMessage
    }

    [System.UInt16] $sqlMajorVersionNumber = $sqlVersion.Split('.')[0]

    return $sqlMajorVersionNumber
}

<#
    .SYNOPSIS
        Restarts a SQL Server instance and associated services

    .PARAMETER ServerName
        Hostname of the SQL Server to be configured

    .PARAMETER InstanceName
        Name of the SQL instance to be configured. Default is 'MSSQLSERVER'

    .PARAMETER Timeout
        Timeout value for restarting the SQL services. The default value is 120 seconds.

    .PARAMETER SkipClusterCheck
        If cluster check should be skipped. If this is present no connection
        is made to the instance to check if the instance is on a cluster.

        This need to be used for some resource, for example for the SqlServerNetwork
        resource when it's used to enable a disable protocol.

    .PARAMETER SkipWaitForOnline
        If this is present no connection is made to the instance to check if the
        instance is online.

        This need to be used for some resource, for example for the SqlServerNetwork
        resource when it's used to disable protocol.

    .PARAMETER OwnerNode
        Specifies a list of owner nodes names of a cluster groups. If the SQL Server
        instance is a Failover Cluster instance then the cluster group will only
        be taken offline and back online when the owner of the cluster group is
        one of the nodes specified in this list. These node names specified in this
        parameter must match the Owner property of the cluster resource, for example
        @('sqltest10', 'SQLTEST11'). The names are case-insensitive.
        If this parameter is not specified the cluster group will be taken offline
        and back online regardless of owner.

    .EXAMPLE
        Restart-SqlService -ServerName localhost

    .EXAMPLE
        Restart-SqlService -ServerName localhost -InstanceName 'NamedInstance'

    .EXAMPLE
        Restart-SqlService -ServerName localhost -InstanceName 'NamedInstance' -SkipClusterCheck -SkipWaitForOnline

    .EXAMPLE
        Restart-SqlService -ServerName CLU01 -Timeout 300

    .EXAMPLE
        Restart-SqlService -ServerName CLU01 -Timeout 300 -OwnerNode 'testclu10'
#>
function Restart-SqlService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.UInt32]
        $Timeout = 120,

        [Parameter()]
        [Switch]
        $SkipClusterCheck,

        [Parameter()]
        [Switch]
        $SkipWaitForOnline,

        [Parameter()]
        [System.String[]]
        $OwnerNode
    )

    $restartWindowsService = $true

    # Check if a cluster, otherwise assume that a Windows service should be restarted.
    if (-not $SkipClusterCheck.IsPresent)
    {
        ## Connect to the instance
        $serverObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

        if ($serverObject.IsClustered)
        {
            # Make sure Windows service is not restarted outside of the cluster.
            $restartWindowsService = $false

            $restartSqlClusterServiceParameters = @{
                InstanceName = $serverObject.ServiceName
            }

            if ($PSBoundParameters.ContainsKey('Timeout'))
            {
                $restartSqlClusterServiceParameters['Timeout'] = $Timeout
            }

            if ($PSBoundParameters.ContainsKey('OwnerNode'))
            {
                $restartSqlClusterServiceParameters['OwnerNode'] = $OwnerNode
            }

            Restart-SqlClusterService @restartSqlClusterServiceParameters
        }
    }

    if ($restartWindowsService)
    {
        if ($InstanceName -eq 'MSSQLSERVER')
        {
            $serviceName = 'MSSQLSERVER'
        }
        else
        {
            $serviceName = 'MSSQL${0}' -f $InstanceName
        }

        Write-Verbose -Message ($script:localizedData.GetServiceInformation -f 'SQL Server') -Verbose

        $sqlService = Get-Service -Name $serviceName

        <#
            Get all dependent services that are running.
            There are scenarios where an automatic service is stopped and should not be restarted automatically.
        #>
        $agentService = $sqlService.DependentServices |
            Where-Object -FilterScript { $_.Status -eq 'Running' }

        # Restart the SQL Server service
        Write-Verbose -Message ($script:localizedData.RestartService -f 'SQL Server') -Verbose
        $sqlService |
            Restart-Service -Force

        # Start dependent services
        $agentService |
            ForEach-Object -Process {
                Write-Verbose -Message ($script:localizedData.StartingDependentService -f $_.DisplayName) -Verbose
                $_ | Start-Service
            }
    }

    Write-Verbose -Message ($script:localizedData.WaitingInstanceTimeout -f $ServerName, $InstanceName, $Timeout) -Verbose

    if (-not $SkipWaitForOnline.IsPresent)
    {
        $connectTimer = [System.Diagnostics.StopWatch]::StartNew()

        $connectSqlError = $null

        do
        {
            # This call, if it fails, will take between ~9-10 seconds to return.
            $testConnectionServerObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'SilentlyContinue' -ErrorVariable 'connectSqlError'

            # Make sure we have an SMO object to test Status
            if ($testConnectionServerObject)
            {
                if ($testConnectionServerObject.Status -eq 'Online')
                {
                    break
                }
            }

            # Waiting 2 seconds to not hammer the SQL Server instance.
            Start-Sleep -Seconds 2
        } until ($connectTimer.Elapsed.TotalSeconds -ge $Timeout)

        $connectTimer.Stop()

        # Was the timeout period reach before able to connect to the SQL Server instance?
        if (-not $testConnectionServerObject -or $testConnectionServerObject.Status -ne 'Online')
        {
            $errorMessage = $script:localizedData.FailedToConnectToInstanceTimeout -f @(
                $ServerName,
                $InstanceName,
                $Timeout
            )

            $newInvalidOperationExceptionParameters = @{
                Message = $errorMessage
            }

            if ($connectSqlError)
            {
                $newInvalidOperationExceptionParameters.ErrorRecord = $connectSqlError[$connectSqlError.Count - 1]
            }

            New-InvalidOperationException @newInvalidOperationExceptionParameters
        }
    }
}

<#
    .SYNOPSIS
        Restarts a SQL Server cluster instance and associated services

    .PARAMETER InstanceName
        Specifies the instance name that matches a SQL Server MSCluster_Resource
        property <clustergroup>.PrivateProperties.InstanceName.

    .PARAMETER Timeout
        Timeout value for restarting the SQL services. The default value is 120 seconds.

    .PARAMETER OwnerNode
        Specifies a list of owner nodes names of a cluster groups. If the SQL Server
        instance is a Failover Cluster instance then the cluster group will only
        be taken offline and back online when the owner of the cluster group is
        one of the nodes specified in this list. These node names specified in this
        parameter must match the Owner property of the cluster resource, for example
        @('sqltest10', 'SQLTEST11'). The names are case-insensitive.
        If this parameter is not specified the cluster group will be taken offline
        and back online regardless of owner.
#>
function Restart-SqlClusterService
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.UInt32]
        $Timeout = 120,

        [Parameter()]
        [System.String[]]
        $OwnerNode
    )

    # Get the cluster resources
    Write-Verbose -Message ($script:localizedData.GetSqlServerClusterResources) -Verbose

    $sqlService = Get-CimInstance -Namespace 'root/MSCluster' -ClassName 'MSCluster_Resource' -Filter "Type = 'SQL Server'" |
        Where-Object -FilterScript {
            $_.PrivateProperties.InstanceName -eq $InstanceName -and $_.State -eq 2
        }

    # If the cluster resource is found and online then continue.
    if ($sqlService)
    {
        $isOwnerOfClusterResource = $true

        if ($PSBoundParameters.ContainsKey('OwnerNode') -and $sqlService.OwnerNode -notin $OwnerNode)
        {
            $isOwnerOfClusterResource = $false
        }

        if ($isOwnerOfClusterResource)
        {
            Write-Verbose -Message ($script:localizedData.GetSqlAgentClusterResource) -Verbose

            $agentService = $sqlService |
                Get-CimAssociatedInstance -ResultClassName MSCluster_Resource |
                Where-Object -FilterScript {
                    $_.Type -eq 'SQL Server Agent' -and $_.State -eq 2
                }

            # Build a listing of resources being acted upon
            $resourceNames = @($sqlService.Name, ($agentService |
                        Select-Object -ExpandProperty Name)) -join "', '"

            # Stop the SQL Server and dependent resources
            Write-Verbose -Message ($script:localizedData.BringClusterResourcesOffline -f $resourceNames) -Verbose

            $sqlService |
                Invoke-CimMethod -MethodName TakeOffline -Arguments @{
                    Timeout = $Timeout
                }

            # Start the SQL server resource
            Write-Verbose -Message ($script:localizedData.BringSqlServerClusterResourcesOnline) -Verbose

            $sqlService |
                Invoke-CimMethod -MethodName BringOnline -Arguments @{
                    Timeout = $Timeout
                }

            # Start the SQL Agent resource
            if ($agentService)
            {
                if ($PSBoundParameters.ContainsKey('OwnerNode') -and $agentService.OwnerNode -notin $OwnerNode)
                {
                    $isOwnerOfClusterResource = $false
                }

                if ($isOwnerOfClusterResource)
                {
                    Write-Verbose -Message ($script:localizedData.BringSqlServerAgentClusterResourcesOnline) -Verbose

                    $agentService |
                        Invoke-CimMethod -MethodName BringOnline -Arguments @{
                            Timeout = $Timeout
                        }
                }
                else
                {
                    Write-Verbose -Message (
                        $script:localizedData.NotOwnerOfClusterResource -f (Get-ComputerName), $agentService.Name, $agentService.OwnerNode
                    ) -Verbose
                }
            }
        }
        else
        {
            Write-Verbose -Message (
                $script:localizedData.NotOwnerOfClusterResource -f (Get-ComputerName), $sqlService.Name, $sqlService.OwnerNode
            ) -Verbose
        }
    }
    else
    {
        Write-Warning -Message ($script:localizedData.ClusterResourceNotFoundOrOffline -f $InstanceName)
    }
}

<#
    .SYNOPSIS
        Restarts a Reporting Services instance and associated services

    .PARAMETER InstanceName
        Name of the instance to be restarted. Default is 'MSSQLSERVER'
        (the default instance).

    .PARAMETER WaitTime
        Number of seconds to wait between service stop and service start.
        Default value is 0 seconds.
#>
function Restart-ReportingServicesService
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $InstanceName = 'MSSQLSERVER',

        [Parameter()]
        [System.UInt16]
        $WaitTime = 0
    )

    if ($InstanceName -eq 'SSRS')
    {
        # Check if we're dealing with SSRS 2017 or SQL2019
        $ServiceName = 'SQLServerReportingServices'

        Write-Verbose -Message ($script:localizedData.GetServiceInformation -f $ServiceName) -Verbose
        $reportingServicesService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    }

    if ($null -eq $reportingServicesService)
    {
        $ServiceName = 'ReportServer'

        <#
            Pre-2017 SSRS support multiple instances, check if we're dealing
            with a named instance.
        #>
        if (-not ($InstanceName -eq 'MSSQLSERVER'))
        {
            $ServiceName += '${0}' -f $InstanceName
        }

        Write-Verbose -Message ($script:localizedData.GetServiceInformation -f $ServiceName) -Verbose
        $reportingServicesService = Get-Service -Name $ServiceName
    }

    <#
        Get all dependent services that are running.
        There are scenarios where an automatic service is stopped and should
        not be restarted automatically.
    #>
    $dependentService = $reportingServicesService.DependentServices | Where-Object -FilterScript {
        $_.Status -eq 'Running'
    }

    Write-Verbose -Message ($script:localizedData.RestartService -f $reportingServicesService.DisplayName) -Verbose

    Write-Verbose -Message ($script:localizedData.StoppingService -f $reportingServicesService.DisplayName) -Verbose
    $reportingServicesService | Stop-Service -Force

    if ($WaitTime -ne 0)
    {
        Write-Verbose -Message ($script:localizedData.WaitServiceRestart -f $WaitTime, $reportingServicesService.DisplayName) -Verbose
        Start-Sleep -Seconds $WaitTime
    }

    Write-Verbose -Message ($script:localizedData.StartingService -f $reportingServicesService.DisplayName) -Verbose
    $reportingServicesService | Start-Service

    # Start dependent services
    $dependentService | ForEach-Object -Process {
        Write-Verbose -Message ($script:localizedData.StartingDependentService -f $_.DisplayName) -Verbose
        $_ | Start-Service
    }
}

<#
    .SYNOPSIS
        Executes the alter method on an Availability Group Replica object.

    .PARAMETER AvailabilityGroupReplica
        The Availability Group Replica object that must be altered.
#>
function Update-AvailabilityGroupReplica
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityReplica]
        $AvailabilityGroupReplica
    )

    try
    {
        $originalErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $AvailabilityGroupReplica.Alter()
    }
    catch
    {
        $errorMessage = $script:localizedData.AlterAvailabilityGroupReplicaFailed -f $AvailabilityGroupReplica.Name
        New-InvalidOperationException -Message $errorMessage -ErrorRecord $_
    }
    finally
    {
        $ErrorActionPreference = $originalErrorActionPreference
    }
}

<#
    .SYNOPSIS
        Impersonates a login and determines whether required permissions are present.

    .PARAMETER ServerName
        String containing the host name of the SQL Server to connect to.

    .PARAMETER InstanceName
        String containing the SQL Server Database Engine instance to connect to.

    .PARAMETER LoginName
        String containing the login (user) which should be checked for a permission.

    .PARAMETER Permissions
        This is a list that represents a SQL Server set of database permissions.

    .PARAMETER SecurableClass
        String containing the class of permissions to test. It can be:
            SERVER: A permission that is applicable against server objects.
            LOGIN: A permission that is applicable against login objects.

        Default is 'SERVER'.

    .PARAMETER SecurableName
        String containing the name of the object against which permissions exist,
        e.g. if SecurableClass is LOGIN this is the name of a login permissions
        may exist against.

        Default is $null.

    .NOTES
        These SecurableClass are not yet in this module yet and so are not implemented:
            'APPLICATION ROLE', 'ASSEMBLY', 'ASYMMETRIC KEY', 'CERTIFICATE',
            'CONTRACT', 'DATABASE', 'ENDPOINT', 'FULLTEXT CATALOG',
            'MESSAGE TYPE', 'OBJECT', 'REMOTE SERVICE BINDING', 'ROLE',
            'ROUTE', 'SCHEMA', 'SERVICE', 'SYMMETRIC KEY', 'TYPE', 'USER',
            'XML SCHEMA COLLECTION'

#>
function Test-LoginEffectivePermissions
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Permissions,

        [Parameter()]
        [ValidateSet('SERVER', 'LOGIN')]
        [System.String]
        $SecurableClass = 'SERVER',

        [Parameter()]
        [System.String]
        $SecurableName
    )

    # Assume the permissions are not present
    $permissionsPresent = $false

    $invokeSqlDscQueryParameters = @{
        ServerName   = $ServerName
        InstanceName = $InstanceName
        DatabaseName = 'master'
        PassThru     = $true
    }

    if ( [System.String]::IsNullOrEmpty($SecurableName) )
    {
        $queryToGetEffectivePermissionsForLogin = "
            EXECUTE AS LOGIN = '$LoginName'
            SELECT DISTINCT permission_name
            FROM fn_my_permissions(null,'$SecurableClass')
            REVERT
        "
    }
    else
    {
        $queryToGetEffectivePermissionsForLogin = "
            EXECUTE AS LOGIN = '$LoginName'
            SELECT DISTINCT permission_name
            FROM fn_my_permissions('$SecurableName','$SecurableClass')
            REVERT
        "
    }

    Write-Verbose -Message ($script:localizedData.GetEffectivePermissionForLogin -f $LoginName, $InstanceName) -Verbose

    $loginEffectivePermissionsResult = Invoke-SqlDscQuery @invokeSqlDscQueryParameters -Query $queryToGetEffectivePermissionsForLogin
    $loginEffectivePermissions = $loginEffectivePermissionsResult.Tables.Rows.permission_name

    if ( $null -ne $loginEffectivePermissions )
    {
        $loginMissingPermissions = Compare-Object -ReferenceObject $Permissions -DifferenceObject $loginEffectivePermissions |
            Where-Object -FilterScript { $_.SideIndicator -ne '=>' } |
            Select-Object -ExpandProperty InputObject

        if ( $loginMissingPermissions.Count -eq 0 )
        {
            $permissionsPresent = $true
        }
    }

    return $permissionsPresent
}

<#
    .SYNOPSIS
        Determine if the seeding mode of the specified availability group is automatic.

    .PARAMETER ServerName
        The hostname of the server that hosts the SQL instance.

    .PARAMETER InstanceName
        The name of the SQL instance that hosts the availability group.

    .PARAMETER AvailabilityGroupName
        The name of the availability group to check.

    .PARAMETER AvailabilityReplicaName
        The name of the availability replica to check.
#>
function Test-AvailabilityReplicaSeedingModeAutomatic
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AvailabilityGroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AvailabilityReplicaName
    )

    # Assume automatic seeding is disabled by default
    $availabilityReplicaSeedingModeAutomatic = $false

    $serverObject = Connect-SQL -ServerName $ServerName -InstanceName $InstanceName -ErrorAction 'Stop'

    # Only check the seeding mode if this is SQL 2016 or newer
    if ( $serverObject.Version -ge 13 )
    {
        $invokeSqlDscQueryParameters = @{
            ServerName   = $ServerName
            InstanceName = $InstanceName
            DatabaseName = 'master'
            PassThru     = $true
        }

        $queryToGetSeedingMode = "
            SELECT seeding_mode_desc
            FROM sys.availability_replicas ar
            INNER JOIN sys.availability_groups ag ON ar.group_id = ag.group_id
            WHERE ag.name = '$AvailabilityGroupName'
                AND ar.replica_server_name = '$AvailabilityReplicaName'
        "
        $seedingModeResults = Invoke-SqlDscQuery @invokeSqlDscQueryParameters -Query $queryToGetSeedingMode
        $seedingMode = $seedingModeResults.Tables.Rows.seeding_mode_desc

        if ( $seedingMode -eq 'Automatic' )
        {
            $availabilityReplicaSeedingModeAutomatic = $true
        }
    }

    return $availabilityReplicaSeedingModeAutomatic
}

<#
    .SYNOPSIS
        Get the server object of the primary replica of the specified availability group.

    .PARAMETER ServerObject
        The current server object connection.

    .PARAMETER AvailabilityGroup
        The availability group object used to find the primary replica server name.
#>
function Get-PrimaryReplicaServerObject
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.AvailabilityGroup]
        $AvailabilityGroup
    )

    $primaryReplicaServerObject = $serverObject

    # Determine if we're connected to the primary replica
    if ( ( $AvailabilityGroup.PrimaryReplicaServerName -ne $serverObject.DomainInstanceName ) -and ( -not [System.String]::IsNullOrEmpty($AvailabilityGroup.PrimaryReplicaServerName) ) )
    {
        $primaryReplicaServerObject = Connect-SQL -ServerName $AvailabilityGroup.PrimaryReplicaServerName -ErrorAction 'Stop'
    }

    return $primaryReplicaServerObject
}

<#
    .SYNOPSIS
        Determine if the current login has impersonate permissions

    .PARAMETER ServerObject
        The server object on which to perform the test.

    .PARAMETER SecurableName
        If set then impersonate permission on this specific securable (e.g. login) is also checked.

#>
function Test-ImpersonatePermissions
{
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject,

        [Parameter()]
        [System.String]
        $SecurableName
    )

    # The impersonate any login permission only exists in SQL 2014 and above
    $testLoginEffectivePermissionsParams = @{
        ServerName   = $ServerObject.ComputerNamePhysicalNetBIOS
        InstanceName = $ServerObject.ServiceName
        LoginName    = $ServerObject.ConnectionContext.TrueLogin
        Permissions  = @('IMPERSONATE ANY LOGIN')
    }

    $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

    if ($impersonatePermissionsPresent)
    {
        Write-Verbose -Message ( 'The login "{0}" has impersonate any login permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.SInstanceName ) -Verbose
        return $impersonatePermissionsPresent
    }
    else
    {
        Write-Verbose -Message ( 'The login "{0}" does not have impersonate any login permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose
    }

    # Check for sysadmin / control server permission which allows impersonation
    $testLoginEffectivePermissionsParams = @{
        ServerName   = $ServerObject.ComputerNamePhysicalNetBIOS
        InstanceName = $ServerObject.ServiceName
        LoginName    = $ServerObject.ConnectionContext.TrueLogin
        Permissions  = @('CONTROL SERVER')
    }

    $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

    if ($impersonatePermissionsPresent)
    {
        Write-Verbose -Message ( 'The login "{0}" has control server permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose
        return $impersonatePermissionsPresent
    }
    else
    {
        Write-Verbose -Message ( 'The login "{0}" does not have control server permissions on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose
    }

    if (-not [System.String]::IsNullOrEmpty($SecurableName))
    {
        # Check for login-specific impersonation permissions
        $testLoginEffectivePermissionsParams = @{
            ServerName     = $ServerObject.ComputerNamePhysicalNetBIOS
            InstanceName   = $ServerObject.ServiceName
            LoginName      = $ServerObject.ConnectionContext.TrueLogin
            Permissions    = @('IMPERSONATE')
            SecurableClass = 'LOGIN'
            SecurableName  = $SecurableName
        }

        $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

        if ($impersonatePermissionsPresent)
        {
            Write-Verbose -Message ( 'The login "{0}" has impersonate permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName, $SecurableName ) -Verbose
            return $impersonatePermissionsPresent
        }
        else
        {
            Write-Verbose -Message ( 'The login "{0}" does not have impersonate permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName, $SecurableName ) -Verbose
        }

        # Check for login-specific control permissions
        $testLoginEffectivePermissionsParams = @{
            ServerName     = $ServerObject.ComputerNamePhysicalNetBIOS
            InstanceName   = $ServerObject.ServiceName
            LoginName      = $ServerObject.ConnectionContext.TrueLogin
            Permissions    = @('CONTROL')
            SecurableClass = 'LOGIN'
            SecurableName  = $SecurableName
        }

        $impersonatePermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

        if ($impersonatePermissionsPresent)
        {
            Write-Verbose -Message ( 'The login "{0}" has control permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName, $SecurableName ) -Verbose
            return $impersonatePermissionsPresent
        }
        else
        {
            Write-Verbose -Message ( 'The login "{0}" does not have control permissions on the instance "{1}\{2}" for the login "{3}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName, $SecurableName ) -Verbose
        }
    }

    Write-Verbose -Message ( 'The login "{0}" does not have any impersonate permissions required on the instance "{1}\{2}".' -f $testLoginEffectivePermissionsParams.LoginName, $testLoginEffectivePermissionsParams.ServerName, $testLoginEffectivePermissionsParams.InstanceName ) -Verbose

    return $impersonatePermissionsPresent
}

<#
    .SYNOPSIS
        Takes a SQL Instance name in the format of 'Server\Instance' and splits
        it into a hash table prepared to be passed into Connect-SQL.

    .PARAMETER FullSqlInstanceName
        The full SQL instance name string to be split.

    .OUTPUTS
        Hash table with the properties ServerName and InstanceName.
#>
function Split-FullSqlInstanceName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $FullSqlInstanceName
    )

    $sqlServer, $sqlInstanceName = $FullSqlInstanceName.Split('\')

    if ( [System.String]::IsNullOrEmpty($sqlInstanceName) )
    {
        $sqlInstanceName = 'MSSQLSERVER'
    }

    return @{
        ServerName   = $sqlServer
        InstanceName = $sqlInstanceName
    }
}

<#
    .SYNOPSIS
        Determine if the cluster has the required permissions to the supplied server.

    .PARAMETER ServerObject
        The server object on which to perform the test.
#>
function Test-ClusterPermissions
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification='Because the code throws based on an prior expression')]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )

    $clusterServiceName = 'NT SERVICE\ClusSvc'
    $ntAuthoritySystemName = 'NT AUTHORITY\SYSTEM'
    $availabilityGroupManagementPerms = @('Connect SQL', 'Alter Any Availability Group', 'View Server State')
    $clusterPermissionsPresent = $false

    # Retrieve the SQL Server and Instance name from the server object
    $sqlServer = $ServerObject.NetName
    $sqlInstanceName = $ServerObject.ServiceName

    foreach ( $loginName in @( $clusterServiceName, $ntAuthoritySystemName ) )
    {
        if ( $ServerObject.Logins[$loginName] -and -not $clusterPermissionsPresent )
        {
            $testLoginEffectivePermissionsParams = @{
                ServerName   = $sqlServer
                InstanceName = $sqlInstanceName
                LoginName    = $loginName
                Permissions  = $availabilityGroupManagementPerms
            }

            $clusterPermissionsPresent = Test-LoginEffectivePermissions @testLoginEffectivePermissionsParams

            if ( -not $clusterPermissionsPresent )
            {
                switch ( $loginName )
                {
                    $clusterServiceName
                    {
                        Write-Verbose -Message ( $script:localizedData.ClusterLoginMissingRecommendedPermissions -f $loginName, ( $availabilityGroupManagementPerms -join ', ' ) ) -Verbose
                    }

                    $ntAuthoritySystemName
                    {
                        Write-Verbose -Message ( $script:localizedData.ClusterLoginMissingPermissions -f $loginName, ( $availabilityGroupManagementPerms -join ', ' ) ) -Verbose
                    }
                }
            }
            else
            {
                Write-Verbose -Message ( $script:localizedData.ClusterLoginPermissionsPresent -f $loginName ) -Verbose
            }
        }
        elseif ( -not $clusterPermissionsPresent )
        {
            switch ( $loginName )
            {
                $clusterServiceName
                {
                    Write-Verbose -Message ($script:localizedData.ClusterLoginMissingRecommendedPermissions -f $loginName, "Trying with '$ntAuthoritySystemName'.") -Verbose
                }

                $ntAuthoritySystemName
                {
                    Write-Verbose -Message ( $script:localizedData.ClusterLoginMissing -f $loginName, '' ) -Verbose
                }
            }
        }
    }

    # If neither 'NT SERVICE\ClusSvc' or 'NT AUTHORITY\SYSTEM' have the required permissions, throw an error.
    if ( -not $clusterPermissionsPresent )
    {
        throw ($script:localizedData.ClusterPermissionsMissing -f $sqlServer, $sqlInstanceName )
    }

    return $clusterPermissionsPresent
}

<#
    .SYNOPSIS
        Determine if the current node is hosting the instance.

    .PARAMETER ServerObject
        The server object on which to perform the test.
#>
function Test-ActiveNode
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )

    $result = $false

    # Determine if this is a failover cluster instance (FCI)
    if ( $ServerObject.IsMemberOfWsfcCluster )
    {
        <#
            If the current node name is the same as the name the instances is
            running on, then this is the active node
        #>
        $result = $ServerObject.ComputerNamePhysicalNetBIOS -eq (Get-ComputerName)
    }
    else
    {
        <#
            This is a standalone instance, therefore the node will always host
            the instance.
        #>
        $result = $true
    }

    return $result
}

<#
    .SYNOPSIS
        Execute an SQL script located in a file on disk.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine.
        For default instances, only specify the computer name. For named instances,
        use the format ComputerName\InstanceName.

    .PARAMETER InputFile
        Path to SQL script file that will be executed.

    .PARAMETER Query
        The full query that will be executed.

    .PARAMETER Credential
        The credentials to use to authenticate using SQL Authentication. To
        authenticate using Windows Authentication, assign the credentials
        to the built-in parameter 'PsDscRunAsCredential'. If both parameters
        'Credential' and 'PsDscRunAsCredential' are not assigned, then the
        SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER QueryTimeout
        Specifies, as an integer, the number of seconds after which the T-SQL
        script execution will time out. In some SQL Server versions there is a
        bug in Invoke-SqlCmd where the normal default value 0 (no timeout) is not
        respected and the default value is incorrectly set to 30 seconds.

    .PARAMETER Variable
        Creates a Invoke-SqlCmd scripting variable for use in the Invoke-SqlCmd
        script, and sets a value for the variable.

    .PARAMETER DisableVariables
        Specifies, as a boolean, whether or not PowerShell will ignore Invoke-SqlCmd
        scripting variables that share a format such as $(variable_name). For more
        information how to use this, please go to the help documentation for
        [Invoke-SqlCmd](https://docs.microsoft.com/en-us/powershell/module/sqlserver/Invoke-Sqlcmd).

    .PARAMETER Encrypt
        Specifies how encryption should be enforced. When not specified, the default
        value is `Mandatory`.

        This value maps to the Encrypt property SqlConnectionEncryptOption
        on the SqlConnection object of the Microsoft.Data.SqlClient driver.

        This parameter can only be used when the module SqlServer v22.x.x is installed.

    .NOTES
        This wrapper for Invoke-SqlCmd make verbose functionality of PRINT and
        RAISEERROR statements work as those are outputted in the verbose output
        stream. For some reason having the wrapper in a separate module seems to
        trigger (so that it works getting) the verbose output for those statements.

        Parameter `Encrypt` controls whether the connection used by `Invoke-SqlCmd`
        should enforce encryption. This parameter can only be used together with the
        module _SqlServer_ v22.x (minimum v22.0.49-preview). The parameter will be
        ignored if an older major versions of the module _SqlServer_ is used.
        Encryption is mandatory by default, which generates the following exception
        when the correct certificates are not present:

        "A connection was successfully established with the server, but then
        an error occurred during the login process. (provider: SSL Provider,
        error: 0 - The certificate chain was issued by an authority that is
        not trusted.)"

        For more details, see the article [Connect to SQL Server with strict encryption](https://learn.microsoft.com/en-us/sql/relational-databases/security/networking/connect-with-strict-encryption?view=sql-server-ver16)
        and [Configure SQL Server Database Engine for encrypting connections](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption?view=sql-server-ver16).
#>
function Invoke-SqlScript
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(ParameterSetName = 'File', Mandatory = $true)]
        [System.String]
        $InputFile,

        [Parameter(ParameterSetName = 'Query', Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter()]
        [System.UInt32]
        $QueryTimeout,

        [Parameter()]
        [System.String[]]
        $Variable,

        [Parameter()]
        [System.Boolean]
        $DisableVariables,

        [Parameter()]
        [ValidateSet('Mandatory', 'Optional', 'Strict')]
        [System.String]
        $Encrypt
    )

    Import-SqlDscPreferredModule

    if ($PSCmdlet.ParameterSetName -eq 'File')
    {
        $null = $PSBoundParameters.Remove('Query')
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Query')
    {
        $null = $PSBoundParameters.Remove('InputFile')
    }

    if ($null -ne $Credential)
    {
        $null = $PSBoundParameters.Add('Username', $Credential.UserName)

        $null = $PSBoundParameters.Add('Password', $Credential.GetNetworkCredential().Password)
    }

    $null = $PSBoundParameters.Remove('Credential')

    if ($PSBoundParameters.ContainsKey('Encrypt'))
    {
        $commandInvokeSqlCmd = Get-Command -Name 'Invoke-SqlCmd'

        if ($null -ne $commandInvokeSqlCmd -and $commandInvokeSqlCmd.Parameters.Keys -notcontains 'Encrypt')
        {
            $null = $PSBoundParameters.Remove('Encrypt')
        }
    }

    if ([System.String]::IsNullOrEmpty($Variable))
    {
        $null = $PSBoundParameters.Remove('Variable')
    }

    Invoke-SqlCmd @PSBoundParameters
}

<#
    .SYNOPSIS
        Builds service account parameters for service account.

    .PARAMETER ServiceAccount
        Credential for the service account.
#>
function Get-ServiceAccount
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ServiceAccount
    )

    $accountParameters = @{ }

    switch -Regex ($ServiceAccount.UserName.ToUpper())
    {
        '^(?:NT ?AUTHORITY\\)?(SYSTEM|LOCALSERVICE|LOCAL SERVICE|NETWORKSERVICE|NETWORK SERVICE)$'
        {
            $accountParameters = @{
                "UserName" = "NT AUTHORITY\$($Matches[1])"
            }
        }

        '^(?:NT SERVICE\\)(.*)$'
        {
            $accountParameters = @{
                "UserName" = "NT SERVICE\$($Matches[1])"
            }
        }

        # Testing if account is a Managed Service Account, which ends with '$'.
        '\$$'
        {
            $accountParameters = @{
                "UserName" = $ServiceAccount.UserName
            }
        }

        # Normal local or domain service account.
        default
        {
            $accountParameters = @{
                "UserName" = $ServiceAccount.UserName
                "Password" = $ServiceAccount.GetNetworkCredential().Password
            }
        }
    }

    return $accountParameters
}

<#
    .SYNOPSIS
    Recursively searches Exception stack for specific error number.

    .PARAMETER ExceptionToSearch
    The Exception object to test

    .PARAMETER ErrorNumber
    The specific error number to look for

    .NOTES
    This function allows us to more easily write mocks.
#>
function Find-ExceptionByNumber
{
    # Define parameters
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Exception]
        $ExceptionToSearch,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorNumber
    )

    # Define working variables
    $errorFound = $false

    # Check to see if the exception has an inner exception
    if ($ExceptionToSearch.InnerException)
    {
        # Assign found to the returned recursive call
        $errorFound = Find-ExceptionByNumber -ExceptionToSearch $ExceptionToSearch.InnerException -ErrorNumber $ErrorNumber
    }

    # Check to see if it was found
    if (!$errorFound)
    {
        # Check this exceptions message
        $errorFound = $ExceptionToSearch.Number -eq $ErrorNumber
    }

    # Return
    return $errorFound
}

<#
    .SYNOPSIS
        Get static name properties of he specified protocol.

    .PARAMETER ProtocolName
        Specifies the name of network protocol to return name properties for.
        Possible values are 'TcpIp', 'NamedPipes', or 'ShareMemory'.

    .NOTES
        The static values returned matches the values returned by the class
        ServerProtocol. The property DisplayName could potentially be localized
        while the property Name must be exactly like it is returned by the
        class ServerProtocol, with the correct casing.
#>
function Get-ProtocolNameProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName
    )

    $protocolNameProperties = @{ }

    switch ($ProtocolName)
    {
        'TcpIp'
        {
            $protocolNameProperties.DisplayName = 'TCP/IP'
            $protocolNameProperties.Name = 'Tcp'
        }

        'NamedPipes'
        {
            $protocolNameProperties.DisplayName = 'Named Pipes'
            $protocolNameProperties.Name = 'Np'
        }

        'SharedMemory'
        {
            $protocolNameProperties.DisplayName = 'Shared Memory'
            $protocolNameProperties.Name = 'Sm'
        }
    }

    return $protocolNameProperties
}

<#
    .SYNOPSIS
        Returns the ServerProtocol object for the specified SQL Server instance
        and protocol name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance to connect to.

    .PARAMETER ProtocolName
        Specifies the name of network protocol to be configured. Possible values
        are 'TcpIp', 'NamedPipes', or 'ShareMemory'.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server to connect to.

    .NOTES
        The class Microsoft.SqlServer.Management.Smo.Wmi.ServerProtocol is
        returned by this function.
#>
function Get-ServerProtocolObject
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('TcpIp', 'NamedPipes', 'SharedMemory')]
        [System.String]
        $ProtocolName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName
    )

    $serverProtocolProperties = $null

    $newObjectParameters = @{
        TypeName     = 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
        ArgumentList = @($ServerName)
    }

    $managedComputerObject = New-Object @newObjectParameters

    $serverInstance = $managedComputerObject.ServerInstances[$InstanceName]

    if ($serverInstance)
    {
        $protocolNameProperties = Get-ProtocolNameProperties -ProtocolName $ProtocolName

        $serverProtocolProperties = $serverInstance.ServerProtocols[$protocolNameProperties.Name]
    }
    else
    {
        $errorMessage = $script:localizedData.FailedToObtainServerInstance -f $InstanceName, $ServerName
        New-InvalidOperationException -Message $errorMessage
    }

    return $serverProtocolProperties
}

<#
    .SYNOPSIS
        Converts the combination of server name and instance name to
        the correct server instance name.

    .PARAMETER InstanceName
        Specifies the name of the SQL Server instance on the host.

    .PARAMETER ServerName
        Specifies the host name of the SQL Server.
#>
function ConvertTo-ServerInstanceName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName
    )

    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $serverInstance = $ServerName
    }
    else
    {
        $serverInstance = '{0}\{1}' -f $ServerName, $InstanceName
    }

    return $serverInstance
}

<#
    .SYNOPSIS
        Returns the SQL Server major version from the setup.exe executable provided
        in the Path parameter.

    .PARAMETER Path
        String containing the path to the SQL Server setup.exe executable.

    .NOTES
        This function should be removed when it is not longer used, and instead
        the private function Get-FileVersionInformation shall be used.
#>
function Get-FilePathMajorVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    (Get-Item -Path $Path).VersionInfo.ProductVersion.Split('.')[0]
}

<#
    .SYNOPSIS
        Test if the specific feature flag should be enabled.

    .PARAMETER FeatureFlag
        An array of feature flags that should be compared against.

    .PARAMETER TestFlag
        The feature flag that is being check if it should be enabled.
#>
function Test-FeatureFlag
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String[]]
        $FeatureFlag,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFlag
    )

    $flagEnabled = $FeatureFlag -and ($FeatureFlag -and $FeatureFlag.Contains($TestFlag))

    return $flagEnabled
}
