<#
    .SYNOPSIS
        Uninstalls SQL Server Power BI Report Server.

    .DESCRIPTION
        Uninstalls SQL Server Power BI Report Server using the provided setup executable.

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

    .PARAMETER PassThru
        If specified the command will return the setup process exit code.


    .INPUTS
        None.

.OUTPUTS
        `System.Int32`

        When PassThru is specified the function will return the setup process exit
        code.

    .EXAMPLE
        Uninstall-SqlDscBIReportServer -MediaPath 'E:\PowerBIReportServer.exe'

        Uninstalls Power BI Report Server.

    .EXAMPLE
        Uninstall-SqlDscBIReportServer -MediaPath 'E:\PowerBIReportServer.exe' -LogPath 'C:\Logs\PowerBIReportServer_Uninstall.log'

        Uninstalls Power BI Report Server and specifies a custom log path.

    .EXAMPLE
        Uninstall-SqlDscBIReportServer -MediaPath 'E:\PowerBIReportServer.exe' -Force

        Uninstalls Power BI Report Server without prompting for confirmation.

    .EXAMPLE
        $exitCode = Uninstall-SqlDscBIReportServer -MediaPath 'E:\PowerBIReportServer.exe' -PassThru

        Uninstalls Power BI Report Server and returns the setup exit code.
#>
function Uninstall-SqlDscBIReportServer
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'Because ShouldProcess is used in Invoke-SetupAction')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([System.Int32])]
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
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    $exitCode = Invoke-ReportServerSetupAction -Uninstall @PSBoundParameters

    if ($PassThru.IsPresent)
    {
        return $exitCode
    }
}
