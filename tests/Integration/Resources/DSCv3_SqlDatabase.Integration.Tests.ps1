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

    <#
        Need to define that variables here to be used in the Pester Discover to
        build the ForEach-blocks.
    #>
    $script:dscResourceFriendlyName = 'SqlDatabase'
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceFriendlyName = 'SqlDatabase'
}

<#
    .SYNOPSIS
        Integration tests for SqlDatabase resource using DSCv3.

    .NOTES
        These tests verify the SqlDatabase class-based resource works correctly
        with DSCv3. See GitHub issue #2403 for context.
#>
Describe "$($script:dscResourceFriendlyName)_Integration" -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Output the PowerShell version used in the test
        Write-Verbose -Message "`nPowerShell version used in integration test:`n$($PSVersionTable | Out-String)" -Verbose

        $script:serverName = Get-ComputerName
        $script:instanceName = 'DSCSQLTEST'

        <#
            Credential object for DSCv3. Using lowercase 'username' and 'password'
            as required by DSCv3 psDscAdapter for PSCredential conversion.
            See PowerShell/DSC PR #1308 for details on credential handling in DSCv3.
        #>
        $script:sqlAdminCredential = @{
            username = "$env:COMPUTERNAME\SqlAdmin"
            password = 'P@ssw0rd1'
        }
    }

    Context 'When getting the current state of the model database' {
        It 'Should return the expected current state for the model database' {
            $desiredParameters = @{
                InstanceName  = $script:instanceName
                ServerName    = $script:serverName
                Name          = 'model'
                RecoveryModel = 'Simple'
                Ensure        = 'Present'
                Credential    = $script:sqlAdminCredential
            }

            $result = dsc --trace-level info resource get --resource SqlServerDsc/SqlDatabase --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json -Depth 5 | Out-String)" -Verbose

            $result.actualState.Name | Should -Be 'model'
            $result.actualState.InstanceName | Should -Be $script:instanceName
            $result.actualState.Ensure | Should -Be 'Present'
            $result.actualState.RecoveryModel | Should -BeIn @('Full', 'Simple', 'BulkLogged')
        }

        It 'Should return the expected current state for the master database' {
            $desiredParameters = @{
                InstanceName = $script:instanceName
                ServerName   = $script:serverName
                Name         = 'master'
                Ensure       = 'Present'
                Credential   = $script:sqlAdminCredential
            }

            $result = dsc --trace-level info resource get --resource SqlServerDsc/SqlDatabase --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json -Depth 5 | Out-String)" -Verbose

            $result.actualState.Name | Should -Be 'master'
            $result.actualState.InstanceName | Should -Be $script:instanceName
            $result.actualState.Ensure | Should -Be 'Present'
        }
    }

    Context 'When testing the current state of the model database' {
        It 'Should return true when the database is in the desired state' {
            $desiredParameters = @{
                InstanceName = $script:instanceName
                ServerName   = $script:serverName
                Name         = 'model'
                Ensure       = 'Present'
                Credential   = $script:sqlAdminCredential
            }

            $result = dsc --trace-level info resource test --resource SqlServerDsc/SqlDatabase --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json -Depth 5 | Out-String)" -Verbose

            $result.inDesiredState | Should -BeTrue
        }

        It 'Should return false when the database is not in the desired state' {
            # Request a non-existent database which should return Ensure = 'Absent'
            $desiredParameters = @{
                InstanceName = $script:instanceName
                ServerName   = $script:serverName
                Name         = 'NonExistentDatabase_DSCv3Test'
                Ensure       = 'Present'
                Credential   = $script:sqlAdminCredential
            }

            $result = dsc --trace-level info resource test --resource SqlServerDsc/SqlDatabase --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json -Depth 5 | Out-String)" -Verbose

            $result.inDesiredState | Should -BeFalse
        }
    }

    Context 'When getting the current state of a non-existent database' {
        It 'Should return Ensure as Absent' {
            $desiredParameters = @{
                InstanceName = $script:instanceName
                ServerName   = $script:serverName
                Name         = 'NonExistentDatabase_DSCv3Test'
                Ensure       = 'Present'
                Credential   = $script:sqlAdminCredential
            }

            $result = dsc --trace-level info resource get --resource SqlServerDsc/SqlDatabase --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json -Depth 5 | Out-String)" -Verbose

            $result.actualState.Name | Should -Be 'NonExistentDatabase_DSCv3Test'
            $result.actualState.Ensure | Should -Be 'Absent'
        }
    }

    Context 'When testing the model database with a different recovery model' {
        It 'Should return false when recovery model is not in desired state' {
            $desiredParameters = @{
                InstanceName  = $script:instanceName
                ServerName    = $script:serverName
                Name          = 'model'
                RecoveryModel = 'Simple'
                Ensure        = 'Present'
                Credential    = $script:sqlAdminCredential
            }

            $result = dsc --trace-level info resource test --resource SqlServerDsc/SqlDatabase --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json -Depth 5 | Out-String)" -Verbose

            $result.inDesiredState | Should -BeFalse
        }
    }

    Context 'When setting the model database recovery model to Simple' {
        It 'Should successfully set the recovery model' {
            $desiredParameters = @{
                InstanceName  = $script:instanceName
                ServerName    = $script:serverName
                Name          = 'model'
                RecoveryModel = 'Simple'
                Ensure        = 'Present'
                Credential    = $script:sqlAdminCredential
            }

            $result = dsc --trace-level info resource set --resource SqlServerDsc/SqlDatabase --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json -Depth 5 | Out-String)" -Verbose

            $result.afterState.RecoveryModel | Should -Be 'Simple'
        }
    }

    Context 'When testing the model database after setting recovery model to Simple' {
        It 'Should return true when recovery model is in desired state' {
            $desiredParameters = @{
                InstanceName  = $script:instanceName
                ServerName    = $script:serverName
                Name          = 'model'
                RecoveryModel = 'Simple'
                Ensure        = 'Present'
                Credential    = $script:sqlAdminCredential
            }

            $result = dsc --trace-level info resource test --resource SqlServerDsc/SqlDatabase --output-format json --input ($desiredParameters | ConvertTo-Json -Compress) | ConvertFrom-Json

            $dscExitCode = $LASTEXITCODE # cSpell: ignore LASTEXITCODE

            if ($dscExitCode -ne 0)
            {
                throw ('DSC executable failed with exit code {0}.' -f $dscExitCode)
            }

            Write-Verbose -Message "Result:`n$($result | ConvertTo-Json -Depth 5 | Out-String)" -Verbose

            $result.inDesiredState | Should -BeTrue
        }
    }
}
