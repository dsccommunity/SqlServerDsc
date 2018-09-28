<#
    .SYNOPSIS
        Assert that the test environment is properly setup and loaded into the
        PowerShell session.

    .DESCRIPTION
        Assert that the test environment is properly setup and loaded into the
        PowerShell session.

    .PARAMETER Force
        Force the cloning of the repository DscResource.Tests, overwriting any
        existing.
#>
[CmdletBinding()]
param
(
    [Parameter()]
    [Switch]
    $Force
)

if (-not (Test-Path -Path '.\DscResource.Tests'))
{
    Write-Verbose -Message 'Cloning DscResource.Tests.'

    git clone 'https://github.com/PowerShell/DscResource.Tests' 'DscResource.Tests'
}
elseif ($Force)
{
    Write-Verbose -Message 'Resetting DscResource.Tests to latest commit in dev branch.'
    Push-Location
    Set-Location -Path '.\DscResource.Tests'
    git fetch origin dev
    git checkout dev
    git reset --hard origin/dev
    Pop-Location
}
else
{
    Write-Verbose -Message 'DscResource.Tests is already cloned.'
}

if (-not ('Microsoft.DscResourceKit.Test' -as [Type]))
{
    Write-Verbose -Message 'Loading Microsoft.DscResourceKit types.'

    <#
        This loads the types:
            Microsoft.DscResourceKit.Test
            Microsoft.DscResourceKit.UnitTest
            Microsoft.DscResourceKit.IntegrationTest

        Change WarningAction so it does not output a warning for the sealed class.
    #>
    Add-Type -Path (Join-Path -Path '.\DscResource.Tests' -ChildPath 'Microsoft.DscResourceKit.cs') -WarningAction SilentlyContinue
}
else
{
    Write-Verbose -Message 'The types Microsoft.DscResourceKit is already loaded.'
}
