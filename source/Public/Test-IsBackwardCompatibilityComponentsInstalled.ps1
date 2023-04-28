<#
    .SYNOPSIS
        Returns whether the Backward Compatibility Components are installed.

    .DESCRIPTION
        Returns whether the Backward Compatibility Components are installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-IsBackwardCompatibilityComponentsInstalled -Version ([System.Version] '16.0')

        Returns $true if Backward Compatibility Components are installed.
#>
function Test-IsBackwardCompatibilityComponentsInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.Version]
        $Version
    )

    $configurationStateRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\ConfigurationState'

    $getRegistryPropertyValueParameters = @{
        Path        = $configurationStateRegistryPath -f $Version.Major
        Name        = 'Tools_Legacy_Full'
        ErrorAction = 'SilentlyContinue'
    }

    $isBCInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isBCInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
