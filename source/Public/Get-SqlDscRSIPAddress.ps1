<#
    .SYNOPSIS
        Gets the available IP addresses for SQL Server Reporting Services.
#>
function Get-SqlDscRSIPAddress
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding()]
    [OutputType([ReportServerIPAddress[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration
    )

    process
    {
        $instanceName = $Configuration.InstanceName

        Write-Verbose -Message ($script:localizedData.Get_SqlDscRSIPAddress_Getting -f $instanceName)

        $invokeRsCimMethodParameters = @{
            CimInstance = $Configuration
            MethodName  = 'ListIPAddresses'
        }

        try
        {
            $result = Invoke-RsCimMethod @invokeRsCimMethodParameters

            # Return the IP addresses as ReportServerIPAddress objects
            if ($result.IPAddress -and $result.IPAddress.Count -gt 0)
            {
                $ipAddressObjects = for ($i = 0; $i -lt $result.IPAddress.Count; $i++)
                {
                    $ipAddressObject = [ReportServerIPAddress]::new()
                    $ipAddressObject.IPAddress = $result.IPAddress[$i]
                    $ipAddressObject.IPVersion = $result.IPVersion[$i]
                    $ipAddressObject.IsDhcpEnabled = $result.IsDhcpEnabled[$i]

                    $ipAddressObject
                }

                return $ipAddressObjects
            }
        }
        catch
        {
            $errorMessage = $script:localizedData.Get_SqlDscRSIPAddress_FailedToGet -f $instanceName, $_.Exception.Message

            $errorRecord = New-ErrorRecord -Exception (New-InvalidOperationException -Message $errorMessage -PassThru) -ErrorId 'GSRSIP0001' -ErrorCategory 'InvalidOperation' -TargetObject $Configuration

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}
