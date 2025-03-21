<#
    .DESCRIPTION
        This example shows how to install a Microsoft SQL Server Reporting Service
        instance (2017 or newer).
#>
Configuration Example
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SqlInstallCredential
    )

    Import-DscResource -ModuleName 'SqlServerDsc'

    node localhost
    {
        SqlRSSetup 'InstallDefaultInstance'
        {
            InstanceName         = 'SSRS'
            Action               = 'Uninstall'
            MediaPath            = 'C:\InstallMedia\SQLServerReportingServices.exe'

            # This needs to be set to although it is not used during uninstall.
            AcceptLicensingTerms = $true

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}
