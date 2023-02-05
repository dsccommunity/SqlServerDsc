<#
    .SYNOPSIS
        Converts a normalized service type to a managed service type.

    .DESCRIPTION
        Converts a normalized service type to its managed service type equivalent.

    .PARAMETER ServiceType
        Specifies the normalized service type to convert to the correct manged
        service type.

    .EXAMPLE
        ConvertTo-ManagedServiceType -ServiceType 'DatabaseEngine'

        Returns the manged service type for the normalized service type 'DatabaseEngine'.
#>
function ConvertTo-ManagedServiceType
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet('DatabaseEngine', 'SQLServerAgent', 'Search', 'IntegrationServices', 'AnalysisServices', 'ReportingServices', 'SQLServerBrowser', 'NotificationServices')]
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
            }

            'SQLServerAgent'
            {
                $serviceTypeValue = 'SqlAgent'
            }

            'Search'
            {
                $serviceTypeValue = 'Search'
            }

            'IntegrationServices'
            {
                $serviceTypeValue = 'SqlServerIntegrationService'
            }

            'AnalysisServices'
            {
                $serviceTypeValue = 'AnalysisServer'
            }

            'ReportingServices'
            {
                $serviceTypeValue = 'ReportServer'
            }

            'SQLServerBrowser'
            {
                $serviceTypeValue = 'SqlBrowser'
            }

            'NotificationServices'
            {
                $serviceTypeValue = 'NotificationServer'
            }
        }

        return $serviceTypeValue -as [Microsoft.SqlServer.Management.Smo.Wmi.ManagedServiceType]
    }
}
