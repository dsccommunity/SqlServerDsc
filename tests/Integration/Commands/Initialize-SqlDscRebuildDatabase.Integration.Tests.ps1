[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
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
Describe 'Initialize-SqlDscRebuildDatabase' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Stop the SQL Server instance so we can rebuild the databases
        $serviceName = 'MSSQL$DSCSQLTEST'
        $sqlService = Get-Service -Name $serviceName -ErrorAction 'Stop'

        if ($sqlService.Status -eq 'Running')
        {
            Write-Verbose -Message "Stopping SQL Server service '$serviceName'..." -Verbose
            Stop-Service -Name $serviceName -Force -ErrorAction 'Stop'
            Start-Sleep -Seconds 5
        }

        # Verify service is stopped
        $sqlService = Get-Service -Name $serviceName -ErrorAction 'Stop'
        if ($sqlService.Status -ne 'Stopped')
        {
            Write-Error -Message "Failed to stop SQL Server service '$serviceName'"
        }
    }

    AfterAll {
        # Ensure SQL Server service is running after tests
        $serviceName = 'MSSQL$DSCSQLTEST'
        $sqlService = Get-Service -Name $serviceName -ErrorAction 'Stop'

        if ($sqlService.Status -ne 'Running')
        {
            Write-Verbose -Message "Starting SQL Server service '$serviceName'..." -Verbose
            Start-Service -Name $serviceName -ErrorAction 'Stop'
            Start-Sleep -Seconds 10
        }

        # Verify service is running
        $sqlService = Get-Service -Name $serviceName -ErrorAction 'Stop'
        if ($sqlService.Status -ne 'Running')
        {
            Write-Error -Message "Failed to start SQL Server service '$serviceName'"
        }
    }

    Context 'When rebuilding database on a named instance' {
        Context 'When specifying only mandatory parameters' {
            It 'Should run the rebuild command without throwing (using Force parameter)' {
                # Set splatting parameters for Initialize-SqlDscRebuildDatabase
                $saPwd = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                $rebuildSqlDscDatabaseParameters = @{
                    InstanceName        = 'DSCSQLTEST'
                    SAPwd               = $saPwd
                    SqlSysAdminAccounts = @(
                        ('{0}\SqlAdmin' -f (Get-ComputerName))
                    )
                    MediaPath           = $env:IsoDrivePath
                    Verbose             = $true
                    ErrorAction         = 'Stop'
                    Force               = $true
                }

                try
                {
                    $null = Initialize-SqlDscRebuildDatabase @rebuildSqlDscDatabaseParameters
                }
                catch
                {
                    # Output Summary.txt if it exists to help diagnose the failure
                    $summaryFiles = Get-ChildItem -Path 'C:\Program Files\Microsoft SQL Server' -Filter 'Summary.txt' -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -match '\\Setup Bootstrap\\Log\\' } |
                        Sort-Object -Property LastWriteTime -Descending |
                        Select-Object -First 1

                    if ($summaryFiles)
                    {
                        Write-Verbose "==== SQL Server Setup Summary.txt (from $($summaryFiles.FullName)) ====" -Verbose
                        Get-Content -Path $summaryFiles.FullName | Write-Verbose -Verbose
                        Write-Verbose "==== End of Summary.txt ====" -Verbose
                    }
                    else
                    {
                        Write-Verbose 'No Summary.txt file found.' -Verbose
                    }

                    # Re-throw the original error
                    throw $_
                }
            }

            It 'Should have the SQL Server service running after rebuild' {
                $serviceName = 'MSSQL$DSCSQLTEST'
                Start-Service -Name $serviceName -ErrorAction 'Stop'
                Start-Sleep -Seconds 10

                $sqlService = Get-Service -Name $serviceName -ErrorAction 'Stop'
                $sqlService.Status | Should -Be 'Running'
            }

            It 'Should be able to connect to the instance after rebuild' {
                $computerName = Get-ComputerName
                $mockSqlAdministratorUserName = 'SqlAdmin'
                $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                $mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new(
                    $mockSqlAdministratorUserName,
                    $mockSqlAdministratorPassword
                )

                $serverObject = Connect-SqlDscDatabaseEngine -InstanceName 'DSCSQLTEST' -Credential $mockSqlAdminCredential -ErrorAction 'Stop'

                $serverObject | Should -Not -BeNullOrEmpty
                $serverObject.Name | Should -Match 'DSCSQLTEST'

                Disconnect-SqlDscDatabaseEngine -ServerObject $serverObject
            }
        }

        Context 'When specifying optional TempDB parameters' {
            It 'Should run the rebuild command with custom TempDB file count' {
                # Set splatting parameters for Initialize-SqlDscRebuildDatabase
                $saPwd = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                $rebuildSqlDscDatabaseParameters = @{
                    InstanceName         = 'DSCSQLTEST'
                    SAPwd                = $saPwd
                    SqlSysAdminAccounts  = @(
                        ('{0}\SqlAdmin' -f (Get-ComputerName))
                    )
                    MediaPath            = $env:IsoDrivePath
                    SqlTempDbFileCount   = 8
                    Verbose              = $true
                    ErrorAction          = 'Stop'
                    Force                = $true
                }

                try
                {
                    $null = Initialize-SqlDscRebuildDatabase @rebuildSqlDscDatabaseParameters
                }
                catch
                {
                    # Output Summary.txt if it exists to help diagnose the failure
                    $summaryFiles = Get-ChildItem -Path 'C:\Program Files\Microsoft SQL Server' -Filter 'Summary.txt' -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -match '\\Setup Bootstrap\\Log\\' } |
                        Sort-Object -Property LastWriteTime -Descending |
                        Select-Object -First 1

                    if ($summaryFiles)
                    {
                        Write-Verbose "==== SQL Server Setup Summary.txt (from $($summaryFiles.FullName)) ====" -Verbose
                        Get-Content -Path $summaryFiles.FullName | Write-Verbose -Verbose
                        Write-Verbose "==== End of Summary.txt ====" -Verbose
                    }
                    else
                    {
                        Write-Verbose 'No Summary.txt file found.' -Verbose
                    }

                    # Re-throw the original error
                    throw $_
                }
            }

            It 'Should have the SQL Server service running after rebuild with TempDB parameters' {
                $serviceName = 'MSSQL$DSCSQLTEST'
                Start-Service -Name $serviceName -ErrorAction 'Stop'
                Start-Sleep -Seconds 10

                $sqlService = Get-Service -Name $serviceName -ErrorAction 'Stop'
                $sqlService.Status | Should -Be 'Running'
            }
        }

        Context 'When specifying optional SqlCollation parameter' {
            It 'Should run the rebuild command with custom collation' {
                # Set splatting parameters for Initialize-SqlDscRebuildDatabase
                $saPwd = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

                $rebuildSqlDscDatabaseParameters = @{
                    InstanceName        = 'DSCSQLTEST'
                    SAPwd               = $saPwd
                    SqlSysAdminAccounts = @(
                        ('{0}\SqlAdmin' -f (Get-ComputerName))
                    )
                    MediaPath           = $env:IsoDrivePath
                    SqlCollation        = 'SQL_Latin1_General_CP1_CI_AS'
                    Verbose             = $true
                    ErrorAction         = 'Stop'
                    Force               = $true
                }

                try
                {
                    $null = Initialize-SqlDscRebuildDatabase @rebuildSqlDscDatabaseParameters
                }
                catch
                {
                    # Output Summary.txt if it exists to help diagnose the failure
                    $summaryFiles = Get-ChildItem -Path 'C:\Program Files\Microsoft SQL Server' -Filter 'Summary.txt' -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -match '\\Setup Bootstrap\\Log\\' } |
                        Sort-Object -Property LastWriteTime -Descending |
                        Select-Object -First 1

                    if ($summaryFiles)
                    {
                        Write-Verbose "==== SQL Server Setup Summary.txt (from $($summaryFiles.FullName)) ====" -Verbose
                        Get-Content -Path $summaryFiles.FullName | Write-Verbose -Verbose
                        Write-Verbose "==== End of Summary.txt ====" -Verbose
                    }
                    else
                    {
                        Write-Verbose 'No Summary.txt file found.' -Verbose
                    }

                    # Re-throw the original error
                    throw $_
                }
            }

            It 'Should have the SQL Server service running after rebuild with collation' {
                $serviceName = 'MSSQL$DSCSQLTEST'
                Start-Service -Name $serviceName -ErrorAction 'Stop'
                Start-Sleep -Seconds 10

                $sqlService = Get-Service -Name $serviceName -ErrorAction 'Stop'
                $sqlService.Status | Should -Be 'Running'
            }
        }
    }
}
