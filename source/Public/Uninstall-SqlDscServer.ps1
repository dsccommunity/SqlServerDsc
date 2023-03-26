<#
    .SYNOPSIS
        Uninstall features from a Microsoft SQL Server instance.

    .DESCRIPTION
        Uninstall features from a Microsoft SQL Server instance.

        See the link in the commands help for information on each parameter for
        the setup action Uninstall. The link points to SQL Server command line
        setup documentation.

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

    .PARAMETER Features
        See the notes section for more information.

    .PARAMETER SuppressPrivacyStatementNotice
        See the notes section for more information.

    .LINK
        https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt

    .OUTPUTS
        None.

    .EXAMPLE
        Uninstall-SqlDscServer -InstanceName 'MyInstance' -Features 'SQLENGINE' -MediaPath 'E:\'

        Uninstalls the database engine from the named instance MyInstance.

    .NOTES
        The parameters are intentionally not described since it would take a lot
        of effort to keep them up to date. Instead there is a link that points to
        the SQL Server command line setup documentation which will stay relevant.
#>
function Uninstall-SqlDscServer
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
        [ValidateSet(
            'SQL',
            'SQLEngine', # Part of parent feature SQL
            'Replication', # Part of parent feature SQL
            'FullText', # Part of parent feature SQL
            'DQ', # Part of parent feature SQL
            'PolyBase', # Part of parent feature SQL
            'PolyBaseCore', # Part of parent feature SQL
            'PolyBaseJava', # Part of parent feature SQL
            'AdvancedAnalytics', # Part of parent feature SQL
            'SQL_INST_MR', # Part of parent feature SQL
            'SQL_INST_MPY', # Part of parent feature SQL
            'SQL_INST_JAVA', # Part of parent feature SQL
            'AS',
            'RS',
            'RS_SHP',
            'RS_SHPWFE', # cspell: disable-line
            'DQC',
            'IS',
            'IS_Master', # Part of parent feature IS
            'IS_Worker', # Part of parent feature IS
            'MDS',
            'SQL_SHARED_MPY',
            'SQL_SHARED_MR',
            'Tools',
            'BC', # Part of parent feature Tools
            'Conn', # Part of parent feature Tools
            'DREPLAY_CTLR', # Part of parent feature Tools (cspell: disable-line)
            'DREPLAY_CLT', # Part of parent feature Tools (cspell: disable-line)
            'SNAC_SDK', # Part of parent feature Tools (cspell: disable-line)
            'SDK', # Part of parent feature Tools
            'LocalDB', # Part of parent feature Tools
            'AZUREEXTENSION'
        )]
        [System.String[]]
        $Features,

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SuppressPrivacyStatementNotice
    )

    Invoke-SetupAction -Uninstall @PSBoundParameters -ErrorAction 'Stop'
}
