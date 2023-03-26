<#
    .SYNOPSIS
        Converts a normalized service type name to a managed service type name.

    .DESCRIPTION
        Converts a normalized service type name to its managed service type name
        equivalent.

    .PARAMETER ServiceType
        Specifies the normalized service type to convert to the correct manged
        service type.

    .EXAMPLE
        ConvertTo-ManagedServiceType -ServiceType 'DatabaseEngine'

        Returns the manged service type name for the normalized service type 'DatabaseEngine'.
#>
function ConvertTo-ManagedServiceType
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet('DatabaseEngine', 'SqlServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
        [System.String]
        $ServiceType
    )

    process
    {
        # Map the normalized service type to a valid value from the managed service type.
        switch ($ServiceType)
        {
            'DatabaseEngine'
            {
                $serviceTypeValue = 'SqlServer'

                break
            }

            'SqlServerAgent'
            {
                $serviceTypeValue = 'SqlAgent'

                break
            }

            'Search'
            {
                $serviceTypeValue = 'Search'

                break
            }

            'IntegrationServices'
            {
                $serviceTypeValue = 'SqlServerIntegrationService'

                break
            }

            'AnalysisServices'
            {
                $serviceTypeValue = 'AnalysisServer'

                break
            }

            'ReportingServices'
            {
                $serviceTypeValue = 'ReportServer'

                break
            }

            'SQLServerBrowser'
            {
                $serviceTypeValue = 'SqlBrowser'

                break
            }

            'NotificationServices'
            {
                $serviceTypeValue = 'NotificationServer'

                break
            }
        }

        return $serviceTypeValue -as [Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType]
    }
}
