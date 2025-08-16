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
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $BaseBranch = 'origin/main',

    [Parameter()]
    [string]
    $CurrentBranch = 'HEAD'
)

function Get-PublicCommandsUsedByDscResources {
    <#
        .SYNOPSIS
            Dynamically discovers public commands used by DSC resources and classes.
    #>
    param(
        [Parameter()]
        [string]
        $SourcePath = 'source'
    )
    
    $usedCommands = @()
    
    # Get all public command names
    $publicCommandFiles = Get-ChildItem -Path (Join-Path -Path $SourcePath -ChildPath 'Public') -Filter '*.ps1' -ErrorAction SilentlyContinue
    $publicCommandNames = $publicCommandFiles | ForEach-Object { $_.BaseName }
    
    if (-not $publicCommandNames) {
        Write-Warning "No public commands found in $SourcePath/Public"
        return @()
    }
    
    # Search in DSC Resources
    $dscResourcesPath = Join-Path -Path $SourcePath -ChildPath 'DSCResources'
    if (Test-Path -Path $dscResourcesPath) {
        $dscResourceFiles = Get-ChildItem -Path $dscResourcesPath -Recurse -Filter '*.ps*' -ErrorAction SilentlyContinue
        foreach ($file in $dscResourceFiles) {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                foreach ($commandName in $publicCommandNames) {
                    # Look for command usage patterns: commandName, & commandName, or | commandName
                    if ($content -match "\b$commandName\b") {
                        $usedCommands += $commandName
                    }
                }
            }
        }
    }
    
    # Search in Classes
    $classesPath = Join-Path -Path $SourcePath -ChildPath 'Classes'
    if (Test-Path -Path $classesPath) {
        $classFiles = Get-ChildItem -Path $classesPath -Filter '*.ps1' -ErrorAction SilentlyContinue
        foreach ($file in $classFiles) {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                foreach ($commandName in $publicCommandNames) {
                    # Look for command usage patterns: commandName, & commandName, or | commandName
                    if ($content -match "\b$commandName\b") {
                        $usedCommands += $commandName
                    }
                }
            }
        }
    }
    
    # Return unique commands
    return $usedCommands | Sort-Object -Unique
}

function Get-ChangedFiles {
    <#
        .SYNOPSIS
            Gets the list of files changed between two git references.
    #>
    param(
        [string]$From,
        [string]$To
    )
    
    try {
        # Try different git diff approaches
        $gitDiffOutput = $null
        
        # First, try the standard diff
        $gitDiffOutput = & git diff --name-only "$From..$To" 2>&1
        if ($LASTEXITCODE -eq 0 -and $gitDiffOutput) {
            return $gitDiffOutput | Where-Object -FilterScript { $_ -and $_.Trim() }
        }
        
        # If that fails, try without the range syntax
        $gitDiffOutput = & git diff --name-only $From $To 2>&1
        if ($LASTEXITCODE -eq 0 -and $gitDiffOutput) {
            return $gitDiffOutput | Where-Object -FilterScript { $_ -and $_.Trim() }
        }
        
        # If we're comparing with HEAD and have untracked files, include them
        if ($To -eq 'HEAD') {
            $untrackedFiles = & git ls-files --others --exclude-standard 2>&1
            if ($LASTEXITCODE -eq 0 -and $untrackedFiles) {
                return $untrackedFiles | Where-Object -FilterScript { $_ -and $_.Trim() }
            }
        }
        
        Write-Warning "Failed to get git diff between $From and $To. Exit code: $LASTEXITCODE. Output: $gitDiffOutput"
        return @()
    }
    catch {
        Write-Warning "Error getting changed files: $_"
        return @()
    }
}

function Get-PrivateFunctionsUsedByCommand {
    <#
        .SYNOPSIS
            Gets private functions that a public command depends on.
    #>
    param(
        [string]$CommandName,
        [string]$SourcePath
    )
    
    $commandFile = Join-Path $SourcePath "Public/$CommandName.ps1"
    if (-not (Test-Path $commandFile)) {
        return @()
    }
    
    $privateFunctions = @()
    $content = Get-Content $commandFile -Raw
    
    # Look for direct function calls to private functions
    $privateFunctionFiles = Get-ChildItem -Path (Join-Path -Path $SourcePath -ChildPath "Private") -Filter "*.ps1" | Select-Object -ExpandProperty BaseName
    foreach ($privateFunction in $privateFunctionFiles) {
        if ($content -match "\b$privateFunction\b") {
            $privateFunctions += $privateFunction
        }
    }
    
    return $privateFunctions
}

function Test-ShouldRunDscResourceIntegrationTests {
    <#
        .SYNOPSIS
            Main function that determines if DSC resource integration tests should run.
    #>
    param(
        [string]$BaseBranch = 'origin/main',
        [string]$CurrentBranch = 'HEAD',
        [string]$SourcePath = 'source'
    )
    
    Write-Output "Analyzing changes between $BaseBranch and $CurrentBranch..."
    
    # Get list of public commands used by DSC resources dynamically
    $PublicCommandsUsedByDscResources = Get-PublicCommandsUsedByDscResources -SourcePath $SourcePath
    Write-Output "Discovered $($PublicCommandsUsedByDscResources.Count) public commands used by DSC resources and classes."
    
    $changedFiles = Get-ChangedFiles -From $BaseBranch -To $CurrentBranch
    
    if (-not $changedFiles) {
        Write-Output "No changed files detected. DSC resource integration tests will run by default."
        return $true
    }
    
    Write-Output "Changed files:"
    $changedFiles | ForEach-Object { Write-Output "  $_" }
    
    # Check if any DSC resources are directly changed
    $changedDscResources = $changedFiles | Where-Object -FilterScript { $_ -match '^source/DSCResources/' -or $_ -match '^source/Classes/' }
    if ($changedDscResources) {
        Write-Output "DSC resources or classes have been modified. DSC resource integration tests will run."
        Write-Output "Changed DSC resources/classes:"
        $changedDscResources | ForEach-Object { Write-Output "  $_" }
        return $true
    }
    
    # Check if any public commands used by DSC resources are changed
    $changedPublicCommands = $changedFiles | Where-Object -FilterScript { $_ -match '^source/Public/(.+)\.ps1$' } | 
        ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension((Split-Path -Path $_ -Leaf)) }
    
    $affectedCommands = $changedPublicCommands | Where-Object -FilterScript { $_ -in $PublicCommandsUsedByDscResources }
    if ($affectedCommands) {
        Write-Output "Public commands used by DSC resources have been modified. DSC resource integration tests will run."
        Write-Output "Affected commands:"
        $affectedCommands | ForEach-Object { Write-Output "  $_" }
        return $true
    }
    
    # Check if any private functions used by the affected public commands are changed
    $changedPrivateFunctions = $changedFiles | Where-Object -FilterScript { $_ -match '^source/Private/(.+)\.ps1$' } | 
        ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension((Split-Path -Path $_ -Leaf)) }
    
    $affectedPrivateFunctions = @()
    foreach ($command in $PublicCommandsUsedByDscResources) {
        $privateFunctionsUsed = Get-PrivateFunctionsUsedByCommand -CommandName $command -SourcePath $SourcePath
        $affectedPrivateFunctions += $privateFunctionsUsed | Where-Object -FilterScript { $_ -in $changedPrivateFunctions }
    }
    
    if ($affectedPrivateFunctions) {
        Write-Output "Private functions used by DSC resource-related public commands have been modified. DSC resource integration tests will run."
        Write-Output "Affected private functions:"
        $affectedPrivateFunctions | ForEach-Object { Write-Output "  $_" }
        return $true
    }
    
    # Check if integration test files themselves are changed
    $changedIntegrationTests = $changedFiles | Where-Object -FilterScript { $_ -match '^tests/Integration/Resources/' }
    if ($changedIntegrationTests) {
        Write-Output "DSC resource integration test files have been modified. DSC resource integration tests will run."
        Write-Output "Changed integration test files:"
        $changedIntegrationTests | ForEach-Object { Write-Output "  $_" }
        return $true
    }
    
    # Check if pipeline configuration is changed
    $changedPipelineFiles = $changedFiles | Where-Object -FilterScript { $_ -match 'azure-pipelines\.yml$|\.build/' }
    if ($changedPipelineFiles) {
        Write-Output "Pipeline configuration has been modified. DSC resource integration tests will run."
        Write-Output "Changed pipeline files:"
        $changedPipelineFiles | ForEach-Object { Write-Output "  $_" }
        return $true
    }
    
    Write-Output "No changes detected that would affect DSC resources. DSC resource integration tests can be skipped."
    return $false
}

# If script is run directly (not imported), execute the main function
if ($MyInvocation.InvocationName -ne '.') {
    $shouldRun = Test-ShouldRunDscResourceIntegrationTests -BaseBranch $BaseBranch -CurrentBranch $CurrentBranch
    
    # Output result for Azure DevOps variables
    Write-Output "##vso[task.setvariable variable=ShouldRunDscResourceIntegrationTests]$shouldRun"
    
    # Also output as regular output for local testing
    Write-Output "ShouldRunDscResourceIntegrationTests: $shouldRun"
    
    # Set exit code based on result for script usage
    if ($shouldRun) {
        exit 0
    } else {
        exit 1
    }
}