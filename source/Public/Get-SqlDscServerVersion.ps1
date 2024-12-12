<#
    .SYNOPSIS
        Get server version.
    .DESCRIPTION
        This command gets the version from a SQL Server Database Engine instance.
    .PARAMETER ServerObject
        Specifies current server connection object.
    .EXAMPLE
        $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'MyInstance'
        $serverObject | Get-SqlDscServerVersion
        Get the version of the SQL Server instance.
    .OUTPUTS
        `[Microsoft.SqlServer.Management.Common.ServerVersion]`

    #>

function Get-SqlDscServerVersion
{
    [OutputType([Microsoft.SqlServer.Management.Common.ServerVersion])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )
    return $ServerObject.ServerVersion
}
