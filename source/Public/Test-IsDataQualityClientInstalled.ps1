<#
    .SYNOPSIS
        Returns whether the Data Quality Client is installed.

    .DESCRIPTION
        Returns whether the Data Quality Client is installed.

    .PARAMETER Version
       Specifies the version for which to return installed components.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-IsDataQualityClientInstalled -Version ([System.Version] '16.0')

        Returns $true Data Quality Client is installed.
#>
function Test-IsDataQualityClientInstalled
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
        Name        = 'SQL_DQ_CLIENT_Full'
        ErrorAction = 'SilentlyContinue'
    }

    $isDQCInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isDQCInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
