<#
    .SYNOPSIS
        Add a SQL Server node to an Failover Cluster instance (FCI).

    .DESCRIPTION
        Add a SQL Server node to an Failover Cluster instance (FCI).

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

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .PARAMETER Force
        If specified the command will not ask for confirmation. Same as if Confirm:$false
        is used.

    .PARAMETER IAcknowledgeEntCalLimits
        See the notes section for more information.

    .PARAMETER InstanceName
        See the notes section for more information.

    .PARAMETER Enu
        See the notes section for more information.

    .PARAMETER UpdateEnabled
        See the notes section for more information.

    .PARAMETER UpdateSource
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

    .PARAMETER ProductKey
        See the notes section for more information.

    .PARAMETER AgtSvcAccount
        See the notes section for more information.

    .PARAMETER AgtSvcPassword
        See the notes section for more information.

    .PARAMETER ASSvcAccount
        See the notes section for more information.

    .PARAMETER ASSvcPassword
        See the notes section for more information.

    .PARAMETER SqlSvcAccount
        See the notes section for more information.

    .PARAMETER SqlSvcPassword
        See the notes section for more information.

    .PARAMETER ISSvcAccount
        See the notes section for more information.

    .PARAMETER ISSvcPassword
        See the notes section for more information.

    .PARAMETER RsInstallMode
        See the notes section for more information.

    .PARAMETER RSSvcAccount
        See the notes section for more information.

    .PARAMETER RSSvcPassword
        See the notes section for more information.

    .PARAMETER FailoverClusterIPAddresses
        See the notes section for more information.

    .PARAMETER ConfirmIPDependencyChange
        See the notes section for more information.

    .PARAMETER ProductCoveredBySA
        See the notes section for more information.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Add-SqlDscNode -AcceptLicensingTerms -InstanceName 'MyInstance' -FailoverClusterIPAddresses 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0' -MediaPath 'E:\'

        Adds the current node's SQL Server instance 'MyInstance' to the Failover Cluster instance.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.
#>
function Add-SqlDscNode
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in Invoke-SetupAction')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in Invoke-SetupAction')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $AcceptLicensingTerms,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IAcknowledgeEntCalLimits,

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
        [System.String]
        $ProductKey, # This is argument PID but $PID is reserved variable.

        [Parameter()]
        [System.String]
        $AgtSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $AgtSvcPassword,

        [Parameter()]
        [System.String]
        $ASSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $ASSvcPassword,

        [Parameter()]
        [System.String]
        $SqlSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $SqlSvcPassword,

        [Parameter()]
        [System.String]
        $ISSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $ISSvcPassword,

        [Parameter()]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.String]
        $RsInstallMode,

        [Parameter()]
        [System.String]
        $RSSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $RSSvcPassword,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FailoverClusterIPAddresses,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ConfirmIPDependencyChange,

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

    Invoke-SetupAction -AddNode @PSBoundParameters -ErrorAction 'Stop'
}
