<#
    .SYNOPSIS
        Returns whether the Software Development Kit is installed.

    .DESCRIPTION
        Returns whether the Software Development Kit is installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-IsSoftwareDevelopmentKitInstalled -Version ([System.Version] '16.0')

        Returns $true if Software Development Kit is installed.
#>
function Test-SqlDscIsSoftwareDevelopmentKitInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Version]
        $Version
    )

    $configurationStateRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\ConfigurationState'

    $getRegistryPropertyValueParameters = @{
        Path        = $configurationStateRegistryPath -f $Version.Major
        Name        = 'SDK_Full'
        ErrorAction = 'SilentlyContinue'
    }

    $isSDKInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isSDKInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
