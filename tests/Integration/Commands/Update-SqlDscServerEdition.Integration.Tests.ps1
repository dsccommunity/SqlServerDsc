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

Describe 'Update-SqlDscServerEdition' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $computerName = Get-ComputerName
        Write-Verbose -Message ("Running integration test as user '{0}' on computer '{1}'." -f $env:UserName, $computerName) -Verbose
    }

    Context 'When upgrading edition of a SQL Server instance' {
        <#
            This test is skipped because there is no edition to upgrade from in CI.
            The CI environment installs a specific edition and we don't have a
            lower edition instance to upgrade from.

            To run this test locally:
            1. Install a SQL Server instance with a lower edition (e.g., Evaluation)
            2. Obtain a valid product key for the target edition
            3. Remove the -Skip parameter
            4. Update the parameters below with valid values
        #>
        It 'Should run the command without throwing' -Skip {
            $updateSqlDscServerEditionParameters = @{
                AcceptLicensingTerms = $true
                InstanceName         = 'YOURINSTANCE'
                ProductKey           = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
                MediaPath            = $env:IsoDrivePath
                Verbose              = $true
                ErrorAction          = 'Stop'
                Force                = $true
            }

            try
            {
                $null = Update-SqlDscServerEdition @updateSqlDscServerEditionParameters
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
