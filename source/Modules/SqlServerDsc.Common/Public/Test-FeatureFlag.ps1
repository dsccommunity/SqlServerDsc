<#
    .SYNOPSIS
        Test if the specific feature flag should be enabled.

    .PARAMETER FeatureFlag
        An array of feature flags that should be compared against.

    .PARAMETER TestFlag
        The feature flag that is being check if it should be enabled.
#>
function Test-FeatureFlag
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.String[]]
        $FeatureFlag,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFlag
    )

    $flagEnabled = $FeatureFlag -and ($FeatureFlag -and $FeatureFlag.Contains($TestFlag))

    return $flagEnabled
}
