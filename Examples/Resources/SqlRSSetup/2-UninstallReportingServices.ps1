<#
    .EXAMPLE
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

    Import-DscResource -ModuleName SqlServerDsc

    node localhost
    {
        SqlRSSetup 'InstallDefaultInstance'
        {
            InstanceName         = 'SSRS'
            IAcceptLicensTerms   = 'Yes'
            Action               = 'Uninstall'

            PsDscRunAsCredential = $SqlInstallCredential
        }
    }
}
