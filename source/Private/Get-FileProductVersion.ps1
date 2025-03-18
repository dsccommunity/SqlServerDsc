<#
    .SYNOPSIS
        Gets the product version of a file.

    .DESCRIPTION
        Gets the product version of a file and returns it as a System.Version object.
        This can be useful for checking the version of installed components or binaries.

    .PARAMETER Path
        The path to the file to get the product version from.

    .EXAMPLE
        Get-FileProductVersion -Path 'C:\Temp\setup.exe'

        Returns the product version of the file setup.exe as a System.Version object.
#>
function Get-FileProductVersion
{
    [CmdletBinding()]
    [OutputType([System.Version])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    try
    {
        $fileItem = Get-Item -Path $Path -ErrorAction 'Stop'

        return [System.Version] $fileItem.VersionInfo.ProductVersion
    }
    catch
    {
        $errorMessage = $script:localizedData.Get_FileProductVersion_GetFileProductVersionError -f $Path, $_.Exception.Message

        Write-Error -Message $errorMessage -ErrorAction 'Stop'
    }
}
