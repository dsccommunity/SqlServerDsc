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

Describe 'Disable-SqlDscRsSecureConnection' {
    Context 'When disabling secure connection for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $script:originalLevel = $script:configuration.SecureConnectionLevel
        }

        AfterAll {
            # Restore the original secure connection level
            $restoreConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            if ($script:originalLevel -eq 0)
            {
                $restoreConfig | Disable-SqlDscRsSecureConnection -Force
            }
            else
            {
                $restoreConfig | Enable-SqlDscRsSecureConnection -Force
            }
        }

        It 'Should disable secure connection using pipeline' {
            # First ensure secure connection is enabled
            $script:configuration | Enable-SqlDscRsSecureConnection -Force

            # Disable secure connection
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Disable-SqlDscRsSecureConnection -Force

            # Verify secure connection is disabled
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.SecureConnectionLevel | Should -Be 0
        }

        It 'Should return configuration when using PassThru' {
            # First enable TLS
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Enable-SqlDscRsSecureConnection -Force

            # Disable with PassThru
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $result = $config | Disable-SqlDscRsSecureConnection -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When disabling secure connection for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $script:originalLevel = $script:configuration.SecureConnectionLevel
        }

        AfterAll {
            # Restore the original secure connection level
            $restoreConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            if ($script:originalLevel -eq 0)
            {
                $restoreConfig | Disable-SqlDscRsSecureConnection -Force
            }
            else
            {
                $restoreConfig | Enable-SqlDscRsSecureConnection -Force
            }
        }

        It 'Should disable secure connection using pipeline' {
            # First ensure secure connection is enabled
            $script:configuration | Enable-SqlDscRsSecureConnection -Force

            # Disable secure connection
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Disable-SqlDscRsSecureConnection -Force

            # Verify secure connection is disabled
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.SecureConnectionLevel | Should -Be 0
        }

        It 'Should return configuration when using PassThru' {
            # First enable TLS
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Enable-SqlDscRsSecureConnection -Force

            # Disable with PassThru
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $result = $config | Disable-SqlDscRsSecureConnection -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When disabling secure connection for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $script:originalLevel = $script:configuration.SecureConnectionLevel
        }

        AfterAll {
            # Restore the original secure connection level
            $restoreConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            if ($script:originalLevel -eq 0)
            {
                $restoreConfig | Disable-SqlDscRsSecureConnection -Force
            }
            else
            {
                $restoreConfig | Enable-SqlDscRsSecureConnection -Force
            }
        }

        It 'Should disable secure connection using pipeline' {
            # First ensure secure connection is enabled
            $script:configuration | Enable-SqlDscRsSecureConnection -Force

            # Disable secure connection
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Disable-SqlDscRsSecureConnection -Force

            # Verify secure connection is disabled
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $verifyConfig.SecureConnectionLevel | Should -Be 0
        }

        It 'Should return configuration when using PassThru' {
            # First enable TLS
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $config | Enable-SqlDscRsSecureConnection -Force

            # Disable with PassThru
            $config = Get-SqlDscRSConfiguration -InstanceName 'SSRS'
            $result = $config | Disable-SqlDscRsSecureConnection -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'SSRS'
        }
    }

    Context 'When disabling secure connection for Power BI Report Server' -Tag @('Integration_PowerBI') {
        # cSpell: ignore PBIRS
        BeforeAll {
            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $script:originalLevel = $script:configuration.SecureConnectionLevel
        }

        AfterAll {
            # Restore the original secure connection level
            $restoreConfig = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            if ($script:originalLevel -eq 0)
            {
                $restoreConfig | Disable-SqlDscRsSecureConnection -Force
            }
            else
            {
                $restoreConfig | Enable-SqlDscRsSecureConnection -Force
            }
        }

        It 'Should disable secure connection for PBIRS using pipeline' {
            # First ensure secure connection is enabled
            $script:configuration | Enable-SqlDscRsSecureConnection -Force

            # Disable secure connection
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $config | Disable-SqlDscRsSecureConnection -Force

            # Verify secure connection is disabled
            $verifyConfig = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $verifyConfig.SecureConnectionLevel | Should -Be 0
        }

        It 'Should return configuration when using PassThru' {
            # First enable TLS
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $config | Enable-SqlDscRsSecureConnection -Force

            # Disable with PassThru
            $config = Get-SqlDscRSConfiguration -InstanceName 'PBIRS'
            $result = $config | Disable-SqlDscRsSecureConnection -Force -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.InstanceName | Should -Be 'PBIRS'
        }
    }
}
