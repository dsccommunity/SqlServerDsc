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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'SqlServerDsc'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    # Loading stub cmdlets
    Import-Module -Name "$PSScriptRoot/../../Unit/Stubs/SqlServer.psm1" -Force
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    Remove-Module -Name SqlServer -Force
}

Describe 'Revoke-SqlDscServerPermission' -Tag 'IntegrationTest' {
    BeforeAll {
        $mockInstanceName = 'DSCSQLTEST'
        $mockServerName = $env:COMPUTERNAME

        $mockSqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
            'SqlAdmin',
            (ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force)
        )

        $mockConnectSqlParameters = @{
            ServerName   = $mockServerName
            InstanceName = $mockInstanceName
            Credential   = $mockSqlCredential
            ErrorAction  = 'Stop'
        }

        $script:mockServerObject = Connect-SqlDscDatabaseEngine @mockConnectSqlParameters

        # Define test permission sets
        $script:testPermissionSet = [Microsoft.SqlServer.Management.Smo.ServerPermissionSet] @{
            ConnectSql = $true
        }

        $script:testPrincipalName = 'TestUser2'

        # Clean up any existing test user
        InModuleScope -ScriptBlock {
            if ($script:mockServerObject.Logins[$script:testPrincipalName])
            {
                $script:mockServerObject.Logins[$script:testPrincipalName].Drop()
            }
        }

        # Create test user for permission testing
        InModuleScope -ScriptBlock {
            $testLogin = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList @(
                $script:mockServerObject,
                $script:testPrincipalName
            )
            $testLogin.LoginType = 'SqlLogin'
            $testLogin.Create('P@ssw0rd1')
        }

        # Grant permission first so we can revoke it
        $script:mockServerObject | Grant-SqlDscServerPermission -Name $script:testPrincipalName -Permission $script:testPermissionSet -Force
    }

    AfterAll {
        # Clean up the test user
        InModuleScope -ScriptBlock {
            if ($script:mockServerObject.Logins[$script:testPrincipalName])
            {
                $script:mockServerObject.Logins[$script:testPrincipalName].Drop()
            }
        }

        $script:mockServerObject | Disconnect-SqlDscDatabaseEngine
    }

    Context 'When revoking server permissions from a principal' {
        It 'Should revoke permissions without throwing an error' {
            {
                $script:mockServerObject | Revoke-SqlDscServerPermission -Name $script:testPrincipalName -Permission $script:testPermissionSet -Force
            } | Should -Not -Throw
        }

        It 'Should show the permissions as no longer granted' {
            $result = $script:mockServerObject | Test-SqlDscServerPermission -Name $script:testPrincipalName -Grant -Permission $script:testPermissionSet

            $result | Should -BeFalse
        }
    }
}
