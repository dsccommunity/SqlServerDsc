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
    $script:dscModuleName = 'SqlServerDsc'

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Stubs') -ChildPath 'SMO.cs')

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Test-SqlDscServerPermission' -Tag 'Public' {
    Context 'When testing parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Grant'
                ExpectedParameters = '-ServerObject <Server> -Name <string> -Grant -Permission <string[]> [-WithGrant] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'Deny'
                ExpectedParameters = '-ServerObject <Server> -Name <string> -Deny -Permission <string[]> [-WithGrant] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscServerPermission').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When testing parameter properties' {
        It 'Should have ServerObject as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['ServerObject']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Name as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['Name']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should have Grant as a mandatory parameter in Grant parameter set' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['Grant']
            $grantParameterSetAttributes = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'Grant' }
            $grantParameterSetAttributes.Mandatory | Should -BeTrue
        }

        It 'Should have Deny as a mandatory parameter in Deny parameter set' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['Deny']
            $denyParameterSetAttributes = $parameterInfo.Attributes | Where-Object { $_.ParameterSetName -eq 'Deny' }
            $denyParameterSetAttributes.Mandatory | Should -BeTrue
        }

        It 'Should have WithGrant as an optional parameter' {
            $parameterInfo = (Get-Command -Name 'Test-SqlDscServerPermission').Parameters['WithGrant']
            $parameterInfo.Attributes.Mandatory | Should -BeFalse
        }
    }

    Context 'When testing permissions successfully' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName Test-SqlDscServerPermissionState -MockWith {
                return $true
            }
        }

        It 'Should return true when permissions are in desired state' {
            $result = Test-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Grant -Permission @('ConnectSql')

            $result | Should -BeTrue
        }

        It 'Should call Test-SqlDscServerPermissionState' {
            Test-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Grant -Permission @('ConnectSql')

            Should -Invoke -CommandName Test-SqlDscServerPermissionState -Times 1
        }
    }

    Context 'When permissions are not in desired state' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName Test-SqlDscServerPermissionState -MockWith {
                return $false
            }
        }

        It 'Should return false when permissions are not in desired state' {
            $result = Test-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Grant -Permission @('ConnectSql')

            $result | Should -BeFalse
        }
    }

    Context 'When testing fails with an exception' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName Test-SqlDscServerPermissionState -MockWith {
                throw 'Mock error'
            }
        }

        It 'Should return false when an exception occurs' {
            $result = Test-SqlDscServerPermission -ServerObject $mockServerObject -Name 'TestUser' -Grant -Permission @('ConnectSql')

            $result | Should -BeFalse
        }
    }

    Context 'When using pipeline input' {
        BeforeAll {
            $mockServerObject = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server'
            $mockServerObject.InstanceName = 'MockInstance'

            Mock -CommandName Test-SqlDscServerPermissionState -MockWith {
                return $true
            }
        }

        It 'Should accept ServerObject from pipeline' {
            $result = $mockServerObject | Test-SqlDscServerPermission -Name 'TestUser' -Grant -Permission @('ConnectSql')

            $result | Should -BeTrue
        }
    }
}