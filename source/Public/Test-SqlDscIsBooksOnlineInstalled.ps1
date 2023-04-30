<#
    .SYNOPSIS
        Returns whether the Books Online is installed.

    .DESCRIPTION
        Returns whether the Books Online is installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsBooksOnlineInstalled -Version ([System.Version] '16.0')

        Returns $true if SQL Server Books Online is installed.
#>
function Test-SqlDscIsBooksOnlineInstalled
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
        Name        = 'SQL_BOL_Components'
        ErrorAction = 'SilentlyContinue'
    }

    $isBOLInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isBOLInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
