$script:modulesFolderPath = Split-Path -Path $PSScriptRoot -Parent

$script:localizationModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.LocalizationHelper'
Import-Module -Name (Join-Path -Path $script:localizationModulePath -ChildPath 'DscResource.LocalizationHelper.psm1')


$script:localizedData = Get-LocalizedData -ResourceName 'DscResource.Common' -ScriptRoot $PSScriptRoot

<#
    .SYNOPSIS
        This method is used to compare current and desired values for any DSC resource.

    .PARAMETER CurrentValues
        This is hash table of the current values that are applied to the resource.

    .PARAMETER DesiredValues
        This is a PSBoundParametersDictionary of the desired values for the resource.

    .PARAMETER ValuesToCheck
        This is a list of which properties in the desired values list should be checked.
        If this is empty then all values in DesiredValues are checked.
#>
function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $DesiredValues,

        [Parameter()]
        [System.Array]
        $ValuesToCheck
    )

    $returnValue = $true

    if (($DesiredValues.GetType().Name -ne 'HashTable') `
        -and ($DesiredValues.GetType().Name -ne 'CimInstance') `
        -and ($DesiredValues.GetType().Name -ne 'PSBoundParametersDictionary'))
    {
        $errorMessage = $script:localizedData.PropertyTypeInvalidForDesiredValues -f $($DesiredValues.GetType().Name)
        New-InvalidArgumentException -ArgumentName 'DesiredValues' -Message $errorMessage
    }

    if (($DesiredValues.GetType().Name -eq 'CimInstance') -and ($null -eq $ValuesToCheck))
    {
        $errorMessage = $script:localizedData.PropertyTypeInvalidForValuesToCheck
        New-InvalidArgumentException -ArgumentName 'ValuesToCheck' -Message $errorMessage
    }

    if (($null -eq $ValuesToCheck) -or ($ValuesToCheck.Count -lt 1))
    {
        $keyList = $DesiredValues.Keys
    }
    else
    {
        $keyList = $ValuesToCheck
    }

    $keyList | ForEach-Object -Process {
        if (($_ -ne 'Verbose'))
        {
            if (($CurrentValues.ContainsKey($_) -eq $false) `
            -or ($CurrentValues.$_ -ne $DesiredValues.$_) `
            -or (($DesiredValues.GetType().Name -ne 'CimInstance' -and $DesiredValues.ContainsKey($_) -eq $true) -and ($null -ne $DesiredValues.$_ -and $DesiredValues.$_.GetType().IsArray)))
            {
                if ($DesiredValues.GetType().Name -eq 'HashTable' -or `
                    $DesiredValues.GetType().Name -eq 'PSBoundParametersDictionary')
                {
                    $checkDesiredValue = $DesiredValues.ContainsKey($_)
                }
                else
                {
                    # If DesiredValue is a CimInstance.
                    $checkDesiredValue = $false
                    if (([System.Boolean]($DesiredValues.PSObject.Properties.Name -contains $_)) -eq $true)
                    {
                        if ($null -ne $DesiredValues.$_)
                        {
                            $checkDesiredValue = $true
                        }
                    }
                }

                if ($checkDesiredValue)
                {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    if ($desiredType.IsArray -eq $true)
                    {
                        if (($CurrentValues.ContainsKey($fieldName) -eq $false) `
                        -or ($null -eq $CurrentValues.$fieldName))
                        {
                            Write-Verbose -Message ($script:localizedData.PropertyValidationError -f $fieldName) -Verbose

                            $returnValue = $false
                        }
                        else
                        {
                            $arrayCompare = Compare-Object -ReferenceObject $CurrentValues.$fieldName `
                                                           -DifferenceObject $DesiredValues.$fieldName
                            if ($null -ne $arrayCompare)
                            {
                                Write-Verbose -Message ($script:localizedData.PropertiesDoesNotMatch -f $fieldName) -Verbose

                                $arrayCompare | ForEach-Object -Process {
                                    Write-Verbose -Message ($script:localizedData.PropertyThatDoesNotMatch -f $_.InputObject, $_.SideIndicator) -Verbose
                                }

                                $returnValue = $false
                            }
                        }
                    }
                    else
                    {
                        switch ($desiredType.Name)
                        {
                            'String'
                            {
                                if (-not [System.String]::IsNullOrEmpty($CurrentValues.$fieldName) -or `
                                    -not [System.String]::IsNullOrEmpty($DesiredValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            'Int32'
                            {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            { $_ -eq 'Int16' -or $_ -eq 'UInt16' -or $_ -eq 'Single' }
                            {
                                if (-not ($DesiredValues.$fieldName -eq 0) -or `
                                    -not ($null -eq $CurrentValues.$fieldName))
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            'Boolean'
                            {
                                if ($CurrentValues.$fieldName -ne $DesiredValues.$fieldName)
                                {
                                    Write-Verbose -Message ($script:localizedData.ValueOfTypeDoesNotMatch `
                                        -f $desiredType.Name, $fieldName, $($CurrentValues.$fieldName), $($DesiredValues.$fieldName)) -Verbose

                                    $returnValue = $false
                                }
                            }

                            default
                            {
                                Write-Warning -Message ($script:localizedData.UnableToCompareProperty `
                                    -f $fieldName, $desiredType.Name)

                                $returnValue = $false
                            }
                        }
                    }
                }
            }
        }
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Returns the value of the provided in the Name parameter, at the registry
        location provided in the Path parameter.

    .PARAMETER Path
        String containing the path in the registry to the property name.

    .PARAMETER PropertyName
        String containing the name of the property for which the value is returned.
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

    <#
        Using a try/catch block instead of 'SilentlyContinue' to be
        able to unit test a failing registry path.
    #>
    try
    {
        $getItemPropertyResult = (Get-ItemProperty @getItemPropertyParameters -ErrorAction Stop).$Name
    }
    catch
    {
         $getItemPropertyResult = $null
    }

    return $getItemPropertyResult
}

<#
    .SYNOPSIS
        Returns the value of the provided in the Name parameter, at the registry
        location provided in the Path parameter.

    .PARAMETER Path
        String containing the path in the registry to the property name.

    .PARAMETER PropertyName
        String containing the name of the property for which the value is returned.
#>
function Format-Path
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $TrailingSlash
    )

    # Remove trailing slash ('\') from path.
    if ($TrailingSlash.IsPresent)
    {
        <#
            Trim backslash, but only if the path contains a full path and
            not just a qualifier.
        #>
        if ($Path -notmatch '^[a-zA-Z]:\\$')
        {
            $Path = $Path.TrimEnd('\')
        }

        <#
            If the path only contains a qualifier but no backslash ('M:'),
            then a backslash is added ('M:\').
        #>
        if ($Path -match '^[a-zA-Z]:$')
        {
            $Path = '{0}\' -f $Path
        }
    }

    return $Path
}

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
    $robocopyExecutable = Get-Command -Name "Robocopy.exe" -ErrorAction Stop

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

    $robocopyArgumentList = '{0} {1} {2} {3} {4} {5}' -f $quotedPath,
                                                         $quotedDestinationPath,
                                                         $robocopyArgumentCopySubDirectoriesIncludingEmpty,
                                                         $robocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                                                         $robocopyArgumentUseUnbufferedIO,
                                                         $robocopyArgumentSilent

    $robocopyStartProcessParameters = @{
        FilePath = $robocopyExecutable.Name
        ArgumentList = $robocopyArgumentList
    }

    Write-Verbose -Message  ($script:localizedData.RobocopyArguments -f $robocopyArgumentList) -Verbose
    $robocopyProcess = Start-Process @robocopyStartProcessParameters -Wait -NoNewWindow -PassThru

    switch ($($robocopyProcess.ExitCode))
    {
        {$_ -in 8, 16}
        {
            $errorMessage = $script:localizedData.RobocopyErrorCopying -f $_
            New-InvalidOperationException -Message $errorMessage
        }

        {$_ -gt 7 }
        {
            $errorMessage = $script:localizedData.RobocopyFailuresCopying -f $_
            New-InvalidResultException -Message $errorMessage
        }

        1
        {
            Write-Verbose -Message  $script:localizedData.RobocopySuccessful -Verbose
        }

        2
        {
            Write-Verbose -Message  $script:localizedData.RobocopyRemovedExtraFilesAtDestination -Verbose
        }

        3
        {
            Write-Verbose -Message  $script:localizedData.RobocopySuccessfulAndRemovedExtraFilesAtDestination -Verbose
        }

        {$_ -eq 0 -or $null -eq $_ }
        {
            Write-Verbose -Message  $script:localizedData.RobocopyAllFilesPresent -Verbose
        }
    }
}

<#
    .SYNOPSIS
        Returns the path of the current user's temporary folder.
#>
function Get-TemporaryFolder
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param()

    return [IO.Path]::GetTempPath()
}

<#
    .SYNOPSIS
        Connects to the source using the provided credentials and then uses
        robocopy to download the installation media to a local temporary folder.

    .PARAMETER SourcePath
        Source path to be copied.

    .PARAMETER SourceCredential
        The credentials to access the SourcePath.

    .PARAMETER PassThru
        If used, returns the destination path as string.

    .OUTPUTS
        Returns the destination path (when used with the parameter PassThru).
#>
function Invoke-InstallationMediaCopy
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SourcePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    Connect-UncPath -RemotePath $SourcePath -SourceCredential $SourceCredential

    <#
        Create a destination folder so the media files aren't written
        to the root of the Temp folder.
    #>
    $mediaDestinationFolder = Split-Path -Path $SourcePath -Leaf
    if (-not $mediaDestinationFolder )
    {
        $mediaDestinationFolder = New-Guid | Select-Object -ExpandProperty Guid
    }

    $mediaDestinationPath = Join-Path -Path (Get-TemporaryFolder) -ChildPath $mediaDestinationFolder

    Write-Verbose -Message ($script:localizedData.RobocopyIsCopying -f $SourcePath, $mediaDestinationPath)
    Copy-ItemWithRobocopy -Path $SourcePath -DestinationPath $mediaDestinationPath

    Disconnect-UncPath -RemotePath $SourcePath

    if ($PassThru.IsPresent)
    {
        return $mediaDestinationPath
    }
}

<#
    .SYNOPSIS
        Connects to the UNC path provided in the parameter SourcePath.
        Optionally connects using the provided credentials.

    .PARAMETER SourcePath
        Source path to connect to.

    .PARAMETER SourceCredential
        The credentials to access the path provided in SourcePath.

    .PARAMETER PassThru
        If used, returns a MSFT_SmbMapping object that represents the newly
        created SMB mapping.

    .OUTPUTS
        Returns a MSFT_SmbMapping object that represents the newly created
        SMB mapping (ony when used with parameter PassThru).
#>
function Connect-UncPath
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemotePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $SourceCredential,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    $newSmbMappingParameters = @{
        RemotePath = $RemotePath
    }

    if ($PSBoundParameters.ContainsKey('SourceCredential'))
    {
        $newSmbMappingParameters['UserName'] = "$($SourceCredential.GetNetworkCredential().Domain)\$($SourceCredential.GetNetworkCredential().UserName)"
        $newSmbMappingParameters['Password'] = $SourceCredential.GetNetworkCredential().Password
    }

    $newSmbMappingResult = New-SmbMapping @newSmbMappingParameters

    if ($PassThru.IsPresent)
    {
        return $newSmbMappingResult
    }
}

<#
    .SYNOPSIS
        Disconnects from the UNC path provided in the parameter SourcePath.

    .PARAMETER SourcePath
        Source path to disconnect from.
#>
function Disconnect-UncPath
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemotePath
    )

    Remove-SmbMapping -RemotePath $RemotePath -Force
}

<#
    .SYNOPSIS
        Queries the registry and returns $true if there is a pending reboot.

    .OUTPUTS
        Returns $true if there is a pending reboot, otherwise it returns $false.
#>
function Test-PendingReboot
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
    )

    $getRegistryPropertyValueParameters = @{
        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        Name = 'PendingFileRenameOperations'
    }

    <#
        If the key 'PendingFileRenameOperations' does not exist then if should
        return $false, otherwise it should return $true.
    #>
    return $null -ne (Get-RegistryPropertyValue @getRegistryPropertyValueParameters)
}

<#
    .SYNOPSIS
        Starts the SQL setup process.

    .PARAMETER FilePath
        String containing the path to setup.exe.

    .PARAMETER ArgumentList
        The arguments that should be passed to setup.exe.

    .PARAMETER Timeout
        The timeout in seconds to wait for the process to finish.
#>
function Start-SqlSetupProcess
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath,

        [Parameter()]
        [System.String]
        $ArgumentList,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Timeout
    )

    $startProcessParameters = @{
        FilePath = $FilePath
        ArgumentList = $ArgumentList
    }

    $sqlSetupProcess = Start-Process @startProcessParameters -PassThru -NoNewWindow -ErrorAction Stop

    Write-Verbose -Message ($script:localizedData.StartSetupProcess -f $sqlSetupProcess.Id, $startProcessParameters.FilePath, $Timeout) -Verbose

    Wait-Process -InputObject $sqlSetupProcess -Timeout $Timeout -ErrorAction Stop

    return $sqlSetupProcess.ExitCode
}

Export-ModuleMember -Function @(
    'Test-DscParameterState'
    'Get-RegistryPropertyValue'
    'Format-Path'
    'Copy-ItemWithRobocopy'
    'Get-TemporaryFolder'
    'Invoke-InstallationMediaCopy'
    'Connect-UncPath'
    'Disconnect-UncPath'
    'Test-PendingReboot'
    'Start-SqlSetupProcess'
)
