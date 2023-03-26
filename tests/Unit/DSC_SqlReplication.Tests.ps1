<#
    .SYNOPSIS
        Unit test for DSC_SqlReplication DSC resource.
#>

# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
# Suppressing this rule because tests are mocking passwords in clear text.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
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
    $script:dscModuleName = 'SqlServerDsc'
    $script:dscResourceName = 'DSC_SqlReplication'

    $env:SqlServerDscCI = $true

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

    # Loading mocked classes
    Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs') -ChildPath 'SMO.cs')

    # Load the correct SQL Module stub
    $script:stubModuleName = Import-SQLModuleStub -PassThru

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscResourceName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscResourceName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Restore-TestEnvironment -TestEnvironment $script:testEnvironment

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscResourceName -All | Remove-Module -Force

    # Unload the stub module.
    Remove-SqlModuleStub -Name $script:stubModuleName

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Helper functions' {
    Context 'Get-SqlLocalServerName' {
        It 'Should return COMPUTERNAME given MSSQLSERVER' {
            InModuleScope -ScriptBlock {
                <#
                    Using helper function in DscResource.Common to get
                    correct hostname cross-plattform.
                #>
                $mockComputerName = Get-ComputerName

                Get-SqlLocalServerName -InstanceName MSSQLSERVER | Should -Be $mockComputerName
            }
        }

        It 'Should return COMPUTERNAME\InstanceName given InstanceName' {
            InModuleScope -ScriptBlock {
                <#
                    Using helper function in DscResource.Common to get
                    correct hostname cross-plattform.
                #>
                $mockComputerName = Get-ComputerName

                Get-SqlLocalServerName -InstanceName InstanceName | Should -Be "$($mockComputerName)\InstanceName"
            }
        }
    }
}

Describe 'The system is not in the desired state given Local distribution mode' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $mockPassword = ConvertTo-SecureString 'P@$$w0rd1' -AsPlainText -Force
            $mockCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('AdminLink', $mockPassword)

            $script:mockTestParameters = @{
                InstanceName = 'MSSQLSERVER'
                AdminLinkCredentials = $mockCredentials
                DistributorMode = 'Local'
                WorkingDirectory = 'C:\Temp'
            }
        }

        Mock -CommandName Get-SqlInstanceMajorVersion -MockWith { return '99' }
        Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME' }
        Mock -CommandName New-ServerConnection -MockWith {
            return [PSCustomObject] @{
                ServerInstance = $SqlServerName
            }
        }
        Mock -CommandName New-ReplicationServer -MockWith {
            return [PSCustomObject] @{
                IsDistributor = $false
                IsPublisher = $false
                DistributionDatabase = ''
                DistributionServer = 'SERVERNAME'
                WorkingDirectory = ''
            }
        }
        Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
        Mock -CommandName Install-LocalDistributor
        Mock -CommandName Install-RemoteDistributor
        Mock -CommandName Register-DistributorPublisher
        Mock -CommandName Uninstall-Distributor
        Mock -CommandName Import-SqlDscPreferredModule
    }

    Context 'The system is not in the desired state' {
        Context 'Get method' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:result = Get-TargetResource @mockTestParameters
                }
            }

            It 'Get method calls Get-SqlInstanceMajorVersion with InstanceName = MSSQLSERVER' {
                Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                    -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
            }

            It 'Get method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
                Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                    -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
            }

            It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
                Should -Invoke -CommandName New-ServerConnection -Times 1 `
                    -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
            }

            It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
                Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                    -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
            }

            It 'Get method does not call New-DistributionDatabase' {
                Should -Invoke -CommandName New-DistributionDatabase -Times 0
            }

            It 'Get method does not call Install-LocalDistributor' {
                Should -Invoke -CommandName Install-LocalDistributor -Times 0
            }

            It 'Get method does not call Install-RemoteDistributor' {
                Should -Invoke -CommandName Install-RemoteDistributor -Times 0
            }

            It 'Ger method does not call Register-DistributorPublisher' {
                Should -Invoke -CommandName Register-DistributorPublisher -Times 0
            }

            It 'Ger method does not call Uninstall-Distributor' {
                Should -Invoke -CommandName Uninstall-Distributor -Times 0
            }

            It 'Get method returns Ensure = Absent' {
                InModuleScope -ScriptBlock {
                    $result.Ensure | Should -Be 'Absent'
                }
            }

            It 'Get method returns InstanceName = ''MSSQLSERVER''' {
                InModuleScope -ScriptBlock {
                    $result.InstanceName | Should -Be $mockTestParameters.InstanceName
                }
            }

            It 'Get method returns DistributorMode as $null' {
                InModuleScope -ScriptBlock {
                    $result.DistributorMode | Should -BeNullOrEmpty
                }
            }

            It 'Get method returns DistributionDBName as $null' {
                InModuleScope -ScriptBlock {
                    $result.DistributionDBName | Should -BeNullOrEmpty
                }
            }

            It 'Get method returns RemoteDistributor as $null' {
                InModuleScope -ScriptBlock {
                    $result.RemoteDistributor | Should -BeNullOrEmpty
                }
            }

            It 'Get method returns WorkingDirectory as $null' {
                InModuleScope -ScriptBlock {
                    $result.WorkingDirectory | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'Test method' {
        It 'Test method returns false' {
            InModuleScope -ScriptBlock {
                Test-TargetResource @mockTestParameters | Should -BeFalse
            }
        }
    }

    Context 'Set method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-TargetResource @mockTestParameters
            }
        }

        It 'Set method calls Get-SqlInstanceMajorVersion with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Set method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
        }

        It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
        }

        It 'Set method calls New-DistributionDatabase with $DistributionDBName = distribution' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 1 `
                -ParameterFilter { $DistributionDBName -eq 'distribution' }
        }

        It 'Set method calls Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 1 `
                -ParameterFilter { $ReplicationServer.DistributionServer -eq 'SERVERNAME' }
        }

        It 'Set method calls Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 1 `
                -ParameterFilter { $PublisherName -eq 'SERVERNAME' }
        }

        It 'Set method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Set method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }
    }
}

Describe 'The system is not in the desired state given Remote distribution mode' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $mockPassword = ConvertTo-SecureString 'P@$$w0rd1' -AsPlainText -Force
            $mockCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('AdminLink', $mockPassword)

            $script:mockTestParameters = @{
                InstanceName = 'INSTANCENAME'
                AdminLinkCredentials = $mockCredentials
                DistributorMode = 'Remote'
                RemoteDistributor = 'REMOTESERVER'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Present'
            }
        }

        Mock -CommandName Get-SqlInstanceMajorVersion -MockWith { return '99' }
        Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME\INSTANCENAME' }
        Mock -CommandName New-ServerConnection -MockWith {
            return [PSCustomObject] @{
                ServerInstance = $SqlServerName
            }
        }
        Mock -CommandName New-ReplicationServer -MockWith {
            return [PSCustomObject] @{
                IsDistributor = $false
                IsPublisher = $false
                DistributionDatabase = ''
                DistributionServer = ''
                WorkingDirectory = ''
            }
        }
        Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
        Mock -CommandName Install-LocalDistributor
        Mock -CommandName Install-RemoteDistributor
        Mock -CommandName Register-DistributorPublisher
        Mock -CommandName Uninstall-Distributor
        Mock -CommandName Import-SqlDscPreferredModule
    }

    Context 'The system is not in the desired state' {
        Context 'Get method' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    $script:result = Get-TargetResource @mockTestParameters
                }
            }

            It 'Get method calls Get-SqlInstanceMajorVersion with $InstanceName = INSTANCENAME' {
                Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                    -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
            }

            It 'Get method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
                Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                    -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
            }

            It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
                Should -Invoke -CommandName New-ServerConnection -Times 1 `
                    -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
            }

            It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
                Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                    -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
            }

            It 'Get method does not call New-DistributionDatabase' {
                Should -Invoke -CommandName New-DistributionDatabase -Times 0
            }

            It 'Get method does not call Install-LocalDistributor' {
                Should -Invoke -CommandName Install-LocalDistributor -Times 0
            }

            It 'Get method does not call Install-RemoteDistributor' {
                Should -Invoke -CommandName Install-RemoteDistributor -Times 0
            }

            It 'Ger method does not call Register-DistributorPublisher' {
                Should -Invoke -CommandName Register-DistributorPublisher -Times 0
            }

            It 'Ger method does not call Uninstall-Distributor' {
                Should -Invoke -CommandName Uninstall-Distributor -Times 0
            }

            It 'Get method returns Ensure = Absent' {
                InModuleScope -ScriptBlock {
                    $result.Ensure | Should -Be 'Absent'
                }
            }

            It 'Get method returns InstanceName = ''INSTANCENAME''' {
                InModuleScope -ScriptBlock {
                    $result.InstanceName | Should -Be $mockTestParameters.InstanceName
                }
            }

            It 'Get method returns DistributorMode as $null' {
                InModuleScope -ScriptBlock {
                    $result.DistributorMode | Should -BeNullOrEmpty
                }
            }

            It 'Get method returns DistributionDBName as $null' {
                InModuleScope -ScriptBlock {
                    $result.DistributionDBName | Should -BeNullOrEmpty
                }
            }

            It 'Get method returns RemoteDistributor as $null' {
                InModuleScope -ScriptBlock {
                    $result.RemoteDistributor | Should -BeNullOrEmpty
                }
            }

            It 'Get method returns WorkingDirectory as $null' {
                InModuleScope -ScriptBlock {
                    $result.WorkingDirectory | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'Test method' {
        It 'Test method returns false' {
            InModuleScope -ScriptBlock {
                Test-TargetResource @mockTestParameters | Should -BeFalse
            }
        }
    }

    Context 'Set method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-TargetResource @mockTestParameters
            }
        }

        It 'Set method calls Get-SqlInstanceMajorVersion with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Set method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Set method calls New-ServerConnection with $SqlServerName = ''REMOTESERVER''' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'REMOTESERVER' }
        }

        It 'Set method calls Register-DistributorPublisher with RemoteDistributor connection' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 1 `
                -ParameterFilter {
                    $PublisherName -eq 'SERVERNAME\INSTANCENAME' `
                    -and $ServerConnection.ServerInstance -eq 'REMOTESERVER'
                }
        }

        It 'Set method calls Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 1 `
                -ParameterFilter { $RemoteDistributor -eq 'REMOTESERVER' }
        }

        It 'Set method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Set method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }
    }

    Context 'When calling the Set method with the ''Remote'' distributor mode, but does not provide the parameter RemoteDistributor' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $mockTestParameters.Remove('RemoteDistributor')
            }
        }

        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = '{0} (Parameter ''RemoteDistributor'')' -f $script:localizedData.NoRemoteDistributor

                { Set-TargetResource @mockTestParameters } | Should -Throw -ExpectedMessage ('*' + $mockErrorMessage)
            }
        }
    }
}

Describe 'The system is in sync given Local distribution mode' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $mockPassword = ConvertTo-SecureString 'P@$$w0rd1' -AsPlainText -Force
            $mockCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('AdminLink', $mockPassword)

            $script:mockTestParameters = @{
                InstanceName = 'MSSQLSERVER'
                AdminLinkCredentials = $mockCredentials
                DistributorMode = 'Local'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Present'
            }
        }

        Mock -CommandName Get-SqlInstanceMajorVersion -MockWith { return '99' }
        Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME' }
        Mock -CommandName New-ServerConnection -MockWith {
            return [PSCustomObject] @{
                ServerInstance = $SqlServerName
            }
        }
        Mock -CommandName New-ReplicationServer -MockWith {
            return [PSCustomObject] @{
                IsDistributor = $true
                IsPublisher = $true
                DistributionDatabase = 'distribution'
                DistributionServer = 'SERVERNAME'
                WorkingDirectory = 'C:\temp'
            }
        }
        Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
        Mock -CommandName Install-LocalDistributor
        Mock -CommandName Install-RemoteDistributor
        Mock -CommandName Register-DistributorPublisher
        Mock -CommandName Uninstall-Distributor
        Mock -CommandName Import-SqlDscPreferredModule
    }

    Context 'Get method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:result = Get-TargetResource @mockTestParameters
            }
        }

        It 'Get method calls Get-SqlInstanceMajorVersion with InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Get method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
        }

        It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
        }

        It 'Get method does not call New-DistributionDatabase' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Get method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Get method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Ger method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }

        It 'Ger method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }

        It 'Get method returns Ensure = Present' {
            InModuleScope -ScriptBlock {
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Get method returns InstanceName = ''MSSQLSERVER''' {
            InModuleScope -ScriptBlock {
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
            }
        }

        It 'Get method returns DistributorMode = ''Local''' {
            InModuleScope -ScriptBlock {
                $result.DistributorMode | Should -Be $mockTestParameters.DistributorMode
            }
        }

        It 'Get method returns DistributionDBName = ''distribution''' {
            InModuleScope -ScriptBlock {
                $result.DistributionDBName | Should -Be 'distribution'
            }
        }

        It 'Get method returns RemoteDistributor = ''SERVERNAME''' {
            InModuleScope -ScriptBlock {
                $result.RemoteDistributor | Should -Be 'SERVERNAME'
            }
        }

        It 'Get method returns WorkingDirectory = ''C:\temp''' {
            InModuleScope -ScriptBlock {
                $result.WorkingDirectory | Should -Be 'C:\temp'
            }
        }
    }

    Context 'Test method' {
        It 'Test method returns true' {
            InModuleScope -ScriptBlock {
                Test-TargetResource @mockTestParameters | Should -BeTrue
            }
        }
    }

    Context 'Set method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-TargetResource @mockTestParameters
            }
        }

        It 'Set method calls Get-SqlInstanceMajorVersion with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Set method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
        }

        It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
        }

        It 'Set method does not call New-DistributionDatabase with $DistributionDBName = distribution' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Set method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Set method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Set method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }

        It 'Set method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }
    }
}

Describe 'The system is in sync given Remote distribution mode' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $mockPassword = ConvertTo-SecureString 'P@$$w0rd1' -AsPlainText -Force
            $mockCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('AdminLink', $mockPassword)

            $script:mockTestParameters = @{
                InstanceName = 'INSTANCENAME'
                AdminLinkCredentials = $mockCredentials
                DistributorMode = 'Remote'
                RemoteDistributor = 'REMOTESERVER'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Present'
            }
        }

        Mock -CommandName Get-SqlInstanceMajorVersion -MockWith { return '99' }
        Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME\INSTANCENAME' }
        Mock -CommandName New-ServerConnection -MockWith {
            return [PSCustomObject] @{
                ServerInstance = $SqlServerName
            }
        }
        Mock -CommandName New-ReplicationServer -MockWith {
            return [PSCustomObject] @{
                IsDistributor = $false
                IsPublisher = $true
                DistributionDatabase = 'distribution'
                DistributionServer = 'REMOTESERVER'
                WorkingDirectory = 'C:\temp'
            }
        }
        Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
        Mock -CommandName Install-LocalDistributor
        Mock -CommandName Install-RemoteDistributor
        Mock -CommandName Register-DistributorPublisher
        Mock -CommandName Uninstall-Distributor
        Mock -CommandName Import-SqlDscPreferredModule
    }

    Context 'Get method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:result = Get-TargetResource @mockTestParameters
            }
        }

        It 'Get method calls Get-SqlInstanceMajorVersion with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Get method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Get method does not call New-DistributionDatabase' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Get method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Get method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Ger method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }

        It 'Ger method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }

        It 'Get method returns Ensure = Present' {
            InModuleScope -ScriptBlock {
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Get method returns InstanceName = ''INSTANCENAME''' {
            InModuleScope -ScriptBlock {
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
            }
        }

        It 'Get method returns DistributorMode = ''Remote''' {
            InModuleScope -ScriptBlock {
                $result.DistributorMode | Should -Be $mockTestParameters.DistributorMode
            }
        }

        It 'Get method returns DistributionDBName = distribution' {
            InModuleScope -ScriptBlock {
                $result.DistributionDBName | Should -Be 'distribution'
            }
        }

        It 'Get method returns RemoteDistributor = ''REMOTESERVER''' {
            InModuleScope -ScriptBlock {
                $result.RemoteDistributor | Should -Be $mockTestParameters.RemoteDistributor
            }
        }

        It 'Get method returns WorkingDirectory = C:\temp' {
            InModuleScope -ScriptBlock {
                $result.WorkingDirectory | Should -Be 'C:\temp'
            }
        }
    }

    Context 'Test method' {
        It 'Test method returns true' {
            InModuleScope -ScriptBlock {
                Test-TargetResource @mockTestParameters | Should -BeTrue
            }
        }
    }

    Context 'Set method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-TargetResource @mockTestParameters
            }
        }

        It 'Set method calls Get-SqlInstanceMajorVersion with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Set method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Set method does not call New-DistributionDatabase' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Set method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Set method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Set method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }

        It 'Set method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }
    }
}

Describe 'The system is not in desired state given Local distribution, but should be Absent' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $mockPassword = ConvertTo-SecureString 'P@$$w0rd1' -AsPlainText -Force
            $mockCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('AdminLink', $mockPassword)

            $script:mockTestParameters = @{
                InstanceName = 'MSSQLSERVER'
                AdminLinkCredentials = $mockCredentials
                DistributorMode = 'Local'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Absent'
            }
        }

        Mock -CommandName Get-SqlInstanceMajorVersion -MockWith { return '99' }
        Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME' }
        Mock -CommandName New-ServerConnection -MockWith {
            return [PSCustomObject] @{
                ServerInstance = $SqlServerName
            }
        }
        Mock -CommandName New-ReplicationServer -MockWith {
            return [PSCustomObject] @{
                IsDistributor = $true
                IsPublisher = $true
                DistributionDatabase = 'distribution'
                DistributionServer = 'SERVERNAME'
                WorkingDirectory = 'C:\temp'
            }
        }
        Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
        Mock -CommandName Install-LocalDistributor
        Mock -CommandName Install-RemoteDistributor
        Mock -CommandName Register-DistributorPublisher
        Mock -CommandName Uninstall-Distributor
        Mock -CommandName Import-SqlDscPreferredModule
    }

    Context 'Get method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:result = Get-TargetResource @mockTestParameters
            }
        }
        It 'Get method calls Get-SqlInstanceMajorVersion with InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Get method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
        }

        It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
        }

        It 'Get method does not call New-DistributionDatabase' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Get method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Get method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Ger method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }

        It 'Ger method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }

        It 'Get method returns Ensure = Present' {
            InModuleScope -ScriptBlock {
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Get method returns InstanceName = ''MSSQLSERVER''' {
            InModuleScope -ScriptBlock {
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
            }
        }

        It 'Get method returns DistributorMode = ''Local''' {
            InModuleScope -ScriptBlock {
                $result.DistributorMode | Should -Be $mockTestParameters.DistributorMode
            }
        }

        It 'Get method returns DistributionDBName = distribution' {
            InModuleScope -ScriptBlock {
                $result.DistributionDBName | Should -Be 'distribution'
            }
        }

        It 'Get method returns RemoteDistributor is empty' {
            InModuleScope -ScriptBlock {
                $result.RemoteDistributor | Should -Be 'SERVERNAME'
            }
        }

        It 'Get method returns WorkingDirectory = C:\temp' {
            InModuleScope -ScriptBlock {
                $result.WorkingDirectory | Should -Be 'C:\temp'
            }
        }
    }

    Context 'Test method' {
        It 'Test method returns false' {
            InModuleScope -ScriptBlock {
                Test-TargetResource @mockTestParameters | Should -BeFalse
            }
        }
    }

    Context 'Set method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-TargetResource @mockTestParameters
            }
        }

        It 'Set method calls Get-SqlInstanceMajorVersion with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Set method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
        }

        It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
        }

        It 'Set method calls Uninstall-Distributor with $ReplicationServer.DistributionServer = SERVERNAME' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 1 `
                -ParameterFilter { $ReplicationServer.DistributionServer -eq 'SERVERNAME' }
        }

        It 'Set method does not call New-DistributionDatabase' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Set method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Set method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Set method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }
    }
}

Describe 'The system is not in desired state given Remote distribution, but should be Absent' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $mockPassword = ConvertTo-SecureString 'P@$$w0rd1' -AsPlainText -Force
            $mockCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('AdminLink', $mockPassword)

            $script:mockTestParameters = @{
                InstanceName = 'INSTANCENAME'
                AdminLinkCredentials = $mockCredentials
                DistributorMode = 'Remote'
                RemoteDistributor = 'REMOTESERVER'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Absent'
            }
        }

        Mock -CommandName Get-SqlInstanceMajorVersion -MockWith { return '99' }
        Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME\INSTANCENAME' }
        Mock -CommandName New-ServerConnection -MockWith {
            return [PSCustomObject] @{
                ServerInstance = $SqlServerName
            }
        }
        Mock -CommandName New-ReplicationServer -MockWith {
            return [PSCustomObject] @{
                IsDistributor = $false
                IsPublisher = $true
                DistributionDatabase = 'distribution'
                DistributionServer = 'REMOTESERVER'
                WorkingDirectory = 'C:\temp'
            }
        }
        Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
        Mock -CommandName Install-LocalDistributor
        Mock -CommandName Install-RemoteDistributor
        Mock -CommandName Register-DistributorPublisher
        Mock -CommandName Uninstall-Distributor
        Mock -CommandName Import-SqlDscPreferredModule
    }

    Context 'Get method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:result = Get-TargetResource @mockTestParameters
            }
        }

        It 'Get method calls Get-SqlInstanceMajorVersion with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Get method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Get method does not call New-DistributionDatabase' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Get method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Get method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Ger method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }

        It 'Ger method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }

        It 'Get method returns Ensure = Present' {
            InModuleScope -ScriptBlock {
                $result.Ensure | Should -Be 'Present'
            }
        }

        It 'Get method returns InstanceName = ''INSTANCENAME''' {
            InModuleScope -ScriptBlock {
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
            }
        }

        It 'Get method returns DistributorMode = ''Remote''' {
            InModuleScope -ScriptBlock {
                $result.DistributorMode | Should -Be $mockTestParameters.DistributorMode
            }
        }

        It 'Get method returns DistributionDBName = distribution' {
            InModuleScope -ScriptBlock {
                $result.DistributionDBName | Should -Be 'distribution'
            }
        }

        It 'Get method returns RemoteDistributor = ''REMOTESERVER''' {
            InModuleScope -ScriptBlock {
                $result.RemoteDistributor | Should -Be $mockTestParameters.RemoteDistributor
            }
        }

        It 'Get method returns WorkingDirectory = C:\temp' {
            InModuleScope -ScriptBlock {
                $result.WorkingDirectory | Should -Be 'C:\temp'
            }
        }
    }

    Context 'Test method' {
        It 'Test method returns false' {
            InModuleScope -ScriptBlock {
                Test-TargetResource @mockTestParameters | Should -BeFalse
            }
        }
    }

    Context 'Set method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-TargetResource @mockTestParameters
            }
        }

        It 'Set method calls Get-SqlInstanceMajorVersion with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Set method calls Get-SqlLocalServerName with $InstanceName = INSTANCENAME' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'INSTANCENAME' }
        }

        It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME\INSTANCENAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME\INSTANCENAME' }
        }

        It 'Set method calls Uninstall-Distributor with $ReplicationServer.DistributionServer = REMOTESERVER' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 1 `
                -ParameterFilter { $ReplicationServer.DistributionServer -eq 'REMOTESERVER' }
        }

        It 'Set method does not call New-DistributionDatabase' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Set method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Set method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Set method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }
    }
}

Describe 'The system is in sync when Absent' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            $mockPassword = ConvertTo-SecureString 'P@$$w0rd1' -AsPlainText -Force
            $mockCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @('AdminLink', $mockPassword)

            $script:mockTestParameters = @{
                InstanceName = 'MSSQLSERVER'
                AdminLinkCredentials = $mockCredentials
                DistributorMode = 'Local'
                WorkingDirectory = 'C:\temp'
                Ensure = 'Absent'
            }
        }

        Mock -CommandName Get-SqlInstanceMajorVersion -MockWith { return '99' }
        Mock -CommandName Get-SqlLocalServerName -MockWith { return 'SERVERNAME' }
        Mock -CommandName New-ServerConnection -MockWith {
            return [PSCustomObject] @{
                ServerInstance = $SqlServerName
            }
        }
        Mock -CommandName New-ReplicationServer -MockWith {
            return [PSCustomObject] @{
                IsDistributor = $false
                IsPublisher = $false
                DistributionDatabase = ''
                DistributionServer = ''
                WorkingDirectory = ''
            }
        }
        Mock -CommandName New-DistributionDatabase -MockWith { return [PSCustomObject] @{} }
        Mock -CommandName Install-LocalDistributor
        Mock -CommandName Install-RemoteDistributor
        Mock -CommandName Register-DistributorPublisher
        Mock -CommandName Uninstall-Distributor
        Mock -CommandName Import-SqlDscPreferredModule
    }

    Context 'Get method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:result = Get-TargetResource @mockTestParameters
            }
        }

        It 'Get method calls Get-SqlInstanceMajorVersion with InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Get method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Get method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
        }

        It 'Get method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
        }

        It 'Get method does not call New-DistributionDatabase' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Get method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Get method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Ger method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }

        It 'Ger method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }

        It 'Get method returns Ensure = Absent' {
            InModuleScope -ScriptBlock {
                $result.Ensure | Should -Be 'Absent'
            }
        }

        It 'Get method returns InstanceName = ''MSSQLSERVER''' {
            InModuleScope -ScriptBlock {
                $result.InstanceName | Should -Be $mockTestParameters.InstanceName
            }
        }

        It 'Get method returns DistributorMode as $null' {
            InModuleScope -ScriptBlock {
                $result.DistributorMode | Should -BeNullOrEmpty
            }
        }

        It 'Get method returns DistributionDBName as $null' {
            InModuleScope -ScriptBlock {
                $result.DistributionDBName | Should -BeNullOrEmpty
            }
        }

        It 'Get method returns RemoteDistributor as $null' {
            InModuleScope -ScriptBlock {
                $result.RemoteDistributor | Should -BeNullOrEmpty
            }
        }

        It 'Get method returns WorkingDirectory as $null' {
            InModuleScope -ScriptBlock {
                $result.WorkingDirectory | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Test method' {
        It 'Test method returns true' {
            InModuleScope -ScriptBlock {
                Test-TargetResource @mockTestParameters | Should -BeTrue
            }
        }
    }

    Context 'Set method' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Set-TargetResource @mockTestParameters
            }
        }

        It 'Set method calls Get-SqlInstanceMajorVersion with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlInstanceMajorVersion -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Set method calls Get-SqlLocalServerName with $InstanceName = MSSQLSERVER' {
            Should -Invoke -CommandName Get-SqlLocalServerName -Times 1 `
                -ParameterFilter { $InstanceName -eq 'MSSQLSERVER' }
        }

        It 'Set method calls New-ServerConnection with $SqlServerName = SERVERNAME' {
            Should -Invoke -CommandName New-ServerConnection -Times 1 `
                -ParameterFilter { $SqlServerName -eq 'SERVERNAME' }
        }

        It 'Set method calls New-ReplicationServer with $ServerConnection.ServerInstance = SERVERNAME' {
            Should -Invoke -CommandName New-ReplicationServer -Times 1 `
                -ParameterFilter { $ServerConnection.ServerInstance -eq 'SERVERNAME' }
        }

        It 'Set method does not call New-DistributionDatabase with $DistributionDBName = distribution' {
            Should -Invoke -CommandName New-DistributionDatabase -Times 0
        }

        It 'Set method does not call Install-LocalDistributor' {
            Should -Invoke -CommandName Install-LocalDistributor -Times 0
        }

        It 'Set method does not call Install-RemoteDistributor' {
            Should -Invoke -CommandName Install-RemoteDistributor -Times 0
        }

        It 'Set method does not call Register-DistributorPublisher' {
            Should -Invoke -CommandName Register-DistributorPublisher -Times 0
        }

        It 'Set method does not call Uninstall-Distributor' {
            Should -Invoke -CommandName Uninstall-Distributor -Times 0
        }
    }
}

Describe 'New-ServerConnection' {
    Context 'When SQL major version is 16 (SQL Server 2022)' {
        BeforeAll {
            Mock -CommandName New-Object -ParameterFilter {
                $TypeName -eq 'Microsoft.SqlServer.Management.Common.ServerConnection'
            } -MockWith {
                return 'Mocked server connection object for {0}' -f $ArgumentList
            }
        }

        It 'Should return the server connection without throwing' {
            InModuleScope -ScriptBlock {
                $result = New-ServerConnection -SqlMajorVersion 16 -SqlServerName 'localhost\SqlInstance'

                $result | Should -Be 'Mocked server connection object for localhost\SqlInstance'
            }
        }
    }

    Context 'When SQL major version is 15 or less (SQL Server 2019 or older)' {
        BeforeAll {
            Mock -CommandName Get-ConnectionInfoAssembly -MockWith {
                return New-Object -TypeName System.Object |
                    Add-Member -Name 'GetType' -MemberType 'ScriptMethod' -Value {
                        param
                        (
                            [Parameter()]
                            $TypeName,

                            [Parameter()]
                            $ArgumentList
                        )

                        # Return type String instead of Microsoft.SqlServer.Management.Common.ServerConnection
                        return 'System.String'
                    } -PassThru -Force
            }
        }

        It 'Should return the server connection without throwing' {
            InModuleScope -ScriptBlock {
                $result = New-ServerConnection -SqlMajorVersion 15 -SqlServerName 'localhost\SqlInstance'

                <#
                    The mock of GetType() returns the type [System.String]. In the
                    New-Object call the string will be filled with the value passed
                    as ArgumentList.
                #>
                $result | Should -Be 'localhost\SqlInstance'
            }
        }
    }
}
