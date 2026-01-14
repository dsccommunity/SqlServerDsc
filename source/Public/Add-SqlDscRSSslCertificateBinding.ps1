<#
    .SYNOPSIS
        Adds an SSL certificate binding for SQL Server Reporting Services.

    .DESCRIPTION
        Adds an SSL certificate binding for SQL Server Reporting Services or
        Power BI Report Server by calling the `CreateSSLCertificateBinding`
        method on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command binds an SSL certificate to a specific application,
        IP address, and port for the Reporting Services instance. URL reservations
        must be set prior for the specified application to determine if the TLS/SSL
        certificate binding is valid.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Application
        Specifies the application for which to create the SSL binding.
        Valid values are:
        - 'ReportServerWebService': The Report Server Web Service.
        - 'ReportServerWebApp': The Reports web application (SQL Server 2016+).
        - 'ReportManager': The Report Manager (SQL Server 2014 and earlier).

    .PARAMETER CertificateHash
        Specifies the thumbprint (hash) of the SSL certificate to bind.
        The certificate must be installed in the local machine certificate
        store.

    .PARAMETER IPAddress
        Specifies the IP address for the SSL binding. Use '0.0.0.0' to bind
        to all IP addresses. Default value is '0.0.0.0'.

    .PARAMETER Port
        Specifies the port number for the SSL binding. Default value is 443.

    .PARAMETER Lcid
        Specifies the language code identifier (LCID) for the operation.
        If not specified, defaults to the operating system language. Common
        values include 1033 for English (US).

    .PARAMETER PassThru
        If specified, returns the configuration CIM instance after adding
        the SSL certificate binding.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Add-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'A1B2C3D4E5F6...'

        Adds an SSL certificate binding for the Report Server Web Service
        using the default IP address (0.0.0.0) and port (443).

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Add-SqlDscRSSslCertificateBinding -Configuration $config -Application 'ReportServerWebApp' -CertificateHash 'A1B2C3D4E5F6...' -Port 8443 -Confirm:$false

        Adds an SSL certificate binding on port 8443 without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Add-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'A1B2C3D4E5F6...' -PassThru

        Adds the SSL binding and returns the configuration CIM instance.

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
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-createsslcertificatebinding
#>
function Add-SqlDscRSSslCertificateBinding
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

        Write-Verbose -Message ($script:localizedData.Add_SqlDscRSSslCertificateBinding_Adding -f $CertificateHash, $Application, $instanceName)

        $descriptionMessage = $script:localizedData.Add_SqlDscRSSslCertificateBinding_ShouldProcessDescription -f $CertificateHash, $Application, $instanceName
        $confirmationMessage = $script:localizedData.Add_SqlDscRSSslCertificateBinding_ShouldProcessConfirmation -f $CertificateHash, $Application
        $captionMessage = $script:localizedData.Add_SqlDscRSSslCertificateBinding_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            $invokeRsCimMethodParameters = @{
                CimInstance = $Configuration
                MethodName  = 'CreateSSLCertificateBinding'
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
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        ($script:localizedData.Add_SqlDscRSSslCertificateBinding_FailedToAdd -f $instanceName, $_.Exception.Message),
                        'ASRSSCB0001',
                        [System.Management.Automation.ErrorCategory]::InvalidOperation,
                        $Configuration
                    )
                )
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
