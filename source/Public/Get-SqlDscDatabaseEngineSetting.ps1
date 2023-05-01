<#
    .SYNOPSIS
        Returns the database engine settings.

    .DESCRIPTION
        Returns the database engine settings.

    .PARAMETER InstanceId
       Specifies the instance id on which to check if component is installed.

    .OUTPUTS
        `[System.Management.Automation.PSCustomObject]`

    .EXAMPLE
        Get-SqlDscDatabaseEngineSetting -InstanceId 'MSSQL13.SQL2016'

        Returns the settings for the database engine.
#>
function Get-SqlDscDatabaseEngineSetting
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceId
    )

    $databaseEngineSettings = $null

    $getItemPropertyParameters = @{
        Path        = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\Setup' -f $InstanceId
        ErrorAction = 'SilentlyContinue'
    }

    $setupSettings = Get-ItemProperty @getItemPropertyParameters

    if (-not $setupSettings)
    {
        $missingDatabaseEngineMessage = $script:localizedData.DatabaseEngineSetting_Get_NotInstalled -f $Version.ToString()

        $writeErrorParameters = @{
            Message      = $missingDatabaseEngineMessage
            Category     = 'InvalidOperation'
            ErrorId      = 'GISS0001' # cspell: disable-line
            TargetObject = $Version
        }

        Write-Error @writeErrorParameters
    }
    else
    {
        $databaseEngineSettings = [InstalledComponentSetting]::Parse($setupSettings)
    }

    return $databaseEngineSettings
}
