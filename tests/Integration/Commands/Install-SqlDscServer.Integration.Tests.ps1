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
    Context 'When using Install parameter set' {
        Context 'When installing database engine default instance' {
            It 'Should run the command without throwing' {
                {
                    # TODO: Add additional properties, for example service accounts, to the splatting parameters.
                    # Set splatting parameters for Install-SqlDscServer
                    $installSqlDscServerParameters = @{
                        Install = $true
                        AcceptLicensingTerms = $true
                        InstanceName = 'MSSQLSERVER'
                        Features = 'SQLENGINE'
                        SqlSysAdminAccounts = @(
                            ('{0}\SqlAdmin' -f (Get-ComputerName))
                        )
                        MediaPath = $env:IsoDrivePath # Set by the prerequisites tests
                        Verbose = $true
                        ErrorAction = 'Stop'
                        Force = $true
                    }

                    Install-SqlDscServer @installSqlDscServerParameters
                } | Should -Not -Throw
            }
        }
    }
}
