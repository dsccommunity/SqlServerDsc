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

# cSpell: ignore DSCSQLTEST
Describe 'Assert-SqlLogin' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose
    }

    Context 'When connecting to the named instance DSCSQLTEST' {
        BeforeAll {
            $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'DSCSQLTEST'
        }

        AfterAll {
            Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject
        }

        Context 'When asserting a login that exists' {
            It 'Should not throw an error for sa login' {
                { $serverObject | Assert-SqlLogin -Principal 'sa' } | Should -Not -Throw
            }

            It 'Should not throw an error for NT AUTHORITY\SYSTEM login' {
                { Assert-SqlLogin -ServerObject $serverObject -Principal 'NT AUTHORITY\SYSTEM' } | Should -Not -Throw
            }
        }

        Context 'When asserting a login that does not exist' {
            It 'Should throw a terminating error for non-existent login' {
                { $serverObject | Assert-SqlLogin -Principal 'NonExistentLogin123456' } | Should -Throw -ExpectedMessage '*does not exist as a login*'
            }
        }
    }
}