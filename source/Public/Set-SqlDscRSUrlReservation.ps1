<#
    .SYNOPSIS
        Sets the URL reservations for a SQL Server Reporting Services or Power BI
        Report Server application to the specified list.

    .DESCRIPTION
        The `Set-SqlDscRSUrlReservation` command ensures that only the specified
        URL reservations exist for the given application. It removes any existing
        URL reservations that are not in the specified list and adds any URLs that
        are not currently reserved.

        This command uses the `Get-SqlDscRSUrlReservation`, `Add-SqlDscRSUrlReservation`,
        and `Remove-SqlDscRSUrlReservation` commands internally.

    .PARAMETER Configuration
        Specifies the Reporting Services configuration CIM instance. This is typically
        obtained by calling the `Get-SqlDscRSConfiguration` command.

    .PARAMETER Application
        Specifies the Reporting Services application for which to set URL reservations.
        Valid values are: ReportServerWebService, ReportServerWebApp, ReportManager.

    .PARAMETER UrlString
        Specifies one or more URL strings to reserve. Any existing URL reservations
        for the application that are not in this list will be removed.

    .PARAMETER Lcid
        Specifies the locale identifier (LCID) for the URL reservation. If not
        specified, the operating system language code is used.

    .PARAMETER PassThru
        If specified, returns the Reporting Services configuration CIM instance.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .INPUTS
        Microsoft.Management.Infrastructure.CimInstance

        Accepts a CIM instance for the Reporting Services configuration from the
        pipeline.

    .OUTPUTS
        None by default.

        Microsoft.Management.Infrastructure.CimInstance

        If `-PassThru` is specified, returns the Reporting Services configuration
        CIM instance.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        $config | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString 'http://+:80', 'https://+:443' -Force

        Sets the URL reservations for the ReportServerWebService application to
        only 'http://+:80' and 'https://+:443'. Any other existing reservations
        for this application will be removed.

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
        $config | Set-SqlDscRSUrlReservation -Application 'ReportServerWebApp' -UrlString 'http://+:80' -Force -PassThru

        Sets the URL reservations for the ReportServerWebApp application on a
        Power BI Report Server instance and returns the configuration object.

    .NOTES
        This command calls the ReserveUrl and RemoveURL methods on the
        MSReportServer_ConfigurationSetting CIM class.

    .LINK
        Get-SqlDscRSUrlReservation

    .LINK
        Add-SqlDscRSUrlReservation

    .LINK
        Remove-SqlDscRSUrlReservation

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-reserveurl

    .LINK
        https://docs.microsoft.com/en-us/sql/reporting-services/wmi-provider-library-reference/configurationsetting-method-removeurl
#>
function Set-SqlDscRSUrlReservation
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the examples use pipeline input the rule cannot validate.')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([System.Object])]
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
        [System.String[]]
        $UrlString,

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

        $verboseDescriptionMessage = $script:localizedData.Set_SqlDscRSUrlReservation_ShouldProcessVerboseDescription -f $Application, $instanceName
        $verboseWarningMessage = $script:localizedData.Set_SqlDscRSUrlReservation_ShouldProcessVerboseWarning -f $Application, $instanceName
        $captionMessage = $script:localizedData.Set_SqlDscRSUrlReservation_ShouldProcessCaption

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Get current URL reservations
            $currentReservations = $Configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # Build a list of current URLs for the specified application
            $currentUrls = @()

            if ($null -ne $currentReservations.Application -and $null -ne $currentReservations.UrlString)
            {
                for ($i = 0; $i -lt $currentReservations.Application.Count; $i++)
                {
                    if ($currentReservations.Application[$i] -eq $Application)
                    {
                        $currentUrls += $currentReservations.UrlString[$i]
                    }
                }
            }

            Write-Verbose -Message ($script:localizedData.Set_SqlDscRSUrlReservation_CurrentUrls -f $Application, ($currentUrls -join ', '))
            Write-Verbose -Message ($script:localizedData.Set_SqlDscRSUrlReservation_DesiredUrls -f $Application, ($UrlString -join ', '))

            # Determine URLs to remove (in current but not in desired)
            $urlsToRemove = $currentUrls | Where-Object -FilterScript { $_ -notin $UrlString }

            # Determine URLs to add (in desired but not in current)
            $urlsToAdd = $UrlString | Where-Object -FilterScript { $_ -notin $currentUrls }

            # Build common parameters for Add/Remove commands
            $commonParams = @{
                Application = $Application
                Force       = $true
                ErrorAction = 'Stop'
            }

            if ($PSBoundParameters.ContainsKey('Lcid'))
            {
                $commonParams['Lcid'] = $Lcid
            }

            # Remove URLs that should not exist
            foreach ($urlToRemove in $urlsToRemove)
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscRSUrlReservation_RemovingUrl -f $urlToRemove, $Application, $instanceName)

                $Configuration | Remove-SqlDscRSUrlReservation @commonParams -UrlString $urlToRemove
            }

            # Add URLs that should exist
            foreach ($urlToAdd in $urlsToAdd)
            {
                Write-Verbose -Message ($script:localizedData.Set_SqlDscRSUrlReservation_AddingUrl -f $urlToAdd, $Application, $instanceName)

                $Configuration | Add-SqlDscRSUrlReservation @commonParams -UrlString $urlToAdd
            }

            if ($PassThru.IsPresent)
            {
                return $Configuration
            }
        }
    }
}
