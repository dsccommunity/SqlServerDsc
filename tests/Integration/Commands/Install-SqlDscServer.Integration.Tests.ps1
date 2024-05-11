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

BeforeAll {
       <#
    .SYNOPSIS
        This function will output the Setup Bootstrap Summary.txt log file.

    .DESCRIPTION
        This function will output the Summary.txt log file, this is to be
        able to debug any problems that potentially occurred during setup.
        This will pick up the newest Summary.txt log file, so any
        other log files will be ignored (AppVeyor build worker has
        SQL Server instances installed by default).
        This code is meant to work regardless what SQL Server
        major version is used for the integration test.
    #>
    function Show-SqlBootstrapLog
    {
        [CmdletBinding()]
        param
        (
        )

        $summaryLogPath = Get-ChildItem -Path 'C:\Program Files\Microsoft SQL Server\**\Setup Bootstrap\Log\Summary.txt' |
            Sort-Object -Property LastWriteTime -Descending |
            Select-Object -First 1

        $summaryLog = Get-Content $summaryLogPath

        Write-Verbose -Message $('-' * 80) -Verbose
        Write-Verbose -Message 'Summary.txt' -Verbose
        Write-Verbose -Message $('-' * 80) -Verbose

        $summaryLog | ForEach-Object -Process {
            Write-Verbose $_ -Verbose
        }

        Write-Verbose -Message $('-' * 80) -Verbose
    }
}

Describe 'Install-SqlDscServer' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        # Get the built SqlServerDsc module path.
        $modulePath = Split-Path -Parent -Path (Get-Module -name SqlServerDsc -ListAvailable).ModuleBase
    }

    Context 'When using Install parameter set' {
        Context 'When installing database engine default instance' {
            It 'Should run the command without throwing' {
                {
                    Write-Verbose -Message ('Running install as user ''{0}''.' -f $env:UserName) -Verbose

                    $computerName = Get-ComputerName

                    # Set splatting parameters for Install-SqlDscServer
                    $installSqlDscServerParameters = @{
                        Install               = $true
                        AcceptLicensingTerms  = $true
                        InstanceName          = 'MSSQLSERVER'
                        Features              = 'SQLENGINE'
                        SqlSysAdminAccounts   = @(
                            ('{0}\SqlAdmin' -f $computerName)
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
                        SqlCollation          = 'Finnish_Swedish_CI_AS'
                        InstallSharedDir      = 'C:\Program Files\Microsoft SQL Server'
                        InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
                        MediaPath             = $env:IsoDrivePath
                        Verbose               = $true
                        ErrorAction           = 'Stop'
                        Force                 = $true
                    }

                    Install-SqlDscServer @installSqlDscServerParameters

                    # <#
                    #     Fails with the following error message:

                    #     VERBOSE:   Exit code (Decimal):           -2068774911
                    #     VERBOSE:   Exit facility code:            1201
                    #     VERBOSE:   Exit error code:               1
                    #     VERBOSE:   Exit message:                  There was an error generating the XML document.

                    #     Searches points to a permission issue, but the user has been
                    #     granted the local administrator permissions. But code be
                    #     Searches also points to user right SeEnableDelegationPrivilege
                    #     which was not evaluated if it was set correctly or even needed.
                    # #>
                    # $installScriptBlock = {
                    #     param
                    #     (
                    #         [Parameter(Mandatory = $true)]
                    #         [System.String]
                    #         $IsoDrivePath,

                    #         [Parameter(Mandatory = $true)]
                    #         [System.String]
                    #         $ComputerName,

                    #         [Parameter(Mandatory = $true)]
                    #         [System.String]
                    #         $ModulePath
                    #     )

                    #     Write-Verbose -Message ('Running install as user ''{0}''.' -f $env:UserName) -Verbose

                    #     Import-Module -Name $ModulePath -Force -ErrorAction 'Stop'

                    #     # Set splatting parameters for Install-SqlDscServer
                    #     $installSqlDscServerParameters = @{
                    #         Install               = $true
                    #         AcceptLicensingTerms  = $true
                    #         InstanceName          = 'MSSQLSERVER'
                    #         Features              = 'SQLENGINE'
                    #         SqlSysAdminAccounts   = @(
                    #             ('{0}\SqlAdmin' -f $ComputerName)
                    #         )
                    #         SqlSvcAccount         = '{0}\svc-SqlPrimary' -f $ComputerName
                    #         SqlSvcPassword        = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
                    #         SqlSvcStartupType     = 'Automatic'
                    #         AgtSvcAccount         = '{0}\svc-SqlAgentPri' -f $ComputerName
                    #         AgtSvcPassword        = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
                    #         AgtSvcStartupType     = 'Automatic'
                    #         BrowserSvcStartupType = 'Automatic'
                    #         SecurityMode          = 'SQL'
                    #         SAPwd                 = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
                    #         SqlCollation          = 'Finnish_Swedish_CI_AS'
                    #         InstallSharedDir      = 'C:\Program Files\Microsoft SQL Server'
                    #         InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
                    #         MediaPath             = $IsoDrivePath
                    #         Verbose               = $true
                    #         ErrorAction           = 'Stop'
                    #         Force                 = $true
                    #     }

                    #     Install-SqlDscServer @installSqlDscServerParameters
                    # }

                    # $invokeCommandUsername = '{0}\SqlInstall' -f $ComputerName
                    # $invokeCommandPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
                    # $invokeCommandCredential = New-Object System.Management.Automation.PSCredential ($invokeCommandUsername, $invokeCommandPassword)

                    # # Runs command as SqlInstall user.
                    # Invoke-Command -ComputerName 'localhost' -Credential $invokeCommandCredential -ScriptBlock $installScriptBlock -ArgumentList @(
                    #     $env:IsoDrivePath, # Already set by the prerequisites tests
                    #     (Get-ComputerName),
                    #     $modulePath
                    # )
                } | Should -Not -Throw
            }

            It 'Should have installed the SQL Server database engine' {
                # Validate the SQL Server installation
                $sqlServerService = Get-Service -Name 'MSSQLSERVER'

                $sqlServerService | Should -Not -BeNullOrEmpty
                $sqlServerService.Status | Should -Be 'Running'
            }

            # It 'Should output the Summary.txt log file' {
            #     Show-SqlBootstrapLog
            # }
        }
    }
}
