<#
    .SYNOPSIS
        Determines if DSC resource integration tests should run based on changed files.

    .DESCRIPTION
        This script analyzes the git diff to determine if DSC resource integration tests
        need to run. It checks if changes affect:
        - DSC resources themselves
        - Public commands used by DSC resources or classes
        - Private functions used by those public commands
        - Classes used by DSC resources

    .PARAMETER BaseBranch
        The base branch to compare against. Default is 'origin/main'.

    .PARAMETER CurrentBranch
        The current branch or commit to compare. Default is 'HEAD'.

    .EXAMPLE
        Test-ShouldRunDscResourceIntegrationTests

    .EXAMPLE
        Test-ShouldRunDscResourceIntegrationTests -BaseBranch 'origin/main' -CurrentBranch 'HEAD'

    .OUTPUTS
        System.Boolean. Returns $true if DSC resource integration tests should run, $false otherwise.
#>
[CmdletBinding()]
param
(
    [Parameter()]
    [System.String]
    $BaseBranch = 'origin/main',

    [Parameter()]
    [System.String]
    $CurrentBranch = 'HEAD'
)

<#
    .SYNOPSIS
        Dynamically discovers public commands used by DSC resources and classes.

    .DESCRIPTION
        This function scans all DSC resource and class files to identify which public
        commands from the Public directory are actually used. It searches for command
        usage patterns in the source code.

    .PARAMETER SourcePath
        The source path containing Public, DSCResources, and Classes directories.
        Default is 'source'.

    .EXAMPLE
        Get-PublicCommandsUsedByDscResources

    .EXAMPLE
        Get-PublicCommandsUsedByDscResources -SourcePath 'source'

    .OUTPUTS
        System.String[]. Array of public command names that are used by DSC resources and classes.
#>
function Get-PublicCommandsUsedByDscResources
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $SourcePath = 'source'
    )
    
    $usedCommands = @()
    
    # Get all public command names
    $publicCommandFiles = Get-ChildItem -Path (Join-Path -Path $SourcePath -ChildPath 'Public') -Filter '*.ps1' -ErrorAction SilentlyContinue
    $publicCommandNames = $publicCommandFiles | ForEach-Object -Process { $_.BaseName }
    
    if (-not $publicCommandNames)
    {
        Write-Warning -Message "No public commands found in $SourcePath/Public"
        return @()
    }
    
    # Search in DSC Resources
    $dscResourcesPath = Join-Path -Path $SourcePath -ChildPath 'DSCResources'
    if (Test-Path -Path $dscResourcesPath)
    {
        $dscResourceFiles = Get-ChildItem -Path $dscResourcesPath -Recurse -Filter '*.ps*' -ErrorAction SilentlyContinue
        foreach ($file in $dscResourceFiles)
        {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content)
            {
                foreach ($commandName in $publicCommandNames)
                {
                    # Look for command usage patterns: commandName, & commandName, or | commandName
                    if ($content -match "\b$commandName\b")
                    {
                        $usedCommands += $commandName
                    }
                }
            }
        }
    }
    
    # Search in Classes
    $classesPath = Join-Path -Path $SourcePath -ChildPath 'Classes'
    if (Test-Path -Path $classesPath)
    {
        $classFiles = Get-ChildItem -Path $classesPath -Filter '*.ps1' -ErrorAction SilentlyContinue
        foreach ($file in $classFiles)
        {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content)
            {
                foreach ($commandName in $publicCommandNames)
                {
                    # Look for command usage patterns: commandName, & commandName, or | commandName
                    if ($content -match "\b$commandName\b")
                    {
                        $usedCommands += $commandName
                    }
                }
            }
        }
    }
    
    # Return unique commands
    return $usedCommands | Sort-Object -Unique
}

<#
    .SYNOPSIS
        Gets the list of files changed between two git references.

    .DESCRIPTION
        This function retrieves the list of files that have been modified between
        two git references using git diff. It handles various scenarios including
        different diff syntax and untracked files.

    .PARAMETER From
        The source git reference (branch, commit, tag).

    .PARAMETER To
        The target git reference (branch, commit, tag).

    .EXAMPLE
        Get-ChangedFiles -From 'origin/main' -To 'HEAD'

    .OUTPUTS
        System.String[]. Array of file paths that have been changed.
#>
function Get-ChangedFiles
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $From,

        [Parameter(Mandatory = $true)]
        [System.String]
        $To
    )
    
    try
    {
        # Try different git diff approaches
        $gitDiffOutput = $null
        
        # First, try the standard diff
        $gitDiffOutput = & git diff --name-only "$From..$To" 2>&1
        if ($LASTEXITCODE -eq 0 -and $gitDiffOutput)
        {
            return $gitDiffOutput | Where-Object -FilterScript { $_ -and $_.Trim() }
        }
        
        # If that fails, try without the range syntax
        $gitDiffOutput = & git diff --name-only $From $To 2>&1
        if ($LASTEXITCODE -eq 0 -and $gitDiffOutput)
        {
            return $gitDiffOutput | Where-Object -FilterScript { $_ -and $_.Trim() }
        }
        
        # If we're comparing with HEAD and have untracked files, include them
        if ($To -eq 'HEAD')
        {
            $untrackedFiles = & git ls-files --others --exclude-standard 2>&1
            if ($LASTEXITCODE -eq 0 -and $untrackedFiles)
            {
                return $untrackedFiles | Where-Object -FilterScript { $_ -and $_.Trim() }
            }
        }
        
        Write-Warning -Message "Failed to get git diff between $From and $To. Exit code: $LASTEXITCODE. Output: $gitDiffOutput"
        return @()
    }
    catch
    {
        Write-Warning -Message "Error getting changed files: $_"
        return @()
    }
}

<#
    .SYNOPSIS
        Gets private functions that a public command depends on.

    .DESCRIPTION
        This function analyzes a public command file to identify which private
        functions it depends on by searching for function calls in the source code.

    .PARAMETER CommandName
        The name of the public command to analyze.

    .PARAMETER SourcePath
        The source path containing Public and Private directories.

    .EXAMPLE
        Get-PrivateFunctionsUsedByCommand -CommandName 'Connect-SqlDscDatabaseEngine' -SourcePath 'source'

    .OUTPUTS
        System.String[]. Array of private function names that are used by the command.
#>
function Get-PrivateFunctionsUsedByCommand
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $CommandName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SourcePath
    )
    
    $commandFile = Join-Path -Path $SourcePath -ChildPath "Public/$CommandName.ps1"
    if (-not (Test-Path -Path $commandFile))
    {
        return @()
    }
    
    $privateFunctions = @()
    $content = Get-Content -Path $commandFile -Raw
    
    # Look for direct function calls to private functions
    $privateFunctionFiles = Get-ChildItem -Path (Join-Path -Path $SourcePath -ChildPath "Private") -Filter "*.ps1" | Select-Object -ExpandProperty BaseName
    foreach ($privateFunction in $privateFunctionFiles)
    {
        if ($content -match "\b$privateFunction\b")
        {
            $privateFunctions += $privateFunction
        }
    }
    
    return $privateFunctions
}

<#
    .SYNOPSIS
        Main function that determines if DSC resource integration tests should run.

    .DESCRIPTION
        This function analyzes the changes between two git references and determines
        if DSC resource integration tests should run based on the files that have
        been modified. It checks for changes to DSC resources, classes, public
        commands used by DSC resources, private functions, integration tests, and
        pipeline configuration.

    .PARAMETER BaseBranch
        The base branch to compare against. Default is 'origin/main'.

    .PARAMETER CurrentBranch
        The current branch or commit to compare. Default is 'HEAD'.

    .PARAMETER SourcePath
        The source path containing the source code directories. Default is 'source'.

    .EXAMPLE
        Test-ShouldRunDscResourceIntegrationTests

    .EXAMPLE
        Test-ShouldRunDscResourceIntegrationTests -BaseBranch 'origin/main' -CurrentBranch 'feature-branch'

    .OUTPUTS
        System.Boolean. Returns $true if DSC resource integration tests should run, $false otherwise.
#>
function Test-ShouldRunDscResourceIntegrationTests
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $BaseBranch = 'origin/main',

        [Parameter()]
        [System.String]
        $CurrentBranch = 'HEAD',

        [Parameter()]
        [System.String]
        $SourcePath = 'source'
    )
    
    Write-Output -InputObject "Analyzing changes between $BaseBranch and $CurrentBranch..."
    
    # Get list of public commands used by DSC resources dynamically
    $PublicCommandsUsedByDscResources = Get-PublicCommandsUsedByDscResources -SourcePath $SourcePath
    Write-Output -InputObject "Discovered $($PublicCommandsUsedByDscResources.Count) public commands used by DSC resources and classes."
    
    $changedFiles = Get-ChangedFiles -From $BaseBranch -To $CurrentBranch
    
    if (-not $changedFiles)
    {
        Write-Output -InputObject "No changed files detected. DSC resource integration tests will run by default."
        return $true
    }
    
    Write-Output -InputObject "Changed files:"
    $changedFiles | ForEach-Object -Process { Write-Output -InputObject "  $_" }
    
    # Check if any DSC resources are directly changed
    $changedDscResources = $changedFiles | Where-Object -FilterScript { $_ -match '^source/DSCResources/' -or $_ -match '^source/Classes/' }
    if ($changedDscResources)
    {
        Write-Output -InputObject "DSC resources or classes have been modified. DSC resource integration tests will run."
        Write-Output -InputObject "Changed DSC resources/classes:"
        $changedDscResources | ForEach-Object -Process { Write-Output -InputObject "  $_" }
        return $true
    }
    
    # Check if any public commands used by DSC resources are changed
    $changedPublicCommands = $changedFiles | Where-Object -FilterScript { $_ -match '^source/Public/(.+)\.ps1$' } | 
        ForEach-Object -Process { [System.IO.Path]::GetFileNameWithoutExtension((Split-Path -Path $_ -Leaf)) }
    
    $affectedCommands = $changedPublicCommands | Where-Object -FilterScript { $_ -in $PublicCommandsUsedByDscResources }
    if ($affectedCommands)
    {
        Write-Output -InputObject "Public commands used by DSC resources have been modified. DSC resource integration tests will run."
        Write-Output -InputObject "Affected commands:"
        $affectedCommands | ForEach-Object -Process { Write-Output -InputObject "  $_" }
        return $true
    }
    
    # Check if any private functions used by the affected public commands are changed
    $changedPrivateFunctions = $changedFiles | Where-Object -FilterScript { $_ -match '^source/Private/(.+)\.ps1$' } | 
        ForEach-Object -Process { [System.IO.Path]::GetFileNameWithoutExtension((Split-Path -Path $_ -Leaf)) }
    
    $affectedPrivateFunctions = @()
    foreach ($command in $PublicCommandsUsedByDscResources)
    {
        $privateFunctionsUsed = Get-PrivateFunctionsUsedByCommand -CommandName $command -SourcePath $SourcePath
        $affectedPrivateFunctions += $privateFunctionsUsed | Where-Object -FilterScript { $_ -in $changedPrivateFunctions }
    }
    
    if ($affectedPrivateFunctions)
    {
        Write-Output -InputObject "Private functions used by DSC resource-related public commands have been modified. DSC resource integration tests will run."
        Write-Output -InputObject "Affected private functions:"
        $affectedPrivateFunctions | ForEach-Object -Process { Write-Output -InputObject "  $_" }
        return $true
    }
    
    # Check if integration test files themselves are changed
    $changedIntegrationTests = $changedFiles | Where-Object -FilterScript { $_ -match '^tests/Integration/Resources/' }
    if ($changedIntegrationTests)
    {
        Write-Output -InputObject "DSC resource integration test files have been modified. DSC resource integration tests will run."
        Write-Output -InputObject "Changed integration test files:"
        $changedIntegrationTests | ForEach-Object -Process { Write-Output -InputObject "  $_" }
        return $true
    }
    
    # Check if pipeline configuration is changed
    $changedPipelineFiles = $changedFiles | Where-Object -FilterScript { $_ -match 'azure-pipelines\.yml$|\.build/' }
    if ($changedPipelineFiles)
    {
        Write-Output -InputObject "Pipeline configuration has been modified. DSC resource integration tests will run."
        Write-Output -InputObject "Changed pipeline files:"
        $changedPipelineFiles | ForEach-Object -Process { Write-Output -InputObject "  $_" }
        return $true
    }
    
    Write-Output -InputObject "No changes detected that would affect DSC resources. DSC resource integration tests can be skipped."
    return $false
}

# If script is run directly (not imported), execute the main function
if ($MyInvocation.InvocationName -ne '.')
{
    $shouldRun = Test-ShouldRunDscResourceIntegrationTests -BaseBranch $BaseBranch -CurrentBranch $CurrentBranch
    
    # Output result for Azure DevOps variables
    Write-Output -InputObject "##vso[task.setvariable variable=ShouldRunDscResourceIntegrationTests]$shouldRun"
    
    # Also output as regular output for local testing
    Write-Output -InputObject "ShouldRunDscResourceIntegrationTests: $shouldRun"
    
    # Set exit code based on result for script usage
    if ($shouldRun)
    {
        exit 0
    }
    else
    {
        exit 1
    }
}
