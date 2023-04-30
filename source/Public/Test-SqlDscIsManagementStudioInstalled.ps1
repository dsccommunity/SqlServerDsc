<#
    .SYNOPSIS
        Returns whether the SQL Server Management Studio is installed.

    .DESCRIPTION
        Returns whether the SQL Server Management Studio is installed.

    .PARAMETER Version
       Specifies the version for which to check if component is installed.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-SqlDscIsManagementStudioInstalled -Version ([System.Version] '12.0')

        Returns $true if SQL Server Management Studio is installed.
#>
function Test-SqlDscIsManagementStudioInstalled
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
                Verify if SQL Server Management Studio 2008 or SQL Server Management
                Studio 2008 R2 (major version 10) is installed.
            #>
            $productIdentifyingNumber = '{72AB7E6F-BC24-481E-8C45-1AB5B3DD795D}'

            break
        }

        11
        {
            # Verify if SQL Server Management Studio 2012 (major version 11) is installed.
            $productIdentifyingNumber = '{A7037EB2-F953-4B12-B843-195F4D988DA1}'

            break
        }

        12
        {
            # Verify if SQL Server Management Studio 2014 (major version 12) is installed.
            $productIdentifyingNumber = '{75A54138-3B98-4705-92E4-F619825B121F}'

            break
        }

        default
        {
            $writeErrorParameters = @{
                Message = $script:localizedData.IsManagementStudioInstalled_Test_NotSupportedVersion
                Category = 'InvalidOperation'
                ErrorId = 'TIMSI0001' # cSpell: disable-line
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
