<#
    .SYNOPSIS
        Imports a (preferred) module in a standardized way.

    .DESCRIPTION
        Imports a (preferred) module in a standardized way. If the parameter `Name`
        is not specified the command will imports the default module SqlServer
        if it exist, otherwise SQLPS.

        If the environment variable `SMODefaultModuleName` is set to a module name
        that name will be used as the preferred module name instead of the default
        module 'SqlServer'.

        The module is always imported globally.

    .PARAMETER Name
        Specifies the name of a preferred module.

    .PARAMETER Force
        Forces the removal of the previous module, to load the same or newer version
        fresh. This is meant to make sure the newest version is used, with the latest
        assemblies.

    .EXAMPLE
        Import-SqlDscPreferredModule

        Imports the default preferred module (SqlServer) if it exist, otherwise
        it will try to import the module SQLPS.

    .EXAMPLE
        Import-SqlDscPreferredModule -Force

        Will forcibly import the default preferred module if it exist, otherwise
        it will try to import the module SQLPS. Prior to importing it will remove
        an already loaded module.

    .EXAMPLE
        Import-SqlDscPreferredModule -Name 'OtherSqlModule'

        Imports the specified preferred module OtherSqlModule if it exist, otherwise
        it will try to import the module SQLPS.
#>
function Import-SqlDscPreferredModule
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Alias('PreferredModule')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $getSqlDscPreferredModuleParameters = @{
        Refresh = $true
    }

    if ($PSBoundParameters.ContainsKey('Name'))
    {
        $getSqlDscPreferredModuleParameters.Name = @($Name, 'SQLPS')
    }

    $availableModuleName = Get-SqlDscPreferredModule @getSqlDscPreferredModuleParameters

    if ($Force.IsPresent)
    {
        Write-Verbose -Message $script:localizedData.PreferredModule_ForceRemoval

        $removeModule = @()

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $removeModule += $Name
        }

        # Available module could be
        if ($availableModuleName)
        {
            $removeModule += $availableModuleName
        }

        if ($removeModule -contains 'SQLPS')
        {
            $removeModule += 'SQLASCmdlets' # cSpell: disable-line
        }

        Remove-Module -Name $removeModule -Force -ErrorAction 'SilentlyContinue'
    }

    if ($availableModuleName)
    {
        if (-not $Force.IsPresent)
        {
            # Check if the preferred module is already loaded into the session.
            $loadedModuleName = (Get-Module -Name $availableModuleName | Select-Object -First 1).Name

            if ($loadedModuleName)
            {
                Write-Verbose -Message ($script:localizedData.PreferredModule_AlreadyImported -f $loadedModuleName)

                return
            }
        }

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
            if ($availableModuleName -eq 'SQLPS')
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
                ($script:localizedData.PreferredModule_FailedFinding),
                'ISDPM0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'PreferredModule'
            )
        )
    }
}
