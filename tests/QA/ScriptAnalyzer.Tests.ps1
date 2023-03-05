<#
    .SYNOPSIS
        Quality test that runs the Script Analyzer with the Script Analyzer settings
        file in the .vscode folder.

    .NOTES
        In addition to the custom rules that are part of this repository's Script
        Analyzer settings file, it will also run the HQRM test that has been run by
        the build task 'DscResource_Tests_Stop_On_Fail'. When the issue in the
        repository DscResource.Test is resolved this should not be needed. See issue
        https://github.com/dsccommunity/DscResource.Test/issues/100.
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }

    <#
        Need to add the SMO stub classes so that the analyzer rule 'UseSyntacticallyCorrectExamples'
        (from Indented.ScriptAnalyzerRules) can properly parse parameters that uses SMO types,
        e.g. [Microsoft.SqlServer.Management.Smo.Server].
    #>
    Add-Type -Path "$PSScriptRoot/../Unit/Stubs/SMO.cs"

    $repositoryPath = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../..')
    $sourcePath = Join-Path -Path $repositoryPath -ChildPath 'source'

    $moduleFiles = Get-ChildItem -Path $sourcePath -Recurse -Include @('*.psm1', '*.ps1')

    $testCases = @()

    foreach ($moduleFile in $moduleFiles)
    {
        $moduleFilePathNormalized = $moduleFile.FullName -replace '\\', '/'
        $repositoryPathNormalized = $repositoryPath -replace '\\', '/'
        $escapedRepositoryPath = [System.Text.RegularExpressions.RegEx]::Escape($repositoryPathNormalized)
        $relativePath = $moduleFilePathNormalized -replace ($escapedRepositoryPath + '/')

        $testCases += @{
            ScriptPath = $moduleFile.FullName
            RelativePath = $relativePath
        }
    }
}

Describe 'Script Analyzer Rules' {
    Context 'When there are source files' {
        BeforeAll {
            $repositoryPath = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../..')
            $scriptAnalyzerSettingsPath = Join-Path -Path $repositoryPath -ChildPath '.vscode\analyzersettings.psd1'
        }

        It 'Should pass all PS Script Analyzer rules for file ''<RelativePath>''' -ForEach $testCases {
            $pssaError = Invoke-ScriptAnalyzer -Path $ScriptPath -Settings $scriptAnalyzerSettingsPath

            <#
                Filter out rules.

                TODO: The rules (e.g. "TypeNotFound") are not excluded correctly even if it
                      is excluded in the file 'analyzersettings.psd1'. This is a workaround
                      until it is properly excluded for source files, and instead only is
                      run for the built module script module file (SqlServerDsc.psm1).
            #>
            $pssaError = $pssaError | Where-Object -FilterScript { $_.RuleName -notin @('TypeNotFound', 'RequiresModuleInvalid') }

            $report = $pssaError | Format-Table -AutoSize | Out-String -Width 200
            $pssaError | Should -HaveCount 0 -Because "all script analyzer rules should pass.`r`n`r`n $report`r`n"
        }
    }
}
