<#
    .SYNOPSIS
        Sets the virtual directory for SQL Server Reporting Services.

    .DESCRIPTION
        Sets the virtual directory for SQL Server Reporting Services or
        Power BI Report Server by calling the `SetVirtualDirectory` method on
        the `MSReportServer_ConfigurationSetting` CIM instance.

        This command must be called before URL reservations can be added for
        a Reporting Services application. The virtual directory defines the
        path segment in the URL used to access the application.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Application
        Specifies the application for which to set the virtual directory.
        Valid values are:
        - 'ReportServerWebService': The Report Server Web Service.
        - 'ReportServerWebApp': The Reports web application (SQL Server 2016+).
        - 'ReportManager': The Report Manager (SQL Server 2014 and earlier).

    .PARAMETER VirtualDirectory
        Specifies the virtual directory name. This is the path segment used
        in the URL to access the application. Common values are 'ReportServer'
        for the web service and 'Reports' for the web portal.

    .PARAMETER Lcid
        Specifies the language code identifier (LCID) for the virtual directory.
        If not specified, defaults to the operating system language. Common
        values include 1033 for English (US).

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after setting
        the virtual directory.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSVirtualDirectory -Application 'ReportServerWebService' -VirtualDirectory 'ReportServer'

        Sets the virtual directory for the Report Server Web Service to
        'ReportServer'.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Set-SqlDscRSVirtualDirectory -Configuration $config -Application 'ReportServerWebApp' -VirtualDirectory 'Reports' -Confirm:$false

        Sets the virtual directory for the Reports web application to 'Reports'
        without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSVirtualDirectory -Application 'ReportServerWebService' -VirtualDirectory 'ReportServer' -PassThru

        Sets the virtual directory and returns the configuration CIM instance.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        None. By default, this command does not generate any output.

    .OUTPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        When PassThru is specified, returns the MSReportServer_ConfigurationSetting
        CIM instance.

    .NOTES
        The virtual directory must be set before URL reservations can be added
        for the application. After setting the virtual directory, use
        `Add-SqlDscRSUrlReservation` to add URL reservations.

        The Reporting Services service may need to be restarted for the change
        to take effect.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-setvirtualdirectory
#>
function Set-SqlDscRSVirtualDirectory
{
    # cSpell: ignore PBIRS Lcid
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ReportServerWebService', 'ReportServerWebApp', 'ReportManager')]
        [System.String]
        $Application,

        [Parameter(Mandatory = $true)]
        [System.String]
        $VirtualDirectory,

        [Parameter()]
        [System.Int32]
        $Lcid,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $instanceName = $Configuration.InstanceName

        if (-not $PSBoundParameters.ContainsKey('Lcid'))
        {
            $Lcid = (Get-OperatingSystem).OSLanguage
        }

        Write-Verbose -Message ($script:localizedData.Set_SqlDscRSVirtualDirectory_Setting -f $VirtualDirectory, $Application, $instanceName)

        $descriptionMessage = $script:localizedData.Set_SqlDscRSVirtualDirectory_ShouldProcessDescription -f $VirtualDirectory, $Application, $instanceName
        $confirmationMessage = $script:localizedData.Set_SqlDscRSVirtualDirectory_ShouldProcessConfirmation -f $VirtualDirectory, $Application
        $captionMessage = $script:localizedData.Set_SqlDscRSVirtualDirectory_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'SetVirtualDirectory'
                Arguments   = @{
                    Application      = $Application
                    VirtualDirectory = $VirtualDirectory
                    Lcid             = $Lcid
                }
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
            catch
            {
                $errorMessage = $script:localizedData.Set_SqlDscRSVirtualDirectory_FailedToSet -f $instanceName, $_.Exception.Message

                $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'SSRSVD0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
