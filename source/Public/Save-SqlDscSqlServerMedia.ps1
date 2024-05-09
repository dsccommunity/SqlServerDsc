<#
    .SYNOPSIS
        Downloads SQL Server media from a provided URL and saves the downloaded
        media file to the specified file path

    .DESCRIPTION
        The Save-SqlDscSqlServerMedia function downloads SQL Server media from a
        provided URL and saves the downloaded media file to the specified file path.

        If the URL ends with ".exe", it is treated as an executable that downloads
        an ISO. If it doesn't, it is treated as a direct link to an ISO.

        The function also prints the SHA1 hash of the downloaded file.

    .PARAMETER MediaUrl
        The URL of the SQL Server media to download.

    .PARAMETER DestinationPath
        The file path where the downloaded media file should be saved.

    .PARAMETER FileName
        The file name of the downloaded media file. Defaults to media.iso if not
        provided.

    .PARAMETER Quiet
        Disables verbose progress output during the download process.

    .EXAMPLE
        Save-SqlServerMedia -MediaUrl 'https://download.microsoft.com/download/c/c/9/cc9c6797-383c-4b24-8920-dc057c1de9d3/SQL2022-SSEI-Dev.exe' -DestinationPath 'C:\path\to\destination'

        This downloads the SQL Server 2022 media and saves it to the specified destination path.

    .EXAMPLE
        Save-SqlServerMedia -MediaUrl 'https://download.microsoft.com/download/d/a/2/da259851-b941-459d-989c-54a18a5d44dd/SQL2019-SSEI-Dev.exe' -DestinationPath 'C:\path\to\destination'

        This downloads the SQL Server 2019 media and saves it to the specified destination path.

    .EXAMPLE
        Save-SqlServerMedia -MediaUrl 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU.iso' -DestinationPath 'C:\path\to\destination'

        This downloads the SQL Server 2017 media and saves it to the specified destination path.

    .EXAMPLE
        Save-SqlServerMedia -MediaUrl 'https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SQLServer2016SP1-FullSlipstream-x64-ENU.iso' -DestinationPath 'C:\path\to\destination'

        This downloads the SQL Server 2016 media and saves it to the specified destination path.
#>
function Save-SqlDscSqlServerMedia
{
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $MediaUrl,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        $DestinationPath,

        [Parameter()]
        [System.String]
        $FileName = 'media.iso',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Quiet
    )

    # if ($Quiet.IsPresent)
    # {
    #     # By switching to 'SilentlyContinue' should theoretically increase the download speed.
    #     $previousProgressPreference = $ProgressPreference
    #     $ProgressPreference = 'SilentlyContinue'
    # }

    $destinationFilePath = Join-Path -Path $DestinationPath -ChildPath $FileName

    Write-Verbose -Message "Downloading SQL Server media to '$destinationFilePath'"

    Write-Verbose -Message "Start downloading the SQL Server media at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if ($MediaUrl -match '\.exe$')
    {
        # Change the file extension of the destination file path to .exe
        $destinationExecutableFilePath = [System.IO.Path]::ChangeExtension($destinationFilePath, 'exe')

        # Download the executable that will be used to download the ISO media.
        Invoke-WebRequest -Uri $MediaUrl -OutFile $destinationExecutableFilePath | Out-Null

        Write-Verbose -Message 'Provided URL was an executable file. Using executable to download the media file.'

        $executableArguments = @()

        if ($Quiet.IsPresent)
        {
            Write-Verbose -Message 'Quiet mode enabled.'

            $executableArguments += @(
                '/Quiet'            )
        }

        if ($VerbosePreference -eq 'SilentlyContinue')
        {
            $executableArguments += @(
                '/HideProgressBar'
            )
        }

        $executableArguments += @(
            '/ENU',
            '/Action=Download',
            '/Language=en-US',
            '/MediaType=ISO',
            "/MediaPath=$destinationFilePath"
        )

        $startProcessArgumentList = $executableArguments -join ' '

        # Download ISO media using the downloaded executable.
        Start-Process -FilePath $destinationFilePath -ArgumentList $startProcessArgumentList -Wait
    }
    else
    {
        # Direct ISO download
        Invoke-WebRequest -Uri $MediaUrl -OutFile $destinationFilePath
    }

    # if ($Quiet.IsPresent)
    # {
    #     $ProgressPreference = $previousProgressPreference
    # }

    Write-Verbose -Message "Finished downloading the SQL Server media iso at $(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')" -Verbose

    return (Get-Item -Path $destinationFilePath)
}
