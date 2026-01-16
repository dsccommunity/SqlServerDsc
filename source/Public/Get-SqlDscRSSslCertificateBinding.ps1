<#
    .SYNOPSIS
        Gets SSL certificate bindings for SQL Server Reporting Services.

    .DESCRIPTION
        Gets the SSL certificate bindings for SQL Server Reporting Services or
        Power BI Report Server by calling the `ListSSLCertificateBindings` method
        on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command retrieves information about which SSL certificates are
        bound to the Reporting Services instance and on which IP addresses
        and ports.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .PARAMETER Lcid
        Specifies the language code identifier (LCID) for the request.
        If not specified, defaults to the operating system language. Common
        values include 1033 for English (US).

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSSslCertificateBinding

        Gets all SSL certificate bindings for the Reporting Services instance 'SSRS'.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-SqlDscRSSslCertificateBinding -Configuration $config -Lcid 1033

        Gets all SSL certificate bindings with a specific LCID.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.Management.Automation.PSCustomObject`

        Returns objects with properties: Application, CertificateHash, IPAddress,
        Port, and Lcid.

    .NOTES
        This command calls the WMI method `ListSSLCertificateBindings`.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-listsslcertificatebindings
#>
function Get-SqlDscRSSslCertificateBinding
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter()]
        [System.Int32]
        $Lcid
    )

    process
    {
        $instanceName = $Configuration.InstanceName

        if (-not $PSBoundParameters.ContainsKey('Lcid'))
        {
            $Lcid = (Get-OperatingSystem).OSLanguage
        }

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSSslCertificateBinding_Getting -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'ListSSLCertificateBindings'
            Arguments   = @{
                Lcid = $Lcid
            }
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

            <#
                The WMI method returns multiple parallel arrays:
                - Application: Array of application names
                - CertificateHash: Array of certificate thumbprints
                - IPAddress: Array of IP addresses
                - Port: Array of port numbers
            #>
            if ($result.Application)
            {
                for ($i = 0; $i -lt $result.Application.Count; $i++)
                {
                    [PSCustomObject] @{
                        Application     = $result.Application[$i]
                        CertificateHash = $result.CertificateHash[$i]
                        IPAddress       = $result.IPAddress[$i]
                        Port            = $result.Port[$i]
                        Lcid            = $Lcid
                    }
                }
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSSslCertificateBinding_FailedToGet -f $instanceName

            $exception = New-Exception -Message $errorMessage -ErrorRecord $_

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSSCB0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}
