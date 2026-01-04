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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}

Describe 'Install-SqlDscFailoverCluster Integration Tests' -Skip -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    # Integration tests require a Windows Failover Cluster environment
    # which is not available in the CI pipeline. Remove -Skip and uncomment
    # the test structure below when running locally with a cluster environment.

    It 'Should run a simple integration test' {
        $true | Should -BeTrue
    }

    <#
        Template for local testing with a failover cluster environment.
        Uncomment and modify as needed.

        BeforeAll {
            $script:clusterNetworkName = 'YOURCLUSTER01'
            $script:clusterIPAddresses = @(
                'IPv4;192.168.0.100;ClusterNetwork1;255.255.255.0'
            )

            $script:installParameters = @{
                AcceptLicensingTerms       = $true
                MediaPath                  = 'D:\'
                InstanceName               = 'YOURINSTANCE'
                Features                   = 'SQLENGINE'
                InstallSqlDataDir          = 'C:\Program Files\Microsoft SQL Server'
                SqlSysAdminAccounts        = "$env:USERDOMAIN\$env:USERNAME"
                FailoverClusterNetworkName = $script:clusterNetworkName
                FailoverClusterIPAddresses = $script:clusterIPAddresses
                Force                      = $true
                ErrorAction                = 'Stop'
            }
        }

        Context 'When installing SQL Server in a failover cluster' {
            It 'Should install SQL Server without throwing an exception' {
                { Install-SqlDscFailoverCluster @script:installParameters } | Should -Not -Throw
            }

            It 'Should have created the SQL Server cluster resource' {
                $clusterResource = Get-ClusterResource -Name "SQL Server ($($script:installParameters.InstanceName))" -ErrorAction 'SilentlyContinue'

                $clusterResource | Should -Not -BeNullOrEmpty
            }

            It 'Should have the cluster resource in online state' {
                $clusterResource = Get-ClusterResource -Name "SQL Server ($($script:installParameters.InstanceName))" -ErrorAction 'SilentlyContinue'

                $clusterResource.State | Should -Be 'Online'
            }
        }

        Context 'When connecting to the clustered SQL Server instance' {
            It 'Should be able to connect to the instance' {
                $serverObject = Connect-SqlDscDatabaseEngine -ServerName $script:clusterNetworkName -InstanceName $script:installParameters.InstanceName

                $serverObject | Should -Not -BeNullOrEmpty

                Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject
            }
        }
    #>
}
