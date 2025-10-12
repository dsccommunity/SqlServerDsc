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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

# cSpell: ignore DSCSQLTEST
Describe 'Uninstall-SqlDscServer' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose
    }

    It 'Should have the named instance SQL Server service started' {
        $getServiceResult = Get-Service -Name 'MSSQL$DSCSQLTEST' -ErrorAction 'Stop'

        $getServiceResult.Status | Should -Be 'Running'
    }

    Context 'When uninstalling a named instance' {
        It 'Should run the command without throwing' {
            # Set splatting parameters for Uninstall-SqlDscServer
            $uninstallSqlDscServerParameters = @{
                InstanceName          = 'DSCSQLTEST'
                Features              = 'SQLENGINE'
                MediaPath             = $env:IsoDrivePath
                Verbose               = $true
                ErrorAction           = 'Stop'
                Force                 = $true
            }

            $null = Uninstall-SqlDscServer @uninstallSqlDscServerParameters
        }

        It 'Should not have a named instance SQL Server service' {
            Get-Service -Name 'SQL Server (DSCSQLTEST)' -ErrorAction 'Ignore' | Should -BeNullOrEmpty
        }
    }
}
