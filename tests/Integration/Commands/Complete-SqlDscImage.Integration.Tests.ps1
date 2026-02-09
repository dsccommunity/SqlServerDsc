[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Plain text used only for test credentials in CI.')]
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

# cSpell: ignore DSCSQLTEST, PrepareImage, CompleteImage
Describe 'Complete-SqlDscImage' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $computerName = Get-ComputerName
    }

    Context 'When completing a prepared SQL Server image' {
        It 'Should run the command without throwing' {
            # Set splatting parameters for Complete-SqlDscImage with service account configuration
            $completeSqlDscImageParameters = @{
                AcceptLicensingTerms  = $true
                InstanceName          = 'DSCSQLTEST'
                InstanceId            = 'DSCSQLTEST'
                SqlSvcAccount         = '{0}\svc-SqlPrimary' -f $computerName
                SqlSvcPassword        = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
                SqlSvcStartupType     = 'Automatic'
                AgtSvcAccount         = '{0}\svc-SqlAgentPri' -f $computerName
                AgtSvcPassword        = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
                AgtSvcStartupType     = 'Automatic'
                BrowserSvcStartupType = 'Automatic'
                SecurityMode          = 'SQL'
                SAPwd                 = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
                SqlSysAdminAccounts   = @(
                    ('{0}\SqlAdmin' -f $computerName)
                )
                InstallSqlDataDir     = 'C:\Program Files\Microsoft SQL Server\MSSQL\Data'
                SqlBackupDir          = 'C:\Program Files\Microsoft SQL Server\MSSQL\Backup'
                SqlTempDbDir          = 'C:\Program Files\Microsoft SQL Server\MSSQL\Data'
                SqlTempDbLogDir       = 'C:\Program Files\Microsoft SQL Server\MSSQL\Data'
                SqlUserDbDir          = 'C:\Program Files\Microsoft SQL Server\MSSQL\Data'
                SqlUserDbLogDir       = 'C:\Program Files\Microsoft SQL Server\MSSQL\Data'
                TcpEnabled            = $true
                NpEnabled             = $false
                MediaPath             = $env:IsoDrivePath
                Verbose               = $true
                ErrorAction           = 'Stop'
                Force                 = $true
            }

            try
            {
                $null = Complete-SqlDscImage @completeSqlDscImageParameters
            }
            catch
            {
                # Output Summary.txt if it exists to help diagnose the failure
                Get-SqlDscSetupLog -Verbose | Write-Verbose -Verbose

                # Re-throw the original error
                throw $_
            }
        }
    }
}
