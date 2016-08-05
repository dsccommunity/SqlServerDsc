$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'xSQLServerEndPointState'

#region HEADER

# Unit Test Template Version: 1.1.0
[String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 

#endregion HEADER

# Begin Testing
try
{
    #region Pester Test Initialization
    $defaultParameters = @{
        InstanceName = 'DEFAULT'
        NodeName = 'localhost'
        Name = 'DefaultMirrorEndpoint'
        
    }
    #endregion Pester Test Initialization

    Describe "$($script:DSCResourceName)\Get-TargetResource" {
        $testParameters = $defaultParameters

        Context 'When the system is not in the desired state' {
            BeforeAll {
                # This has intentially been left blank 
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Stopped' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            $result = Get-TargetResource @testParameters

            It 'Should not return the same value as expected state Started' {
                $result.State | Should Not Be 'Started'
                $result.State | Should Be 'Stopped'
            }

            It 'Should return the same values as passed as parameters when expected state is Started' {
                $result.NodeName | Should Be $testParameters.NodeName
                $result.InstanceName | Should Be $testParameters.InstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when expected state is Started' {
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context
            }
            
            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Started' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable
    
            $result = Get-TargetResource @testParameters

            It 'Should not return the same value as expected state Stopped' {
                $result.State | Should Not Be 'Stopped'
                $result.State | Should Be 'Started'
            }

            It 'Should return the same values as passed as parameters when expected state is Stopped' {
                $result.NodeName | Should Be $testParameters.NodeName
                $result.InstanceName | Should Be $testParameters.InstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when expected state is Stopped' {
                Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }
    
        Context 'When the system is in the desired state' {
            BeforeAll {
                # This has intentially been left blank
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Started' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            $result = Get-TargetResource @testParameters

            It 'Should return the same value as expected state Started' {
                $result.State | Should Not Be 'Stopped'
                $result.State | Should Be 'Started'
            }

            It 'Should return the same values as passed as parameters when expected state is Started' {
                $result.NodeName | Should Be $testParameters.NodeName
                $result.InstanceName | Should Be $testParameters.InstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Get-SQLPSInstance when expected state is Started' {
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context 
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Stopped' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            $result = Get-TargetResource @testParameters

            It 'Should return the same value as expected state Stopped' {
                $result.State | Should Not Be 'Started'
                $result.State | Should Be 'Stopped'
            }

            It 'Should return the same values as passed as parameters when expected state is Stopped' {
                $result.NodeName | Should Be $testParameters.NodeName
                $result.InstanceName | Should Be $testParameters.InstanceName
                $result.Name | Should Be $testParameters.Name
            }

            It 'Should call the mock function Get-SQLPSInstance when expected state is Stopped' {
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }

        Assert-VerifiableMocks
    }
    
    Describe "$($script:DSCResourceName)\Test-TargetResource" {
        Context 'When the system is not in the desired state' {
            BeforeAll {
                # This has intentially been left blank
            }
            
            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Stopped' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should return that desired state as absent when desired state is Started' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    State = 'Started' 
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when desired state of Started is absent' {
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context 
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Started' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should return that desired state as absent when desired state is Stopped' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    State = 'Stopped' 
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $false
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when desired state of Started is absent' {
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }

        Context 'When the system is in the desired state' {
            BeforeAll {
                # This has intentially been left blank
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Started' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should return that desired state as present when desired state is Started' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    State = 'Started' 
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when desired state of Started is present' {
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope Context 
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Stopped' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should return that desired state as present when desired state is Stopped' {
                $testParameters = $defaultParameters
                $testParameters += @{
                    State = 'Stopped' 
                }

                $result = Test-TargetResource @testParameters
                $result | Should Be $true
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when desired state of Stopped is present' {
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope Context 
            }
        }

        Assert-VerifiableMocks
    }

    Describe "$($script:DSCResourceName)\Set-TargetResource" {
        Get-Module -Name MockSQLPS | Remove-Module -Force
        New-Module -Name MockSQLPS -ScriptBlock {
            function Set-SqlHADREndpoint { return }
        
            Export-ModuleMember -Function Set-SqlHADREndpoint
        } | Import-Module -Force -Scope Global

        Mock Set-SqlHADREndpoint -MockWith {} -ModuleName $script:DSCResourceName -Verifiable

        Context 'When the system is not in the desired state' {
            BeforeAll {
                # This has intentially been left blank
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                State = 'Stopped' 
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Started' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should not throw an error when desired state is not equal to Stopped' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when desired state is not equal to Stopped' {
                 Set-TargetResource @testParameters
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should call the mock function Set-SqlHADREndpoint when desired state is not equal to Stopped' {
                 Set-TargetResource @testParameters
                 Assert-MockCalled Set-SqlHADREndpoint -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                State = 'Started' 
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Stopped' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should not throw an error when desired state is not equal to Started' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when desired state is not equal to Started' {
                 Set-TargetResource @testParameters
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 2 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should call the mock function Set-SqlHADREndpoint when desired state is not equal to Started' {
                 Set-TargetResource @testParameters
                 Assert-MockCalled Set-SqlHADREndpoint -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            } 
       }

        Context 'When the system is in the desired state' {
            BeforeAll {
                # This has intentially been left blank
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                State = 'Stopped' 
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Stopped' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should not throw an error when desired state is equal to Stopped' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when desired state is equal to Stopped' {
                 Set-TargetResource @testParameters
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should not call the mock function Set-SqlHADREndpoint when desired state is equal to Stopped' {
                 Set-TargetResource @testParameters
                 Assert-MockCalled Set-SqlHADREndpoint -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope It
            }

            $testParameters = $defaultParameters
            $testParameters += @{
                State = 'Started' 
            }

            Mock -CommandName Get-SQLAlwaysOnEndpoint -MockWith {
                # TypeName: Microsoft.SqlServer.Management.Smo.Endpoint
                return New-Object Object |            
                    Add-Member NoteProperty Name $testParameters.Name -PassThru | 
                    Add-Member NoteProperty EndpointState 'Started' -PassThru -Force # TypeName: Microsoft.SqlServer.Management.Smo.EndpointState
            } -ModuleName $script:DSCResourceName -Verifiable

            It 'Should not throw an error when desired state is equal to Started' {
                { Set-TargetResource @testParameters } | Should Not Throw
            }

            It 'Should call the mock function Get-SQLAlwaysOnEndpoint when desired state is equal to Started' {
                 Set-TargetResource @testParameters
                 Assert-MockCalled Get-SQLAlwaysOnEndpoint -Exactly -Times 1 -ModuleName $script:DSCResourceName -Scope It
            }

            It 'Should not call the mock function Set-SqlHADREndpoint when desired state is equal to Started' {
                 Set-TargetResource @testParameters
                 Assert-MockCalled Set-SqlHADREndpoint -Exactly -Times 0 -ModuleName $script:DSCResourceName -Scope It
            } 
        }

        Assert-VerifiableMocks
    }
}
finally
{
    #region FOOTER

    Restore-TestEnvironment -TestEnvironment $TestEnvironment 

    #endregion
}
