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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Get-SqlDscRSPackage' -Tag 'Public' {
    Context 'When using the Package parameter set' {
        Context 'When the installed package is found' {
            BeforeAll {
                # Use TestDrive for cross-platform compatibility
                $script:mockInstallFolder = $TestDrive

                Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                    return @{
                        InstanceName  = 'SSRS'
                        InstallFolder = $script:mockInstallFolder
                    }
                }

                Mock -CommandName Get-FileVersion -MockWith {
                    return [PSCustomObject]@{
                        ProductName    = 'Microsoft SQL Server Reporting Services'
                        ProductVersion = '15.0.8963.8162'
                        FileVersion    = '2019.150.8963.8162'
                        FileName       = 'ReportingServicesService.exe'
                    }
                }
            }

            It 'Should return the version information for SSRS' {
                $result = Get-SqlDscRSPackage -Package 'SSRS'

                $result | Should -Not -BeNullOrEmpty
                $result.ProductName | Should -Be 'Microsoft SQL Server Reporting Services'
                $result.ProductVersion | Should -Be '15.0.8963.8162'

                Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -ParameterFilter {
                    $InstanceName -eq 'SSRS'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-FileVersion -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the installed package is found for PBIRS' {
            BeforeAll {
                # Use TestDrive for cross-platform compatibility
                $script:mockInstallFolder = $TestDrive

                Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                    return @{
                        InstanceName  = 'PBIRS'
                        InstallFolder = $script:mockInstallFolder
                    }
                }

                Mock -CommandName Get-FileVersion -MockWith {
                    return [PSCustomObject]@{
                        ProductName    = 'Microsoft Power BI Report Server'
                        ProductVersion = '15.0.1111.1234'
                        FileVersion    = '2019.150.1111.1234'
                        FileName       = 'ReportingServicesService.exe'
                    }
                }
            }

            It 'Should return the version information for PBIRS' {
                $result = Get-SqlDscRSPackage -Package 'PBIRS'

                $result | Should -Not -BeNullOrEmpty
                $result.ProductName | Should -Be 'Microsoft Power BI Report Server'
                $result.ProductVersion | Should -Be '15.0.1111.1234'

                Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -ParameterFilter {
                    $InstanceName -eq 'PBIRS'
                } -Exactly -Times 1 -Scope It

                Should -Invoke -CommandName Get-FileVersion -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the installed package is not found' {
            BeforeAll {
                Mock -CommandName Get-SqlDscRSSetupConfiguration
            }

            It 'Should throw an error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Get_SqlDscRSPackage_PackageNotFound -f 'SSRS'
                }

                { Get-SqlDscRSPackage -Package 'SSRS' } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When using the FilePath parameter set' {
        Context 'When the file is a valid SSRS executable' {
            BeforeAll {
                # Create a mock file in TestDrive
                $script:mockFilePath = Join-Path -Path $TestDrive -ChildPath 'SQLServerReportingServices.exe'
                $null = New-Item -Path $script:mockFilePath -ItemType File -Force

                Mock -CommandName Get-FileVersion -MockWith {
                    return [PSCustomObject]@{
                        ProductName    = 'Microsoft SQL Server Reporting Services'
                        ProductVersion = '15.0.8963.8162'
                        FileVersion    = '2019.150.8963.8162'
                        FileName       = $script:mockFilePath
                    }
                }
            }

            It 'Should return the version information' {
                $result = Get-SqlDscRSPackage -FilePath $script:mockFilePath

                $result | Should -Not -BeNullOrEmpty
                $result.ProductName | Should -Be 'Microsoft SQL Server Reporting Services'
                $result.ProductVersion | Should -Be '15.0.8963.8162'

                Should -Invoke -CommandName Get-FileVersion -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the file is a valid PBIRS executable' {
            BeforeAll {
                # Create a mock file in TestDrive
                $script:mockFilePath = Join-Path -Path $TestDrive -ChildPath 'PBIReportServer.exe'
                $null = New-Item -Path $script:mockFilePath -ItemType File -Force

                Mock -CommandName Get-FileVersion -MockWith {
                    return [PSCustomObject]@{
                        ProductName    = 'Microsoft Power BI Report Server'
                        ProductVersion = '15.0.1111.1234'
                        FileVersion    = '2019.150.1111.1234'
                        FileName       = $script:mockFilePath
                    }
                }
            }

            It 'Should return the version information' {
                $result = Get-SqlDscRSPackage -FilePath $script:mockFilePath

                $result | Should -Not -BeNullOrEmpty
                $result.ProductName | Should -Be 'Microsoft Power BI Report Server'
                $result.ProductVersion | Should -Be '15.0.1111.1234'

                Should -Invoke -CommandName Get-FileVersion -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the file has an invalid product name' {
            BeforeAll {
                # Create a mock file in TestDrive
                $script:mockFilePath = Join-Path -Path $TestDrive -ChildPath 'SomeProduct.exe'
                $null = New-Item -Path $script:mockFilePath -ItemType File -Force

                Mock -CommandName Get-FileVersion -MockWith {
                    return [PSCustomObject]@{
                        ProductName    = 'Some Other Product'
                        ProductVersion = '1.0.0.0'
                        FileVersion    = '1.0.0.0'
                        FileName       = $script:mockFilePath
                    }
                }
            }

            It 'Should throw an error' {
                $mockErrorMessage = InModuleScope -ScriptBlock {
                    $validProductNames = @(
                        'Microsoft SQL Server Reporting Services'
                        'Microsoft Power BI Report Server'
                    )

                    $script:localizedData.Get_SqlDscRSPackage_InvalidProductName -f 'Some Other Product', ($validProductNames -join "', '")
                }

                { Get-SqlDscRSPackage -FilePath $script:mockFilePath } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }

        Context 'When the file has an invalid product name but Force is specified' {
            BeforeAll {
                # Create a mock file in TestDrive
                $script:mockFilePath = Join-Path -Path $TestDrive -ChildPath 'SomeProduct2.exe'
                $null = New-Item -Path $script:mockFilePath -ItemType File -Force

                Mock -CommandName Get-FileVersion -MockWith {
                    return [PSCustomObject]@{
                        ProductName    = 'Some Other Product'
                        ProductVersion = '1.0.0.0'
                        FileVersion    = '1.0.0.0'
                        FileName       = $script:mockFilePath
                    }
                }
            }

            It 'Should return the version information without throwing' {
                $result = Get-SqlDscRSPackage -FilePath $script:mockFilePath -Force

                $result | Should -Not -BeNullOrEmpty
                $result.ProductName | Should -Be 'Some Other Product'
                $result.ProductVersion | Should -Be '1.0.0.0'

                Should -Invoke -CommandName Get-FileVersion -Exactly -Times 1 -Scope It
            }
        }
    }

    Context 'Parameter validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Package'
                ExpectedParameters = '-Package <string> [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'FilePath'
                ExpectedParameters = '-FilePath <string> [-Force] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSPackage').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have Package as a mandatory parameter in Package parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSPackage').Parameters['Package']
            $packageParameterSet = $parameterInfo.ParameterSets['Package']
            $packageParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have FilePath as a mandatory parameter in FilePath parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSPackage').Parameters['FilePath']
            $filePathParameterSet = $parameterInfo.ParameterSets['FilePath']
            $filePathParameterSet.IsMandatory | Should -BeTrue
        }

        It 'Should have Force as a non-mandatory parameter in FilePath parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSPackage').Parameters['Force']
            $forceParameterSet = $parameterInfo.ParameterSets['FilePath']
            $forceParameterSet.IsMandatory | Should -BeFalse
        }

        It 'Should have Package parameter with validate set SSRS and PBIRS' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSPackage').Parameters['Package']
            $validateSetAttribute = $parameterInfo.Attributes | Where-Object -FilterScript { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSetAttribute.ValidValues | Should -Contain 'SSRS'
            $validateSetAttribute.ValidValues | Should -Contain 'PBIRS'
        }

        It 'Should have Package as the default parameter set' {
            $commandInfo = Get-Command -Name 'Get-SqlDscRSPackage'
            $commandInfo.DefaultParameterSet | Should -Be 'Package'
        }
    }
}
