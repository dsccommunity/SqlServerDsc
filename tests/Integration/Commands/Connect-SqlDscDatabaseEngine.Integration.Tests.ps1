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

Describe 'Connect-SqlDscDatabaseEngine' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $computerName = Get-ComputerName

        $previouslyErrorViewPreference = $ErrorView
        $ErrorView = 'DetailedView'
    }

    AfterAll {
        $ErrorView = $previouslyErrorViewPreference

        Write-Verbose -Message ('Error count: {0}' -f $Error.Count) -Verbose
        Write-Verbose -Message ($Error | Out-String) -Verbose
    }

    Context 'When connecting to the default instance impersonating a Windows user' {
        It 'Should return the correct result' {
            {
                $sqlAdministratorUserName = '{0}\SqlAdmin' -f $computerName
                $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                $connectSqlDscDatabaseEngineParameters = @{
                    Credential  = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)
                    Verbose     = $true
                    ErrorAction = 'Stop'
                }


                $sqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

                $sqlServerObject.Status.ToString() | Should -Match '^Online$'
            } | Should -Not -Throw
        }
    }
}
