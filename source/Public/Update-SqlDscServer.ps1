<#
    .SYNOPSIS
        Perform minor version updates to the SQL Server instance.
    .DESCRIPTION
        Perform minor version updates to the SQL Server instance.
        This function will update the SQL Server instance to the latest minor version
        available in the supplied path.
    .PARAMETER MediaPath
        Specifies the path to look CU or SP files.
    .OUTPUTS
        None.
#>
function Update-SqlDscServer
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $MediaPath,
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [Microsoft.SqlServer.Management.Smo.Server]
        $ServerObject
    )
    $sqlMajorVersion = $ServerObject | Get-SqlDscServerVersion | Select-Object -ExpandProperty Major
    $sqlMinorVersion = $ServerObject | Get-SqlDscServerVersion | Select-Object -ExpandProperty BuildNumber
    $selectedExe = Find-SqlDscLatestCu -MediaPath $MediaPath -MajorVersion $sqlMajorVersion

    if (-not $selectedExe) {
        Write-Error -Message "No update found for SQL Server version $sqlMajorVersion In the folder"
        throw "Could not determine the update file to use"
    }

    $exeMinorVersion = Get-FilePathMinorVersion -Path $selectedExe
    if ($exeMinorVersion -le $sqlMinorVersion) {
        return
    }

    $patchSplat = @(
        "/Action=Patch"
        "/Quiet"
        "/IAcceptSQLServerLicenseTerms"
        "/InstanceId=$(($ServerObject.ServiceInstanceId -split '\.')[1])"
    )
    $process = Start-Process -FilePath $selectedExe -ArgumentList $patchSplat -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Error "The executable encountered an error."
        throw "$($selectedExe) returned an error code of $($process.ExitCode) with message: $($process.StandardOutput)"
    }
}
