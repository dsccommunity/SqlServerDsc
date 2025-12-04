<#
    .SYNOPSIS
        Executes an setup action using Microsoft SQL Server setup executable.

    .DESCRIPTION
        Executes an setup action using Microsoft SQL Server setup executable.

        See the link in the commands help for information on each parameter. The
        link points to SQL Server command line setup documentation.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .PARAMETER Force
        If specified the command will not ask for confirmation. Same as if Confirm:$false
        is used.

    .PARAMETER InstanceName
        See the notes section for more information.

    .PARAMETER Enu
        See the notes section for more information.

    .PARAMETER PBEngSvcAccount
        See the notes section for more information.

    .PARAMETER PBEngSvcPassword
        See the notes section for more information.

    .PARAMETER PBEngSvcStartupType
        See the notes section for more information.

    .PARAMETER PBStartPortRange
        See the notes section for more information.

    .PARAMETER PBEndPortRange
        See the notes section for more information.

    .PARAMETER PBScaleOut
        See the notes section for more information.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .INPUTS
        None.

    .OUTPUTS
        None.

    .EXAMPLE
        Repair-SqlDscServer -InstanceName 'MyInstance' -MediaPath 'E:\'

        Repairs all installed features of the instance 'MyInstance'.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.

        SQL Server Repair action does not accept the FEATURES parameter. Although
        Microsoft's documentation lists /FEATURES as required for the Repair action,
        the actual SQL Server setup executable (tested with SQL Server 2017 and
        SQL Server 2022) rejects this parameter with the error: "The setting
        'FEATURES' is not allowed when the value of setting 'ACTION' is 'Repair'."
        SQL Server automatically repairs all installed features during a repair
        operation.
#>
function Repair-SqlDscServer
{
    # cSpell: ignore AZUREEXTENSION
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in Invoke-SetupAction')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
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
        [System.String]
        $PBEngSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $PBEngSvcPassword,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $PBEngSvcStartupType,

        [Parameter()]
        [System.UInt16]
        $PBStartPortRange,

        [Parameter()]
        [System.UInt16]
        $PBEndPortRange,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PBScaleOut,

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Invoke-SetupAction -Repair @PSBoundParameters
}
