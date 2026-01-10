<#
    .SYNOPSIS
        Upgrades a SQL Server instance to a different edition.

    .DESCRIPTION
        Upgrades a SQL Server instance to a different edition using the Microsoft
        SQL Server setup executable. This command performs an edition upgrade
        (for example, from Evaluation to Standard or Enterprise edition).

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

    .PARAMETER ProductKey
        See the notes section for more information.

    .PARAMETER SkipRules
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
        Update-SqlDscServerEdition -AcceptLicensingTerms -ProductKey 'NewEditionProductKey' -InstanceName 'MyInstance' -MediaPath 'E:\'

        Upgrades the instance 'MyInstance' with the SQL Server edition that is provided by the product key.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.
#>
function Update-SqlDscServerEdition
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ProductKey,

        [Parameter()]
        [System.String[]]
        $SkipRules,

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

    Invoke-SetupAction -EditionUpgrade @PSBoundParameters
}
