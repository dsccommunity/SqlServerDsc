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

    .PARAMETER Reasons
        Returns the reason a property is not in desired state.
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

    [DscProperty(NotConfigurable)]
    [SqlReason[]]
    $Reasons

    # Passing the module's base directory to the base constructor.
    SqlResourceBase () : base ($PSScriptRoot)
    {
        $this.SqlServerObject = $null
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

            $this.SqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters
        }

        return $this.SqlServerObject
    }
}
