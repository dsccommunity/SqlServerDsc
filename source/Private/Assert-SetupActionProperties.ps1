<#
    .SYNOPSIS
        Assert that the bound parameters are set as required

    .DESCRIPTION
        Assert that required parameters has been specified, and throws an exception if not.

    .PARAMETER Property
       A hashtable containing the parameters to evaluate. Normally this is set to
       $PSBoundParameters.

    .PARAMETER SetupAction
       A string value representing the setup action that is gonna be executed.

    .EXAMPLE
        Assert-SetupActionProperties -Property $PSBoundParameters -SetupAction 'Install'

        Throws an exception if the bound parameters are not in the correct state.

    .OUTPUTS
        None.

    .NOTES
        This function is used by the command Invoke-SetupAction to verify that
        the bound parameters are in the required state.
#>
function Assert-SetupActionProperties
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The command uses plural noun to describe that it contain a collection of asserts.')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Property,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetupAction
    )

    if ($Property.ContainsKey('Features'))
    {
        $setupExecutableFileVersion = $Property.MediaPath |
            Join-Path -ChildPath 'setup.exe' |
            Get-FileVersionInformation

        $Property.Features |
            Assert-Feature -ProductVersion $setupExecutableFileVersion.ProductVersion
    }

    # If one of the properties PBStartPortRange and PBEndPortRange are specified, then both must be specified.
    $assertParameters = @('PBStartPortRange', 'PBEndPortRange')

    $assertRequiredCommandParameterParameters = @{
        BoundParameterList = $Property
        RequiredParameter  = $assertParameters
        IfParameterPresent = $assertParameters
    }

    Assert-BoundParameter @assertRequiredCommandParameterParameters

    # The parameter UseSqlRecommendedMemoryLimits is mutually exclusive to SqlMinMemory and SqlMaxMemory.
    Assert-BoundParameter -BoundParameterList $Property -MutuallyExclusiveList1 @(
        'UseSqlRecommendedMemoryLimits'
    ) -MutuallyExclusiveList2 @(
        'SqlMinMemory'
        'SqlMaxMemory'
    )

    # If Role is set to SPI_AS_NewFarm then the specific parameters are required.
    if ($Property.ContainsKey('Role') -and $Property.Role -eq 'SPI_AS_NewFarm')
    {
        Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @(
            'FarmAccount'
            'FarmPassword'
            'Passphrase'
            'FarmAdminiPort' # cspell: disable-line
        )
    }

    # If the parameter SecurityMode is set to 'SQL' then the parameter SAPwd is required.
    if ($Property.ContainsKey('SecurityMode') -and $Property.SecurityMode -eq 'SQL')
    {
        Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @('SAPwd')
    }

    # If the parameter FileStreamLevel is set and is greater or equal to 2 then the parameter FileStreamShareName is required.
    if ($Property.ContainsKey('FileStreamLevel') -and $Property.FileStreamLevel -ge 2)
    {
        Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @('FileStreamShareName')
    }

    # If a *SvcAccount is specified then the accompanying *SvcPassword must be set unless it is a (global) managed service account, virtual account, or a built-in account.
    $accountProperty = @(
        'PBEngSvcAccount'
        'PBDMSSvcAccount' # cSpell: disable-line
        'AgtSvcAccount'
        'ASSvcAccount'
        'FarmAccount'
        'SqlSvcAccount'
        'ISSvcAccount'
        'RSSvcAccount'
    )

    foreach ($currentAccountProperty in $accountProperty)
    {
        if ($currentAccountProperty -in $Property.Keys)
        {
            # If not (global) managed service account, virtual account, or a built-in account.
            if ((Test-AccountRequirePassword -Name $Property.$currentAccountProperty))
            {
                $assertPropertyName = $currentAccountProperty -replace 'Account', 'Password'

                Assert-BoundParameter -BoundParameterList $Property -RequiredParameter $assertPropertyName
            }
        }
    }

    # If feature AzureExtension is specified then the all the Azure* parameters must be set (except AzureArcProxy).
    if ($Property.ContainsKey('Features') -and $Property.Features -contains 'AZUREEXTENSION') # cSpell: disable-line
    {
        Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @(
            'AzureSubscriptionId'
            'AzureResourceGroup'
            'AzureRegion'
            'AzureTenantId'
            'AzureServicePrincipal'
            'AzureServicePrincipalSecret'
            'ProductCoveredBySA'
        )
    }

    # If feature is SQLENGINE, then for specified setup actions the parameter AgtSvcAccount is mandatory.
    if ($SetupAction -in ('CompleteImage', 'InstallFailoverCluster', 'PrepareFailoverCluster', 'AddNode'))
    {
        if ($Property.ContainsKey('Features') -and $Property.Features -contains 'SQLENGINE')
        {
            Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @('AgtSvcAccount')
        }
    }

    if ($SetupAction -in ('InstallFailoverCluster', 'PrepareFailoverCluster', 'AddNode'))
    {
        # The parameter ASSvcAccount is mandatory if feature AS is installed and setup action is InstallFailoverCluster, PrepareFailoverCluster, or AddNode.
        if ($Property.ContainsKey('Features') -and $Property.Features -contains 'AS')
        {
            Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @('ASSvcAccount')
        }

        # The parameter SqlSvcAccount is mandatory if feature SQLENGINE is installed and setup action is InstallFailoverCluster, PrepareFailoverCluster, or AddNode.
        if ($Property.ContainsKey('Features') -and $Property.Features -contains 'SQLENGINE')
        {
            Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @('SqlSvcAccount')
        }

        # The parameter ISSvcAccount is mandatory if feature IS is installed and setup action is InstallFailoverCluster, PrepareFailoverCluster, or AddNode.
        if ($Property.ContainsKey('Features') -and $Property.Features -contains 'IS')
        {
            Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @('ISSvcAccount')
        }

        if ($Property.ContainsKey('Features') -and $Property.Features -contains 'RS')
        {
            Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @('RSSvcAccount')
        }
    }

    # The ASServerMode value PowerPivot is not allowed when parameter set is InstallFailoverCluster or CompleteFailoverCluster.
    if ($SetupAction -in ('InstallFailoverCluster', 'CompleteFailoverCluster'))
    {
        if ($Property.ContainsKey('ASServerMode') -and $Property.ASServerMode -eq 'PowerPivot')
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.InstallSqlServerProperties_ASServerModeInvalidValue -f $SetupAction),
                    'ASAP0001', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    'Command parameters'
                )
            )
        }
    }

    # The ASServerMode value PowerPivot is not allowed when parameter set is InstallFailoverCluster or CompleteFailoverCluster.
    if ($SetupAction -in ('AddNode'))
    {
        if ($Property.ContainsKey('RsInstallMode') -and $Property.RsInstallMode -ne 'FilesOnlyMode')
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.InstallSqlServerProperties_RsInstallModeInvalidValue -f $SetupAction),
                    'ASAP0002', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    'Command parameters'
                )
            )
        }
    }

    if ($SetupAction -in ('Install'))
    {
        if ($Property.ContainsKey('Features') -and $Property.Features -contains 'SQLENGINE')
        {
            Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @(
                'SqlSysAdminAccounts'
            )
        }

        if ($Property.ContainsKey('Features') -and $Property.Features -contains 'AS')
        {
            Assert-BoundParameter -BoundParameterList $Property -RequiredParameter @(
                'ASSysAdminAccounts'
            )
        }
    }
}
