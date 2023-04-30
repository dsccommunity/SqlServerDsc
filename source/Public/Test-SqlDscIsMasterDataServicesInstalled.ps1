<#
    .SYNOPSIS
        Returns whether the Master Data Services are installed.

    .DESCRIPTION
        Returns whether the Master Data Services are installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        IsMasterDataServicesInstalled -Version ([System.Version] '16.0')

        Returns $true if Master Data Services are installed.
#>
function Test-SqlDscIsMasterDataServicesInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Version]
        $Version
    )

    $result = $false

    if ((Get-SqlDscMasterDataServicesSetting -Version $Version -ErrorAction 'SilentlyContinue'))
    {
        $result = $true
    }

    return $result
}
