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

Describe 'Pre.Set-SqlDscRSUrlReservation' {
    Context 'When setting HTTPS URL reservations for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'

            # Use HTTPS with port 443 for testing
            $script:testUrl1 = 'https://+:443'
        }

        It 'Should set HTTPS URL reservation on port 443 for ReportServerWebService' {
            $script:configuration | Set-SqlDscRSUrlReservation -Application 'ReportServerWebService' -UrlString $script:testUrl1 -Force -ErrorAction 'Stop'

            # Verify the URLs are set correctly
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # Get URLs for the specified application
            $currentUrls = @()

            for ($i = 0; $i -lt $reservations.Application.Count; $i++)
            {
                if ($reservations.Application[$i] -eq 'ReportServerWebService')
                {
                    $currentUrls += $reservations.UrlString[$i]
                }
            }

            $currentUrls | Should -Contain $script:testUrl1
        }

        It 'Should set HTTPS URL reservation on port 443 for ReportServerWebApp' {
            $script:configuration | Set-SqlDscRSUrlReservation -Application 'ReportServerWebApp' -UrlString $script:testUrl1 -Force -ErrorAction 'Stop'

            # Verify the URLs are set correctly
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $reservations = $config | Get-SqlDscRSUrlReservation -ErrorAction 'Stop'

            # Get URLs for the specified application
            $currentUrls = @()

            for ($i = 0; $i -lt $reservations.Application.Count; $i++)
            {
                if ($reservations.Application[$i] -eq 'ReportServerWebApp')
                {
                    $currentUrls += $reservations.UrlString[$i]
                }
            }

            $currentUrls | Should -Contain $script:testUrl1
        }
    }
}
