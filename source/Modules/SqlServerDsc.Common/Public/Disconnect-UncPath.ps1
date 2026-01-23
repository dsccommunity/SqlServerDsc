<#
    .SYNOPSIS
        Disconnects from the UNC path provided in the parameter SourcePath.

    .PARAMETER SourcePath
        Source path to disconnect from.
#>
function Disconnect-UncPath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemotePath
    )

    Remove-SmbMapping -RemotePath $RemotePath -Force
}
