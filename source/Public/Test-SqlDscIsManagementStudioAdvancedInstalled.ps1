<#
    .SYNOPSIS
        Returns whether the SQL Server Management Studio Advanced is installed.

    .DESCRIPTION
        Returns whether the SQL Server Management Studio Advanced is installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsManagementStudioAdvancedInstalled -Version ([System.Version] '12.0')

        Returns $true if SQL Server Management Studio Advanced is installed.
#>
function Test-SqlDscIsManagementStudioAdvancedInstalled
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Version]
        $Version
    )

    # If an unsupported version was passed, make sure the function returns $false.
    $productIdentifyingNumber = $null

    switch ($Version.Major)
    {
        10
        {
            <#
                Evaluating if SQL Server Management Studio Advanced 2008 or
                SQL Server Management Studio Advanced 2008 R2 (major version 10)
                is installed.
            #>
            $productIdentifyingNumber = '{B5FE23CC-0151-4595-84C3-F1DE6F44FE9B}'

            break
        }

        11
        {
            <#
                Evaluating if SQL Server Management Studio Advanced 2012 (major
                version 11) is installed.
            #>
            $productIdentifyingNumber = '{7842C220-6E9A-4D5A-AE70-0E138271F883}'

            break
        }

        12
        {
            <#
                Evaluating if SQL Server Management Studio Advanced 2014 (major
                version 12) is installed.
            #>
            $productIdentifyingNumber = '{B5ECFA5C-AC4F-45A4-A12E-A76ABDD9CCBA}'

            break
        }

        default
        {
            $writeErrorParameters = @{
                Message = $script:localizedData.IsManagementStudioAdvancedInstalled_Test_NotSupportedVersion
                Category = 'InvalidOperation'
                ErrorId = 'TIMSAI0001' # cSpell: disable-line
                TargetObject = $Version
            }

            Write-Error @writeErrorParameters
        }
    }

    $result = $false

    if ($productIdentifyingNumber)
    {
        $registryUninstallPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'

        $getItemPropertyParameters = @{
            Path        = Join-Path -Path $registryUninstallPath -ChildPath $productIdentifyingNumber
            ErrorAction = 'SilentlyContinue'
        }

        $registryObject = Get-ItemProperty @getItemPropertyParameters

        if ($registryObject)
        {
            $result = $true
        }
    }

    return $result
}
