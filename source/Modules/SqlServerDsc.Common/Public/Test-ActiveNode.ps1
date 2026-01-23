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
