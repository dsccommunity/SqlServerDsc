<#
    .SYNOPSIS
        Upgrades a SQL Server instance to a newer version.

    .DESCRIPTION
        Upgrades a SQL Server instance to a newer version using the Microsoft
        SQL Server setup executable. This command performs an in-place upgrade
        of an existing SQL Server instance.

        See the link in the commands help for information on each parameter. The
        link points to SQL Server command line setup documentation.

    .PARAMETER AcceptLicensingTerms
        Required parameter to be able to run unattended install. By specifying this
        parameter you acknowledge the acceptance all license terms and notices for
        the specified features, the terms and notices that the Microsoft SQL Server
        setup executable normally ask for.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .PARAMETER InstanceName
        See the notes section for more information.

    .PARAMETER Enu
        See the notes section for more information.

    .PARAMETER UpdateEnabled
        See the notes section for more information.

    .PARAMETER UpdateSource
        See the notes section for more information.

    .PARAMETER InstanceDir
        See the notes section for more information.

    .PARAMETER InstanceId
        See the notes section for more information.

    .PARAMETER ProductKey
        See the notes section for more information.

    .PARAMETER BrowserSvcStartupType
        See the notes section for more information.

    .PARAMETER FTUpgradeOption
        See the notes section for more information.

    .PARAMETER ISSvcAccount
        See the notes section for more information.

    .PARAMETER ISSvcPassword
        See the notes section for more information.

    .PARAMETER ISSvcStartupType
        See the notes section for more information.

    .PARAMETER AllowUpgradeForSSRSSharePointMode
        See the notes section for more information.

    .PARAMETER AllowDqRemoval
        Specifies whether to allow removal of Data Quality (DQ) Services during
        upgrade to SQL Server 2025 (17.x) and later versions.

    .PARAMETER FailoverClusterRollOwnership
        See the notes section for more information.

    .PARAMETER ProductCoveredBySA
        See the notes section for more information.

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .PARAMETER Force
        If specified the command will not ask for confirmation. Same as if Confirm:$false
        is used.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        Update-SqlDscServer -AcceptLicensingTerms -InstanceName 'MyInstance' -MediaPath 'E:\'

        Upgrades the instance 'MyInstance' with the SQL Server version that is provided by the media path.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.
#>
function Update-SqlDscServer
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in Invoke-SetupAction')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $AcceptLicensingTerms,

        [Parameter(Mandatory = $true)]
        [System.String]
        $MediaPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Enu,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UpdateEnabled,

        [Parameter()]
        [System.String]
        $UpdateSource,

        [Parameter()]
        [System.String]
        $InstanceDir,

        [Parameter()]
        [System.String]
        $InstanceId,

        [Parameter()]
        [System.String]
        $ProductKey,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $BrowserSvcStartupType,

        [Parameter()]
        [ValidateSet('Rebuild', 'Reset', 'Import')]
        [System.String]
        $FTUpgradeOption,

        [Parameter()]
        [System.String]
        $ISSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $ISSvcPassword,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $ISSvcStartupType,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AllowUpgradeForSSRSSharePointMode,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AllowDqRemoval,

        [Parameter()]
        [ValidateRange(0, 2)]
        [System.UInt16]
        $FailoverClusterRollOwnership,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ProductCoveredBySA,

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Invoke-SetupAction -Upgrade @PSBoundParameters
}
