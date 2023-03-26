<#
    .SYNOPSIS
        Imports the module SqlServer (preferred) or SQLPS in a standardized way.

    .DESCRIPTION
        Imports the module SqlServer (preferred) or SQLPS in a standardized way.
        The module is always imported globally.

    .PARAMETER PreferredModule
        Specifies the name of the preferred module. Defaults to 'SqlServer'.

    .PARAMETER Force
        Forces the removal of the previous SQL module, to load the same or newer
        version fresh. This is meant to make sure the newest version is used, with
        the latest assemblies.

    .EXAMPLE
        Import-SqlDscPreferredModule

        Imports the default preferred module (SqlServer) if it exist, otherwise
        it will try to import the module SQLPS.

    .EXAMPLE
        Import-SqlDscPreferredModule -Force

        Removes any already loaded module of the default preferred module (SqlServer)
        and the module SQLPS, then it will forcibly import the default preferred
        module if it exist, otherwise it will try to import the module SQLPS.

    .EXAMPLE
        Import-SqlDscPreferredModule -PreferredModule 'OtherSqlModule'

        Imports the specified preferred module OtherSqlModule if it exist, otherwise
        it will try to import the module SQLPS.
#>
function Import-SqlDscPreferredModule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $PreferredModule = 'SqlServer',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent)
    {
        Write-Verbose -Message $script:localizedData.PreferredModule_ForceRemoval

        Remove-Module -Name @(
            $PreferredModule,
            'SQLPS',
            'SQLASCmdlets' # cSpell: disable-line
        ) -Force -ErrorAction 'SilentlyContinue'
    }
    else
    {
        <#
            Check if either of the modules are already loaded into the session.
            Prefer to use the first one (in order found).
            NOTE: There should actually only be either SqlServer or SQLPS loaded,
            otherwise there can be problems with wrong assemblies being loaded.
        #>
        $loadedModuleName = (Get-Module -Name @($PreferredModule, 'SQLPS') | Select-Object -First 1).Name

        if ($loadedModuleName)
        {
            Write-Verbose -Message ($script:localizedData.PreferredModule_AlreadyImported -f $loadedModuleName)

            return
        }
    }

    $availableModuleName = $null

    # Get the newest SqlServer module if more than one exist
    $availableModule = Get-Module -FullyQualifiedName $PreferredModule -ListAvailable |
        Sort-Object -Property 'Version' -Descending |
        Select-Object -First 1 -Property 'Name', 'Path', 'Version'

    if ($availableModule)
    {
        $availableModuleName = $availableModule.Name

        Write-Verbose -Message ($script:localizedData.PreferredModule_ModuleFound -f $availableModuleName)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.PreferredModule_ModuleNotFound)

        # Only run on Windows that has Machine state.
        if (-not ($IsLinux -or $IsMacOS))
        {
            <#
                After installing SQL Server the current PowerShell session doesn't know
                about the new path that was added for the SQLPS module. This reloads
                PowerShell session environment variable PSModulePath to make sure it
                contains all paths.
            #>

            <#
                Get the environment variables from all targets session, user and machine.
                Casts the value to System.String to convert $null values to empty string.
            #>
            $modulePathSession = [System.String] [System.Environment]::GetEnvironmentVariable('PSModulePath')
            $modulePathUser = [System.String] [System.Environment]::GetEnvironmentVariable('PSModulePath', 'User')
            $modulePathMachine = [System.String] [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')

            $modulePath = $modulePathSession, $modulePathUser, $modulePathMachine -join ';'

            $modulePathArray = $modulePath -split ';' |
                Where-Object -FilterScript {
                    -not [System.String]::IsNullOrEmpty($_)
                } |
                Sort-Object -Unique

            $modulePath = $modulePathArray -join ';'

            Set-PSModulePath -Path $modulePath
        }

        # Get the newest SQLPS module if more than one exist.
        $availableModule = Get-Module -FullyQualifiedName 'SQLPS' -ListAvailable |
            Select-Object -Property Name, Path, @{
                Name       = 'Version'
                Expression = {
                    # Parse the build version number '120', '130' from the Path.
                    (Select-String -InputObject $_.Path -Pattern '\\([0-9]{3})\\' -List).Matches.Groups[1].Value
                }
            } |
            Sort-Object -Property 'Version' -Descending |
            Select-Object -First 1

        if ($availableModule)
        {
            # This sets $availableModuleName to the Path of the module to be loaded.
            $availableModuleName = Split-Path -Path $availableModule.Path -Parent
        }
    }

    if ($availableModuleName)
    {
        try
        {
            Write-Debug -Message ($script:localizedData.PreferredModule_PushingLocation)

            Push-Location

            <#
                SQLPS has unapproved verbs, disable checking to ignore Warnings.
                Suppressing verbose so all cmdlet is not listed.
            #>
            $importedModule = Import-Module -Name $availableModuleName -DisableNameChecking -Verbose:$false -Force:$Force -Global -PassThru -ErrorAction 'Stop'

            <#
                SQLPS returns two entries, one with module type 'Script' and another with module type 'Manifest'.
                Only return the object with module type 'Manifest'.
                SqlServer only returns one object (of module type 'Script'), so no need to do anything for SqlServer module.
            #>
            if ($availableModuleName -ne $PreferredModule)
            {
                $importedModule = $importedModule | Where-Object -Property 'ModuleType' -EQ -Value 'Manifest'
            }

            Write-Verbose -Message ($script:localizedData.PreferredModule_ImportedModule -f $importedModule.Name, $importedModule.Version, $importedModule.Path)
        }
        finally
        {
            Write-Debug -Message ($script:localizedData.PreferredModule_PoppingLocation)

            Pop-Location
        }
    }
    else
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                ($script:localizedData.PreferredModule_FailedFinding -f $PreferredModule),
                'ISDPM0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'PreferredModule'
            )
        )
    }
}
