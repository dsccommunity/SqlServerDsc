<#
    .SYNOPSIS
        Returns the database engine settings.

    .DESCRIPTION
        Returns the database engine settings for the specified SQL Server instance.
        This command reads the instance's setup registry keys and converts them
        into an InstalledComponentSetting object suitable for use by DSC resources
        and automation scripts.

    .PARAMETER InstanceId
       Specifies the instance id on which to check if component is installed.

    .OUTPUTS
        `[System.Management.Automation.PSCustomObject]`

    .EXAMPLE
        Get-SqlDscDatabaseEngineInstalledSetting -InstanceId 'MSSQL13.SQL2016'

        Returns the settings for the database engine.
#>
function Get-SqlDscDatabaseEngineInstalledSetting
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.String]
        $InstanceId
    )

    process
    {
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
}
