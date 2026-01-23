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
        Connect-Sql

        Connects to the default instance on the local server.

    .EXAMPLE
        Connect-Sql -InstanceName 'MyInstance'

        Connects to the instance 'MyInstance' on the local server.

    .EXAMPLE
        Connect-Sql ServerName 'sql.company.local' -InstanceName 'MyInstance' -ErrorAction 'Stop'

        Connects to the instance 'MyInstance' on the server 'sql.company.local'.
#>
function Connect-Sql
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
        [ValidateSet('tcp', 'np', 'lpc')]
        [System.String]
        $Protocol,

        [Parameter()]
        [System.UInt16]
        $Port,

        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $StatementTimeout = 600,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Encrypt
    )

    Import-SqlDscPreferredModule

    <#
        Build the connection string in the format: [protocol:]hostname[\instance][,port]
        Examples:
        - ServerName (default instance, no protocol/port)
        - ServerName\Instance (named instance)
        - tcp:ServerName (default instance with protocol)
        - tcp:ServerName\Instance (named instance with protocol)
        - ServerName,1433 (default instance with port)
        - ServerName\Instance,50200 (named instance with port)
        - tcp:ServerName,1433 (default instance with protocol and port)
        - tcp:ServerName\Instance,50200 (named instance with protocol and port)
    #>
    if ($InstanceName -eq 'MSSQLSERVER')
    {
        $databaseEngineInstance = $ServerName
    }
    else
    {
        $databaseEngineInstance = '{0}\{1}' -f $ServerName, $InstanceName
    }

    # Append port if specified
    if ($PSBoundParameters.ContainsKey('Port'))
    {
        $databaseEngineInstance = '{0},{1}' -f $databaseEngineInstance, $Port
    }

    # Prepend protocol if specified
    if ($PSBoundParameters.ContainsKey('Protocol'))
    {
        $databaseEngineInstance = '{0}:{1}' -f $Protocol, $databaseEngineInstance
    }

    $sqlConnectionContext = [Microsoft.SqlServer.Management.Common.ServerConnection]::new()
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
        )
    }
    else
    {
        $connectUserName = $Credential.UserName

        Write-Verbose -Message (
            $script:localizedData.ConnectingUsingImpersonation -f $connectUsername, $LoginType
        )

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
        $sqlServerObject = [Microsoft.SqlServer.Management.Smo.Server]::new($sqlConnectionContext)

        <#
        The addition of the ConnectTimeout property to the ConnectionContext will force the
        Connect() method to block until successful.  The SMO object's Status property may not
        report 'Online' immediately even though the Connect() was successful.  The loop is to
        ensure the SMO's Status property was been updated.
        #>
        $sqlServerObject.ConnectionContext.Connect()

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
            )

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
            Connect() will ensure we actually can connect, but we need to disconnect
            from the session so we don't have anything hanging. If we need run a
            method on the returned $sqlServerObject it will automatically open a
            new session and then close, therefore we don't need to keep this
            session open.
        #>
        $sqlServerObject.ConnectionContext.Disconnect()
    }
}
