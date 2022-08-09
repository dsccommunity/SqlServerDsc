<#
    .SYNOPSIS
        The SqlResource base have generic properties and methods for the class-based
        resources.
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

    SqlResourceBase () : base ()
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
