<#
    .SYNOPSIS
        Find the latest Cumulative Update for SQL Server In folder
    .DESCRIPTION
        Find the latest Cumulative Update for SQL Server In folder
        This function will find the latest Cumulative Update for SQL Server in the supplied path.
    .PARAMETER MediaPath
        Specifies the path to look CU files.
    .OUTPUTS
        System.String
#>

function Find-SqlDscLatestCu {

    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $MediaPath,
        [Parameter(Mandatory = $true)]
        [System.String]
        $MajorVersion
    )
    $highestMinorVersion = -1
    $selectedExe = $null
    $exeFiles = Get-ChildItem -Path $MediaPath -Filter *.exe
    foreach ($exeFile in $exeFiles) {
        $fileMajorVersion = Get-FilePathMajorVersion -Path $exeFile.FullName
        if ($fileMajorVersion -eq $MajorVersion) {
            $fileMinorVersion = Get-FilePathMinorVersion -Path $exeFile.FullName
            if ($fileMinorVersion -gt $highestMinorVersion) {
                $highestMinorVersion = $fileMinorVersion
                $selectedExe = $exeFile.FullName
            }
        }
    }
    return $selectedExe
}
