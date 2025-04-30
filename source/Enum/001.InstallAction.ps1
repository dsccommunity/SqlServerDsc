<#
    .SYNOPSIS
        The possible states for the commands and DSC resources with the parameter
        Action.
#>
enum InstallAction
{
    Install = 1
    Repair
    Uninstall
}
