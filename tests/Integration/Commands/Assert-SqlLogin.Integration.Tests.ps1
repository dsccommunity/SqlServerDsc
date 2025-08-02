[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName
}

Describe 'Assert-SqlLogin' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $script:instanceName = 'DSCSQLTEST'
        $script:computerName = Get-ComputerName
    }

    Context 'When connecting to SQL Server instance' {
        BeforeAll {
            $script:sqlAdminCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList @(
                'SqlAdmin',
                ('P@ssw0rd1' | ConvertTo-SecureString -AsPlainText -Force)
            )
            $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:instanceName -Credential $script:sqlAdminCredential
        }

        Context 'When a login exists' {
            It 'Should not throw an error for sa login' {
                { Assert-SqlLogin -ServerObject $script:serverObject -Principal 'sa' } | Should -Not -Throw
            }

            It 'Should not throw an error when using pipeline' {
                { $script:serverObject | Assert-SqlLogin -Principal 'sa' } | Should -Not -Throw
            }

            It 'Should not throw an error for NT AUTHORITY\SYSTEM login' {
                { Assert-SqlLogin -ServerObject $script:serverObject -Principal 'NT AUTHORITY\SYSTEM' } | Should -Not -Throw
            }

            It 'Should not throw an error for SqlAdmin login' {
                { Assert-SqlLogin -ServerObject $script:serverObject -Principal ('{0}\SqlAdmin' -f $script:computerName) } | Should -Not -Throw
            }
        }

        Context 'When a login does not exist' {
            It 'Should throw a terminating error for non-existent login' {
                { Assert-SqlLogin -ServerObject $script:serverObject -Principal 'NonExistentLogin123' } | Should -Throw -ExpectedMessage "*does not exist as a login*"
            }

            It 'Should throw an error with ObjectNotFound category' {
                try
                {
                    Assert-SqlLogin -ServerObject $script:serverObject -Principal 'NonExistentLogin123'
                }
                catch
                {
                    $_.CategoryInfo.Category | Should -Be 'ObjectNotFound'
                }
            }
        }
    }
}
