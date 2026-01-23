<#
    .SYNOPSIS
        Connects to the source using the provided credentials and then uses
        robocopy to download the installation media to a local temporary folder.

    .PARAMETER SourcePath
        Source path to be copied.

    .PARAMETER SourceCredential
        The credentials to access the SourcePath.

    .PARAMETER PassThru
        If used, returns the destination path as string.

    .OUTPUTS
        Returns the destination path (when used with the parameter PassThru).
#>
function Invoke-InstallationMediaCopy
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourcePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    Connect-UncPath -RemotePath $SourcePath -SourceCredential $SourceCredential

    $SourcePath = $SourcePath.TrimEnd('/\')
    <#
        Create a destination folder so the media files aren't written
        to the root of the Temp folder.
    #>
    $serverName, $shareName, $leafs = ($SourcePath -replace '\\\\') -split '\\'
    if ($leafs)
    {
        $mediaDestinationFolder = $leafs | Select-Object -Last 1
    }
    else
    {
        $mediaDestinationFolder = New-Guid | Select-Object -ExpandProperty Guid
    }

    $mediaDestinationPath = Join-Path -Path (Get-TemporaryFolder) -ChildPath $mediaDestinationFolder

    Write-Verbose -Message ($script:localizedData.RobocopyIsCopying -f $SourcePath, $mediaDestinationPath) -Verbose
    Copy-ItemWithRobocopy -Path $SourcePath -DestinationPath $mediaDestinationPath

    Disconnect-UncPath -RemotePath $SourcePath

    if ($PassThru.IsPresent)
    {
        return $mediaDestinationPath
    }
}
