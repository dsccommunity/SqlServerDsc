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

<#
    .NOTES
        These tests change the Reporting Services service account to the svc-RS
        account that was created in the Prerequisites tests. The Get-SqlDscRSServiceAccount
        tests run after this and verify the account was changed successfully.
#>
Describe 'Set-SqlDscRSServiceAccount' {
    Context 'When setting service account for SQL Server Reporting Services' -Tag @('Integration_SQL2017_RS') {
        BeforeAll {
            $computerName = Get-ComputerName
            $script:serviceAccountName = '{0}\svc-RS' -f $computerName
            $script:serviceAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
            $script:serviceAccountCredential = [System.Management.Automation.PSCredential]::new($script:serviceAccountName, $script:serviceAccountPassword)

            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $script:originalServiceAccount = $script:configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'
        }

        It 'Should have the original service account set' {
            $script:originalServiceAccount | Should -Not -BeNullOrEmpty
        }

        It 'Should change the service account to svc-RS' {
            $script:configuration |
                Set-SqlDscRSServiceAccount -Credential $script:serviceAccountCredential -RestartService -SuppressUrlReservationWarning -Force -ErrorAction 'Stop'
        }

        It 'Should have the new service account set after the change' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $result | Should -BeExactly $script:serviceAccountName
        }
    }

    Context 'When setting service account for SQL Server Reporting Services' -Tag @('Integration_SQL2019_RS') {
        BeforeAll {
            $computerName = Get-ComputerName
            $script:serviceAccountName = '{0}\svc-RS' -f $computerName
            $script:serviceAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
            $script:serviceAccountCredential = [System.Management.Automation.PSCredential]::new($script:serviceAccountName, $script:serviceAccountPassword)

            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $script:originalServiceAccount = $script:configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'
        }

        It 'Should have the original service account set' {
            $script:originalServiceAccount | Should -Not -BeNullOrEmpty
        }

        It 'Should change the service account to svc-RS' {
            $script:configuration |
                Set-SqlDscRSServiceAccount -Credential $script:serviceAccountCredential -RestartService -SuppressUrlReservationWarning -Force -ErrorAction 'Stop'
        }

        It 'Should have the new service account set after the change' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $result | Should -BeExactly $script:serviceAccountName
        }
    }

    Context 'When setting service account for SQL Server Reporting Services' -Tag @('Integration_SQL2022_RS') {
        BeforeAll {
            $computerName = Get-ComputerName
            $script:serviceAccountName = '{0}\svc-RS' -f $computerName
            $script:serviceAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
            $script:serviceAccountCredential = [System.Management.Automation.PSCredential]::new($script:serviceAccountName, $script:serviceAccountPassword)

            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $script:originalServiceAccount = $script:configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'
        }

        It 'Should have the original service account set' {
            $script:originalServiceAccount | Should -Not -BeNullOrEmpty
        }

        It 'Should change the service account to svc-RS' {
            $script:configuration |
                Set-SqlDscRSServiceAccount -Credential $script:serviceAccountCredential -RestartService -SuppressUrlReservationWarning -Force -ErrorAction 'Stop'
        }

        It 'Should have the new service account set after the change' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'SSRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $result | Should -BeExactly $script:serviceAccountName
        }
    }

    Context 'When setting service account for Power BI Report Server' -Tag @('Integration_PowerBI') {
        BeforeAll {
            $computerName = Get-ComputerName
            $script:serviceAccountName = '{0}\svc-RS' -f $computerName
            $script:serviceAccountPassword = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
            $script:serviceAccountCredential = [System.Management.Automation.PSCredential]::new($script:serviceAccountName, $script:serviceAccountPassword)

            $script:configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $script:originalServiceAccount = $script:configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'
        }

        It 'Should have the original service account set' {
            $script:originalServiceAccount | Should -Not -BeNullOrEmpty
        }

        It 'Should change the service account to svc-RS' {
            $script:configuration |
                Set-SqlDscRSServiceAccount -Credential $script:serviceAccountCredential -RestartService -SuppressUrlReservationWarning -Force -ErrorAction 'Stop'
        }

        It 'Should have the new service account set after the change' {
            $configuration = Get-SqlDscRSConfiguration -InstanceName 'PBIRS' -ErrorAction 'Stop'
            $result = $configuration | Get-SqlDscRSServiceAccount -ErrorAction 'Stop'

            $result | Should -BeExactly $script:serviceAccountName
        }
    }
}
