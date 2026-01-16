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

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSSslCertificate

        Gets all available SSL certificates for the Reporting Services instance.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'PBIRS' | Get-SqlDscRSSslCertificate

        Gets all available SSL certificates for Power BI Report Server.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.Management.Automation.PSCustomObject`

        Returns objects with properties: CertificateName, HostName,
        and CertificateHash.

    .NOTES
        This command calls the WMI method `ListSSLCertificates`. This method
        does not require an LCID parameter as it simply lists available
        certificates on the machine.

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
        $Configuration
    )

    process
    {
        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSSslCertificate_Getting -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'ListSSLCertificates'
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

            <#
                The WMI method returns multiple parallel arrays:
                - CertName: Array of certificate friendly names
                - HostName: Array of host names for the certificates
                - CertificateHash: Array of certificate thumbprints
                - Length: The length of the arrays
            #>
            if ($result.Length -gt 0)
            {
                for ($i = 0; $i -lt $result.Length; $i++)
                {
                    [PSCustomObject] @{
                        CertificateName = $result.CertName[$i]
                        HostName        = $result.HostName[$i]
                        CertificateHash = $result.CertificateHash[$i]
                    }
                }
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSSslCertificate_FailedToGet -f $instanceName, $_.Exception.Message

            $exception = New-InvalidOperationException -Message $errorMessage -ErrorRecord $_ -PassThru

            $errorRecord = New-ErrorRecord -Exception $exception -ErrorId 'GSRSSC0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}
