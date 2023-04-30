<#
    .SYNOPSIS
        Returns whether the Integration Services are installed.

    .DESCRIPTION
        Returns whether the Integration Services are installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsIntegrationServicesInstalled -Version ([System.Version] '16.0')

        Returns $true if Integration Services are installed.
#>
function Test-SqlDscIsIntegrationServicesInstalled
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

    if ((Get-SqlDscIntegrationServicesSetting -Version $Version -ErrorAction 'SilentlyContinue'))
    {
        $result = $true
    }

    return $result
}
