<#
    .SYNOPSIS
        Get the first available (preferred) module that is installed.

    .DESCRIPTION
        Get the first available (preferred) module that is installed.

        If the environment variable `SMODefaultModuleName` is set to a module name
        that name will be used as the preferred module name instead of the default
        module 'SqlServer'.

    .PARAMETER Name
        Specifies the list of the (preferred) modules to search for, in order.
        Defaults to 'SqlServer' and then 'SQLPS'.

    .PARAMETER Refresh
        Specifies if the session environment variable PSModulePath should be refresh
        with the paths from other environment variable targets (Machine and User).

    .EXAMPLE
        Get-SqlDscPreferredModule

        Returns the module name SqlServer if it is installed, otherwise it will
        return SQLPS if is is installed. If neither is installed `$null` is
        returned.

    .EXAMPLE
        Get-SqlDscPreferredModule -Refresh

        Updated the session environment variable PSModulePath and then returns the
        module name SqlServer if it is installed, otherwise it will return SQLPS
        if is is installed. If neither is installed `$null` is returned.

    .EXAMPLE
        Get-SqlDscPreferredModule -Name @('MyModule', 'SQLPS')

        Returns the module name MyModule if it is installed, otherwise it will
        return SQLPS if is is installed. If neither is installed `$null` is
        returned.

    .NOTES
        If the module SQLPS is specified (default value) the path is returned as
        the module name. This is because importing 'SQLPS' using simply the name
        could make the wrong version to be imported when several different version
        of SQL Server is installed on the same node. To make sure the correct
        (latest) version is imported the path to the latest version of SQLPS is
        returned. The returned path can be passed directly to the parameter Name
        of the command Import-Module.
#>
function Get-SqlDscPreferredModule
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String[]]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Refresh
    )

    if (-not $PSBoundParameters.ContainsKey('Name'))
    {
        if ($env:SMODefaultModuleName)
        {
            $Name = @($env:SMODefaultModuleName, 'SQLPS')
        }
        else
        {
            $Name = @('SqlServer', 'SQLPS')
        }
    }

    if ($Refresh.IsPresent)
    {
        # Only run on Windows that has Machine state.
        if (-not ($IsLinux -or $IsMacOS))
        {
            <#
                After installing SQL Server the current PowerShell session doesn't know
                about the new path that was added for the SQLPS module. This reloads
                PowerShell session environment variable PSModulePath to make sure it
                contains all paths.
            #>

            $modulePath = Get-PSModulePath -FromTarget 'Session', 'User', 'Machine'

            Set-PSModulePath -Path $modulePath
        }
    }

    $availableModuleName = $null

    $availableModule = Get-Module -FullyQualifiedName $Name -ListAvailable |
        Select-Object -Property @(
            'Name',
            'Path',
            @{
                Name       = 'Version'
                Expression = {
                    if ($_.Name -eq 'SQLPS')
                    {
                        <#
                            Parse the build version number '120', '130' from the Path.
                            Older version of SQLPS did not have correct versioning.
                        #>
                        (Select-String -InputObject $_.Path -Pattern '\\([0-9]{3})\\' -List).Matches.Groups[1].Value
                    }
                    else
                    {
                        $versionToReturn = $_.Version

                        if ($_.ContainsKey('PrivateData') -and $_.PrivateData.ContainsKey('PSData') -and $_.PrivateData.PSData.ContainsKey('Prerelease'))
                        {
                            if (-not [System.String]::IsNullOrEmpty($_.PrivateData.PSData.Prerelease))
                            {
                                $versionToReturn = '{0}-{1}' -f $_.Version, $_.PrivateData.PSData.Prerelease
                            }
                        }

                        $versionToReturn
                    }
                }
            }
        )

    Write-Verbose -Message ('Get-SqlDscPreferredModule Available Modules: {0}' -f ($availableModule | Out-String)) -Verbose

    foreach ($preferredModuleName in $Name)
    {
        $preferredModule = $availableModule |
            Where-Object -Property 'Name' -EQ -Value $preferredModuleName

        Write-Verbose -Message ('PreferredModuleName: {0}' -f $preferredModuleName) -Verbose
        Write-Verbose -Message ('Found PreferredModule: {0}' -f ($preferredModule | Out-String)) -Verbose

        if ($preferredModule)
        {
            if ($preferredModule.Name -eq 'SQLPS')
            {
                # Get the latest version if available.
                $preferredModule = $preferredModule |
                    Sort-Object -Property 'Version' -Descending |
                    Select-Object -First 1

                <#
                    For SQLPS the path to the module need to be returned as the
                    module name to be absolutely sure the latest version is used.
                #>
                $availableModuleName = Split-Path -Path $preferredModule.Path -Parent
            }
            else
            {
                $availableModuleName = ($preferredModule | Select-Object -First 1).Name
            }

            Write-Verbose -Message ($script:localizedData.PreferredModule_ModuleFound -f $availableModuleName)

            break
        }
    }

    if (-not $availableModuleName)
    {
        $errorMessage = $script:localizedData.PreferredModule_ModuleNotFound

        # cSpell: disable-next
        Write-Error -Message $errorMessage -Category 'ObjectNotFound' -ErrorId 'GSDPM0001' -TargetObject ($Name -join ', ')
    }

    return $availableModuleName
}
