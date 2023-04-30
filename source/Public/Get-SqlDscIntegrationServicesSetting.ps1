<#
    .SYNOPSIS
        Returns the Integration Services settings.

    .DESCRIPTION
        Returns the Integration Services settings.

    .PARAMETER Version
       Specifies the version for which to return settings for.

    .OUTPUTS
        `[System.Management.Automation.PSCustomObject]`

    .EXAMPLE
        Get-SqlDscIntegrationServicesSetting -Version ([System.Version] '16.0')

        Returns the settings for the Integration Services.
#>
function Get-SqlDscIntegrationServicesSetting
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Version]
        $Version
    )

    $integrationServicesSettings = $null

    $getItemPropertyParameters = @{
        Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\DTS\Setup' -f $Version.Major
        ErrorAction = 'SilentlyContinue'
    }

    $setupSettings = Get-ItemProperty @getItemPropertyParameters

    if (-not $setupSettings)
    {
        $missingIntegrationServiceMessage = $script:localizedData.IntegrationServicesSetting_Get_NotInstalled -f $Version.ToString()

        $writeErrorParameters = @{
            Message = $missingIntegrationServiceMessage
            Category = 'InvalidOperation'
            ErrorId = 'GISS0001' # cspell: disable-line
            TargetObject = $Version
        }

        Write-Error @writeErrorParameters
    }
    else
    {
        $integrationServicesSettings = [InstalledComponentSetting]::Parse($setupSettings)
    }

    return $integrationServicesSettings
}
