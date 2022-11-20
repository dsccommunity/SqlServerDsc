<#
    .SYNOPSIS
        Completes the SQL Server instance installation in the Failover Cluster
        instance.

    .DESCRIPTION
        Completes the SQL Server instance installation in the Failover Cluster
        instance that was prepared using `Install-SqlDscServer` with the parameter
        `-PrepareFailoverCluster`.

        See the link in the commands help for information on each parameter. The
        link points to SQL Server command line setup documentation.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Complete-SqlDscFailoverCluster -InstanceName 'MyInstance' -InstallSqlDataDir 'D:\MSSQL\Data' -SqlSysAdminAccounts @('MyAdminAccount') -FailoverClusterNetworkName 'TestCluster01A' -FailoverClusterIPAddresses 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0' -MediaPath 'E:\'

        Completes the installation of the SQL Server instance 'MyInstance' in the
        Failover Cluster instance.

    .NOTES
        All parameters has intentionally not been added to this comment-based help
        since it would take a lot of effort to keep it up to date. Instead there is
        a link in the comment-based help that points to the SQL Server command line
        setup documentation which will stay relevant.
#>
function Complete-SqlDscFailoverCluster
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
        $Enu,

        [Parameter()]
        [System.String]
        $ProductKey, # This is argument PID but $PID is reserved variable.

        [Parameter()]
        [System.String]
        $ASBackupDir,

        [Parameter()]
        [System.String]
        $ASCollation,

        [Parameter()]
        [System.String]
        $ASConfigDir,

        [Parameter()]
        [System.String]
        $ASDataDir,

        [Parameter()]
        [System.String]
        $ASLogDir,

        [Parameter()]
        [System.String]
        $ASTempDir,

        [Parameter()]
        [ValidateSet('Multidimensional', 'PowerPivot', 'Tabular')]
        [System.String]
        $ASServerMode,

        [Parameter()]
        [System.String[]]
        $ASSysAdminAccounts,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ASProviderMSOLAP,

        [Parameter(Mandatory = $true)]
        [System.String]
        $InstallSqlDataDir,

        [Parameter()]
        [System.String]
        $SqlBackupDir,

        [Parameter()]
        [ValidateSet('SQL')]
        [System.String]
        $SecurityMode,

        [Parameter()]
        [System.Security.SecureString]
        $SAPwd,

        [Parameter()]
        [System.String]
        $SqlCollation,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $SqlSysAdminAccounts,

        [Parameter()]
        [System.String]
        $SqlTempDbDir,

        [Parameter()]
        [System.String]
        $SqlTempDbLogDir,

        [Parameter()]
        [System.UInt16]
        $SqlTempDbFileCount,

        [Parameter()]
        [ValidateRange(4, 262144)]
        [System.UInt16]
        $SqlTempDbFileSize,

        [Parameter()]
        [ValidateRange(0, 1024)]
        [System.UInt16]
        $SqlTempDbFileGrowth,

        [Parameter()]
        [ValidateRange(4, 262144)]
        [System.UInt16]
        $SqlTempDbLogFileSize,

        [Parameter()]
        [ValidateRange(0, 1024)]
        [System.UInt16]
        $SqlTempDbLogFileGrowth,

        [Parameter()]
        [System.String]
        $SqlUserDbDir,

        [Parameter()]
        [System.String]
        $SqlUserDbLogDir,

        [Parameter()]
        [ValidateSet('SharePointFilesOnlyMode', 'DefaultNativeMode', 'FilesOnlyMode')]
        [System.String]
        $RsInstallMode,

        [Parameter()]
        [System.String]
        $FailoverClusterGroup,

        [Parameter()]
        [System.String[]]
        $FailoverClusterDisks,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FailoverClusterNetworkName,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FailoverClusterIPAddresses,

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

    Invoke-SetupAction -CompleteFailoverCluster @PSBoundParameters -ErrorAction 'Stop'
}
