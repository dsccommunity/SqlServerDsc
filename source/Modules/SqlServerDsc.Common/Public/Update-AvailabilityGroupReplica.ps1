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
