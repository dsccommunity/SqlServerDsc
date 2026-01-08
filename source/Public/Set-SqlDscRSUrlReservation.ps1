<#
    .SYNOPSIS
        Sets the URL reservations for a SQL Server Reporting Services or Power BI
        Report Server application to the specified list, or recreates all existing
        URL reservations.

    .DESCRIPTION
        The `Set-SqlDscRSUrlReservation` command can operate in two modes:

        **Set Mode (default):** Ensures that only the specified URL reservations
        exist for the given application. It removes any existing URL reservations
        that are not in the specified list and adds any URLs that are not currently
        reserved.

        **Recreate Mode:** When using the `-RecreateExisting` parameter, the command
        removes and re-adds all existing URL reservations for all applications.
        This is useful after changing the Windows service account, as URL reservations
        are tied to a specific service account and must be recreated to use the
        new account.

        This command uses the `Get-SqlDscRSUrlReservation`, `Add-SqlDscRSUrlReservation`,
        and `Remove-SqlDscRSUrlReservation` commands internally.

    .PARAMETER Configuration
        Specifies the Reporting Services configuration CIM instance. This is typically
        obtained by calling the `Get-SqlDscRSConfiguration` command.

    .PARAMETER Application
        Specifies the Reporting Services application for which to set URL reservations.
        Valid values are: ReportServerWebService, ReportServerWebApp, ReportManager.
        This parameter is only used in Set mode.

    .PARAMETER UrlString
        Specifies one or more URL strings to reserve. Any existing URL reservations
        for the application that are not in this list will be removed.
        This parameter is only used in Set mode.

    .PARAMETER Lcid
        Specifies the locale identifier (LCID) for the URL reservation. If not
        specified, the operating system language code is used. Note that the
        LCID used when creating a URL reservation is not stored or retrievable,
        so when using `-RecreateExisting`, the LCID cannot be determined from
        the existing reservations and defaults to the OS language.

    .PARAMETER PassThru
        If specified, returns the Reporting Services configuration CIM instance.

    .PARAMETER Force
        If specified, suppresses the confirmation prompt.

    .PARAMETER RecreateExisting
        If specified, removes and re-adds all existing URL reservations for all
        applications. This is useful after changing the Windows service account,
        as URL reservations are tied to a specific service account and must be
        recreated to use the new account. This parameter cannot be used with
        `-Application` or `-UrlString`.

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

    .EXAMPLE
        $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
        $config | Set-SqlDscRSUrlReservation -RecreateExisting -Force

        Recreates all existing URL reservations for all applications. This is
        useful after changing the service account to update the reservations to
        use the new account.

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
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'Set')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration,

        [Parameter(Mandatory = $true, ParameterSetName = 'Set')]
        [ValidateSet('ReportServerWebService', 'ReportServerWebApp', 'ReportManager')]
        [System.String]
        $Application,

        [Parameter(Mandatory = $true, ParameterSetName = 'Set')]
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
        $Force,

        [Parameter(Mandatory = $true, ParameterSetName = 'Recreate')]
        [System.Management.Automation.SwitchParameter]
        $RecreateExisting
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $instanceName = $Configuration.InstanceName

        # Determine ShouldProcess messages based on parameter set
        if ($PSCmdlet.ParameterSetName -eq 'Recreate')
        {
            $verboseDescriptionMessage = $script:localizedData.Set_SqlDscRSUrlReservation_Recreate_ShouldProcessVerboseDescription -f $instanceName
            $verboseWarningMessage = $script:localizedData.Set_SqlDscRSUrlReservation_Recreate_ShouldProcessVerboseWarning -f $instanceName
            $captionMessage = $script:localizedData.Set_SqlDscRSUrlReservation_Recreate_ShouldProcessCaption
        }
        else
        {
            $verboseDescriptionMessage = $script:localizedData.Set_SqlDscRSUrlReservation_ShouldProcessVerboseDescription -f $Application, $instanceName
            $verboseWarningMessage = $script:localizedData.Set_SqlDscRSUrlReservation_ShouldProcessVerboseWarning -f $Application, $instanceName
            $captionMessage = $script:localizedData.Set_SqlDscRSUrlReservation_ShouldProcessCaption
        }

        if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
        {
            # Get current URL reservations
            $currentReservations = $Configuration | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            if ($PSCmdlet.ParameterSetName -eq 'Recreate')
            {
                if ($null -eq $currentReservations.Application -or $currentReservations.Application.Count -eq 0)
                {
                    Write-Verbose -Message ($script:localizedData.Set_SqlDscRSUrlReservation_NoReservationsToRecreate -f $instanceName)
                }
                else
                {
                    # Build common parameters for Add/Remove commands
                    $commonParams = @{
                        Force       = $true
                        ErrorAction = 'Stop'
                    }

                    <#
                        Note: LCID is not returned by ListReservedUrls, so we cannot determine
                        the original LCID. If not specified, Add-SqlDscRSUrlReservation will
                        use default.
                    #>
                    if ($PSBoundParameters.ContainsKey('Lcid'))
                    {
                        $commonParams['Lcid'] = $Lcid
                    }

                    # Recreate all existing URL reservations
                    for ($i = 0; $i -lt $currentReservations.Application.Count; $i++)
                    {
                        $currentApplication = $currentReservations.Application[$i]
                        $currentUrl = $currentReservations.UrlString[$i]

                        Write-Verbose -Message ($script:localizedData.Set_SqlDscRSUrlReservation_RecreatingUrl -f $currentUrl, $currentApplication, $instanceName)

                        $Configuration | Remove-SqlDscRSUrlReservation @commonParams -Application $currentApplication -UrlString $currentUrl
                        $Configuration | Add-SqlDscRSUrlReservation @commonParams -Application $currentApplication -UrlString $currentUrl
                    }
                }
            }
            else
            {
                # Set parameter set - Build a list of current URLs for the specified application
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

                Write-Debug -Message ($script:localizedData.Set_SqlDscRSUrlReservation_CurrentUrls -f $Application, ($currentUrls -join ', '))
                Write-Debug -Message ($script:localizedData.Set_SqlDscRSUrlReservation_DesiredUrls -f $Application, ($UrlString -join ', '))

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
            }
        }

        if ($PassThru.IsPresent)
        {
            return $Configuration
        }
    }
}
