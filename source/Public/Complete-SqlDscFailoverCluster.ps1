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

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .PARAMETER Force
        If specified the command will not ask for confirmation. Same as if Confirm:$false
        is used.

    .PARAMETER InstanceName
        See notes section.

    .PARAMETER Enu
        See notes section.

    .PARAMETER ProductKey
        See notes section.

    .PARAMETER ASBackupDir
        See notes section.

    .PARAMETER ASCollation
        See notes section.

    .PARAMETER ASConfigDir
        See notes section.

    .PARAMETER ASDataDir
        See notes section.

    .PARAMETER ASLogDir
        See notes section.

    .PARAMETER ASTempDir
        See notes section.

    .PARAMETER ASServerMode
        See notes section.

    .PARAMETER ASSysAdminAccounts
        See notes section.

    .PARAMETER ASProviderMSOLAP
        See notes section.

    .PARAMETER InstallSqlDataDir
        See notes section.

    .PARAMETER SqlBackupDir
        See notes section.

    .PARAMETER SecurityMode
        See notes section.

    .PARAMETER SAPwd
        See notes section.

    .PARAMETER SqlCollation
        See notes section.

    .PARAMETER SqlSysAdminAccounts
        See notes section.

    .PARAMETER SqlTempDbDir
        See notes section.

    .PARAMETER SqlTempDbLogDir
        See notes section.

    .PARAMETER SqlTempDbFileCount
        See notes section.

    .PARAMETER SqlTempDbFileSize
        See notes section.

    .PARAMETER SqlTempDbFileGrowth
        See notes section.

    .PARAMETER SqlTempDbLogFileSize
        See notes section.

    .PARAMETER SqlTempDbLogFileGrowth
        See notes section.

    .PARAMETER SqlUserDbDir
        See notes section.

    .PARAMETER SqlUserDbLogDir
        See notes section.

    .PARAMETER RsInstallMode
        See notes section.

    .PARAMETER FailoverClusterGroup
        See notes section.

    .PARAMETER FailoverClusterDisks
        See notes section.

    .PARAMETER FailoverClusterNetworkName
        See notes section.

    .PARAMETER FailoverClusterIPAddresses
        See notes section.

    .PARAMETER ConfirmIPDependencyChange
        See notes section.

    .PARAMETER ProductCoveredBySA
        See notes section.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Complete-SqlDscFailoverCluster -InstanceName 'MyInstance' -InstallSqlDataDir 'D:\MSSQL\Data' -SqlSysAdminAccounts @('MyAdminAccount') -FailoverClusterNetworkName 'TestCluster01A' -FailoverClusterIPAddresses 'IPv4;192.168.0.46;ClusterNetwork1;255.255.255.0' -MediaPath 'E:\'

        Completes the installation of the SQL Server instance 'MyInstance' in the
        Failover Cluster instance.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.
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
        [System.Management.Automation.SwitchParameter]
        $ProductCoveredBySA,

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Invoke-SetupAction -CompleteFailoverCluster @PSBoundParameters -ErrorAction 'Stop'
}
