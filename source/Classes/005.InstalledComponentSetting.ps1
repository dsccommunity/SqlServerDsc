<#
    .SYNOPSIS
        Common properties across all components that can be installed.

    .EXAMPLE
        [InstalledComponentSetting]::new()

        Creates a new empty object.

    .NOTES
        This class should be parent of an derived class that have more properties
        that are unique for each component.
#>
class InstalledComponentSetting
{
    [System.String[]]
    $FeatureList

    [System.Version]
    $Version

    [System.Version]
    $PatchLevel

    [System.String]
    $Edition

    [System.String]
    $EditionType

    [Nullable[System.UInt32]]
    $Language

    [System.String]
    $ProductCode

    [System.String]
    $SqlPath

    InstalledComponentSetting ()
    {
    }

    static [InstalledComponentSetting] op_Addition([InstalledComponentSetting] $Left, [InstalledComponentSetting] $Right)
    {
        $propertyList = $Left.PSObject.Properties.Name

        foreach ($property in $propertyList)
        {
            # Only add values if left side is $null and right side is not null.
            if (-not $Left.$property -and $Right.$property)
            {
                $Left.$property = $Right.$property
            }
        }

        return $Left
    }

    static [InstalledComponentSetting] Parse([PSCustomObject] $Settings)
    {
        $installedComponentSetting = [InstalledComponentSetting]::new()

        if ($settings.FeatureList)
        {
            $installedComponentSetting.FeatureList = $settings.FeatureList -split ' '
        }

        $propertyList = (
            $installedComponentSetting.PSObject.Properties |
                Where-Object -FilterScript {
                    $_.Name -ne 'FeatureList'
                }
        ).Name

        foreach ($property in $propertyList)
        {
            if ($settings.$property)
            {
                $installedComponentSetting.$property = $settings.$property
            }
        }

        return $installedComponentSetting
    }
}
