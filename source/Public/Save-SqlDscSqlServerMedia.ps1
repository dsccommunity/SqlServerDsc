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

    .PARAMETER Url
        The URL of the SQL Server media to download.

    .PARAMETER DestinationPath
        The file path where the downloaded media file should be saved.

    .PARAMETER FileName
        The file name of the downloaded media file. Defaults to media.iso if not
        provided.

    .PARAMETER Language
        The language parameter specifies the language of the downloaded iso. This
        parameter is only used when the provided URL is an executable file. Defaults
        to 'en-US' if not provided.

    .PARAMETER Quiet
        Disables verbose progress output during the download process.

    .PARAMETER Force
        Forces the download of the media file even if the file already exists at the
        specified destination path.

    .EXAMPLE
        Save-SqlDscSqlServerMedia -Url 'https://download.microsoft.com/download/c/c/9/cc9c6797-383c-4b24-8920-dc057c1de9d3/SQL2022-SSEI-Dev.exe' -DestinationPath 'C:\path\to\destination'

        This downloads the SQL Server 2022 media and saves it to the specified destination path.

    .EXAMPLE
        Save-SqlDscSqlServerMedia -Url 'https://download.microsoft.com/download/d/a/2/da259851-b941-459d-989c-54a18a5d44dd/SQL2019-SSEI-Dev.exe' -DestinationPath 'C:\path\to\destination'

        This downloads the SQL Server 2019 media and saves it to the specified destination path.

    .EXAMPLE
        Save-SqlDscSqlServerMedia -Url 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU.iso' -DestinationPath 'C:\path\to\destination'

        This downloads the SQL Server 2017 media and saves it to the specified destination path.

    .EXAMPLE
        Save-SqlDscSqlServerMedia -Url 'https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SQLServer2016SP1-FullSlipstream-x64-ENU.iso' -DestinationPath 'C:\path\to\destination'

        This downloads the SQL Server 2016 media and saves it to the specified destination path.
#>
function Save-SqlDscSqlServerMedia
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        [ValidateScript({ Test-Path $_ -PathType 'Container' })]
        $DestinationPath,

        [Parameter()]
        [System.String]
        $FileName = 'media.iso',

        [Parameter()]
        # Supported by SQL Server version 2019 and 2022.
        [ValidateSet('zh-CN', 'zh-TW', 'en-US', 'fr-FR', 'de-DE', 'it-IT', 'ja-JP', 'ko-KR', 'pt-BR', 'ru-RU', 'es-ES')]
        [System.String]
        $Language = 'en-US',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Quiet,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ((Get-Item -Path "$DestinationPath/*.iso" -Force).Count -gt 0)
    {
        $auditAlreadyPresentMessage = $script:localizedData.SqlServerMedia_Save_InvalidDestinationFolder

        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                $auditAlreadyPresentMessage,
                'SSDSSM0001', # cspell: disable-line
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $DestinationPath
            )
        )
    }

    $destinationFilePath = Join-Path -Path $DestinationPath -ChildPath $FileName

    if ((Test-Path -Path $destinationFilePath) -and (-not $Force))
    {
        $verboseDescriptionMessage = $script:localizedData.SqlServerMedia_Save_ShouldProcessVerboseDescription -f $destinationFilePath
        $verboseWarningMessage = $script:localizedData.qlServerMedia_Save_ShouldProcessVerboseWarning -f $destinationFilePath
        $captionMessage = $script:localizedData.qlServerMedia_Save_ShouldProcessCaption

        if (-not ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage)))
        {
            return
        }

        Remove-Item -Path $destinationFilePath -Force
    }

    # TODO: Localize all the verbose messages.
    Write-Verbose -Message "Downloading SQL Server media to '$destinationFilePath'"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $isExecutable = $false

    if ($Url -match '\.exe$')
    {
        Write-Verbose -Message 'Provided URL is an executable file. Downloading the executable file.'

        $isExecutable = $true

        # Change the file extension of the destination file path to .exe
        $destinationExecutableFilePath = [System.IO.Path]::ChangeExtension($destinationFilePath, 'exe')

        $downloadedFilePath = $destinationExecutableFilePath
    }
    else
    {
        Write-Verbose -Message 'Provided URL is a direct link to an ISO file. Downloading the ISO file.'

        $downloadedFilePath = $destinationFilePath
    }

    if ($Quiet.IsPresent)
    {
        <#
            By switching to 'SilentlyContinue' it removes the progress bar of
            Invoke-WebRequest and should also theoretically increase the download
            speed.
        #>
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
    }

    # Download the URL content.
    Invoke-WebRequest -Uri $Url -OutFile $downloadedFilePath | Out-Null

    if ($Quiet.IsPresent)
    {
        # Revert the progress preference back to the previous value.
        $ProgressPreference = $previousProgressPreference
    }

    if ($isExecutable)
    {
        Write-Verbose -Message 'Provided URL was an executable file. Using executable to download the media file.'

        $executableArguments = @(
            '/Quiet'
        )

        if ($VerbosePreference -eq 'SilentlyContinue')
        {
            $executableArguments += @(
                '/HideProgressBar'
            )
        }
        else
        {
            $executableArguments += @(
                '/Verbose'
            )
        }

        $executableArguments += @(
            '/Action=Download',
            "/Language=$Language",
            '/MediaType=ISO',
            "/MediaPath=$destinationPath"
        )

        $startProcessArgumentList = $executableArguments -join ' '

        # Download ISO media using the downloaded executable.
        Start-Process -FilePath $destinationExecutableFilePath -ArgumentList $startProcessArgumentList -Wait

        Write-Verbose -Message 'Removing the downloaded executable file.'

        # Remove the downloaded executable.
        Remove-Item -Path $destinationExecutableFilePath -Force

        # Get all the iso files in the destination path and if there are more than one throw an error.
        $isoFile = Get-Item -Path "$DestinationPath/*.iso" -Force

        if ($isoFile.Count -gt 1)
        {
            # TODO: Fix to Write-Error
            throw 'More than one iso file found in the destination path. Cannot determine which was downloaded.'
        }

        Write-Verbose -Message ('Renaming the downloaded iso file from ''{0}'' to ''{1}''' -f $isoFile.Name, $FileName)

        # Rename the iso file in the destination path.
        Rename-Item -Path $isoFile.FullName -NewName $FileName -Force
    }

    return (Get-Item -Path $destinationFilePath)
}
