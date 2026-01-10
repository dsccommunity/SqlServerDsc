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

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../TestHelpers/CommonTestHelper.psm1')

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'
}

<#
    .NOTES
        This test file re-initializes Reporting Services after the service account
        has been changed and URL reservations have been recreated. This ensures
        that the Reporting Services instance is fully functional with the new
        service account.

        This test runs after Post.UrlReservationRecreate.RS and before
        Post.ServiceAccountChange.RS to ensure the instance is properly
        initialized before testing accessibility.
#>
Describe 'Post.Reinitialize.RS' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
    BeforeAll {
        if (Test-ContinuousIntegrationTaskCategory -Category 'Integration_PowerBI')
        {
            $script:instanceName = 'PBIRS'
        }
        else
        {
            # Default to SSRS for SQL2017_RS, SQL2019_RS, SQL2022_RS
            $script:instanceName = 'SSRS'
        }

        $script:configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

        # Get the Reporting Services service account from the configuration object.
        $script:serviceAccount = $script:configuration.WindowsServiceIdentityActual

        Write-Verbose -Message "Instance: $script:instanceName, ServiceAccount: $script:serviceAccount" -Verbose
    }

    Context 'When re-initializing Reporting Services after service account change' {
        It 'Should re-initialize the Reporting Services instance' {
            $script:configuration | Initialize-SqlDscRS -Force -ErrorAction 'Stop'
        }

        It 'Should have an initialized instance after re-initialization' {
            # Refresh the configuration after initialization
            $configuration = Get-SqlDscRSConfiguration -InstanceName $script:instanceName -ErrorAction 'Stop'

            $isInitialized = $configuration | Test-SqlDscRSInitialized -ErrorAction 'Stop'

            $isInitialized | Should -BeTrue -Because 'the instance should be initialized after re-initialization'

            Write-Verbose -Message "Instance initialized: $isInitialized" -Verbose
        }

        It 'Should restart the Reporting Services service' {
            $null = $script:configuration | Restart-SqlDscRSService -Force -ErrorAction 'Stop'
        }
    }
}
