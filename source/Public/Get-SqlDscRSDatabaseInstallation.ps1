<#
    .SYNOPSIS
        Gets the report server installations registered in the database.

    .DESCRIPTION
        Gets the Reporting Services installations registered in the report
        server database by calling the `ListReportServersInDatabase` method
        on the `MSReportServer_ConfigurationSetting` CIM instance.

        This command returns information about all report server installations
        that are configured to use the same report server database, which is
        useful in scale-out deployment scenarios.

        The configuration CIM instance can be obtained using the
        `Get-SqlDscRSConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the `MSReportServer_ConfigurationSetting` CIM instance for
        the Reporting Services instance. This can be obtained using the
        `Get-SqlDscRSConfiguration` command. This parameter accepts pipeline
        input.

    .EXAMPLE
        Get-SqlDscRSConfiguration -InstanceName 'SSRS' | Get-SqlDscRSDatabaseInstallation

        Gets all report server installations registered in the database.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        Get-SqlDscRSDatabaseInstallation -Configuration $config

        Gets report server installations using a stored configuration object.

    .INPUTS
        `Microsoft.Management.Infrastructure.CimInstance`

        Accepts MSReportServer_ConfigurationSetting CIM instance via pipeline.

    .OUTPUTS
        `System.Management.Automation.PSCustomObject`

        Returns objects with properties: InstallationID, MachineName,
        InstanceName, and IsInitialized.

    .NOTES
        This command calls the WMI method `ListReportServersInDatabase`.

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-listreportserversindatabase
#>
function Get-SqlDscRSDatabaseInstallation
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

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSDatabaseInstallation_Getting -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'ListReportServersInDatabase'
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters -ErrorAction 'Stop'

            <#
                The WMI method returns multiple parallel arrays:
                - InstallationID: Array of installation IDs
                - MachineName: Array of machine names
                - InstanceName: Array of instance names
                - IsInitialized: Array of initialization states
            #>
            if ($result.InstallationID)
            {
                for ($i = 0; $i -lt $result.InstallationID.Count; $i++)
                {
                    [PSCustomObject] @{
                        InstallationID = $result.InstallationID[$i]
                        MachineName    = $result.MachineName[$i]
                        InstanceName   = $result.InstanceName[$i]
                        IsInitialized  = $result.IsInitialized[$i]
                    }
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    ($script:localizedData.Get_SqlDscRSDatabaseInstallation_FailedToGet -f $instanceName, $_.Exception.Message),
                    'GSRSDI0001',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $Configuration
                )
            )
        }
    }
}
