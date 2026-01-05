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

# cSpell: ignore SQLSERVERAGENT, DSCSQLTEST
Describe 'Initialize-SqlDscImage' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $computerName = Get-ComputerName
        Write-Verbose -Message ("Running integration test as user '{0}' on computer '{1}'." -f $env:UserName, $computerName) -Verbose
    }

    Context 'When preparing database engine instance for image' {
        It 'Should run the command without throwing' {
            $initializeSqlDscImageParameters = @{
                AcceptLicensingTerms = $true
                InstanceId           = 'DSCSQLTEST'
                Features             = 'SQLENGINE'
                InstallSharedDir     = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWowDir  = 'C:\Program Files (x86)\Microsoft SQL Server'
                MediaPath            = $env:IsoDrivePath
                Verbose              = $true
                ErrorAction          = 'Stop'
                Force                = $true
            }

            try
            {
                $null = Initialize-SqlDscImage @initializeSqlDscImageParameters
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
