<#
    .SYNOPSIS
        Removes an SSL certificate binding from SQL Server Reporting Services.

    .DESCRIPTION
        Removes an SSL certificate binding from SQL Server Reporting Services
        or Power BI Report Server by calling the `RemoveSSLCertificateBindings`
        method on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command removes an SSL certificate binding for a specific
        application, certificate, IP address, and port from the Reporting
        Services instance.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Application
        Specifies the application from which to remove the SSL binding.
        Valid values are:
        - 'ReportServerWebService': The Report Server Web Service.
        - 'ReportServerWebApp': The Reports web application (SQL Server 2016+).
        - 'ReportManager': The Report Manager (SQL Server 2014 and earlier).

    .PARAMETER CertificateHash
        Specifies the thumbprint (hash) of the SSL certificate to unbind.

    .PARAMETER IPAddress
        Specifies the IP address of the SSL binding to remove. Use '0.0.0.0'
        for all IP addresses. Default value is '0.0.0.0'.

    .PARAMETER Port
        Specifies the port number of the SSL binding to remove. Default value
        is 443.

    .PARAMETER Lcid
        Specifies the language code identifier (LCID) for the operation.
        If not specified, defaults to the operating system language. Common
        values include 1033 for English (US).

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after removing
        the SSL certificate binding.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'A1B2C3D4E5F6...'

        Removes the SSL certificate binding for the Report Server Web Service.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Remove-SqlDscRSSslCertificateBinding -Configuration $config -Application 'ReportServerWebApp' -CertificateHash 'A1B2C3D4E5F6...' -Port 8443 -Confirm:$false

        Removes an SSL certificate binding on port 8443 without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Remove-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'A1B2C3D4E5F6...' -Force -PassThru

        Removes the SSL binding without confirmation and returns the
        configuration CIM instance.

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
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-removesslcertificatebindings
#>
function Remove-SqlDscRSSslCertificateBinding
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
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
        $CertificateHash,

        [Parameter()]
        [System.String]
        $IPAddress = '0.0.0.0',

        [Parameter()]
        [System.Int32]
        $Port = 443,

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

        Write-Verbose -Message ($script:localizedData.Remove_SqlDscRSSslCertificateBinding_Removing -f $CertificateHash, $Application, $instanceName)

        $descriptionMessage = $script:localizedData.Remove_SqlDscRSSslCertificateBinding_ShouldProcessDescription -f $CertificateHash, $Application, $instanceName
        $confirmationMessage = $script:localizedData.Remove_SqlDscRSSslCertificateBinding_ShouldProcessConfirmation -f $CertificateHash, $Application
        $captionMessage = $script:localizedData.Remove_SqlDscRSSslCertificateBinding_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'RemoveSSLCertificateBindings'
                Arguments   = @{
                    Application     = $Application
                    CertificateHash = $CertificateHash.ToLower()
                    IPAddress       = $IPAddress
                    Port            = $Port
                    Lcid            = $Lcid
                }
            }

            try
            {
                $null = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'
            }
            catch
            {
                $errorMessage = $script:localizedData.Remove_SqlDscRSSslCertificateBinding_FailedToRemove -f $instanceName, $_.Exception.Message

                $exception = New-InvalidOperationException -Message $errorMessage -ErrorRecord $_ -PassThru

                $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'RSRSSCB0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
