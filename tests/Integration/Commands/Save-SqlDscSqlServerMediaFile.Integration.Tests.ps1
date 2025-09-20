[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks noop" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Save-SqlDscSqlServerMediaFile' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Create a temporary directory for testing downloads
        $script:testDownloadPath = Join-Path -Path $env:TEMP -ChildPath "SqlDscTestDownloads_$(Get-Random)"
        New-Item -Path $script:testDownloadPath -ItemType Directory -Force | Out-Null
        
        Write-Verbose -Message "Created test download directory: $script:testDownloadPath" -Verbose
    }

    AfterAll {
        # Clean up test downloads directory
        if ($script:testDownloadPath -and (Test-Path -Path $script:testDownloadPath))
        {
            Write-Verbose -Message "Cleaning up test download directory: $script:testDownloadPath" -Verbose
            Remove-Item -Path $script:testDownloadPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'When downloading SQL Server media using direct ISO URL' {
        BeforeAll {
            # Use SQL Server 2017 ISO URL for testing direct ISO download
            $script:directIsoUrl = 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU.iso'
            $script:expectedFileName = 'SQLServer2017-test.iso'
            
            # Create separate subdirectory for this context to avoid ISO file conflicts
            $script:directIsoTestPath = Join-Path -Path $script:testDownloadPath -ChildPath 'DirectIso'
            New-Item -Path $script:directIsoTestPath -ItemType Directory -Force | Out-Null
        }

        It 'Should download the ISO file directly and return a FileInfo object' {
            $result = Save-SqlDscSqlServerMediaFile -Url $script:directIsoUrl -DestinationPath $script:directIsoTestPath -FileName $script:expectedFileName -Force -Quiet -ErrorAction 'Stop'

            # Verify the result is a FileInfo object
            $result | Should -BeOfType [System.IO.FileInfo]
            
            # Verify the file was downloaded
            $result.Name | Should -Be $script:expectedFileName
            $result.Exists | Should -BeTrue
            $result.Length | Should -BeGreaterThan 0
            
            # Verify the file is in the expected location
            $expectedPath = Join-Path -Path $script:directIsoTestPath -ChildPath $script:expectedFileName
            Test-Path -Path $expectedPath | Should -BeTrue
        }

        It 'Should overwrite existing file when Force parameter is used' {
            # Create separate subdirectory for this test to avoid conflicts
            $overwriteTestPath = Join-Path -Path $script:testDownloadPath -ChildPath 'OverwriteTest'
            New-Item -Path $overwriteTestPath -ItemType Directory -Force | Out-Null
            
            # Use SkipExecution to avoid the safety check while still testing Force parameter
            $executableUrl = 'https://download.microsoft.com/download/e/6/4/e6477a2a-9b58-40f7-8ad6-62bb8491ea78/SQLServerReportingServices.exe'
            $targetFileName = 'overwrite-test.exe'
            
            # First, create a dummy file with the target name
            $dummyFilePath = Join-Path -Path $overwriteTestPath -ChildPath $targetFileName
            'dummy content for overwrite test' | Out-File -FilePath $dummyFilePath -Encoding UTF8
            
            # Verify the dummy file exists and get its original size
            Test-Path -Path $dummyFilePath | Should -BeTrue
            $originalSize = (Get-Item -Path $dummyFilePath).Length
            
            # Download with SkipExecution and Force should overwrite the dummy file
            $result = Save-SqlDscSqlServerMediaFile -Url $executableUrl -DestinationPath $overwriteTestPath -FileName $targetFileName -SkipExecution -Force -Quiet -ErrorAction 'Stop'
            
            # Verify the file was overwritten (should be much larger than the dummy content)
            $result | Should -BeOfType [System.IO.FileInfo]
            $result.Name | Should -Be $targetFileName
            $result.Exists | Should -BeTrue
            $result.Length | Should -BeGreaterThan $originalSize
            $result.Length | Should -BeGreaterThan 1000000  # Executable should be at least 1MB
        }
    }

    Context 'When downloading SQL Server media using executable URL' {
        BeforeAll {
            # Use SQL Server 2022 executable URL for testing executable download and extraction
            $script:executableUrl = 'https://download.microsoft.com/download/c/c/9/cc9c6797-383c-4b24-8920-dc057c1de9d3/SQL2022-SSEI-Dev.exe'
            $script:expectedIsoFileName = 'SQL2022-media.iso'
            
            # Create separate subdirectory for this context to avoid ISO file conflicts
            $script:executableTestPath = Join-Path -Path $script:testDownloadPath -ChildPath 'ExecutableTest'
            New-Item -Path $script:executableTestPath -ItemType Directory -Force | Out-Null
        }

        It 'Should download executable, extract ISO, and clean up executable' -Skip:($env:CI -eq 'true' -and $env:RUNNER_OS -eq 'Linux') {
            # Note: This test is skipped on Linux CI as SQL Server executables are Windows-specific
            $result = Save-SqlDscSqlServerMediaFile -Url $script:executableUrl -DestinationPath $script:executableTestPath -FileName $script:expectedIsoFileName -Language 'en-US' -Force -Quiet -ErrorAction 'Stop'

            # Verify the result is a FileInfo object pointing to the ISO
            $result | Should -BeOfType [System.IO.FileInfo]
            $result.Name | Should -Be $script:expectedIsoFileName
            $result.Extension | Should -Be '.iso'
            $result.Exists | Should -BeTrue
            $result.Length | Should -BeGreaterThan 0

            # Verify the executable was cleaned up (should not exist)
            $executablePath = [System.IO.Path]::ChangeExtension($result.FullName, 'exe')
            Test-Path -Path $executablePath | Should -BeFalse
            
            # Verify only one ISO file exists in the directory
            $isoFiles = Get-ChildItem -Path $script:executableTestPath -Filter '*.iso'
            $isoFiles.Count | Should -Be 1
        }
    }

    Context 'When using SkipExecution parameter with executable URL' {
        BeforeAll {
            # Use SQL Server Reporting Services executable for testing SkipExecution
            $script:rsExecutableUrl = 'https://download.microsoft.com/download/e/6/4/e6477a2a-9b58-40f7-8ad6-62bb8491ea78/SQLServerReportingServices.exe'
            $script:expectedExecutableFileName = 'SSRS-Test.exe'
            
            # Create separate subdirectory for this context to avoid file conflicts
            $script:skipExecutionTestPath = Join-Path -Path $script:testDownloadPath -ChildPath 'SkipExecutionTest'
            New-Item -Path $script:skipExecutionTestPath -ItemType Directory -Force | Out-Null
        }

        It 'Should download executable without extracting when SkipExecution is specified' {
            $result = Save-SqlDscSqlServerMediaFile -Url $script:rsExecutableUrl -DestinationPath $script:skipExecutionTestPath -FileName $script:expectedExecutableFileName -SkipExecution -Force -Quiet -ErrorAction 'Stop'

            # Verify the result is a FileInfo object pointing to the executable
            $result | Should -BeOfType [System.IO.FileInfo]
            $result.Name | Should -Be $script:expectedExecutableFileName
            $result.Extension | Should -Be '.exe'
            $result.Exists | Should -BeTrue
            $result.Length | Should -BeGreaterThan 0

            # Verify no ISO files were created
            $isoFiles = Get-ChildItem -Path $script:skipExecutionTestPath -Filter '*.iso' -ErrorAction SilentlyContinue
            $isoFiles.Count | Should -Be 0
        }
    }

    Context 'When testing error conditions' {
        BeforeAll {
            # Create separate subdirectory for error testing to avoid conflicts
            $script:errorTestPath = Join-Path -Path $script:testDownloadPath -ChildPath 'ErrorTest'
            New-Item -Path $script:errorTestPath -ItemType Directory -Force | Out-Null
        }
        
        It 'Should throw error when ISO files already exist in destination and SkipExecution is not used' {
            # Create a dummy ISO file to trigger the error condition
            $dummyIsoPath = Join-Path -Path $script:errorTestPath -ChildPath 'existing.iso'
            'dummy iso content' | Out-File -FilePath $dummyIsoPath -Encoding UTF8

            # This should throw an error due to existing ISO file
            {
                Save-SqlDscSqlServerMediaFile -Url $script:directIsoUrl -DestinationPath $script:errorTestPath -FileName 'new-download.iso' -Quiet -ErrorAction 'Stop'
            } | Should -Throw -ExpectedMessage '*InvalidDestinationFolder*'

            # Clean up
            Remove-Item -Path $dummyIsoPath -Force -ErrorAction SilentlyContinue
        }

        It 'Should handle invalid URL gracefully' {
            # Test with an invalid URL
            {
                Save-SqlDscSqlServerMediaFile -Url 'https://invalid.example.com/nonexistent.iso' -DestinationPath $script:errorTestPath -FileName 'invalid-test.iso' -Force -Quiet -ErrorAction 'Stop'
            } | Should -Throw
        }
    }

    Context 'When testing different language parameters' {
        BeforeAll {
            # Use SQL Server 2019 executable for language testing
            $script:sql2019Url = 'https://download.microsoft.com/download/d/a/2/da259851-b941-459d-989c-54a18a5d44dd/SQL2019-SSEI-Dev.exe'
            
            # Create separate subdirectory for language testing to avoid conflicts
            $script:languageTestPath = Join-Path -Path $script:testDownloadPath -ChildPath 'LanguageTest'
            New-Item -Path $script:languageTestPath -ItemType Directory -Force | Out-Null
        }

        It 'Should accept different language codes' -Skip:($env:CI -eq 'true' -and $env:RUNNER_OS -eq 'Linux') {
            # Test with French language (this will skip execution due to CI limitations, but validates parameter acceptance)
            $result = Save-SqlDscSqlServerMediaFile -Url $script:sql2019Url -DestinationPath $script:languageTestPath -FileName 'SQL2019-fr.iso' -Language 'fr-FR' -Force -Quiet -ErrorAction 'Stop'

            # On Windows, this should work. On Linux/CI, it will be skipped.
            if ($result) {
                $result | Should -BeOfType [System.IO.FileInfo]
                $result.Name | Should -Be 'SQL2019-fr.iso'
            }
        }
    }
}
