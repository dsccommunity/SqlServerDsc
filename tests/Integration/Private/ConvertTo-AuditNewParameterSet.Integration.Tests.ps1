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

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
}

Describe 'ConvertTo-AuditNewParameterSet' -Tag @('Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_SQL2025') {
    BeforeAll {
        $script:mockInstanceName = 'DSCSQLTEST'
        $script:mockComputerName = Get-ComputerName

        $mockSqlAdministratorUserName = 'SqlAdmin'
        $mockSqlAdministratorPassword = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force

        $script:mockSqlAdminCredential = [System.Management.Automation.PSCredential]::new($mockSqlAdministratorUserName, $mockSqlAdministratorPassword)

        $script:serverObject = Connect-SqlDscDatabaseEngine -InstanceName $script:mockInstanceName -Credential $script:mockSqlAdminCredential -ErrorAction 'Stop'

        # Create a temporary directory for file audits if it doesn't exist
        $script:testAuditPath = 'C:\Temp\SqlDscTestAudits'
        if (-not (Test-Path -Path $script:testAuditPath))
        {
            $null = New-Item -Path $script:testAuditPath -ItemType Directory -Force
        }
    }

    AfterAll {
        # Clean up any test audits that might remain
        $testAudits = Get-SqlDscAudit -ServerObject $script:serverObject -ErrorAction 'SilentlyContinue' |
            Where-Object { $_.Name -like 'SqlDscTestConvert*' }

        foreach ($audit in $testAudits)
        {
            try
            {
                Remove-SqlDscAudit -AuditObject $audit -Force -ErrorAction 'SilentlyContinue'
            }
            catch
            {
                # Ignore cleanup errors
            }
        }

        Disconnect-SqlDscDatabaseEngine -ServerObject $script:serverObject

        # Clean up temporary directory
        if (Test-Path -Path $script:testAuditPath)
        {
            Remove-Item -Path $script:testAuditPath -Recurse -Force -ErrorAction 'SilentlyContinue'
        }
    }

    Context 'When converting an ApplicationLog audit' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_AppLog_' + (Get-Random)
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct parameters that can recreate the audit' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['ServerObject'] | Should -Be $script:serverObject
            $parameters['Name'] | Should -Be $script:testAudit.Name
            $parameters['LogType'] | Should -Be 'ApplicationLog'
            $parameters.ContainsKey('Path') | Should -BeFalse
        }

        It 'Should recreate the audit with the same properties using returned parameters' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.Name | Should -Be $script:testAudit.Name
            $recreatedAudit.DestinationType | Should -Be $script:testAudit.DestinationType
        }
    }

    Context 'When converting a SecurityLog audit' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_SecLog_' + (Get-Random)
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'SecurityLog' -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct parameters for SecurityLog audit' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['LogType'] | Should -Be 'SecurityLog'
            $parameters.ContainsKey('Path') | Should -BeFalse
        }
    }

    Context 'When converting a File audit with basic properties' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_File_' + (Get-Random)
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $script:testAuditPath -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct parameters for File audit' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['Path'].TrimEnd('\', '/') | Should -Be $script:testAuditPath.TrimEnd('\', '/')
            $parameters.ContainsKey('LogType') | Should -BeFalse
        }

        It 'Should recreate the File audit with the same properties' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.Name | Should -Be $script:testAudit.Name
            $recreatedAudit.DestinationType | Should -Be 'File'
            $recreatedAudit.FilePath.TrimEnd('\', '/') | Should -Be $script:testAuditPath.TrimEnd('\', '/')
        }
    }

    Context 'When converting a File audit with MaximumFileSize' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_FileSize_' + (Get-Random)
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $script:testAuditPath -MaximumFileSize 100 -MaximumFileSizeUnit 'Megabyte' -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct file size parameters' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['MaximumFileSize'] | Should -Be 100
            $parameters['MaximumFileSizeUnit'] | Should -Be 'Megabyte'
        }

        It 'Should recreate the audit with the same file size properties' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.MaximumFileSize | Should -Be 100
            $recreatedAudit.MaximumFileSizeUnit | Should -Be 'MB'
        }
    }

    Context 'When converting a File audit with MaximumFiles and ReserveDiskSpace' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_MaxFiles_' + (Get-Random)
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $script:testAuditPath -MaximumFiles 10 -MaximumFileSize 50 -MaximumFileSizeUnit 'Megabyte' -ReserveDiskSpace -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct MaximumFiles and ReserveDiskSpace parameters' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['MaximumFiles'] | Should -Be 10
            $parameters['MaximumFileSize'] | Should -Be 50
            $parameters['MaximumFileSizeUnit'] | Should -Be 'Megabyte'
            $parameters['ReserveDiskSpace'] | Should -BeTrue
            $parameters.ContainsKey('MaximumRolloverFiles') | Should -BeFalse
        }

        It 'Should recreate the audit with the same MaximumFiles properties' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.MaximumFiles | Should -Be 10
            $recreatedAudit.MaximumFileSize | Should -Be 50
            $recreatedAudit.ReserveDiskSpace | Should -BeTrue
        }
    }

    Context 'When converting a File audit with MaximumRolloverFiles' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_Rollover_' + (Get-Random)
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -Path $script:testAuditPath -MaximumRolloverFiles 15 -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct MaximumRolloverFiles parameters' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['MaximumRolloverFiles'] | Should -Be 15
            $parameters.ContainsKey('MaximumFiles') | Should -BeFalse
            $parameters.ContainsKey('ReserveDiskSpace') | Should -BeFalse
        }

        It 'Should recreate the audit with the same MaximumRolloverFiles properties' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.MaximumRolloverFiles | Should -Be 15
        }
    }

    Context 'When converting an audit with OnFailure setting' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_OnFailure_' + (Get-Random)
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -OnFailure 'FailOperation' -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct OnFailure parameter' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['OnFailure'] | Should -Be 'FailOperation'
        }

        It 'Should recreate the audit with the same OnFailure setting' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.OnFailure | Should -Be 'FailOperation'
        }
    }

    Context 'When converting an audit with QueueDelay setting' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_QueueDelay_' + (Get-Random)
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -QueueDelay 3000 -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct QueueDelay parameter' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['QueueDelay'] | Should -Be 3000
        }

        It 'Should recreate the audit with the same QueueDelay setting' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.QueueDelay | Should -Be 3000
        }
    }

    Context 'When converting an audit with AuditGuid' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_Guid_' + (Get-Random)
            $script:testGuid = [System.Guid]::NewGuid().ToString()
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -AuditGuid $script:testGuid -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct AuditGuid parameter' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['AuditGuid'] | Should -Be $script:testGuid
        }

        It 'Should allow overriding AuditGuid with new value' {
            $newGuid = [System.Guid]::NewGuid().ToString()

            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit; NewGuid = $newGuid } -ScriptBlock {
                param($AuditObject, $NewGuid)

                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject -AuditGuid $NewGuid
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['AuditGuid'] | Should -Be $newGuid
            $parameters['AuditGuid'] | Should -Not -Be $script:testAudit.Guid
        }

        It 'Should recreate the audit with the same AuditGuid' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.Guid | Should -Be $script:testGuid
        }
    }

    Context 'When converting an audit with AuditFilter' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_Filter_' + (Get-Random)
            $script:testFilter = "([database_name] = 'master')"
            $script:expectedFilter = "([database_name]='master')"  # SQL Server normalizes the filter
            $script:testAudit = New-SqlDscAudit -ServerObject $script:serverObject -Name $script:testAuditName -LogType 'ApplicationLog' -AuditFilter $script:testFilter -PassThru -Force -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return correct AuditFilter parameter' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['AuditFilter'] | Should -Be $script:expectedFilter
        }

        It 'Should recreate the audit with the same AuditFilter' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.Filter | Should -Be $script:expectedFilter
        }
    }

    Context 'When converting a complex audit with all properties' {
        BeforeAll {
            $script:testAuditName = 'SqlDscTestConvert_Complex_' + (Get-Random)
            $script:testGuid = [System.Guid]::NewGuid().ToString()
            $script:testFilter = "([database_name] = 'tempdb')"
            $script:expectedFilter = "([database_name]='tempdb')"
            $script:testAudit = New-SqlDscAudit `
                -ServerObject $script:serverObject `
                -Name $script:testAuditName `
                -Path $script:testAuditPath `
                -MaximumFileSize 200 `
                -MaximumFileSizeUnit 'Gigabyte' `
                -MaximumFiles 20 `
                -ReserveDiskSpace `
                -OnFailure 'Shutdown' `
                -QueueDelay 2000 `
                -AuditGuid $script:testGuid `
                -AuditFilter $script:testFilter `
                -PassThru `
                -Force `
                -ErrorAction 'Stop'
        }

        AfterAll {
            if ($script:testAudit)
            {
                Remove-SqlDscAudit -AuditObject $script:testAudit -Force -ErrorAction 'SilentlyContinue'
            }
        }

        It 'Should return all correct parameters for complex audit' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            $parameters | Should -Not -BeNullOrEmpty
            $parameters['Path'].TrimEnd('\', '/') | Should -Be $script:testAuditPath.TrimEnd('\', '/')
            $parameters['MaximumFileSize'] | Should -Be 200
            $parameters['MaximumFileSizeUnit'] | Should -Be 'Gigabyte'
            $parameters['MaximumFiles'] | Should -Be 20
            $parameters['ReserveDiskSpace'] | Should -BeTrue
            $parameters['OnFailure'] | Should -Be 'Shutdown'
            $parameters['QueueDelay'] | Should -Be 2000
            $parameters['AuditGuid'] | Should -Be $script:testGuid
            $parameters['AuditFilter'] | Should -Be $script:expectedFilter
        }

        It 'Should recreate the complex audit with all the same properties' {
            $parameters = InModuleScope -Parameters @{ AuditObject = $script:testAudit } -ScriptBlock {
                ConvertTo-AuditNewParameterSet -AuditObject $AuditObject
            }

            # Remove the original audit
            Remove-SqlDscAudit -AuditObject $script:testAudit -Confirm:$false

            # Recreate using the parameters
            $recreatedAudit = New-SqlDscAudit @parameters -Confirm:$false -PassThru

            $recreatedAudit | Should -Not -BeNullOrEmpty
            $recreatedAudit.Name | Should -Be $script:testAudit.Name
            $recreatedAudit.FilePath.TrimEnd('\', '/') | Should -Be $script:testAuditPath.TrimEnd('\', '/')
            $recreatedAudit.MaximumFileSize | Should -Be 200
            $recreatedAudit.MaximumFileSizeUnit | Should -Be 'GB'
            $recreatedAudit.MaximumFiles | Should -Be 20
            $recreatedAudit.ReserveDiskSpace | Should -BeTrue
            $recreatedAudit.OnFailure | Should -Be 'Shutdown'
            $recreatedAudit.QueueDelay | Should -Be 2000
            $recreatedAudit.Guid | Should -Be $script:testGuid
            $recreatedAudit.Filter | Should -Be $script:expectedFilter
        }
    }
}
