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

# cSpell: ignore DSCSQLTEST
Describe 'Disconnect-SqlDscDatabaseEngine' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose
    }

    Context 'When disconnecting from the default instance' {
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

        Context 'When disconnecting using Force parameter' {
            It 'Should disconnect successfully without confirmation' {
                $sqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
                $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                $connectSqlDscDatabaseEngineParameters = @{
                    Credential  = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)
                    Verbose     = $true
                    ErrorAction = 'Stop'
                }

                $sqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

                $sqlServerObject.Status.ToString() | Should -Match '^Online$'

                # Test the disconnect functionality
                Disconnect-SqlDscDatabaseEngine -ServerObject $sqlServerObject -Force -ErrorAction 'Stop'

                # After disconnect, the connection should be closed
                $sqlServerObject.ConnectionContext.IsOpen | Should -BeFalse
            }
        }

        Context 'When disconnecting using pipeline input' {
            It 'Should disconnect successfully via pipeline' {
                $sqlAdministratorUserName = 'SqlAdmin' # Using computer name as NetBIOS name throw exception.
                $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                $connectSqlDscDatabaseEngineParameters = @{
                    Credential  = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)
                    Verbose     = $true
                    ErrorAction = 'Stop'
                }

                $sqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

                $sqlServerObject.Status.ToString() | Should -Match '^Online$'

                # Test the disconnect functionality via pipeline
                $sqlServerObject | Disconnect-SqlDscDatabaseEngine -Force -ErrorAction 'Stop'

                # After disconnect, the connection should be closed
                $sqlServerObject.ConnectionContext.IsOpen | Should -BeFalse
            }
        }
    }

    Context 'When disconnecting from a named instance' {
        It 'Should have the named instance SQL Server service started' {
            $getServiceResult = Get-Service -Name 'MSSQL$DSCSQLTEST' -ErrorAction 'Stop'

            $getServiceResult.Status | Should -Be 'Running'
        }

        Context 'When disconnecting using Windows authentication' {
            It 'Should disconnect successfully from named instance' {
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

                # Test the disconnect functionality
                Disconnect-SqlDscDatabaseEngine -ServerObject $sqlServerObject -Force -ErrorAction 'Stop'

                # After disconnect, the connection should be closed
                $sqlServerObject.ConnectionContext.IsOpen | Should -BeFalse
            }
        }

        Context 'When disconnecting using SQL authentication' {
            It 'Should disconnect successfully from named instance with SQL login' {
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

                # Test the disconnect functionality
                Disconnect-SqlDscDatabaseEngine -ServerObject $sqlServerObject -Force -ErrorAction 'Stop'

                # After disconnect, the connection should be closed
                $sqlServerObject.ConnectionContext.IsOpen | Should -BeFalse
            }
        }
    }
}
