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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

# cSpell: ignore SQLSERVERAGENT, DSCSQLTEST, PrepareImage
Describe 'Install-SqlDscServer - PrepareImage' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        Write-Verbose -Message ('Running integration test as user ''{0}''.' -f $env:UserName) -Verbose

        $computerName = Get-ComputerName
    }

    Context 'When using PrepareImage parameter set' {
        Context 'When preparing database engine instance for image' {
            It 'Should run the command without throwing' {
                # Set splatting parameters for Install-SqlDscServer with PrepareImage
                $installSqlDscServerParameters = @{
                    PrepareImage          = $true
                    AcceptLicensingTerms  = $true
                    InstanceId            = 'DSCSQLTEST'
                    Features              = 'SQLENGINE'
                    InstallSharedDir      = 'C:\Program Files\Microsoft SQL Server'
                    InstallSharedWOWDir   = 'C:\Program Files (x86)\Microsoft SQL Server'
                    MediaPath             = $env:IsoDrivePath
                    Verbose               = $true
                    ErrorAction           = 'Stop'
                    Force                 = $true
                }

                try
                {
                    $null = Install-SqlDscServer @installSqlDscServerParameters
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
        }
    }
}
