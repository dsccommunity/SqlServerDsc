<#
    .SYNOPSIS
        Uninstalls SQL Server Reporting Services or Power BI Report Server.

    .DESCRIPTION
        Uninstalls SQL Server Reporting Services or Power BI Report Server using
        the provided setup executable.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .PARAMETER LogPath
        Specifies the file path where to write the log files, e.g. 'C:\Logs\Uninstall.log'.
        By default log files are created under %TEMP%.

    .PARAMETER SuppressRestart
        Suppresses the restart of the computer after the uninstallation is finished.
        By default the computer is restarted after the uninstallation is finished.

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .PARAMETER Force
        If specified the command will not ask for confirmation. Same as if Confirm:$false
        is used.

    .EXAMPLE
        Uninstall-SqlDscReportingServices -MediaPath 'E:\SQLServerReportingServices.exe'

        Uninstalls SQL Server Reporting Services.

    .EXAMPLE
        Uninstall-SqlDscReportingServices -MediaPath 'E:\PowerBIReportServer.exe' -LogPath 'C:\Logs\PowerBIReportServer_Uninstall.log'

        Uninstalls Power BI Report Server and specifies a custom log path.

    .EXAMPLE
        Uninstall-SqlDscReportingServices -MediaPath 'E:\SQLServerReportingServices.exe' -Force

        Uninstalls SQL Server Reporting Services without prompting for confirmation.
#>
function Uninstall-SqlDscReportingServices
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in Invoke-SetupAction')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $MediaPath,

        [Parameter()]
        [System.String]
        $LogPath,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SuppressRestart,

        [Parameter()]
        [System.UInt32]
        $Timeout = 7200,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    Invoke-ReportServerSetupAction -Uninstall @PSBoundParameters
}
