[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
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

    $env:SqlServerDscCI = $true

    Import-Module -Name $script:dscModuleName

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

Describe 'Import-SqlDscPreferredModule' -Tag 'Public' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName = '__AllParameterSets'
            # cSpell: disable-next
            MockExpectedParameters = '[[-PreferredModule] <string>] [-Force] [<CommonParameters>]'
        }
    ) {
        $result = (Get-Command -Name 'Import-SqlDscPreferredModule').ParameterSets |
            Where-Object -FilterScript {
                $_.Name -eq $mockParameterSetName
            } |
            Select-Object -Property @(
                @{
                    Name = 'ParameterSetName'
                    Expression = { $_.Name }
                },
                @{
                    Name = 'ParameterListAsString'
                    Expression = { $_.ToString() }
                }
            )

        $result.ParameterSetName | Should -Be $MockParameterSetName
        $result.ParameterListAsString | Should -Be $MockExpectedParameters
    }

    BeforeAll {
        <#
            This is the path to the latest version of SQLPS, to test that only the
            newest SQLPS module is returned.
        #>
        $sqlPsLatestModulePath = 'C:\Program Files (x86)\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'

        <#
            For SQLPS module this should be the root of the module.
            The .psd1 file is parsed from the module full path in the code.
        #>
        $sqlPsExpectedModulePath = Split-Path -Path $sqlPsLatestModulePath -Parent


        $mockImportModule = {
            # Convert the single value array [String[]] to the expected string value [String].
            $moduleNameToImport = $Name[0]

            if ($moduleNameToImport -ne $mockExpectedModuleNameToImport)
            {
                throw ('Wrong module was loaded. Expected {0}, but was {1}.' -f $mockExpectedModuleNameToImport, $moduleNameToImport)
            }

            switch ($moduleNameToImport)
            {
                'SqlServer'
                {
                    $importModuleResult = @{
                        ModuleType = 'Script'
                        Version = '21.0.17279'
                        Name = $moduleNameToImport
                        Path = 'C:\Program Files\WindowsPowerShell\Modules\SqlServer\21.0.17279\SqlServer.psm1'
                    }
                }

                $sqlPsExpectedModulePath
                {
                    # Can not use $Name because that contain the path to the module manifest.
                    $importModuleResult = @(
                        @{
                            ModuleType = 'Script'
                            Version = '0.0'
                            # Intentionally formatted to correctly mimic a real run.
                            Name = 'Sqlps'
                            Path = $sqlPsLatestModulePath
                        }
                        @{
                            ModuleType = 'Manifest'
                            Version = '1.0'
                            # Intentionally formatted to correctly mimic a real run.
                            Name = 'sqlps'
                            Path = $sqlPsLatestModulePath
                        }
                    )
                }
            }

            return $importModuleResult
        }

        $mockGetModuleSqlServer = {
            # Return an array to test so that the latest version is only imported.
            return @(
                [PSCustomObject] @{
                    Name = 'SqlServer'
                    Version = [Version] '1.0'
                }

                [PSCustomObject] @{
                    Name = 'SqlServer'
                    Version = [Version] '2.0'
                }
            )
        }

        Mock -CommandName Set-PSModulePath
        Mock -CommandName Push-Location
        Mock -CommandName Pop-Location
    }

    Context 'When module SqlServer is already loaded into the session' {
        BeforeAll {
            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Get-Module -MockWith {
                return @{
                    Name = 'SqlServer'
                }
            }
        }

        It 'Should use the already loaded module and not call Import-Module' {
            { Import-SqlDscPreferredModule } | Should -Not -Throw

            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }

    Context 'When module SQLPS is already loaded into the session' {
        BeforeAll {
            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Get-Module -MockWith {
                return @{
                    Name = 'SQLPS'
                }
            }
        }

        It 'Should use the already loaded module and not call Import-Module' {
            { Import-SqlDscPreferredModule } | Should -Not -Throw

            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }

    Context 'When module SqlServer exists, but not loaded into the session' {
        BeforeAll {
            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Get-Module -ParameterFilter {
                $PesterBoundParameters.ContainsKey('Name')
            }

            Mock -CommandName Get-Module -MockWith $mockGetModuleSqlServer -ParameterFilter {
                $FullyQualifiedName.Name -eq 'SqlServer' -and $ListAvailable -eq $true
            }

            $mockExpectedModuleNameToImport = 'SqlServer'
        }

        It 'Should import the SqlServer module without throwing' {
            { Import-SqlDscPreferredModule } | Should -Not -Throw

            Should -Invoke -CommandName Get-Module -ParameterFilter {
                $FullyQualifiedName.Name -eq 'SqlServer' -and $ListAvailable -eq $true
            } -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Push-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Pop-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It
        }
    }

    Context 'When only module SQLPS exists, but not loaded into the session, and using -Force' {
        BeforeAll {
            Mock -CommandName Import-Module -MockWith $mockImportModule
            Mock -CommandName Remove-Module
            Mock -CommandName Get-Module -ParameterFilter {
                $PesterBoundParameters.ContainsKey('Name')
            }

            $mockExpectedModuleNameToImport = $sqlPsExpectedModulePath

            Mock -CommandName Get-Module -MockWith {
                # Return an array to test so that the latest version is only imported.
                return @(
                    [PSCustomObject] @{
                        Name = 'SQLPS'
                        # This is a path to an older version of SQL PS than $sqlPsLatestModulePath.
                        Path = 'C:\Program Files (x86)\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS\Sqlps.ps1'
                    }

                    [PSCustomObject] @{
                        Name = 'SQLPS'
                        Path = $sqlPsLatestModulePath
                    }
                )
            } -ParameterFilter {
                $FullyQualifiedName.Name -eq 'SQLPS' -and $ListAvailable -eq $true
            }

            Mock -CommandName Get-Module -MockWith {
                return $null
            } -ParameterFilter {
                $FullyQualifiedName.Name -eq 'SqlServer' -and $ListAvailable -eq $true
            }
        }

        It 'Should import the SqlServer module without throwing' {
            { Import-SqlDscPreferredModule -Force } | Should -Not -Throw

            Should -Invoke -CommandName Get-Module -ParameterFilter {
                $FullyQualifiedName.Name -eq 'SqlServer' -and $ListAvailable -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-Module -ParameterFilter {
                $FullyQualifiedName.Name -eq 'SQLPS' -and $ListAvailable -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Push-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Pop-Location -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Remove-Module -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope It
        }
    }

    Context 'When neither SqlServer or SQLPS exists' {
        BeforeAll {
            Mock -CommandName Import-Module

            $mockExpectedModuleNameToImport = $sqlPsExpectedModulePath

            Mock -CommandName Get-Module
        }

        It 'Should throw the correct error message' {
            $mockLocalizedString = InModuleScope -ScriptBlock {
                $script:localizedData.PowerShellSqlModuleNotFound -f 'SqlServer'
            }

            { Import-SqlDscPreferredModule } | Should -Throw -ExpectedMessage $mockLocalizedString

            Should -Invoke -CommandName Get-Module -ParameterFilter {
                $FullyQualifiedName.Name -eq 'SqlServer' -and $ListAvailable -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Get-Module -ParameterFilter {
                $FullyQualifiedName.Name -eq 'SQLPS' -and $ListAvailable -eq $true
            } -Exactly -Times 1 -Scope It

            Should -Invoke -CommandName Push-Location -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Pop-Location -Exactly -Times 0 -Scope It
            Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope It
        }
    }
}
