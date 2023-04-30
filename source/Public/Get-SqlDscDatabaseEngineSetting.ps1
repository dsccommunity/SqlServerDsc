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
function Get-SqlDscDatabaseEngineSetting
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Version]
        $Version
    )

    <#
        HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13.SQL2016\Setup

        FeatureList
        Version
        PatchLevel
        Edition
        EditionType
        Language
        ProductCode
        SqlPath

        TODO: Gör en Get-SqlDscServiceName med data från HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\Services
              Liknande Get-SqlDscInstalledInstance
    #>
    $masterDataServicesSettings = $null

    $getItemPropertyParameters = @{
        Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\Master Data Services\Setup\MDSCoreFeature' -f $Version.Major
        ErrorAction = 'SilentlyContinue'
    }

    $mdsCoreFeatureSettings = Get-ItemProperty @getItemPropertyParameters

    if (-not $mdsCoreFeatureSettings)
    {
        $missingIntegrationServiceMessage = $script:localizedData.MasterDataServicesSetting_Get_NotInstalled -f $Version.ToString()

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
