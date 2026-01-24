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
