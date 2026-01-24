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

Describe 'Initialize-SqlDscFailoverCluster' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    BeforeAll {
        $computerName = Get-ComputerName
        Write-Verbose -Message ("Running integration test as user '{0}' on computer '{1}'." -f $env:UserName, $computerName) -Verbose
    }

    Context 'When preparing a failover cluster node' {
        <#
            This test is skipped because failover cluster is not available on CI build agents.
            The CI environment uses standard virtual machines that do not have the
            Windows Server Failover Clustering feature available.

            To run this test locally:
            1. Set up a Windows Server environment with Failover Clustering feature installed
            2. Ensure the server is part of a domain
            3. Have SQL Server installation media available
            4. Remove the -Skip parameter
            5. Update the parameters below with valid values
        #>
        It 'Should run the command without throwing' -Skip {
            $initializeSqlDscFailoverClusterParameters = @{
                AcceptLicensingTerms = $true
                InstanceName         = 'YOURINSTANCE'
                Features             = 'SQLENGINE'
                MediaPath            = $env:IsoDrivePath
                Verbose              = $true
                ErrorAction          = 'Stop'
                Force                = $true
            }

            try
            {
                $null = Initialize-SqlDscFailoverCluster @initializeSqlDscFailoverClusterParameters
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
