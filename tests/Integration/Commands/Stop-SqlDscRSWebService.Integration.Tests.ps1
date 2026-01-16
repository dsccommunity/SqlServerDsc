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

Describe 'Stop-SqlDscRSWebService' {
    Context 'When stopping web service for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        It 'Should stop web service using pipeline' {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            { $config | Stop-SqlDscRSWebService -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify web service is stopped
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.IsWebServiceEnabled | Should -BeFalse
        }

        It 'Should be idempotent when web service is already stopped' {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            { $config | Stop-SqlDscRSWebService -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify web service is still stopped
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.IsWebServiceEnabled | Should -BeFalse
        }
    }

    Context 'When stopping web service for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        It 'Should stop web service using pipeline' {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            { $config | Stop-SqlDscRSWebService -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify web service is stopped
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.IsWebServiceEnabled | Should -BeFalse
        }

        It 'Should be idempotent when web service is already stopped' {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            { $config | Stop-SqlDscRSWebService -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify web service is still stopped
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.IsWebServiceEnabled | Should -BeFalse
        }
    }

    Context 'When stopping web service for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        It 'Should stop web service using pipeline' {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            { $config | Stop-SqlDscRSWebService -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify web service is stopped
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.IsWebServiceEnabled | Should -BeFalse
        }

        It 'Should be idempotent when web service is already stopped' {
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            { $config | Stop-SqlDscRSWebService -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify web service is still stopped
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.IsWebServiceEnabled | Should -BeFalse
        }
    }

    Context 'When stopping web service for Power BI Report Server' -Tag @('Integration_PowerBI') {
        It 'Should stop web service using pipeline' {
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            { $config | Stop-SqlDscRSWebService -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify web service is stopped
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $verifyConfig.IsWebServiceEnabled | Should -BeFalse
        }

        It 'Should be idempotent when web service is already stopped' {
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            { $config | Stop-SqlDscRSWebService -Force -ErrorAction 'Stop' } | Should -Not -Throw

            # Verify web service is still stopped
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $verifyConfig.IsWebServiceEnabled | Should -BeFalse
        }
    }
}
