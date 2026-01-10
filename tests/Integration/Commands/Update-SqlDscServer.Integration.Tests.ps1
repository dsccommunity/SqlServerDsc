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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

Describe 'Update-SqlDscServer' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $computerName = Get-ComputerName
        Write-Verbose -Message ("Running integration test as user '{0}' on computer '{1}'." -f $env:UserName, $computerName) -Verbose
    }

    Context 'When upgrading version of a SQL Server instance' {
        <#
            This test is skipped because there is no prior version to upgrade from in CI.
            The CI environment only has one SQL Server version installed at a time,
            so we cannot test in-place upgrades.

            To run this test locally:
            1. Install an older version of SQL Server (e.g., SQL Server 2019)
            2. Have installation media for the newer version (e.g., SQL Server 2022)
            3. Remove the -Skip parameter
            4. Update the parameters below with valid values
        #>
        It 'Should run the command without throwing' -Skip {
            $updateSqlDscServerParameters = @{
                AcceptLicensingTerms = $true
                InstanceName         = 'YOURINSTANCE'
                MediaPath            = $env:IsoDrivePath
                Verbose              = $true
                ErrorAction          = 'Stop'
                Force                = $true
            }

            try
            {
                $null = Update-SqlDscServer @updateSqlDscServerParameters
            }
            catch
            {
                # Output Summary.txt if it exists to help diagnose the failure
                Get-SqlDscSetupLog -Verbose | Write-Verbose -Verbose

                # Re-throw the original error
                throw $_
            }
        }
    }
}
