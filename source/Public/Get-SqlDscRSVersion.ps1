<#
    .SYNOPSIS
        Gets the SQL Server Reporting Services version.

    .DESCRIPTION
        Gets the SQL Server Reporting Services version from the setup configuration.
        This is used to determine version-specific behavior.

        The setup configuration object can be obtained using the
        `Get-SqlDscRSSetupConfiguration` command and passed via the pipeline.

    .PARAMETER Configuration
        Specifies the setup configuration object for the Reporting Services instance.
        This can be obtained using the `Get-SqlDscRSSetupConfiguration` command.
        This parameter accepts pipeline input.

    .EXAMPLE
        Get-SqlDscRSSetupConfiguration -InstanceName 'SSRS' | Get-SqlDscRSVersion

        Returns the version for the SSRS instance (e.g. 15.0.1100.0 for SQL 2019).

    .INPUTS
        `System.Management.Automation.PSCustomObject`

        Accepts setup configuration object via pipeline.

    .OUTPUTS
        `System.Version`

        Returns the version of the Reporting Services instance.
#>
function Get-SqlDscRSVersion
{
    [CmdletBinding()]
    [OutputType([System.Version])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Object]
        $Configuration
    )

    process
    {
        if ([System.String]::IsNullOrEmpty($Configuration.CurrentVersion))
        {
            Write-Error -Message $script:localizedData.Get_SqlDscRSVersion_VersionNotFound -Category 'ObjectNotFound' -ErrorId 'GSRSV0001' -TargetObject $Configuration

            return
        }

        $version = [System.Version] $Configuration.CurrentVersion

        return $version
    }
}
