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
                    # Set splatting parameters for Install-SqlDscServer
                    $installSqlDscServerParameters = @{
                        Install               = $true
                        AcceptLicensingTerms  = $true
                        InstanceName          = 'MSSQLSERVER'
                        Features              = 'SQLENGINE'
                        SqlSysAdminAccounts   = @(
                            ('{0}\SqlAdmin' -f (Get-ComputerName))
                        )
                        SqlSvcAccount         = '{0}\svc-SqlPrimary' -f (Get-ComputerName)
                        SqlSvcPassword        = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
                        SqlSvcStartupType     = 'Automatic'
                        AgtSvcAccount         = '{0}\svc-SqlAgentPri' -f (Get-ComputerName)
                        AgtSvcPassword        = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
                        AgtSvcStartupType     = 'Automatic'
                        BrowserSvcStartupType = 'Automatic'
                        SecurityMode          = 'SQL'
                        SAPwd                 = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
                        SqlCollation          = 'Finnish_Swedish_CI_AS'
                        MediaPath             = $env:IsoDrivePath # Already set by the prerequisites tests
                        Verbose               = $true
                        ErrorAction           = 'Stop'
                        Force                 = $true
                    }

                    # TODO: Should run command as SqlInstall user.
                    Install-SqlDscServer @installSqlDscServerParameters
                } | Should -Not -Throw
            }

            It 'Should have installed the SQL Server database engine' {
                # Validate the SQL Server installation
                $sqlServerService = Get-Service -Name 'MSSQLSERVER'

                $sqlServerService | Should -Not -BeNullOrEmpty
                $sqlServerService.Status | Should -Be 'Running'
            }
        }
    }
}
