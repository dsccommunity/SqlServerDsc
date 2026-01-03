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

# cSpell: ignore RSDB
Describe 'Prerequisites - RSDB SQL Server Instance' -Tag @('Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS', 'Integration_PowerBI') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $computerName = Get-ComputerName
    }

    Context 'Install SQL Server Database Engine instance RSDB for Reporting Services database' {
        It 'Should install the RSDB instance without throwing' {
            <#
                Install a minimal SQL Server Database Engine instance named RSDB
                that will be used to host the Reporting Services database for
                integration tests.

                This reuses the same accounts and passwords as the main Prerequisites
                test file. The media path ($env:IsoDrivePath) is set by the main
                Prerequisites test that runs before this one.
            #>
            $installSqlDscServerParameters = @{
                Install               = $true
                AcceptLicensingTerms  = $true
                InstanceName          = 'RSDB'
                Features              = 'SQLENGINE'
                SqlSysAdminAccounts   = @(
                    ('{0}\SqlAdmin' -f $computerName)
                    'BUILTIN\Administrators'
                )
                SqlSvcAccount         = '{0}\svc-SqlPrimary' -f $computerName
                SqlSvcPassword        = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
                SqlSvcStartupType     = 'Automatic'
                AgtSvcAccount         = '{0}\svc-SqlAgentPri' -f $computerName
                AgtSvcPassword        = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
                AgtSvcStartupType     = 'Automatic'
                BrowserSvcStartupType = 'Automatic'
                SecurityMode          = 'SQL'
                SAPwd                 = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
                SqlCollation          = 'SQL_Latin1_General_CP1_CI_AS'
                InstallSharedDir      = 'C:\Program Files\Microsoft SQL Server'
                InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
                NpEnabled             = $true
                TcpEnabled            = $true
                MediaPath             = $env:IsoDrivePath
                Verbose               = $true
                ErrorAction           = 'Stop'
                Force                 = $true
            }

            Install-SqlDscServer @installSqlDscServerParameters
        }

        It 'Should have the RSDB instance running' {
            $service = Get-Service -Name 'MSSQL$RSDB' -ErrorAction 'SilentlyContinue'

            $service | Should -Not -BeNullOrEmpty
            $service.Status | Should -Be 'Running'
        }
    }
}
