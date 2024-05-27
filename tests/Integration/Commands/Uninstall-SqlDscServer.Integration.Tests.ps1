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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Install-SqlDscServer' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Starting the named instance SQL Server service prior to running tests.
        Start-Service -Name 'SQL Server (DSCSQLTEST)' -Verbose -ErrorAction 'Stop'

        $computerName = Get-ComputerName
    }

    It 'Should have the named instance SQL Server service started' {
        $getServiceResult = Get-Service -Name 'SQL Server (DSCSQLTEST)' -ErrorAction 'Stop'

        $getServiceResult.Status | Should -Be 'Running'
    }

    Context 'When uninstalling a named instance' {
        It 'Should run the command without throwing' {
            {
                # Set splatting parameters for Uninstall-SqlDscServer
                $uninstallSqlDscServerParameters = @{
                    InstanceName          = 'DSCSQLTEST'
                    Features              = 'SQLENGINE'
                    MediaPath             = $env:IsoDrivePath
                    Verbose               = $true
                    ErrorAction           = 'Stop'
                    Force                 = $true
                }

                Uninstall-SqlDscServer @uninstallSqlDscServerParameters
            } | Should -Not -Throw
        }

        It 'Should not have a named instance SQL Server service' {
            Get-Service -Name 'SQL Server (DSCSQLTEST)' -ErrorAction 'Ignore' | Should -BeNullOrEmpty
        }
    }
}
