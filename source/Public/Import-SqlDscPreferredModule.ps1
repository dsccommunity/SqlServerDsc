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

    if ($PSBoundParameters.ContainsKey('Force'))
    {
        $getSqlDscPreferredModuleParameters.Refresh = $true
    }

    $availableModule = $null

    try
    {
        $availableModule = Get-SqlDscPreferredModule @getSqlDscPreferredModuleParameters -ErrorAction 'Stop'
    }
    catch
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

    if ($Force.IsPresent -and -not $Confirm)
    {
        Write-Verbose -Message $script:localizedData.PreferredModule_ForceRemoval

        $removeModule = @()

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $removeModule += Get-Module -Name $Name
        }

        # Available module could be
        if ($availableModule)
        {
            $removeModule += $availableModule
        }

        if ($removeModule -contains 'SQLPS')
        {
            $removeModule += Get-Module -Name 'SQLASCmdlets' # cSpell: disable-line
        }

        Remove-Module -ModuleInfo $removeModule -Force -ErrorAction 'SilentlyContinue'
    }
    else
    {
        <#
            Check if the preferred module is already loaded into the session.
        #>
        $loadedModule = Get-Module -Name $availableModule.Name | Select-Object -First 1

        if ($loadedModule)
        {
            Write-Verbose -Message ($script:localizedData.PreferredModule_AlreadyImported -f $loadedModule.Name)

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
        $importedModule = Import-Module -ModuleInfo $availableModule -DisableNameChecking -Verbose:$false -Force:$Force -Global -PassThru -ErrorAction 'Stop'

        <#
            SQLPS returns two entries, one with module type 'Script' and another with module type 'Manifest'.
            Only return the object with module type 'Manifest'.
            SqlServer only returns one object (of module type 'Script'), so no need to do anything for SqlServer module.
        #>
        if ($availableModule.Name -eq 'SQLPS')
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
