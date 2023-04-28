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
function Test-IsMasterDataServicesInstalled
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
        Name        = 'MDSCoreFeature'
        ErrorAction = 'SilentlyContinue'
    }

    $isMDSInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isMDSInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
