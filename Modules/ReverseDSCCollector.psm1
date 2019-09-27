function Export-SQLServerConfiguration
{
    [CmdletBinding()]
    [OutputType([System.String])]
    $InformationPreference = 'Continue'

    Add-ConfigurationDataEntry -Node 'localhost' -Key "ServerNumber" -Value "1" -Description "Identifier for the Current Server"
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("Configuration SQLServerConfiguration")
    [void]$sb.AppendLine("{")
    [void]$sb.AppendLine("    Import-DSCResource -ModuleName SQLServerDSC")
    [void]$sb.AppendLine("    <# Credentials #>")
    [void]$sb.AppendLine("    Node localhost")
    [void]$sb.AppendLine("    {")

    $ResourcesPath = Join-Path -Path $PSScriptRoot `
                               -ChildPath "..\DSCResources\" `
                               -Resolve
    $AllResources = Get-ChildItem $ResourcesPath -Recurse | Where-Object {$_.Name -like 'MSFT_*.psm1'}

    foreach ($ResourceModule in $AllResources)
    {
        Import-Module $ResourceModule.FullName | Out-Null
        $module = Get-Module ($ResourceModule.Name.Split('.')[0]) | Where-Object -FilterScript {$_.ExportedCommands.Keys -contains 'Export-TargetResource'}
        if ($null -ne $module)
        {
            Write-Information "Exporting $($module.Name)"
            $exportString = Export-TargetResource
            [void]$sb.Append($exportString)
        }
    }

    [void]$sb.AppendLine("    }")
    [void]$sb.AppendLine("}")
    [void]$sb.AppendLine("SQLServerConfiguration -ConfigurationData .\ConfigurationData.psd1")
    $FullContent = Set-ObtainRequiredCredentials -Content $sb.ToString()

    #region Prompt the user for a location to save the extract and generate the files
    if ($null -eq $Path -or "" -eq $Path)
    {
        $OutputDSCPath = Read-Host "Destination Path"
    }
    else
    {
        $OutputDSCPath = $Path
    }

    while ((Test-Path -Path $OutputDSCPath -PathType Container -ErrorAction SilentlyContinue) -eq $false)
    {
        try
        {
            Write-Information "Directory `"$OutputDSCPath`" doesn't exist; creating..."
            New-Item -Path $OutputDSCPath -ItemType Directory | Out-Null
            if ($?) {break}
        }
        catch
        {
            Write-Warning "$($_.Exception.Message)"
            Write-Warning "Could not create folder $OutputDSCPath!"
        }
        $OutputDSCPath = Read-Host "Please Provide Output Folder for DSC Configuration (Will be Created as Necessary)"
    }
    <## Ensures the path we specify ends with a Slash, in order to make sure the resulting file path is properly structured. #>
    if (!$OutputDSCPath.EndsWith("\") -and !$OutputDSCPath.EndsWith("/"))
    {
        $OutputDSCPath += "\"
    }
    $outputDSCFile = $OutputDSCPath + "SQLServerConfiguration.ps1"
    $FullContent | Out-File $outputDSCFile
    $outputConfigurationData = $OutputDSCPath + "ConfigurationData.psd1"
    New-ConfigurationDataDocument -Path $outputConfigurationData

    Invoke-Item -Path $OutputDSCPath
    #endregion
}

function Set-ObtainRequiredCredentials
{
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $Content
    )
    $InformationPreference = 'Continue'
    $credsContent = ""

    foreach($credential in $Global:CredsRepo)
    {
        if (!$credential.ToLower().StartsWith("builtin"))
        {
            if (!$chckAzure.Checked)
            {
                $credsContent += "    " + (Resolve-Credentials $credential) + " = Get-Credential -UserName `"" + $credential + "`" -Message `"Please provide credentials`"`r`n"
            }
            else
            {
                $resolvedName = (Resolve-Credentials $credential)
                $credsContent += "    " + $resolvedName + " = Get-AutomationPSCredential -Name " + ($resolvedName.Replace("$", "")) + "`r`n"
            }
        }
    }
    $credsContent += "`r`n"
    $startPosition = $Content.IndexOf("<# Credentials #>") + 19
    $Content = $Content.Insert($startPosition, $credsContent)
    return $Content
}
