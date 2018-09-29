<#
    .SYNOPSIS
        Assert that the test environment is properly setup and loaded into the
        PowerShell session.

    .DESCRIPTION
        Assert that the test environment is properly setup and loaded into the
        PowerShell session.

    .PARAMETER Force
        If there are any step that is not validated correctly, the parameter
        Force will skip any confirmation dialogs that would normally show when
        using the parameter -Confirm, or ConfirmPreference is set to Low.

    .PARAMETER UpdateTestFramework
        Using this parameter will also reset the local test framework repository
        DscResource.Tests to the latest commit in the dev branch (on GitHub).

    .EXAMPLE
        .\Assert-testEnvironment.ps1 -Confirm -Verbose

        Will assert the current PowerShell session and
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param
(
    [Parameter()]
    [Switch]
    $Force,

    [Parameter()]
    [Switch]
    $UpdateTestFramework
)

#region Verify prerequisites Pester
$pesterModuleName = 'Pester'

# This is the minimum version that can be used with the tests in this repo.
$pesterModuleMinimumVersion = '4.0.2'

<#
    Pester v4.4.0 has a fix for '-Not -Throw' so it shows the actual error
    message if an unexpected exception does occur. It will help when debugging
    tests.
    If no Pester module exist, then use this as the minimum version.
#>
$pesterModuleRecommendedMinimumVersion = '4.4.0'

$pesterModule = Get-Module Pester -ListAvailable -Verbose:$false |
    Where-Object -Property 'Version' -GE -Value $pesterModuleMinimumVersion |
    Sort-Object -Property 'Version' -Descending |
    Select-Object -First 1

if (-not $pesterModule)
{
    <#
        Not installing the module here because it's not known what scope the
        user want (can) to install the module in.
    #>
    $message = 'Missing a compatible version of the Pester module. Minimum version of {0} module can be v{2}, but the recommended minimum version is v{1}. Please install {0} module manually, then run this script again.' -f $pesterModuleName, $pesterModuleRecommendedMinimumVersion, $pesterModuleMinimumVersion
    Write-Warning -Message $message
    return
}
else
{
    Write-Verbose -Message ('A compatible {0} module is already installed (v{1}). If you want to use a newer version of Pester module, please install it manually.' -f $pesterModule.Name, $pesterModule.Version)
}
#endregion Verify prerequisites Pester

#region Verify prerequisites test framework DscResource.Tests
$testFrameworkRepositoryName = 'DscResource.Tests'

if (-not (Test-Path -Path (Join-Path -Path '.' -ChildPath $testFrameworkRepositoryName)))
{
    $shouldProcessCaption = 'Clone {0}' -f $testFrameworkRepositoryName
    $shouldProcessDescription = 'Cloning the test framework repository {0}.' -f $testFrameworkRepositoryName
    $shouldProcessWarning = 'Do you want to clone the test framework repository {0}?' -f $testFrameworkRepositoryName
    $shouldProcessReasonResult = [System.Management.Automation.ShouldProcessReason]::None

    if ($Force -or $PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessWarning, $shouldProcessCaption, [ref] $shouldProcessReasonResult))
    {
        git clone 'https://github.com/PowerShell/DscResource.Tests' 'DscResource.Tests'
    }
    else
    {
        Write-Warning -Message 'The necessary types cannot be loaded if the test framework repository is not cloned.'
    }
}
elseif ($UpdateTestFramework)
{
    $shouldProcessCaption = 'Reset {0}' -f $testFrameworkRepositoryName
    $shouldProcessDescription = 'Resetting the test framework repository {0} to latest commit in dev branch.' -f $testFrameworkRepositoryName
    $shouldProcessWarning = 'Do you want to reset the test framework repository {0} to latest commit in dev branch?' -f $testFrameworkRepositoryName
    $shouldProcessReasonResult = [System.Management.Automation.ShouldProcessReason]::None

    if ($Force -or $PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessWarning, $shouldProcessCaption, [ref] $shouldProcessReasonResult))
    {
        Push-Location

        try
        {
            Set-Location -Path '.\DscResource.Tests' -ErrorAction Stop
            git fetch origin dev
            git checkout dev
            git reset --hard origin/dev
        }
        catch
        {
            throw $_
        }
        finally
        {
            Pop-Location
        }
    }
}
else
{
    Write-Verbose -Message 'DscResource.Tests is already cloned.'
}
#endregion Verify prerequisites test framework DscResource.Tests

#region Verify prerequisites Microsoft.DscResourceKit types.
if (-not ('Microsoft.DscResourceKit.Test' -as [Type]))
{
    $dscResourceKitNamespace = 'Microsoft.DscResourceKit'

    $shouldProcessCaption = 'Load {0} types' -f $dscResourceKitNamespace
    $shouldProcessDescription = 'Loading the {0} types into the current session.' -f $dscResourceKitNamespace
    $shouldProcessWarning = 'Do you want to load the {0} types into the current session?' -f $dscResourceKitNamespace
    $shouldProcessReasonResult = [System.Management.Automation.ShouldProcessReason]::None

    if ($Force -or $PSCmdlet.ShouldProcess($shouldProcessDescription, $shouldProcessWarning, $shouldProcessCaption, [ref] $shouldProcessReasonResult))
    {
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
        Write-Warning -Message 'The tests which using the Microsoft.DscResourceKit types cannot be run if the types are not loaded.'
    }
}
else
{
    Write-Verbose -Message 'The types Microsoft.DscResourceKit is already loaded.'
}
#endregion Verify prerequisites Microsoft.DscResourceKit types.
