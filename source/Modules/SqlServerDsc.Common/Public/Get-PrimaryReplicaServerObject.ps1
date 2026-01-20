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
