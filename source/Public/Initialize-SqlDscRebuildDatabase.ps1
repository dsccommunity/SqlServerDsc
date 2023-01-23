<#
    .SYNOPSIS
        Rebuilds the system databases for an SQL Server instance.

    .DESCRIPTION
        Rebuilds the system databases for an SQL Server instance.

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

    .PARAMETER SAPwd
        See the notes section for more information.

    .PARAMETER SqlCollation
        See the notes section for more information.

    .PARAMETER SqlSysAdminAccounts
        See the notes section for more information.

    .PARAMETER SqlTempDbDir
        See the notes section for more information.

    .PARAMETER SqlTempDbLogDir
        See the notes section for more information.

    .PARAMETER SqlTempDbFileCount
        See the notes section for more information.

    .PARAMETER SqlTempDbFileSize
        See the notes section for more information.

    .PARAMETER SqlTempDbFileGrowth
        See the notes section for more information.

    .PARAMETER SqlTempDbLogFileSize
        See the notes section for more information.

    .PARAMETER SqlTempDbLogFileGrowth
        See the notes section for more information.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Initialize-SqlDscRebuildDatabase -InstanceName 'MyInstance' -SqlSysAdminAccounts @('MyAdminAccount') -MediaPath 'E:\'

        Rebuilds the database of the instance 'MyInstance'.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.

        For RebuildDatabase the parameter SAPwd must be set if the instance was
        installed with SecurityMode = 'SQL'.
#>
function Initialize-SqlDscRebuildDatabase
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
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Invoke-SetupAction -RebuildDatabase @PSBoundParameters -ErrorAction 'Stop'
}
