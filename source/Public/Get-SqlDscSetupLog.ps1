<#
    .SYNOPSIS
        Get SQL Server setup bootstrap log.

    .DESCRIPTION
        This command retrieves the SQL Server setup bootstrap log (Summary.txt)
        from the most recent setup operation. The log is typically located in
        the Setup Bootstrap\Log directory under the SQL Server installation path.

        This command is useful for diagnosing SQL Server setup failures or
        understanding what occurred during the installation, upgrade, or rebuild
        operations.

    .PARAMETER Path
        Specifies the root SQL Server installation path to search for the setup log
        file. Defaults to 'C:\Program Files\Microsoft SQL Server'.

    .EXAMPLE
        Get-SqlDscSetupLog

        Retrieves the most recent SQL Server setup log from the default location.

    .EXAMPLE
        Get-SqlDscSetupLog -Path 'D:\SQLServer'

        Retrieves the most recent SQL Server setup log from a custom installation path.

    .EXAMPLE
        Get-SqlDscSetupLog -Verbose | Select-String -Pattern 'Error'

        Retrieves the setup log and filters for lines containing 'Error'.

    .OUTPUTS
        `[System.String[]]`

        Returns the content of the setup log file, or null if no log file is found.
#>
function Get-SqlDscSetupLog
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter()]
        [System.String]
        $Path = 'C:\Program Files\Microsoft SQL Server'
    )

    $setupLogFileName = 'Summary.txt'

    Write-Verbose -Message ($script:localizedData.SetupLog_SearchingForFile -f $setupLogFileName, $Path)

    <#
        Find the most recent Summary.txt file from Setup Bootstrap\Log directories.
        Summary.txt is the standard SQL Server setup diagnostic log that records the outcome
        of installation, upgrade, or rebuild operations. Both the 'Summary.txt' filename and
        'Setup Bootstrap\Log' directory pattern are hardcoded as they are fixed SQL Server
        structures and should not be user-configurable. The -Path parameter allows users to
        specify the root search path for cases where SQL Server is installed in non-standard locations.
    #>
    $summaryFiles = Get-ChildItem -Path $Path -Filter $setupLogFileName -Recurse -ErrorAction 'SilentlyContinue' |
        Where-Object -FilterScript { $_.FullName -match '\\Setup Bootstrap\\Log\\' } |
        Sort-Object -Property 'LastWriteTime' -Descending |
        Select-Object -First 1

    $output = @()

    if ($summaryFiles)
    {
        Write-Verbose -Message ($script:localizedData.SetupLog_FileFound -f $summaryFiles.FullName)

        $output += $script:localizedData.SetupLog_Header -f $setupLogFileName, $summaryFiles.FullName
        $output += Get-Content -Path $summaryFiles.FullName
        $output += $script:localizedData.SetupLog_Footer -f $setupLogFileName

        return $output
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SetupLog_FileNotFound -f $setupLogFileName)

        return $null
    }
}
