<#
    .SYNOPSIS
        Quality test that runs the Script Analyzer with the Script Analyzer settings
        file in the .vscode folder.

    .NOTES
        In addition to the custom rules that are part of this repository's Script
        Analyzer settings file, it will also run the HQRM test that has been run by
        the buold task 'DscResource_Tests_Stop_On_Fail'. When the issue in the
        repository DscResource.Test is resolved this should not be needed. See issue
        https://github.com/dsccommunity/DscResource.Test/issues/100.
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (-not (Test-BuildCategory -Type 'Unit'))
{
    return
}

Describe 'Script Analyzer Rules' {
    BeforeAll {
        $repositoryPath = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../..')
        $sourcePath = Join-Path -Path $repositoryPath -ChildPath 'source'
        $scriptAnalyzerSettingsPath = Join-Path -Path $repositoryPath -ChildPath '.vscode\analyzersettings.psd1'
    }

    Context 'When there are module files' {
        BeforeAll {
            $moduleFiles = Get-ChildItem -Path $sourcePath -Recurse -Include '*.psm1'

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

        It 'Should pass all PS Script Analyzer rules for file ''<RelativePath>''' -TestCases $testCases {
            param
            (
                [Parameter()]
                [System.String]
                $ScriptPath,

                [Parameter()]
                [System.String]
                $RelativePath
            )

            $pssaError = Invoke-ScriptAnalyzer -Path $ScriptPath -Settings $scriptAnalyzerSettingsPath

            $report = $pssaError | Format-Table -AutoSize | Out-String -Width 200
            $pssaError | Should -HaveCount 0 -Because "all script analyzer rules should pass.`r`n`r`n $report`r`n"
        }
    }
}
