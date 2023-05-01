<#
    .SYNOPSIS
        Returns the integration services settings.

    .DESCRIPTION
        Returns the integration services settings.

    .PARAMETER Version
       Specifies the version for which to return settings for.

    .OUTPUTS
        `[System.Management.Automation.PSCustomObject]`

    .EXAMPLE
        Get-SqlDscIntegrationServicesSetting -Version ([System.Version] '16.0')

        Returns the settings for the integration services.
#>
function Get-SqlDscMasterDataServicesSetting
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Version]
        $Version
    )

    $masterDataServicesSettings = $null

    $getItemPropertyParameters = @{
        Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\Master Data Services\Setup\MDSCoreFeature' -f $Version.Major
        ErrorAction = 'SilentlyContinue'
    }

    $mdsCoreFeatureSettings = Get-ItemProperty @getItemPropertyParameters

    if (-not $mdsCoreFeatureSettings)
    {
        $missingMasterDataServicesMessage = $script:localizedData.MasterDataServicesSetting_Get_NotInstalled -f $Version.ToString()

        $writeErrorParameters = @{
            Message = $missingMasterDataServicesMessage
            Category = 'InvalidOperation'
            ErrorId = 'GISS0001' # cspell: disable-line
            TargetObject = $Version
        }

        Write-Error @writeErrorParameters
    }
    else
    {
        $masterDataServicesSettings1 = [InstalledComponentSetting]::Parse($mdsCoreFeatureSettings)

        $getItemPropertyParameters = @{
            Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\Master Data Services\Setup' -f $Version.Major
            ErrorAction = 'SilentlyContinue'
        }

        $mdsSetupSettings = Get-ItemProperty @getItemPropertyParameters

        $masterDataServicesSettings2 = [InstalledComponentSetting]::Parse($mdsSetupSettings)

        $masterDataServicesSettings = $masterDataServicesSettings1 + $masterDataServicesSettings2
    }

    return $masterDataServicesSettings
}
