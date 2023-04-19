<#
    .SYNOPSIS
        Returns the value of the provided property at the provided registry
        path.

    .DESCRIPTION
        Returns the value of the provided property at the provided registry
        path.

    .PARAMETER Path
        Specifies the path in the registry to the property name.

    .PARAMETER PropertyName
        Specifies the the name of the property to return the value for.

    .EXAMPLE
        Get-RegistryPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSAS13.SQL2016\Setup' -Name 'Version'

        Returns the registry value for the property name 'Version' in the specified
        registry path.
#>
function Get-RegistryPropertyValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $getItemPropertyParameters = @{
        Path = $Path
        Name = $Name
    }

    $getItemPropertyResult = (Get-ItemProperty @getItemPropertyParameters).$Name

    return $getItemPropertyResult
}
