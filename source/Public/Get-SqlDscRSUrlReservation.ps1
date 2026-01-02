<#
    .SYNOPSIS
        Gets the URL reservations for SQL Server Reporting Services.

    .DESCRIPTION
        Gets the URL reservations for SQL Server Reporting Services or
        Power BI Report Server by calling the `ListReservedUrls` method on
        the `MSReportServer_ConfigurationSetting` CIM instance.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSUrlReservation

        Gets all URL reservations for the SSRS instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-SqlDscRSUrlReservation -Configuration $config

        Gets all URL reservations for the SSRS instance by passing the
        configuration as a parameter.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `Microsoft.Management.Infrastructure.CimMethodResult`

        Returns the raw CIM method result containing Application and UrlString
        arrays with the reserved URL information.

    .NOTES
        The returned object contains two arrays:
        - Application: Array of application names (e.g., 'ReportServerWebService',
          'ReportServerWebApp', 'ReportManager')
        - UrlString: Array of URL strings (e.g., 'http://+:80')

        The arrays are correlated by index, so Application[0] corresponds to
        UrlString[0].
#>
function Get-SqlDscRSUrlReservation
{
    # cSpell: ignore PBIRS
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimMethodResult])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration
    )

    process
    {
        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSUrlReservation_Getting -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'ListReservedUrls'
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSUrlReservation_FailedToGet -f $instanceName, $_.Exception.Message

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRUR0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        return $result
    }
}
