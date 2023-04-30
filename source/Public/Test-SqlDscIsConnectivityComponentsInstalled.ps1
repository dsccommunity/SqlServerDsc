<#
    .SYNOPSIS
        Returns whether the Connectivity Components are installed.

    .DESCRIPTION
        Returns whether the Connectivity Components are installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsConnectivityComponentsInstalled -Version ([System.Version] '16.0')

        Returns $true if Connectivity Components are installed.
#>
function Test-SqlDscIsConnectivityComponentsInstalled
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
        Name        = 'Connectivity_Full'
        ErrorAction = 'SilentlyContinue'
    }

    $isConnInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isConnInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
