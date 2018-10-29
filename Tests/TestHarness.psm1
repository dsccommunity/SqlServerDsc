function Invoke-TestHarness
{
    [CmdletBinding()]
    param
    (
        [System.String]
        $TestResultsFile,

        [System.String]
        $DscTestsPath
    )

    Write-Verbose -Message 'Commencing all SQLServerDsc tests'

    $repoDir = Join-Path -Path $PSScriptRoot -ChildPath '..\' -Resolve

    $testResultSettings = @{ }
    if ([String]::IsNullOrEmpty($TestResultsFile) -eq $false) {
        $testResultSettings.Add('OutputFormat', 'NUnitXml' )
        $testResultSettings.Add('OutputFile', $TestResultsFile)
    }

    $testsToRun = @()

    # Run Unit Tests
    $unitTestsPath = Join-Path -Path $repoDir -ChildPath 'Tests\Unit'
    $testsToRun += @( (Get-ChildItem -Path $unitTestsPath).FullName )

    # Integration Tests
    $integrationTestsPath = Join-Path -Path $repoDir -ChildPath 'Tests\Integration'
    $testsToRun += @( (Get-ChildItem -Path $integrationTestsPath -Filter '*.Tests.ps1').FullName )

    # DSC Common Tests
    if ($PSBoundParameters.ContainsKey('DscTestsPath') -eq $true)
    {
        $getChildItemParameters = @{
            Path = $DscTestsPath
            Recurse = $true
            Filter = '*.Tests.ps1'
        }

        # Get all tests '*.Tests.ps1'.
        $commonTestFiles = Get-ChildItem @getChildItemParameters

        # Remove DscResource.Tests unit and integration tests.
        $commonTestFiles = $commonTestFiles | Where-Object -FilterScript {
            $_.FullName -notmatch 'DSCResource.Tests\\Tests'
        }

        $testsToRun += @( $commonTestFiles.FullName )
    }

    $results = Invoke-Pester -Script $testsToRun `
        -CodeCoverage $testCoverageFiles `
        -PassThru @testResultSettings

    return $results
}
