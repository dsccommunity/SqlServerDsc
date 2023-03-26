<#
    .SYNOPSIS
        Removes a SQL Server node from an Failover Cluster instance (FCI).

    .DESCRIPTION
        Removes a SQL Server node from an Failover Cluster instance (FCI).

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

    .PARAMETER ConfirmIPDependencyChange
        See the notes section for more information.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Remove-SqlDscNode -InstanceName 'MyInstance' -MediaPath 'E:\'

        Removes the current node's SQL Server instance 'MyInstance' from the
        Failover Cluster instance.

    .NOTES
        All parameters has intentionally not been added to this comment-based help
        since it would take a lot of effort to keep them up to date. Instead there is
        a link in the comment-based help that points to the SQL Server command line
        setup documentation which will stay relevant.
#>
function Remove-SqlDscNode
{
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
        $ConfirmIPDependencyChange,

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Invoke-SetupAction -RemoveNode @PSBoundParameters -ErrorAction 'Stop'
}
