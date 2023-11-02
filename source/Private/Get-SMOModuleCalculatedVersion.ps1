<#
    .SYNOPSIS
        Returns the calculated version of an SMO PowerShell module.

    .DESCRIPTION
        Returns the calculated version of an SMO PowerShell module.

        For SQLServer, the version is calculated using the System.Version
        field with '-preview' appended for pre-release versions . For
        example: 21.1.1 or 22.0.49-preview

        For SQLPS, the version is calculated using the path of the module. For
        example:
        C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules
        returns 130

    .PARAMETER PSModuleInfo
        Specifies the PSModuleInfo object for which to return the calculated version.

    .EXAMPLE
        Get-SMOModuleCalculatedVersion -PSModuleInfo (Get-Module -Name 'sqlps')

        Returns the calculated version as a string.

    .OUTPUTS
        [System.String]
#>
function Get-SMOModuleCalculatedVersion
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.PSModuleInfo]
        $PSModuleInfo
    )

    process
    {
        $version = $null

        if ($PSModuleInfo.Name -eq 'SQLPS')
        {
            <#
                Parse the build version number '120', '130' from the Path.
                Older version of SQLPS did not have correct versioning.
            #>
            $version = $PSModuleInfo.Path -replace '.*\\(\d{2})(\d)\\.*', '$1.$2'
        }
        else
        {
            $version = $PSModuleInfo.Version.ToString()

            if ($PSModuleInfo.PrivateData.PSData.Prerelease)
            {
                $version = '{0}-{1}' -f $PSModuleInfo.Version, $PSModuleInfo.PrivateData.PSData.Prerelease
            }
        }

        return $version
    }
}
