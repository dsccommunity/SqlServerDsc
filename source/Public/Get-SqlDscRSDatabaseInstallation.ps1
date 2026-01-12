<#
    .SYNOPSIS
        Gets the report server installations registered in the database.
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
                The WMI method returns:
                - Length: Number of entries in the arrays
                - InstallationID: Array of installation IDs
                - MachineName: Array of machine names
                - InstanceName: Array of instance names
                - IsInitialized: Array of initialization states
            #>
            if ($result.Length -gt 0)
            {
                for ($i = 0; $i -lt $result.Length; $i++)
                {
                    [PSCustomObject] @{
                        InstallationID = $result.InstallationIDs[$i]
                        MachineName    = $result.MachineNames[$i]
                        InstanceName   = $result.InstanceNames[$i]
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
