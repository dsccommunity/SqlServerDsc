<#
    .SYNOPSIS
        Returns the version information for a file.

    .DESCRIPTION
        Returns the version information for a file.

    .PARAMETER FilePath
        Specifies the file for which to return the version information.

    .EXAMPLE
        Get-FileVersionInformation -FilePath 'E:\setup.exe'

        Returns the version information for the file setup.exe.

    .EXAMPLE
        Get-FileVersionInformation -FilePath (Get-Item -Path 'E:\setup.exe')

        Returns the version information for the file setup.exe.

    .INPUTS
        `System.IO.FileInfo`

        Accepts a file path via the pipeline.

    .OUTPUTS
        `System.Diagnostics.FileVersionInfo`

        Returns the file version information.
#>
function Get-FileVersionInformation
{
    [OutputType([System.Diagnostics.FileVersionInfo])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.FileInfo]
        $FilePath
    )

    process
    {
        $originalErrorActionPreference = $ErrorActionPreference

        $ErrorActionPreference = 'Stop'

        $file = Get-Item -Path $FilePath -ErrorAction 'Stop'

        $ErrorActionPreference = $originalErrorActionPreference

        if ($file.PSIsContainer)
        {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $script:localizedData.FileVersionInformation_Get_FilePathIsNotFile,
                    'GFPVI0001', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $file.FullName
                )
            )
        }

        return $file.VersionInfo
    }
}
