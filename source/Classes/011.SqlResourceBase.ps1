<#
    .SYNOPSIS
        The SqlResource base have generic properties and methods for the class-based
        resources.

    .PARAMETER InstanceName
        The name of the _SQL Server_ instance to be configured. Default value is
        `'MSSQLSERVER'`.

    .PARAMETER ServerName
        The host name of the _SQL Server_ to be configured. Default value is the
        current computer name.

    .PARAMETER Credential
        Specifies the credential to use to connect to the _SQL Server_ instance.

        If parameter **Credential'* is not provided then the resource instance is
        run using the credential that runs the configuration.

    .PARAMETER Protocol
        Specifies the network protocol to use when connecting to the _SQL Server_
        instance. Valid values are `'tcp'` for TCP/IP, `'np'` for Named Pipes,
        and `'lpc'` for Shared Memory.

        If not specified, the connection will use the default protocol order
        configured on the client.

    .PARAMETER Port
        Specifies the TCP port number to use when connecting to the _SQL Server_
        instance. This parameter is only applicable when connecting via TCP/IP.

        If not specified for a named instance, the SQL Server Browser service
        will be used to determine the port. For default instances, port 1433
        is used by default.

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.

    .NOTES
        The protocol values (`'tcp'`, `'np'`, `'lpc'`) are lowercase to match
        the SQL Server connection string prefix format, e.g.,
        `tcp:ServerName\Instance,Port`.
#>
class SqlResourceBase : ResourceBase
{
    <#
        Property for holding the server connection object.
        This should be an object of type [Microsoft.SqlServer.Management.Smo.Server]
        but using that type fails the build process currently.
        See issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/121.
    #>
    hidden [System.Object] $SqlServerObject

    [DscProperty(Key)]
    [System.String]
    $InstanceName

    [DscProperty()]
    [System.String]
    $ServerName = (Get-ComputerName)

    [DscProperty()]
    [PSCredential]
    $Credential

    [DscProperty()]
    [ValidateSet('tcp', 'np', 'lpc')]
    [System.String]
    $Protocol

    [DscProperty()]
    [Nullable[System.UInt16]]
    $Port

    [DscProperty(NotConfigurable)]
    [SqlReason[]]
    $Reasons

    # Passing the module's base directory to the base constructor.
    SqlResourceBase () : base ($PSScriptRoot)
    {
        $this.SqlServerObject = $null

        <#
            These connection properties will not be enforced. Child classes
            should use += to append their own properties to this list.
        #>
        $this.ExcludeDscProperties = @(
            'ServerName'
            'InstanceName'
            'Credential'
            'Protocol'
            'Port'
        )
    }

    <#
        Returns and reuses the server connection object. If the server connection
        object does not exist a connection to the SQL Server instance will occur.

        This should return an object of type [Microsoft.SqlServer.Management.Smo.Server]
        but using that type fails the build process currently.
        See issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/121.
    #>
    hidden [System.Object] GetServerObject()
    {
        if (-not $this.SqlServerObject)
        {
            $connectSqlDscDatabaseEngineParameters = @{
                ServerName   = $this.ServerName
                InstanceName = $this.InstanceName
                ErrorAction  = 'Stop'
            }

            if ($this.Credential)
            {
                $connectSqlDscDatabaseEngineParameters.Credential = $this.Credential
            }

            if ($this.Protocol)
            {
                $connectSqlDscDatabaseEngineParameters.Protocol = $this.Protocol
            }

            if ($this.Port)
            {
                $connectSqlDscDatabaseEngineParameters.Port = $this.Port
            }

            $this.SqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters
        }

        return $this.SqlServerObject
    }

    <#
        .SYNOPSIS
            Converts a string value to the corresponding SMO enum type at runtime.

        .DESCRIPTION
            This helper method is required because PowerShell parses class definitions
            at module load time. Direct SMO type literals (e.g., [SMOType]::Value)
            would fail because SMO assemblies may not be loaded yet.

            This method uses runtime type resolution to avoid parse-time errors.

        .PARAMETER TypeName
            The name of the SMO enum type (e.g., 'RecoveryModel'). If the type name
            does not contain a dot, the Namespace parameter is prepended.

        .PARAMETER Value
            The string value to convert to the enum type.

        .PARAMETER Namespace
            The namespace of the SMO enum type. Defaults to 'Microsoft.SqlServer.Management.Smo'.

        .OUTPUTS
            The SMO enum value.

        .NOTES
            This is required due to PowerShell's class parsing behavior. We cannot
            use SMO types directly in the class definition, because they may not be
            installed when the module is imported. The user also decides which SMO
            to use (SQLPS, SqlServer, dbatools).
    #>
    hidden [System.Object] ConvertToSmoEnumType([System.String] $TypeName, [System.String] $Value)
    {
        return $this.ConvertToSmoEnumType($TypeName, $Value, 'Microsoft.SqlServer.Management.Smo')
    }

    hidden [System.Object] ConvertToSmoEnumType([System.String] $TypeName, [System.String] $Value, [System.String] $Namespace)
    {
        # If the type name doesn't contain a dot, prepend the namespace
        $fullTypeName = if ($TypeName -notmatch '\.')
        {
            '{0}.{1}' -f $Namespace, $TypeName
        }
        else
        {
            $TypeName
        }

        $enumType = [System.Type]::GetType($fullTypeName, $false, $true)

        if (-not $enumType)
        {
            # Try loading from loaded assemblies if direct resolution fails
            $enumType = [System.AppDomain]::CurrentDomain.GetAssemblies().GetTypes() |
                Where-Object -FilterScript { $_.FullName -eq $fullTypeName } |
                Select-Object -First 1
        }

        if (-not $enumType)
        {
            New-InvalidOperationException -Message (
                $this.localizedData.ConvertToSmoEnumType_FailedToFindType -f $fullTypeName
            )
        }

        return [System.Enum]::Parse($enumType, $Value, $true)
    }
}
