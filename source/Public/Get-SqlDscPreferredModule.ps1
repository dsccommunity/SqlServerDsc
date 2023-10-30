<#
    .SYNOPSIS
        Get the first available (preferred) module that is installed.

    .DESCRIPTION
        Get the first available (preferred) module that is installed.

        If the environment variable `SMODefaultModuleName` is set to a module name
        that name will be used as the preferred module name instead of the default
        module 'SqlServer'.

        If the envrionment variable `SMODefaultModuleVersion` is set, then that
        specific version of the preferred module will be searched for.

    .PARAMETER Name
        Specifies the list of the (preferred) modules to search for, in order.
        Defaults to 'SqlServer' and then 'SQLPS'.

    .PARAMETER Refresh
        Specifies if the session environment variable PSModulePath should be refreshed
        with the paths from other environment variable targets (Machine and User).

    .EXAMPLE
        Get-SqlDscPreferredModule

        Returns the SqlServer PSModuleInfo object if it is installed, otherwise it
        will return SQLPS PSModuleInfo object if is is installed. If neither is
        installed `$null` is returned.

    .EXAMPLE
        Get-SqlDscPreferredModule -Refresh

        Updates the session environment variable PSModulePath and then returns the
        SqlServer PSModuleInfo object if it is installed, otherwise it will return SQLPS
        PSModuleInfo object if is is installed. If neither is installed `$null` is
        returned.

    .EXAMPLE
        Get-SqlDscPreferredModule -Name @('MyModule', 'SQLPS')

        Returns the MyModule PSModuleInfo object if it is installed, otherwise it will
        return SQLPS PSModuleInfo object if is is installed. If neither is installed
        `$null` is returned.

    .NOTES

#>
function Get-SqlDscPreferredModule
{
    [OutputType([PSModuleInfo])]
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

    $availableModule = $null

    $availableModules = Get-Module -Name $Name -ListAvailable |
        ForEach-Object -Process {
            @{
                PSModuleInfo = $_
                CalculatedVersion = $_ | Get-SMOModuleCalculatedVersion
            }
        }

    foreach ($preferredModuleName in $Name)
    {
        $preferredModules = $availableModules |
            Where-Object -FilterScript { $_.PSModuleInfo.Name -eq $preferredModuleName }

        if ($preferredModules)
        {
            if ($env:SMODefaultModuleVersion)
            {
                # Get the version specified in $env:SMODefaultModuleVersion if available
                $availableModule = $preferredModules |
                    Where-Object -FilterScript { $_.CalculatedVersion -eq $env:SMODefaultModuleVersion } |
                    Select-Object -First 1
            }
            else
            {
                # Get the latest version if available
                $availableModule = $preferredModules |
                    Sort-Object -Property { ($_.CalculatedVersion -replace '-.+$') -as [System.Version] }, { $_.CalculatedVersion } -Descending |
                    Select-Object -First 1
            }

            Write-Verbose -Message ($script:localizedData.PreferredModule_ModuleVersionFound -f $availableModule.PSModuleInfo.Name, $availableModule.CalculatedVersion)

            break
        }
    }

    if (-not $availableModule)
    {
        $errorMessage = $null

        if ($env:SMODefaultModuleVersion)
        {
            $errorMessage = $script:localizedData.PreferredModule_ModuleVersionNotFound -f $env:SMODefaultModuleVersion
        }
        else
        {
            $errorMessage = $script:localizedData.PreferredModule_ModuleNotFound
        }

        # cSpell: disable-next
        Write-Error -Message $errorMessage -Category 'ObjectNotFound' -ErrorId 'GSDPM0001' -TargetObject ($Name -join ', ')
    }

    return $availableModule.PSModuleInfo
}
