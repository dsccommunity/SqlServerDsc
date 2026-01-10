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
<#
    NOTE: These integration tests skipped due to intermittent failures in CI environment,
    they tend to fail with different errors that need to be be interactively resolved.
    This is not any issues with the command or the module, but rather issues with the
    SQL Server setup/repair process itself (might also be related to CI environmental
    factors, like too few resources).
#>
Describe 'Repair-SqlDscServer' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') -Skip {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        # Check if SQL Server LocalDB is installed (may be pre-installed on hosted agent)
        try
        {
            Write-Verbose -Message 'Checking for SQL Server LocalDB installations...' -Verbose
            $localDbInfo = & sqllocaldb info 2>&1
            if ($LASTEXITCODE -eq 0)
            {
                Write-Verbose -Message "SQL Server LocalDB is installed. Instances found:" -Verbose
                $localDbInfo | ForEach-Object { Write-Verbose -Message "  $_" -Verbose }
            }
            else
            {
                Write-Verbose -Message 'SQL Server LocalDB is not installed or sqllocaldb.exe is not in PATH.' -Verbose
            }
        }
        catch
        {
            Write-Verbose -Message "Could not check for LocalDB: $($_.Exception.Message)" -Verbose
        }
    }

    It 'Should have the named instance SQL Server service running' {
        $getServiceResult = Get-Service -Name 'MSSQL$DSCSQLTEST' -ErrorAction 'Stop'

        $getServiceResult.Status | Should -Be 'Running'
    }

    It 'Should uninstall SQL Server LocalDB if present to avoid repair conflicts' {
        # LocalDB may be pre-installed on hosted agents and cause repair to fail
        # because SqlLocalDB.msi is not in our installation media
        try
        {
            Write-Verbose -Message 'Checking if SQL Server LocalDB is installed...' -Verbose

            # Use registry-based detection instead of Win32_Product to avoid MSI consistency checks
            $uninstallKeys = @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )

            $localDbProducts = Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like '*LocalDB*' }

            if ($localDbProducts)
            {
                foreach ($product in $localDbProducts)
                {
                    Write-Verbose -Message "Uninstalling LocalDB product: $($product.DisplayName) (Product Code: $($product.PSChildName))" -Verbose

                    # Uninstall using msiexec with the product code
                    $uninstallArgs = "/x `"$($product.PSChildName)`" /qn /norestart"
                    $process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $uninstallArgs -Wait -PassThru

                    if ($process.ExitCode -eq 0)
                    {
                        Write-Verbose -Message "Successfully uninstalled: $($product.DisplayName)" -Verbose
                    }
                    else
                    {
                        Write-Warning -Message "Failed to uninstall $($product.DisplayName). Exit code: $($process.ExitCode)"
                    }
                }
            }
            else
            {
                Write-Verbose -Message 'No SQL Server LocalDB products found to uninstall.' -Verbose
            }
        }
        catch
        {
            Write-Warning -Message "Error checking/uninstalling LocalDB: $($_.Exception.Message)"
        }
    }

    Context 'When repairing a named instance' {
        <#
            NOTE: This test may fail if the SQL Server installation includes features
            for which the installation media does not contain the required MSI files.
            For example, if LocalDB is installed but SqlLocalDB.msi is not in the
            installation media, the repair will fail with:
            "An installation package for the product Microsoft SQL Server 2019 LocalDB
            cannot be found. Try the installation again using a valid copy of the
            installation package 'SqlLocalDB.msi'."

            This is a limitation of SQL Server's Repair action - it repairs ALL installed
            features and requires all MSI files to be present in the installation media.

            This test may also intermittently fail with exit code -2068052310 (0x8424000A).
            This appears to be a SQL Server setup behavior where repair completes successfully
            but returns a non-zero exit code. The Summary.txt typically shows:
            - All features passed
            - Warnings: "Service SID support has been enabled on the service"

            The subsequent tests verify the repair was actually successful by checking:
            - SQL Server service is running
            - Can connect to the instance
            If this failure occurs, check the Summary.txt output in the test logs to confirm
            the repair actually completed successfully despite the non-zero exit code.
        #>
        It 'Should run the repair command without throwing' {
            # Set splatting parameters for Repair-SqlDscServer
            $repairSqlDscServerParameters = @{
                InstanceName = 'DSCSQLTEST'
                MediaPath    = $env:IsoDrivePath
                Verbose      = $true
                ErrorAction  = 'Stop'
                Force        = $true
            }

            try
            {
                $null = Repair-SqlDscServer @repairSqlDscServerParameters
            }
            catch
            {
                # Output Summary.txt if it exists to help diagnose the failure
                Get-SqlDscSetupLog -Verbose | Write-Verbose -Verbose

                # Check if this is the known LocalDB MSI missing issue
                if ($_.Exception.Message -match 'SqlLocalDB\.msi')
                {
                    Write-Warning @'
The repair failed because LocalDB is installed but the SqlLocalDB.msi file is not
available in the installation media. This is a known limitation of SQL Server's
Repair action - it repairs ALL installed features and requires all MSI files to
be present in the installation media.

Possible solutions:
1. Use installation media that includes SqlLocalDB.msi
2. Uninstall LocalDB before running repair
3. Use a different SQL Server instance that doesn't have LocalDB installed

This is not a bug in SqlServerDsc but a limitation of SQL Server setup.
'@
                }

                # Re-throw the original error
                throw $_
            }
        }

        It 'Should still have the named instance SQL Server service running after repair' {
            $getServiceResult = Get-Service -Name 'MSSQL$DSCSQLTEST' -ErrorAction 'Stop'

            $getServiceResult | Should -Not -BeNullOrEmpty
            $getServiceResult.Status | Should -Be 'Running'
        }

        It 'Should be able to connect to the instance after repair' {
            $sqlAdministratorUserName = 'SqlAdmin'
            $sqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

            $connectSqlDscDatabaseEngineParameters = @{
                InstanceName = 'DSCSQLTEST'
                Credential   = [System.Management.Automation.PSCredential]::new($sqlAdministratorUserName, $sqlAdministratorPassword)
                ErrorAction  = 'Stop'
            }

            $sqlServerObject = Connect-SqlDscDatabaseEngine @connectSqlDscDatabaseEngineParameters

            $sqlServerObject | Should -Not -BeNullOrEmpty
            $sqlServerObject.InstanceName | Should -Be 'DSCSQLTEST'

            Disconnect-SqlDscDatabaseEngine -ServerObject $sqlServerObject -ErrorAction 'Stop'
        }
    }
}
