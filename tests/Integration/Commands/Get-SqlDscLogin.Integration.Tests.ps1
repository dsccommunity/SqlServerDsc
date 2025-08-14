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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:dscModuleName = 'SqlServerDsc'

    Import-Module -Name $script:dscModuleName

    # Loading stub cmdlets
    Import-Module -Name "$PSScriptRoot/../../Stubs/SqlServerStub.psm1" -Force

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-SqlDscLogin' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    BeforeAll {
        $mockInstanceName = $env:COMPUTERNAME
        $mockSqlCredential = $null
        $mockConnectTimeout = 30
        $mockEncryptConnection = $true

        if ($env:INTEGRATION_TESTS_SQLSERVER_CREDENTIAL)
        {
            <#
                This is set by the pipeline so we can run the tests towards the
                SQL Server instance on the AppVeyor build worker.
            #>
            $mockSqlCredential = (ConvertFrom-Json -InputObject $env:INTEGRATION_TESTS_SQLSERVER_CREDENTIAL)
        }

        try
        {
            $serverObject = Connect-SqlDscDatabaseEngine -InstanceName $mockInstanceName -Credential $mockSqlCredential -ConnectTimeout $mockConnectTimeout -EncryptConnection $mockEncryptConnection
        }
        catch
        {
            Set-ItResult -Skip -Because 'Could not connect to SQL Server instance'
        }
    }

    Context 'When getting all SQL Server logins' {
        It 'Should return an array of Login objects' {
            $result = Get-SqlDscLogin -ServerObject $serverObject

            <#
                Casting to array to ensure we get the count on Windows PowerShell
                when there is only one login.
            #>
            @($result).Count | Should -BeGreaterOrEqual 1
            $result[0] | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Login'
        }

        It 'Should return system logins including sa' {
            $result = Get-SqlDscLogin -ServerObject $serverObject

            $result.Name | Should -Contain 'sa'
        }
    }

    Context 'When getting a specific SQL Server login' {
        It 'Should return the specified login when it exists' {
            $result = Get-SqlDscLogin -ServerObject $serverObject -Name 'sa'

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Login'
            $result.Name | Should -Be 'sa'
            $result.LoginType | Should -Be 'SqlLogin'
        }

        It 'Should throw an error when the login does not exist' {
            { Get-SqlDscLogin -ServerObject $serverObject -Name 'NonExistentLogin' -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage "There is no login with the name 'NonExistentLogin'."
        }

        It 'Should return null when the login does not exist and error action is SilentlyContinue' {
            $result = Get-SqlDscLogin -ServerObject $serverObject -Name 'NonExistentLogin' -ErrorAction 'SilentlyContinue'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When using the Refresh parameter' {
        It 'Should return the same results with and without Refresh' {
            $resultWithoutRefresh = Get-SqlDscLogin -ServerObject $serverObject
            $resultWithRefresh = Get-SqlDscLogin -ServerObject $serverObject -Refresh

            $resultWithoutRefresh.Count | Should -Be $resultWithRefresh.Count
        }
    }

    Context 'When using pipeline input' {
        It 'Should accept ServerObject from pipeline' {
            $result = $serverObject | Get-SqlDscLogin -Name 'sa'

            $result | Should -BeOfType 'Microsoft.SqlServer.Management.Smo.Login'
            $result.Name | Should -Be 'sa'
        }
    }
}
