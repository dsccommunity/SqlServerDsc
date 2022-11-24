<#
    .SYNOPSIS
        Assert that the user has elevated the PowerShell session.

    .DESCRIPTION
        Assert that the user has elevated the PowerShell session.

    .EXAMPLE
        Assert-ElevatedUser

        Throws an exception if the user has not elevated the PowerShell session.

    .OUTPUTS
        None.
#>
function Assert-ElevatedUser
{
    [CmdletBinding()]
    param ()

    $isElevated = $false

    if ($IsMacOS -or $IsLinux)
    {
        $isElevated = (id -u) -eq 0
    }
    else
    {
        [Security.Principal.WindowsPrincipal] $user = [Security.Principal.WindowsIdentity]::GetCurrent()

        $isElevated = $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    if (-not $isElevated)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                $script:localizedData.IsElevated_UserNotElevated,
                'AEU0001',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                'Command parameters'
            )
        )
    }
}
