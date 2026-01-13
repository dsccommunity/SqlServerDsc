<#
    .SYNOPSIS
        Gets the available SSL certificates for SQL Server Reporting Services.

    .DESCRIPTION
        Gets the SSL certificates available on the machine for use with
        SQL Server Reporting Services or Power BI Report Server by calling
        the `ListSSLCertificates` method on the
        `MSReportServer_ConfigurationSetting` CIM instance.

        This command returns information about certificates that can be
        bound to the Reporting Services instance for SSL/TLS connections.

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
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSSslCertificate

        Gets all available SSL certificates for the Reporting Services instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-SqlDscRSSslCertificate -Configuration $config -Lcid 1033

        Gets available SSL certificates with a specific LCID.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.Management.Automation.PSCustomObject`

        Returns objects with properties: CertificateName, Subject, ExpirationDate,
        and CertificateHash.

    .NOTES
        This command calls the WMI method `ListSSLCertificates`.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-listsslcertificates
#>
function Get-SqlDscRSSslCertificate
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

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSSslCertificate_Getting -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'ListSSLCertificates'
            Arguments   = @{
                Lcid = $Lcid
            }
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

            <#
                The WMI method returns multiple parallel arrays:
                - CertName: Array of certificate friendly names
                - CertSubject: Array of certificate subjects
                - CertExpiration: Array of expiration dates
                - CertificateHash: Array of certificate thumbprints
            #>
            if ($result.CertificateHash)
            {
                for ($i = 0; $i -lt $result.CertificateHash.Count; $i++)
                {
                    [PSCustomObject] @{
                        CertificateName = $result.CertName[$i]
                        Subject         = $result.CertSubject[$i]
                        ExpirationDate  = $result.CertExpiration[$i]
                        CertificateHash = $result.CertificateHash[$i]
                    }
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.Get_SqlDscRSSslCertificate_FailedToGet -f $instanceName, $_.Exception.Message),
                    'GSRSSC0001',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Configuration
                )
            )
        }
    }
}
