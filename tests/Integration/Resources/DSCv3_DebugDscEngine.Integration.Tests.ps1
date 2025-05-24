[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'DebugDscEngine'
}

BeforeAll {
    # Need to define the variables here which will be used in Pester Run.
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'DebugDscEngine'
}

Describe "$($script:dscResourceFriendlyName)_Integration" -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI') {
    BeforeAll {
        # Output $PSVersionTable to verify the PowerShell version used in the test
        Write-Verbose -Message "PowerShell version: $($PSVersionTable)" -Verbose
    }

    Context 'When getting the current state of the resource' {
        It 'Should return the expected current state with minimal properties' {
            $desiredParameters = @{
                KeyProperty       = 'TEST_KEY_001'
                MandatoryProperty = 'TestMandatoryValue'
            }

            $result = dsc --trace-level trace resource get --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            Write-Verbose -Message "Result: $($result | ConvertTo-Json -Compress)" -Verbose

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            $result.actualState.KeyProperty | Should -Be 'TEST_KEY_001'
            $result.actualState.MandatoryProperty | Should -Be 'CurrentMandatoryStateValue'
            $result.actualState.WriteProperty | Should -Be 'CurrentStateValue'
            $result.actualState.ReadProperty | Should -Match '^ReadOnlyValue_\d{8}_\d{6}$'
        }

        It 'Should return the expected current state with all properties' {
            $desiredParameters = @{
                KeyProperty       = 'TEST_KEY_002'
                MandatoryProperty = 'TestMandatoryValue'
                WriteProperty     = 'DesiredWriteValue'
            }

            $result = dsc --trace-level trace resource get --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            $result.actualState.KeyProperty | Should -Be 'TEST_KEY_002'
            $result.actualState.MandatoryProperty | Should -Be 'CurrentMandatoryStateValue'
            $result.actualState.WriteProperty | Should -Be 'CurrentStateValue'
            $result.actualState.ReadProperty | Should -Match '^ReadOnlyValue_\d{8}_\d{6}$'
        }

        It 'Should normalize KeyProperty to uppercase' {
            $desiredParameters = @{
                KeyProperty       = 'test_key_lowercase'
                MandatoryProperty = 'TestMandatoryValue'
            }

            $result = dsc --trace-level trace resource get --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            $result.actualState.KeyProperty | Should -BeExactly 'TEST_KEY_LOWERCASE'
        }
    }

    Context 'When testing the desired state of the resource' {
        It 'Should return true when WriteProperty is in desired state' {
            $desiredParameters = @{
                KeyProperty       = 'TEST_KEY_003'
                MandatoryProperty = 'TestMandatoryValue'
                WriteProperty     = 'CurrentStateValue'
            }

            $result = dsc --trace-level trace resource test --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            $result.inDesiredState | Should -Be $true
        }

        It 'Should return false when WriteProperty is not in desired state' {
            $desiredParameters = @{
                KeyProperty       = 'TEST_KEY_004'
                MandatoryProperty = 'TestMandatoryValue'
                WriteProperty     = 'DifferentValue'
            }

            $result = dsc --trace-level trace resource test --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            $result.inDesiredState | Should -Be $false
        }

        It 'Should return true when only key and mandatory properties are specified' {
            $desiredParameters = @{
                KeyProperty       = 'TEST_KEY_005'
                MandatoryProperty = 'TestMandatoryValue'
            }

            $result = dsc --trace-level trace resource test --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            # Should be true because MandatoryProperty is in ExcludeDscProperties
            $result.inDesiredState | Should -Be $true
        }
    }

    Context 'When setting the desired state of the resource' {
        It 'Should set the desired state without throwing when property is not in desired state' {
            $desiredParameters = @{
                KeyProperty       = 'TEST_KEY_006'
                MandatoryProperty = 'TestMandatoryValue'
                WriteProperty     = 'NewDesiredValue'
            }

            {
                $result = dsc --trace-level trace resource set --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

                $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

                if ($dscExitCode -ne 0)
                {
                    throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
                }
            } | Should -Not -Throw
        }

        It 'Should handle property normalization during set operation' {
            $desiredParameters = @{
                KeyProperty       = 'test_key_normalize'
                MandatoryProperty = 'TestMandatoryValue'
                WriteProperty     = '  SpacedValue  '
            }

            {
                $result = dsc --trace-level trace resource set --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

                $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

                if ($dscExitCode -ne 0)
                {
                    throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
                }
            } | Should -Not -Throw
        }
    }

    Context 'When validating parameter validation' {
        It 'Should fail when KeyProperty is empty' {
            $desiredParameters = @{
                KeyProperty       = ''
                MandatoryProperty = 'TestMandatoryValue'
            }

            {
                $result = dsc --trace-level trace resource get --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

                $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

                if ($dscExitCode -ne 0)
                {
                    throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
                }
            } | Should -Throw
        }

        It 'Should fail when MandatoryProperty is empty' {
            $desiredParameters = @{
                KeyProperty       = 'TEST_KEY_007'
                MandatoryProperty = ''
            }

            {
                $result = dsc --trace-level trace resource get --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

                $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

                if ($dscExitCode -ne 0)
                {
                    throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
                }
            } | Should -Throw
        }
    }

    Context 'When using PSDscRunAsCredential' {
        BeforeAll {
            # Create a test user for RunAs scenarios (only in test environments)
            $testUserName = 'TestDscUser'
            $testPassword = ConvertTo-SecureString -String 'P@ssw0rd123!' -AsPlainText -Force
        }

        It 'Should work without PSDscRunAsCredential specified' {
            $desiredParameters = @{
                KeyProperty       = 'TEST_KEY_008'
                MandatoryProperty = 'TestMandatoryValue'
                WriteProperty     = 'NoRunAsCredential'
            }

            {
                $result = dsc --trace-level trace resource get --resource SqlServerDsc/DebugDscEngine --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

                $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

                if ($dscExitCode -ne 0)
                {
                    throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
                }
            } | Should -Not -Throw
        }
    }
}
