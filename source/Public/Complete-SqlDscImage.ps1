<#
    .SYNOPSIS
        Completes the image installation of an SQL Server instance.

    .DESCRIPTION
        Completes the image installation of an SQL Server instance that was prepared
        using `Install-SqlDscServer` with the parameter `-PrepareImage`.

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

    .PARAMETER InstanceName
        See notes section.

    .PARAMETER Enu
        See notes section.

    .PARAMETER InstanceId
        See notes section.

    .PARAMETER PBEngSvcAccount
        See notes section.

    .PARAMETER PBEngSvcPassword
        See notes section.

    .PARAMETER PBEngSvcStartupType
        See notes section.

    .PARAMETER PBStartPortRange
        See notes section.

    .PARAMETER PBEndPortRange
        See notes section.

    .PARAMETER PBScaleOut
        See notes section.

    .PARAMETER ProductKey
        See notes section.

    .PARAMETER AgtSvcAccount
        See notes section.

    .PARAMETER AgtSvcPassword
        See notes section.

    .PARAMETER AgtSvcStartupType
        See notes section.

    .PARAMETER BrowserSvcStartupType
        See notes section.

    .PARAMETER EnableRanU
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

    .PARAMETER SqlSvcAccount
        See notes section.

    .PARAMETER SqlSvcPassword
        See notes section.

    .PARAMETER SqlSvcStartupType
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

    .PARAMETER FileStreamLevel
        See notes section.

    .PARAMETER FileStreamShareName
        See notes section.

    .PARAMETER NpEnabled
        See notes section.

    .PARAMETER TcpEnabled
        See notes section.

    .PARAMETER RsInstallMode
        See notes section.

    .PARAMETER RSSvcAccount
        See notes section.

    .PARAMETER RSSvcPassword
        See notes section.

    .PARAMETER RSSvcStartupType
        See notes section.

    .PARAMETER ProductCoveredBySA
        See notes section.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Complete-SqlDscImage -AcceptLicensingTerms -MediaPath 'E:\'

        Completes the image installation of the SQL Server default instance that
        was prepared using `Install-SqlDscServer` with the parameter `-PrepareImage`.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.
#>
function Complete-SqlDscImage
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

        [Parameter()]
        [System.String]
        $InstanceName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Enu,

        [Parameter()]
        [System.String]
        $InstanceId,

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
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $AgtSvcStartupType,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $BrowserSvcStartupType,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $EnableRanU,

        [Parameter()]
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

        [Parameter()]
        [System.String]
        $SqlSvcAccount,

        [Parameter()]
        [System.Security.SecureString]
        $SqlSvcPassword,

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $SqlSvcStartupType,

        [Parameter()]
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
        [ValidateRange(0, 3)]
        [System.UInt16]
        $FileStreamLevel,

        [Parameter()]
        [System.String]
        $FileStreamShareName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NpEnabled,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $TcpEnabled,

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

        [Parameter()]
        [ValidateSet('Automatic', 'Disabled', 'Manual')]
        [System.String]
        $RSSvcStartupType,

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

    Invoke-SetupAction -CompleteImage @PSBoundParameters -ErrorAction 'Stop'
}
