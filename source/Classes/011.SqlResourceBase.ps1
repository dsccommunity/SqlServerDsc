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
    # Cache for resolved enum types to avoid repeated assembly scanning.
    hidden static [System.Collections.Generic.Dictionary[System.String, System.Type]] $EnumTypeCache = [System.Collections.Generic.Dictionary[System.String, System.Type]]::new()

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
}
