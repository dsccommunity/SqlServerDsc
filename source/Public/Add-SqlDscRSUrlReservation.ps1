<#
    .SYNOPSIS
        Adds a URL reservation for SQL Server Reporting Services.

    .DESCRIPTION
        Adds a URL reservation for SQL Server Reporting Services or
        Power BI Report Server by calling the `ReserveUrl` method on
        the `MSReportServer_ConfigurationSetting` CIM instance.

        This command reserves a URL for a specific application in the
        Reporting Services instance. The application can be the Report Server
        Web Service, the Reports web application (SQL Server 2016+), or the
        Report Manager (SQL Server 2014 and earlier).

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Application
        Specifies the application for which to reserve the URL. Valid values
        are:
        - 'ReportServerWebService': The Report Server Web Service.
        - 'ReportServerWebApp': The Reports web application (SQL Server 2016+).
        - 'ReportManager': The Report Manager (SQL Server 2014 and earlier).

    .PARAMETER UrlString
        Specifies the URL string to reserve. The URL string format is typically
        'http://+:80' or 'https://+:443' where the plus sign (+) is a wildcard
        that matches all hostnames.

    .PARAMETER Lcid
        Specifies the language code identifier (LCID) for the URL reservation.
        If not specified, defaults to the operating system language. Common
        values include 1033 for English (US).

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after adding
        the URL reservation.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80'

        Adds a URL reservation for the Report Server Web Service on port 80.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Add-SqlDscRSUrlReservation -Configuration $config -Application 'ReportServerWebApp' -UrlString 'https://+:443' -Confirm:$false

        Adds a URL reservation for the Reports web application on port 443
        without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Add-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:8080' -Lcid 1033 -PassThru

        Adds a URL reservation with a specific LCID and returns the configuration
        CIM instance.

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
        The Reporting Services service may need to be restarted for the change
        to take effect.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-reserveurl
#>
function Add-SqlDscRSUrlReservation
{
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
        $UrlString,

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

        Write-Verbose -Message ($script:localizedData.Add_SqlDscRSUrlReservation_Adding -f $UrlString, $Application, $instanceName)

        $descriptionMessage = $script:localizedData.Add_SqlDscRSUrlReservation_ShouldProcessDescription -f $UrlString, $Application, $instanceName
        $confirmationMessage = $script:localizedData.Add_SqlDscRSUrlReservation_ShouldProcessConfirmation -f $UrlString, $Application
        $captionMessage = $script:localizedData.Add_SqlDscRSUrlReservation_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'ReserveUrl'
                Arguments   = @{
                    Application = $Application
                    UrlString   = $UrlString
                    Lcid        = $Lcid
                }
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters
            }
            catch
            {
                $errorMessage = $script:localizedData.Add_SqlDscRSUrlReservation_FailedToAdd -f $instanceName

                $exception = New-Exception -Message $errorMessage -ErrorRecord $_

                $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'ASRUR0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
