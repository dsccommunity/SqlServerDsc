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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

# cSpell: ignore DSCSQLTEST
Describe 'Connect-SqlDscDatabaseEngine' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # $previouslyErrorViewPreference = $ErrorView
        # $ErrorView = 'DetailedView'
        # $Error.Clear()
    }

    # AfterAll {
    #     $ErrorView = $previouslyErrorViewPreference

    #     Write-Verbose -Message ('Error count: {0}' -f $Error.Count) -Verbose
    #     Write-Verbose -Message ($Error | Out-String) -Verbose
    # }

    Context 'When connecting to the default instance impersonating a Windows user' {
        BeforeAll {
            # Starting the default instance SQL Server service prior to running tests.
            Start-Service -Name 'MSSQLSERVER' -Verbose -ErrorAction 'Stop'
        }

        AfterAll {
            # Stop the default instance SQL Server service to save memory on the build worker.
            Stop-Service -Name 'MSSQLSERVER' -Verbose -ErrorAction 'Stop'
        }

        It 'Should have the default instance SQL Server service started' {
            $getServiceResult = Get-Service -Name 'MSSQLSERVER' -ErrorAction 'Stop'

            $getServiceResult.Status | Should -Be 'Running'
        }

        Context 'When impersonating a Windows user' {
            It 'Should return the correct result' {
                {
                    $sqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
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

    Context 'When connecting to a named instance' {
        BeforeAll {
            # Starting the named instance SQL Server service prior to running tests.
            Start-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
        }

        AfterAll {
            # Stop the named instance SQL Server service to save memory on the build worker.
            Stop-Service -Name 'MSSQL$DSCSQLTEST' -Verbose -ErrorAction 'Stop'
        }

        It 'Should have the named instance SQL Server service started' {
            $getServiceResult = Get-Service -Name 'MSSQL$DSCSQLTEST' -ErrorAction 'Stop'

            $getServiceResult.Status | Should -Be 'Running'
        }

        Context 'When impersonating a Windows user' {
            It 'Should return the correct result' {
                {
                    $sqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
                    $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                    $connectSqlDscDatabaseEngineParameters = @{
                        InstanceName = 'DSCSQLTEST'
                        Credential   = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)
                        Verbose      = $true
                        ErrorAction  = 'Stop'
                    }

                    $sqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

                    $sqlServerObject.Status.ToString() | Should -Match '^Online$'
                } | Should -Not -Throw
            }
        }

        Context 'When using a SQL login' {
            It 'Should return the correct result' {
                {
                    $sqlAdministratorUserName = 'sa'
                    $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                    $connectSqlDscDatabaseEngineParameters = @{
                        InstanceName = 'DSCSQLTEST' # cSpell: disable-line
                        LoginType    = 'SqlLogin'
                        Credential   = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)
                        Verbose      = $true
                        ErrorAction  = 'Stop'
                    }

                    $sqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

                    $sqlServerObject.Status.ToString() | Should -Match '^Online$'
                } | Should -Not -Throw
            }
        }
    }
}
