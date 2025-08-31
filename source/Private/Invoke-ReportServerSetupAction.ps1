<#
    .SYNOPSIS
        Executes setup using the provided setup executable.

    .DESCRIPTION
        Executes Reporting Services or BI Report Server setup using the provided setup executable.

        See the link in the commands help for information on each parameter.

    .PARAMETER Install
        Specifies that a new installation should be performed.

    .PARAMETER Uninstall
        Specifies that an uninstallation should be performed.

    .PARAMETER Repair
        Specifies that a repair should be performed on an existing installation.

    .PARAMETER AcceptLicensingTerms
        Required parameter to be able to run unattended install. By specifying this
        parameter you acknowledge the acceptance of all license terms and notices for
        the specified features, the terms and notices that the setup executable
        normally asks for.

    .PARAMETER MediaPath
        Specifies the path where to find the SQL Server installation media. On this
        path the SQL Server setup executable must be found.

    .PARAMETER ProductKey
        Specifies the product key to use for the installation, e.g. '12345-12345-12345-12345-12345'.
        This parameter is mutually exclusive with the parameter Edition.

    .PARAMETER EditionUpgrade
        Upgrades the edition of the installed product. Requires that either the
        ProductKey or the Edition parameter is also assigned. By default no edition
        upgrade is performed.

    .PARAMETER Edition
        Specifies a free custom edition to use for the installation. This parameter
        is mutually exclusive with the parameter ProductKey.

    .PARAMETER LogPath
        Specifies the file path where to write the log files, e.g. 'C:\Logs\Install.log'.
        By default log files are created under %TEMP%.

    .PARAMETER InstallFolder
        Specifies the folder where to install the product, e.g. 'C:\Program Files\SSRS'.
        By default the product is installed under the default installation folder.

        Reporting Services: %ProgramFiles%\Microsoft SQL Server Reporting Services
        PI Report Server: %ProgramFiles%\Microsoft Power BI Report Server

    .PARAMETER SuppressRestart
        Suppresses the restart of the computer after the installation is finished.
        By default the computer is restarted after the installation is finished.

    .PARAMETER Timeout
        Specifies how long to wait for the setup process to finish. Default value
        is `7200` seconds (2 hours). If the setup process does not finish before
        this time, an exception will be thrown.

    .PARAMETER Force
        If specified the command will not ask for confirmation. Same as if Confirm:$false
        is used.

    .PARAMETER PassThru
        If specified the command will return the setup process exit code.

    .LINK
        https://learn.microsoft.com/en-us/power-bi/report-server/install-report-server
        https://learn.microsoft.com/en-us/sql/reporting-services/install-windows/install-reporting-services

    .OUTPUTS
        When PassThru is specified the function will return the setup process exit
        code as System.Int32. Otherwise, the function does not generate any output.

    .EXAMPLE
        Invoke-ReportServerSetupAction -Install -AcceptLicensingTerms -MediaPath 'E:\SQLServerReportingServices.exe'

        Installs SQL Server Reporting Services with default settings.

    .EXAMPLE
        Invoke-ReportServerSetupAction -Install -AcceptLicensingTerms -MediaPath 'E:\SQLServerReportingServices.exe' -ProductKey '12345-12345-12345-12345-12345'

        Installs SQL Server Reporting Services using a product key.

    .EXAMPLE
        Invoke-ReportServerSetupAction -Install -AcceptLicensingTerms -MediaPath 'E:\PowerBIReportServer.exe' -Edition 'Evaluation' -InstallFolder 'C:\Program Files\Power BI Report Server'

        Installs Power BI Report Server in evaluation edition to a custom folder.

    .EXAMPLE
        Invoke-ReportServerSetupAction -Install -AcceptLicensingTerms -MediaPath 'E:\SQLServerReportingServices.exe' -ProductKey '12345-12345-12345-12345-12345' -EditionUpgrade -LogPath 'C:\Logs\SSRS_Install.log'

        Installs SQL Server Reporting Services and upgrades the edition using a product key. Also specifies a custom log path.

    .EXAMPLE
        Invoke-ReportServerSetupAction -Repair -AcceptLicensingTerms -MediaPath 'E:\SQLServerReportingServices.exe'

        Repairs an existing installation of SQL Server Reporting Services.

    .EXAMPLE
        Invoke-ReportServerSetupAction -Uninstall -MediaPath 'E:\SQLServerReportingServices.exe' -Force

        Uninstalls SQL Server Reporting Services without prompting for confirmation.

    .EXAMPLE
        $exitCode = Invoke-ReportServerSetupAction -Install -AcceptLicensingTerms -MediaPath 'E:\SQLServerReportingServices.exe' -PassThru

        Installs SQL Server Reporting Services and returns the setup process exit code.
#>
function Invoke-ReportServerSetupAction
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Install,

        [Parameter(ParameterSetName = 'Uninstall', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Uninstall,

        [Parameter(ParameterSetName = 'Repair', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $Repair,

        [Parameter(ParameterSetName = 'Install', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Repair', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $AcceptLicensingTerms,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType 'Leaf'))
                {
                    throw $script:localizedData.ReportServerSetupAction_ReportServerExecutableNotFound
                }

                return $true
            })]
        [System.String]
        $MediaPath,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Repair')]
        [System.String]
        $ProductKey,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Repair')]
        [System.Management.Automation.SwitchParameter]
        $EditionUpgrade,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Repair')]
        [ValidateSet('Developer', 'Evaluation', 'ExpressAdvanced')]
        [System.String]
        $Edition,

        [Parameter()]
        [System.String]
        $LogPath,

        [Parameter(ParameterSetName = 'Install')]
        [Parameter(ParameterSetName = 'Repair')]
        [ValidateScript({
                $parentInstallFolder = Split-Path -Path $_ -Parent

                if (-not (Test-Path -Path $parentInstallFolder))
                {
                    throw $script:localizedData.ReportServerSetupAction_InstallFolderNotFound
                }

                return $true
            })]
        [System.String]
        $InstallFolder,

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

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    $originalErrorActionPreference = $ErrorActionPreference

    $ErrorActionPreference = 'Stop'

    Assert-ElevatedUser -ErrorAction 'Stop'

    $ErrorActionPreference = $originalErrorActionPreference

    $assertBoundParameters = @{
        BoundParameterList     = $PSBoundParameters
        MutuallyExclusiveList1 = @(
            'Edition'
        )
        MutuallyExclusiveList2 = @(
            'ProductKey'
        )
    }

    # Either ProductKey or Edition must be specified, never both.
    Assert-BoundParameter @assertBoundParameters

    # If EditionUpgrade is specified then the parameter ProductKey or Edition must be specified.
    $assertBoundParameters = @{
        BoundParameterList = $PSBoundParameters
        IfParameterPresent = @('EditionUpgrade')
        RequiredParameter  = ('ProductKey', 'Edition')
        RequiredBehavior   = 'Any'
    }

    Assert-BoundParameter @assertBoundParameters

    # Sensitive values.
    $sensitiveValue = @()

    # Default action is install or upgrade.
    $setupArgument = '/quiet /IAcceptLicenseTerms'

    if ($Uninstall.IsPresent)
    {
        $setupArgument += ' /uninstall'
    }
    elseif ($Repair.IsPresent)
    {
        $setupArgument += ' /repair'
    }

    if ($ProductKey)
    {
        $setupArgument += ' /PID={0}' -f $ProductKey

        $sensitiveValue += @(
            $ProductKey
        )
    }

    if ($EditionUpgrade.IsPresent)
    {
        $setupArgument += ' /EditionUpgrade'
    }

    if ($Edition)
    {
        $editionMap = @{
            Developer       = 'Dev'
            Evaluation      = 'Eval'
            ExpressAdvanced = 'ExprAdv'
        }

        $setupArgument += ' /Edition={0}' -f $editionMap.$Edition
    }

    if ($LogPath)
    {
        $setupArgument += ' /log "{0}"' -f $LogPath
    }

    if ($InstallFolder)
    {
        $setupArgument += ' /InstallFolder="{0}"' -f $InstallFolder
    }

    if ($SuppressRestart.IsPresent)
    {
        $setupArgument += ' /norestart'
    }

    $verboseSetupArgument = $setupArgument

    # Obfuscate sensitive values.
    foreach ($currentSensitiveValue in $sensitiveValue)
    {
        $escapedRegExString = [System.Text.RegularExpressions.Regex]::Escape($currentSensitiveValue)

        $verboseSetupArgument = $verboseSetupArgument -replace $escapedRegExString, '********'
    }

    # Clear sensitive values.
    $sensitiveValue = $null

    Write-Verbose -Message ($script:localizedData.ReportServerSetupAction_SetupArguments -f $verboseSetupArgument)

    $verboseDescriptionMessage = $script:localizedData.ReportServerSetupAction_ShouldProcessVerboseDescription -f $PSCmdlet.ParameterSetName
    $verboseWarningMessage = $script:localizedData.ReportServerSetupAction_ShouldProcessVerboseWarning -f $PSCmdlet.ParameterSetName
    $captionMessage = $script:localizedData.ReportServerSetupAction_ShouldProcessCaption

    if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        $expandedMediaPath = [System.Environment]::ExpandEnvironmentVariables($MediaPath)

        $startProcessParameters = @{
            FilePath     = $expandedMediaPath
            ArgumentList = $setupArgument
            Timeout      = $Timeout
        }

        # Clear setupArgument to remove any sensitive values.
        $setupArgument = $null

        # Run setup executable.
        $processExitCode = Start-SqlSetupProcess @startProcessParameters

        $setupExitMessage = ($script:localizedData.SetupAction_SetupExitMessage -f $processExitCode)

        if ($processExitCode -eq 3010)
        {
            Write-Warning -Message (
                '{0} {1}' -f $setupExitMessage, $script:localizedData.SetupAction_SetupSuccessfulRebootRequired
            )
        }
        elseif ($processExitCode -ne 0)
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $setupExitMessage,
                    'IRS0001', # cspell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $PSCmdlet.ParameterSetName
                )
            )
        }
        else
        {
            Write-Verbose -Message (
                '{0} {1}' -f $setupExitMessage, ($script:localizedData.SetupAction_SetupSuccessful)
            )
        }

        if ($PassThru.IsPresent)
        {
            return $processExitCode
        }
    }
}
