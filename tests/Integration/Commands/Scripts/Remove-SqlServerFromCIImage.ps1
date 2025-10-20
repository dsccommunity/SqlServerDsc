<#
    .SYNOPSIS
        Removes all pre-installed SQL Server components from Microsoft Hosted CI agents.

    .DESCRIPTION
        This script removes all SQL Server related products that may be pre-installed
        on Microsoft Hosted agents. These pre-installed components can conflict with
        SQL Server Sysprep/PrepareImage operations, causing errors like "Setup has
        detected that there are SQL Server features already installed on this machine
        that do not support Sysprep."

        The script identifies and uninstalls:
        - SQL Server LocalDB
        - SQL Server Client Tools
        - SQL Server Shared Components
        - SQL Server Browser
        - Any other SQL Server related products

    .PARAMETER WhatIf
        Shows what would be removed without actually removing anything.

    .PARAMETER Confirm
        Prompts for confirmation before removing each product.

    .EXAMPLE
        .\Remove-SqlServerFromCIImage.ps1

        Removes all pre-installed SQL Server components from the CI agent.

    .EXAMPLE
        .\Remove-SqlServerFromCIImage.ps1 -WhatIf

        Shows what SQL Server components would be removed without actually removing them.

    .NOTES
        This script should be run on Microsoft Hosted agents before performing
        SQL Server PrepareImage operations.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param
(
    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $Force
)

$ErrorActionPreference = 'Stop'

if ($Force.IsPresent -and -not $Confirm)
{
    $ConfirmPreference = 'None'
}

Write-Information -MessageData 'Starting removal of pre-installed SQL Server components from CI image...' -InformationAction 'Continue'

# Registry paths to check for installed products
$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

Write-Verbose -Message 'Scanning registry for SQL Server products...'

$allProducts = Get-ItemProperty -Path $uninstallKeys -ErrorAction 'SilentlyContinue'

# Define patterns to match SQL Server related products
$sqlServerPatterns = @(
    '*SQL Server*LocalDB*',
    '*SQL Server*Client*',
    '*SQL Server*Shared*',
    '*SQL Server*Browser*',
    '*SQL Server*Management*',
    '*SQL Server*Tools*',
    '*SQL Server*Native*Client*',
    '*SQL Server*ODBC*',
    '*SQL Server*OLE*DB*',
    '*SQL Server*T-SQL*',
    '*SQL Server*Command*Line*Utilities*',
    '*SQL Server*Data*Tier*',
    '*Microsoft*ODBC*Driver*SQL*Server*',
    '*Microsoft*OLE*DB*Driver*SQL*Server*'
)

# Find all SQL Server related products
$sqlServerProducts = $allProducts | Where-Object {
    $displayName = $_.DisplayName

    if (-not $displayName)
    {
        return $false
    }

    foreach ($pattern in $sqlServerPatterns)
    {
        if ($displayName -like $pattern)
        {
            return $true
        }
    }

    return $false
}

if (-not $sqlServerProducts)
{
    Write-Information -MessageData 'No pre-installed SQL Server components found on this CI image.' -InformationAction 'Continue'

    return
}

Write-Information -MessageData ('Found {0} SQL Server related product(s) to remove:' -f $sqlServerProducts.Count) -InformationAction 'Continue'

foreach ($product in $sqlServerProducts)
{
    Write-Information -MessageData ('  - {0} (Version: {1})' -f $product.DisplayName, $product.DisplayVersion) -InformationAction 'Continue'
}

Write-Information -MessageData '' -InformationAction 'Continue'

$removedCount = 0
$failedCount = 0
$skippedCount = 0

foreach ($product in $sqlServerProducts)
{
    $productName = $product.DisplayName
    $productCode = $product.PSChildName
    $uninstallString = $product.UninstallString

    Write-Verbose -Message ('Processing: {0}' -f $productName)

    # Skip if no uninstall information is available
    if (-not $productCode -and -not $uninstallString)
    {
        Write-Warning -Message ('Skipping {0}: No uninstall information found.' -f $productName)
        $skippedCount++

        continue
    }

    $descriptionMessage = 'Removing SQL Server component ''{0}'' with product code ''{1}'' from the CI image.' -f $productName, $productCode
    $confirmationMessage = 'Are you sure you want to remove ''{0}''?' -f $productName
    $captionMessage = 'Removing SQL Server component from CI image'

    if ($PSCmdlet.ShouldProcess($descriptionMessage, $confirmationMessage, $captionMessage))
    {
        try
        {
            Write-Information -MessageData ('Uninstalling: {0}...' -f $productName) -InformationAction 'Continue'

            # Determine uninstall method based on product code format
            if ($productCode -match '^\{[A-F0-9\-]+\}$')
            {
                # MSI product - use msiexec
                $uninstallArgs = @(
                    '/x'
                    $productCode
                    '/qn'
                    '/norestart'
                    '/L*v'
                    (Join-Path -Path $env:TEMP -ChildPath ('SqlServerUninstall_{0}.log' -f $productCode))
                )

                Write-Verbose -Message ('Using msiexec to uninstall product code: {0}' -f $productCode)

                $previousErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Continue'

                $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $uninstallArgs -Wait -PassThru -NoNewWindow

                $ErrorActionPreference = $previousErrorActionPreference

                if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010)
                {
                    Write-Information -MessageData ('Successfully uninstalled: {0}' -f $productName) -InformationAction 'Continue'
                    $removedCount++
                }
                else
                {
                    Write-Warning -Message ('Failed to uninstall {0}. Exit code: {1}' -f $productName, $process.ExitCode)
                    $failedCount++
                }
            }
            elseif ($uninstallString)
            {
                # Custom uninstaller
                Write-Verbose -Message ('Using custom uninstaller: {0}' -f $uninstallString)

                # Parse uninstall string to separate executable and arguments
                if ($uninstallString -match '^"([^"]+)"(.*)$')
                {
                    $executable = $Matches[1]
                    $arguments = $Matches[2].Trim()
                }
                else
                {
                    $executable = $uninstallString
                    $arguments = ''
                }

                # Add silent flags if not already present
                if ($arguments -notmatch '/quiet|/silent|/s\b|/qn')
                {
                    $arguments += ' /quiet /norestart'
                }

                Write-Verbose -Message ('Executable: {0}' -f $executable)
                Write-Verbose -Message ('Arguments: {0}' -f $arguments)

                if (Test-Path -Path $executable)
                {
                    $previousErrorActionPreference = $ErrorActionPreference
                    $ErrorActionPreference = 'Continue'

                    $process = Start-Process -FilePath $executable -ArgumentList $arguments -Wait -PassThru -NoNewWindow

                    $ErrorActionPreference = $previousErrorActionPreference

                    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010)
                    {
                        Write-Information -MessageData ('Successfully uninstalled: {0}' -f $productName) -InformationAction 'Continue'
                        $removedCount++
                    }
                    else
                    {
                        Write-Warning -Message ('Failed to uninstall {0}. Exit code: {1}' -f $productName, $process.ExitCode)
                        $failedCount++
                    }
                }
                else
                {
                    Write-Warning -Message ('Uninstaller not found: {0}' -f $executable)
                    $failedCount++
                }
            }
            else
            {
                Write-Warning -Message ('Skipping {0}: Unable to determine uninstall method.' -f $productName)
                $skippedCount++
            }
        }
        catch
        {
            Write-Warning -Message ('Error uninstalling {0}: {1}' -f $productName, $_.Exception.Message)
            $failedCount++
        }
    }
    else
    {
        Write-Information -MessageData ('Skipped: {0}' -f $productName) -InformationAction 'Continue'
        $skippedCount++
    }
}

Write-Information -MessageData '' -InformationAction 'Continue'
Write-Information -MessageData 'SQL Server component removal summary:' -InformationAction 'Continue'
Write-Information -MessageData ('  - Successfully removed: {0}' -f $removedCount) -InformationAction 'Continue'
Write-Information -MessageData ('  - Failed to remove: {0}' -f $failedCount) -InformationAction 'Continue'
Write-Information -MessageData ('  - Skipped: {0}' -f $skippedCount) -InformationAction 'Continue'

if ($failedCount -gt 0)
{
    Write-Warning -Message 'Some SQL Server components could not be removed. This may cause issues with PrepareImage operations.'
}
elseif ($removedCount -gt 0)
{
    Write-Information -MessageData 'All SQL Server components were successfully removed.' -InformationAction 'Continue'
    Write-Information -MessageData 'A system restart may be required for changes to take full effect.' -InformationAction 'Continue'
}
