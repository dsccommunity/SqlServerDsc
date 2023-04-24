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
        [ValidateNotNullOrEmpty]
        [System.String]
        $PreferredModule,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $getSqlDscPreferredModuleParameters = @{
        Refresh = $true
    }

    if ($PSBoundParameters.ContainsKey('PreferredModule'))
    {
        $getSqlDscPreferredModuleParameters.PreferredModule = $PreferredModule
    }

    $availableModuleName = Get-SqlDscPreferredModule @getSqlDscPreferredModuleParameters

    if ($Force.IsPresent)
    {
        Write-Verbose -Message $script:localizedData.PreferredModule_ForceRemoval

        $removeModule = @()

        if ($PSBoundParameters.ContainsKey('PreferredModule'))
        {
            $removeModule += $PreferredModule
        }

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
    else
    {
        <#
            Check if either of the modules are already loaded into the session.
            Prefer to use the first one (in order found).
            NOTE: There should actually only be either SqlServer or SQLPS loaded,
            otherwise there can be problems with wrong assemblies being loaded.
        #>
        $loadedModuleName = (Get-Module -Name $PreferredModule | Select-Object -First 1).Name

        if ($loadedModuleName)
        {
            Write-Verbose -Message ($script:localizedData.PreferredModule_AlreadyImported -f $loadedModuleName)

            return
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
                ($script:localizedData.PreferredModule_FailedFinding -f $PreferredModule),
                'ISDPM0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'PreferredModule'
            )
        )
    }
}
