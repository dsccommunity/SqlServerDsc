<#
    .SYNOPSIS
        Unit test for helper functions in module SqlServerDsc.Common.

    .NOTES
        SMO stubs
        ---------
        These are loaded at the start so that it is known that they are left in the
        session after test finishes, and will spill over to other tests. There does
        not exist a way to unload assemblies. It is possible to load these in a
        InModuleScope but the classes are still present in the parent scope when
        Pester has ran.

        SqlServer/SQLPS stubs
        ---------------------
        These are imported using Import-SqlModuleStub in a BeforeAll-block in only
        a test that requires them, and must be removed in an AfterAll-block using
        Remove-SqlModuleStub so the stub cmdlets does not spill over to another
        test.
#>

# Suppressing this rule because ConvertTo-SecureString is used to simplify the tests.
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
# Suppressing this rule because Script Analyzer does not understand Pester's syntax.
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
                & "$PSScriptRoot/../../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
    $script:subModuleName = 'SqlServerDsc.Common'

    $script:parentModule = Get-Module -Name $script:moduleName -ListAvailable | Select-Object -First 1
    $script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'

    $script:subModulePath = Join-Path -Path $script:subModulesFolder -ChildPath $script:subModuleName

    Import-Module -Name $script:subModulePath -ErrorAction 'Stop'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\TestHelpers\CommonTestHelper.psm1')

    # Loading SMO stubs.
    if (-not ('Microsoft.SqlServer.Management.Smo.Server' -as [Type]))
    {
        Add-Type -Path (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Stubs') -ChildPath 'SMO.cs')
    }

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:subModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:subModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:subModuleName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'SqlServerDsc.Common\Invoke-SqlScript' -Tag 'InvokeSqlScript' {
    BeforeAll {
        $invokeScriptFileParameters = @{
            ServerInstance = Get-ComputerName
            InputFile      = 'set.sql'
        }

        $invokeScriptQueryParameters = @{
            ServerInstance = Get-ComputerName
            Query          = 'Test Query'
        }
    }

    Context 'Invoke-SqlScript fails to import SQLPS module' {
        BeforeAll {
            $throwMessage = 'Failed to import SQLPS module.'

            Mock -CommandName Import-SqlDscPreferredModule -MockWith {
                throw $throwMessage
            }
        }

        It 'Should throw the correct error from Import-Module' {
            { Invoke-SqlScript @invokeScriptFileParameters } | Should -Throw -ExpectedMessage $throwMessage
        }
    }

    Context 'Invoke-SqlScript is called with credentials' {
        BeforeAll {
            # Import PowerShell module SqlServer stub cmdlets.
            Import-SQLModuleStub

            $mockPasswordPlain = 'password'
            $mockUsername = 'User'

            $password = ConvertTo-SecureString -String $mockPasswordPlain -AsPlainText -Force
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $mockUsername, $password

            Mock -CommandName Import-SqlDscPreferredModule
            Mock -CommandName Invoke-SqlCmd -ParameterFilter {
                $Username -eq $mockUsername -and $Password -eq $mockPasswordPlain
            }
        }

        AfterAll {
            # Remove PowerShell module SqlServer stub cmdlets.
            Remove-SqlModuleStub
        }

        It 'Should call Invoke-SqlCmd with correct File ParameterSet parameters' {
            $invokeScriptFileParameters.Add('Credential', $credential)
            $null = Invoke-SqlScript @invokeScriptFileParameters

            Should -Invoke -CommandName Invoke-SqlCmd -ParameterFilter {
                $Username -eq $mockUsername -and $Password -eq $mockPasswordPlain
            } -Times 1 -Exactly -Scope It
        }

        It 'Should call Invoke-SqlCmd with correct Query ParameterSet parameters' {
            $invokeScriptQueryParameters.Add('Credential', $credential)
            $null = Invoke-SqlScript @invokeScriptQueryParameters

            Should -Invoke -CommandName Invoke-SqlCmd -ParameterFilter {
                $Username -eq $mockUsername -and $Password -eq $mockPasswordPlain
            } -Times 1 -Exactly -Scope It
        }
    }

    Context 'Invoke-SqlScript fails to execute the SQL scripts' {
        BeforeAll {
            # Import PowerShell module SqlServer stub cmdlets.
            Import-SqlModuleStub
        }

        AfterAll {
            # Remove PowerShell module SqlServer stub cmdlets.
            Remove-SqlModuleStub
        }

        BeforeEach {
            $errorMessage = 'Failed to run SQL Script'

            Mock -CommandName Import-SqlDscPreferredModule
            Mock -CommandName Invoke-SqlCmd -MockWith {
                throw $errorMessage
            }
        }

        It 'Should throw the correct error from File ParameterSet Invoke-SqlCmd' {
            { Invoke-SqlScript @invokeScriptFileParameters } | Should -Throw -ExpectedMessage $errorMessage
        }

        It 'Should throw the correct error from Query ParameterSet Invoke-SqlCmd' {
            { Invoke-SqlScript @invokeScriptQueryParameters } | Should -Throw -ExpectedMessage $errorMessage
        }
    }

    Context 'Invoke-SqlScript is called with parameter Encrypt' {
        BeforeAll {
            # Import PowerShell module SqlServer stub cmdlets.
            Import-SQLModuleStub

            Mock -CommandName Import-SqlDscPreferredModule
            Mock -CommandName Invoke-SqlCmd
        }

        AfterAll {
            # Remove PowerShell module SqlServer stub cmdlets.
            Remove-SqlModuleStub
        }

        Context 'When using SqlServer module v22.x' {
            BeforeAll {
                Mock -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Invoke-SqlCmd'
                } -MockWith {
                    return @{
                        Parameters = @{
                            Keys = @('Encrypt')
                        }
                    }
                }
            }

            It 'Should call Invoke-SqlCmd with correct File ParameterSet parameters' {
                $mockInvokeScriptFileParameters = @{
                    ServerInstance = Get-ComputerName
                    InputFile      = 'set.sql'
                    Encrypt        = 'Optional'
                }

                $null = Invoke-SqlScript @mockInvokeScriptFileParameters

                Should -Invoke -CommandName Invoke-SqlCmd -ParameterFilter {
                    $Encrypt -eq 'Optional'
                } -Times 1 -Exactly -Scope It
            }

            It 'Should call Invoke-SqlCmd with correct Query ParameterSet parameters' {
                $mockInvokeScriptQueryParameters = @{
                    ServerInstance = Get-ComputerName
                    Query          = 'Test Query'
                    Encrypt        = 'Optional'
                }

                $null = Invoke-SqlScript @mockInvokeScriptQueryParameters

                Should -Invoke -CommandName Invoke-SqlCmd -ParameterFilter {
                    $Encrypt -eq 'Optional'
                } -Times 1 -Exactly -Scope It
            }
        }

        Context 'When using SqlServer module v21.x' {
            BeforeAll {
                Mock -CommandName Get-Command -ParameterFilter {
                    $Name -eq 'Invoke-SqlCmd'
                } -MockWith {
                    return @{
                        Parameters = @{
                            Keys = @()
                        }
                    }
                }
            }

            It 'Should call Invoke-SqlCmd with correct File ParameterSet parameters' {
                $mockInvokeScriptFileParameters = @{
                    ServerInstance = Get-ComputerName
                    InputFile      = 'set.sql'
                    Encrypt        = 'Optional'
                }

                $null = Invoke-SqlScript @mockInvokeScriptFileParameters

                Should -Invoke -CommandName Invoke-SqlCmd -ParameterFilter {
                    $PesterBoundParameters.Keys -notcontains 'Encrypt'
                } -Times 1 -Exactly -Scope It
            }

            It 'Should call Invoke-SqlCmd with correct Query ParameterSet parameters' {
                $mockInvokeScriptQueryParameters = @{
                    ServerInstance = Get-ComputerName
                    Query          = 'Test Query'
                    Encrypt        = 'Optional'
                }

                $null = Invoke-SqlScript @mockInvokeScriptQueryParameters

                Should -Invoke -CommandName Invoke-SqlCmd -ParameterFilter {
                    $PesterBoundParameters.Keys -notcontains 'Encrypt'
                } -Times 1 -Exactly -Scope It
            }
        }
    }
}
