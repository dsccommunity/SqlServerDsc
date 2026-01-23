<#
    .SYNOPSIS
        Connects to the UNC path provided in the parameter SourcePath.
        Optionally connects using the provided credentials.

    .PARAMETER SourcePath
        Source path to connect to.

    .PARAMETER SourceCredential
        The credentials to access the path provided in SourcePath.

    .PARAMETER PassThru
        If used, returns a MSFT_SmbMapping object that represents the newly
        created SMB mapping.

    .OUTPUTS
        Returns a MSFT_SmbMapping object that represents the newly created
        SMB mapping (ony when used with parameter PassThru).
#>
function Connect-UncPath
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemotePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    $newSmbMappingParameters = @{
        RemotePath = $RemotePath
    }

    if ($PSBoundParameters.ContainsKey('SourceCredential'))
    {
        $newSmbMappingParameters['UserName'] = $SourceCredential.UserName
        $newSmbMappingParameters['Password'] = $SourceCredential.GetNetworkCredential().Password
    }

    $newSmbMappingResult = New-SmbMapping @newSmbMappingParameters

    if ($PassThru.IsPresent)
    {
        return $newSmbMappingResult
    }
}
