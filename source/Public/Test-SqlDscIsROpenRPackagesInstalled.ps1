<#
    .SYNOPSIS
        Returns whether the component R Open and proprietary R packages are installed.

    .DESCRIPTION
        Returns whether the component R Open and proprietary R packages is installed.

    .PARAMETER InstanceId
       Specifies the instance id on which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsROpenRPackagesInstalled -InstanceId 'MSSQL16.SQL2022'

        Returns $true if R Open and proprietary R packages is installed.
#>
function Test-SqlDscIsROpenRPackagesInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InstanceId
    )

    $configurationStateRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\ConfigurationState'

    $getRegistryPropertyValueParameters = @{
        Path        = $configurationStateRegistryPath -f $InstanceId
        Name        = 'sql_inst_mr'
        ErrorAction = 'SilentlyContinue'
    }

    $isROpenRPackagesInstalled = Get-RegistryPropertyValue @getRegistryPropertyValueParameters

    $result = $false

    if ($isROpenRPackagesInstalled -eq 1)
    {
        $result = $true
    }

    return $result
}
