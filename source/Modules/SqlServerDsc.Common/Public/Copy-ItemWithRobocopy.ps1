<#
    .SYNOPSIS
        Copy folder structure using Robocopy. Every file and folder, including empty ones are copied.

    .PARAMETER Path
        Source path to be copied.

    .PARAMETER DestinationPath
        The path to the destination.
#>
function Copy-ItemWithRobocopy
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DestinationPath
    )

    $quotedPath = '"{0}"' -f $Path
    $quotedDestinationPath = '"{0}"' -f $DestinationPath
    $robocopyExecutable = Get-Command -Name 'Robocopy.exe' -ErrorAction 'Stop'

    $robocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
    $robocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
    $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'

    if ([System.Version]$robocopyExecutable.FileVersionInfo.ProductVersion -ge [System.Version]'6.3.9600.16384')
    {
        Write-Verbose -Message $script:localizedData.RobocopyUsingUnbufferedIo -Verbose

        $robocopyArgumentUseUnbufferedIO = '/J'
    }
    else
    {
        Write-Verbose -Message $script:localizedData.RobocopyNotUsingUnbufferedIo -Verbose
    }

    $robocopyArgumentList = '{0} {1} {2} {3} {4} {5}' -f @(
        $quotedPath,
        $quotedDestinationPath,
        $robocopyArgumentCopySubDirectoriesIncludingEmpty,
        $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
        $robocopyArgumentUseUnbufferedIO,
        $robocopyArgumentSilent
    )

    $robocopyStartProcessParameters = @{
        FilePath     = $robocopyExecutable.Name
        ArgumentList = $robocopyArgumentList
    }

    Write-Verbose -Message ($script:localizedData.RobocopyArguments -f $robocopyArgumentList) -Verbose
    $robocopyProcess = Start-Process @robocopyStartProcessParameters -Wait -NoNewWindow -PassThru

    switch ($($robocopyProcess.ExitCode))
    {
        { $_ -in 8, 16 }
        {
            $errorMessage = $script:localizedData.RobocopyErrorCopying -f $_
            New-InvalidOperationException -Message $errorMessage
        }

        { $_ -gt 7 }
        {
            $errorMessage = $script:localizedData.RobocopyFailuresCopying -f $_
            New-InvalidResultException -Message $errorMessage
        }

        1
        {
            Write-Verbose -Message $script:localizedData.RobocopySuccessful -Verbose
        }

        2
        {
            Write-Verbose -Message $script:localizedData.RobocopyRemovedExtraFilesAtDestination -Verbose
        }

        3
        {
            Write-Verbose -Message (
                '{0} {1}' -f $script:localizedData.RobocopySuccessful, $script:localizedData.RobocopyRemovedExtraFilesAtDestination
            ) -Verbose
        }

        { $_ -eq 0 -or $null -eq $_ }
        {
            Write-Verbose -Message $script:localizedData.RobocopyAllFilesPresent -Verbose
        }
    }
}
