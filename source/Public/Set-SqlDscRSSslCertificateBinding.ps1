<#
    .SYNOPSIS
        Sets SSL certificate bindings for SQL Server Reporting Services.

    .DESCRIPTION
        Sets the SSL certificate bindings for SQL Server Reporting Services
        or Power BI Report Server by managing bindings through the
        `MSReportServer_ConfigurationSetting` CIM instance.

        This command replaces existing SSL certificate bindings for a specific
        application with the specified binding. Any existing bindings for the
        application that don't match will be removed.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Application
        Specifies the application for which to set the SSL binding.
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
        If specified, returns the configuration CIM instance after setting
        the SSL certificate binding.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'A1B2C3D4E5F6...'

        Sets the SSL certificate binding for the Report Server Web Service,
        removing any existing bindings for that application.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Set-SqlDscRSSslCertificateBinding -Configuration $config -Application 'ReportServerWebApp' -CertificateHash 'A1B2C3D4E5F6...' -Port 8443 -Confirm:$false

        Sets an SSL certificate binding on port 8443 without confirmation.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Set-SqlDscRSSslCertificateBinding -Application 'ReportServerWebService' -CertificateHash 'A1B2C3D4E5F6...' -PassThru

        Sets the SSL binding and returns the configuration CIM instance.

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
        to take effect. Existing SSL bindings for the application that do not
        match the specified parameters will be removed.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-createsslcertificatebinding
#>
function Set-SqlDscRSSslCertificateBinding
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

        $descriptionMessage = $script:localizedData.Set_SqlDscRSSslCertificateBinding_ShouldProcessDescription -f $CertificateHash, $Application, $instanceName
        $confirmationMessage = $script:localizedData.Set_SqlDscRSSslCertificateBinding_ShouldProcessConfirmation -f $CertificateHash, $Application
        $captionMessage = $script:localizedData.Set_SqlDscRSSslCertificateBinding_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
        {
            # Get current bindings
            $currentBindings = $Configuration | Get-SqlDscRSSslCertificateBinding -Lcid $Lcid

            # Filter bindings for the specified application
            $applicationBindings = $currentBindings | Where-Object -FilterScript {
                $_.Application -eq $Application
            }

            # Normalize the certificate hash for comparison
            $normalizedHash = $CertificateHash.ToLower()

            # Remove bindings that don't match the desired configuration
            foreach ($binding in $applicationBindings)
            {
                $shouldRemove = $binding.CertificateHash.ToLower() -ne $normalizedHash -or
                    $binding.IPAddress -ne $IPAddress -or
                    $binding.Port -ne $Port

                if ($shouldRemove)
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscRSSslCertificateBinding_RemovingExisting -f $binding.CertificateHash, $Application, $instanceName)

                    $Configuration | Remove-SqlDscRSSslCertificateBinding -Application $Application -CertificateHash $binding.CertificateHash -IPAddress $binding.IPAddress -Port $binding.Port -Lcid $Lcid -Force -ErrorAction 'Stop'
                }
            }

            # Check if the desired binding already exists
            $bindingExists = $applicationBindings | Where-Object -FilterScript {
                $_.CertificateHash.ToLower() -eq $normalizedHash -and
                $_.IPAddress -eq $IPAddress -and
                $_.Port -eq $Port
            }

            if (-not $bindingExists)
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscRSSslCertificateBinding_Adding -f $CertificateHash, $Application, $instanceName)

                $Configuration | Add-SqlDscRSSslCertificateBinding -Application $Application -CertificateHash $CertificateHash -IPAddress $IPAddress -Port $Port -Lcid $Lcid -Force -ErrorAction 'Stop'
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscRSSslCertificateBinding_AlreadyExists -f $CertificateHash, $Application, $instanceName)
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
