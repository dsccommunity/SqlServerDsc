<#
    .SYNOPSIS
        Unit test for DSC_SqlRSSetup DSC resource.
#>

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification='because ConvertTo-SecureString is used to simplify the tests.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification='Because we verify that restart will happen using a global variable.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification='Because Script Analyzer does not understand Pesters syntax.')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidThrowOutsideOfTry', '', Justification='Because the code throws based on an prior expression')]
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
    $script:dscResourceName = 'DSC_SqlRSSetup'

    $env:SqlServerDscCI = $true

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

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

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'DSC_SqlRSSetup\Get-TargetResource' -Tag 'Get' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName       = 'SSRS'
                IAcceptLicenseTerms = 'Yes'
                SourcePath         = '\\server\share\SQLServerReportingServices.exe'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockGetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When there are no installed Reporting Services' {
            BeforeAll {
                Mock -CommandName Get-RegistryPropertyValue
            }

            It 'Should return $null as the InstanceName' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters
                    $result.InstanceName | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IAcceptLicenseTerms | Should -Be $mockGetTargetResourceParameters.IAcceptLicenseTerms
                    $result.SourcePath | Should -Be $mockGetTargetResourceParameters.SourcePath
                }

                Should -Invoke -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
            }

            It 'Should return $null or $false for the rest of the properties' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Action | Should -BeNullOrEmpty
                    $getTargetResourceResult.SourceCredential | Should -BeNullOrEmpty
                    $getTargetResourceResult.ProductKey | Should -BeNullOrEmpty
                    $getTargetResourceResult.ForceRestart | Should -BeFalse
                    $getTargetResourceResult.EditionUpgrade | Should -BeFalse
                    $getTargetResourceResult.Edition | Should -BeNullOrEmpty
                    $getTargetResourceResult.LogPath | Should -BeNullOrEmpty
                    $getTargetResourceResult.InstallFolder | Should -BeNullOrEmpty
                    $getTargetResourceResult.ErrorDumpDirectory | Should -BeNullOrEmpty
                    $getTargetResourceResult.CurrentVersion | Should -BeNullOrEmpty
                    $getTargetResourceResult.ServiceName | Should -BeNullOrEmpty
                }

                Should -Invoke -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When there is an installed Reporting Services' {
            BeforeAll {
                $mockGetRegistryPropertyValue_InstanceName = {
                    <#
                        Currently only the one instance name of 'SSRS' is supported,
                        and the same name is currently used for instance id.
                    #>
                    return 'SSRS'
                }

                $mockGetRegistryPropertyValue_InstanceName_ParameterFilter = {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' `
                        -and $Name -eq 'SSRS'
                }

                $mockGetRegistryPropertyValue_InstallRootDirectory_ParameterFilter = {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' `
                        -and $Name -eq 'InstallRootDirectory'
                }

                $mockGetRegistryPropertyValue_ServiceName_ParameterFilter = {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' `
                        -and $Name -eq 'ServiceName'
                }

                $mockGetRegistryPropertyValue_ErrorDumpDir_ParameterFilter = {
                    $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' `
                        -and $Name -eq 'ErrorDumpDir'
                }

                Mock -CommandName Get-RegistryPropertyValue `
                    -MockWith $mockGetRegistryPropertyValue_InstanceName `
                    -ParameterFilter $mockGetRegistryPropertyValue_InstanceName_ParameterFilter

                Mock -CommandName Get-RegistryPropertyValue `
                    -MockWith {
                        return 'C:\Program Files\Microsoft SQL Server Reporting Services'
                    } -ParameterFilter $mockGetRegistryPropertyValue_InstallRootDirectory_ParameterFilter

                Mock -CommandName Get-RegistryPropertyValue `
                    -MockWith {
                        return 'SQLServerReportingServices'
                    } -ParameterFilter $mockGetRegistryPropertyValue_ServiceName_ParameterFilter

                Mock -CommandName Get-RegistryPropertyValue `
                    -MockWith {
                        return 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
                    } -ParameterFilter $mockGetRegistryPropertyValue_ErrorDumpDir_ParameterFilter

                InModuleScope -ScriptBlock {
                    # This is a workaround for the issue https://github.com/pester/Pester/issues/604.
                    function Get-Package
                    {
                        [CmdletBinding()]
                        param
                        (
                            [Parameter(Mandatory = $true)]
                            [System.String]
                            $Name,

                            [Parameter(Mandatory = $true)]
                            [System.String]
                            $ProviderName
                        )

                        throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
                    }

                    # Need to mock inside InModuleScope to mock the stub function above.
                    Mock -CommandName Get-Package -MockWith {
                        return @{
                            Version = '14.0.6514.11481'
                        }
                    }
                }
            }

            It 'Should return the correct InstanceName' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName
                }

                Should -Invoke -CommandName Get-RegistryPropertyValue `
                    -ParameterFilter $mockGetRegistryPropertyValue_InstanceName_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'
            }

            It 'Should return the same values as passed as parameters' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Get-TargetResource @mockGetTargetResourceParameters

                    $result.IAcceptLicenseTerms | Should -Be $mockGetTargetResourceParameters.IAcceptLicenseTerms
                    $result.SourcePath | Should -Be $mockGetTargetResourceParameters.SourcePath
                }
            }

            It 'Should return the correct values for the rest of the properties' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                    $getTargetResourceResult.Action | Should -BeNullOrEmpty
                    $getTargetResourceResult.SourceCredential | Should -BeNullOrEmpty
                    $getTargetResourceResult.ProductKey | Should -BeNullOrEmpty
                    $getTargetResourceResult.ForceRestart | Should -BeFalse
                    $getTargetResourceResult.EditionUpgrade | Should -BeFalse
                    $getTargetResourceResult.Edition | Should -BeNullOrEmpty
                    $getTargetResourceResult.LogPath | Should -BeNullOrEmpty
                    $getTargetResourceResult.InstallFolder | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services'
                    $getTargetResourceResult.ErrorDumpDirectory | Should -Be 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
                    $getTargetResourceResult.CurrentVersion | Should -Be '14.0.6514.11481'
                    $getTargetResourceResult.ServiceName | Should -Be 'SQLServerReportingServices'
                }

                Should -Invoke -CommandName Get-RegistryPropertyValue `
                    -ParameterFilter $mockGetRegistryPropertyValue_InstallRootDirectory_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'

                Should -Invoke -CommandName Get-RegistryPropertyValue `
                    -ParameterFilter $mockGetRegistryPropertyValue_ServiceName_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'

                Should -Invoke -CommandName Get-RegistryPropertyValue `
                    -ParameterFilter $mockGetRegistryPropertyValue_ErrorDumpDir_ParameterFilter `
                    -Exactly -Times 1 -Scope 'It'

                Should -Invoke -CommandName Get-Package -Exactly -Times 1 -Scope 'It'
            }

            Context 'When there is an installed Reporting Services, but no installed package is found to determine version' {
                BeforeEach {
                    Mock -CommandName Get-Package
                    Mock -CommandName Write-Warning
                }

                It 'Should return the correct values for the rest of the properties' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters

                        $getTargetResourceResult.CurrentVersion | Should -BeNullOrEmpty
                    }

                    Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Scope 'It'
                }
            }
        }
    }
}

Describe 'DSC_SqlRSSetup\Test-TargetResource' -Tag 'Test' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName       = 'SSRS'
                IAcceptLicenseTerms = 'Yes'
                SourcePath         = '\\server\share\SQLServerReportingServices.exe'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockTestTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }
    }

    Context 'When the system is in the desired state' {
        Context 'When there are no installed Reporting Services' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = $null
                    }
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockTestTargetResourceParameters['Action'] = 'Uninstall'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When there is an installed Reporting Services' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'SSRS'
                        CurrentVersion = '14.0.6514.11481'
                    }
                }

                Mock -CommandName Get-FileProductVersion -MockWith {
                    return [System.Version] '14.0.6514.11481'
                }
            }

            It 'Should return $true' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                Should -Invoke -CommandName Get-FileProductVersion -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the installed Reporting Services is an older version that the installation media, but parameter VersionUpgrade is not used' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'SSRS'
                        CurrentVersion = '14.0.6514.11481'
                    }
                }

                Mock -CommandName Get-FileProductVersion -MockWith {
                    return [System.Version] '15.1.1.0'
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    # This is called without the parameter 'VersionUpgrade'.
                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeTrue
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                Should -Invoke -CommandName Get-FileProductVersion -Exactly -Times 1 -Scope 'It'
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When there should be no installed Reporting Services' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'SSRS'
                    }
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockTestTargetResourceParameters['Action'] = 'Uninstall'

                    $result = Test-TargetResource @mockTestTargetResourceParameters

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When there are no installed Reporting Services' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = $null
                    }
                }

                Mock -CommandName Get-FileProductVersion -MockWith {
                    return [System.Version] '14.0.6514.11481'
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $result = Test-TargetResource @mockTestTargetResourceParameters -Verbose

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the wrong version of Reporting Services is installed, and parameter VersionUpgrade is used' {
            BeforeAll {
                Mock -CommandName Get-TargetResource -MockWith {
                    return @{
                        InstanceName = 'SSRS'
                        CurrentVersion = '14.0.6514.11481'
                    }
                }

                Mock -CommandName Get-FileProductVersion -MockWith {
                    return [System.Version] '15.1.1.0'
                }
            }

            It 'Should return $false' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockTestTargetResourceParameters['VersionUpgrade'] = $true

                    $result = Test-TargetResource @mockTestTargetResourceParameters -Verbose

                    $result | Should -BeFalse
                }

                Should -Invoke -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                Should -Invoke -CommandName Get-FileProductVersion -Exactly -Times 1 -Scope 'It'
            }
        }
    }
}

Describe "DSC_SqlRSSetup\Set-TargetResource" -Tag 'Set' {
    BeforeAll {
        <#
            .SYNOPSIS
                Used to test arguments passed to Start-SqlSetupProcess while inside and It-block.

                This function must be called inside a Mock, since it depends being run inside an It-block.

            .PARAMETER Argument
                A string containing all the arguments separated with space and each argument should start with '/'.
                Only the first string in the array is evaluated.

            .PARAMETER ExpectedArgument
                A hash table containing all the expected arguments.
        #>
        function Test-SetupArgument
        {
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $Argument,

                [Parameter(Mandatory = $true)]
                [System.Collections.Hashtable]
                $ExpectedArgument
            )

            $argumentHashTable = @{}

            # Break the argument string into a hash table
            ($Argument -split ' ?/') | ForEach-Object -Process {
                if ($_ -imatch '(\w+)="?([^\/]+)"?')
                {
                    $key = $Matches[1]
                    $value = ($Matches[2] -replace '" "', ' ') -replace '"', ''

                    $argumentHashTable.Add($key, $value)
                }
                elseif ($_ -imatch '(\w+)')
                {
                    $key = $Matches[1]
                    $value = [System.Management.Automation.SwitchParameter] $true

                    $argumentHashTable.Add($key, $value)
                }
            }

            $actualValues = $argumentHashTable.Clone()

            # Limit the output in the console when everything is fine.
            if ($actualValues.Count -ne $ExpectedArgument.Count)
            {
                Write-Warning -Message 'Verified the setup argument count (expected vs actual)'
                Write-Warning -Message ('Expected: {0}' -f ($ExpectedArgument.Keys -join ','))
                Write-Warning -Message ('Actual: {0}' -f ($actualValues.Keys -join ','))
            }

            # Start by checking whether we have the same number of parameters
            $actualValues.Count | Should -Be $ExpectedArgument.Count `
                -Because ('the expected arguments was: {0}' -f ($ExpectedArgument.Keys -join ','))

            Write-Verbose -Message 'Verified actual setup argument values against expected setup argument values' -Verbose

            foreach ($argumentKey in $ExpectedArgument.Keys)
            {
                $argumentKeyName =  $actualValues.GetEnumerator() |
                    Where-Object -FilterScript {
                        $_.Name -eq $argumentKey
                    } | Select-Object -ExpandProperty 'Name'

                $argumentValue = $actualValues.$argumentKey

                $argumentKeyName | Should -Be $argumentKey
                $argumentValue | Should -Be $ExpectedArgument.$argumentKey
            }
        }

        InModuleScope -ScriptBlock {
            $script:mockProductKey = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'

            # Default parameters that are used for the It-blocks.
            $script:mockDefaultParameters = @{
                InstanceName       = 'SSRS'
                IAcceptLicenseTerms = 'Yes'
                SourcePath         = '\\server\share\SQLServerReportingServices.exe'
            }
        }
    }

    BeforeEach {
        InModuleScope -ScriptBlock {
            $script:mockSetTargetResourceParameters = $script:mockDefaultParameters.Clone()
        }

        # Reset global variable DSCMachineStatus before each test.
        $global:DSCMachineStatus = 0
    }


    Context 'When providing a missing SourcePath' {
        BeforeEach {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockSetTargetResourceParameters['Edition'] = 'Development'

                $errorMessage = $script:localizedData.SourcePathNotFound -f $script:mockSetTargetResourceParameters.SourcePath

                { Set-TargetResource @mockSetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ('*' + $errorMessage + " (Parameter 'SourcePath')")
            }
        }
    }

    Context 'When providing a correct path in SourcePath, but no executable' {
        BeforeEach {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-Item -MockWith {
                return @{
                    Extension = ''
                }
            }
        }

        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockSetTargetResourceParameters['Edition'] = 'Development'

                $errorMessage = $script:localizedData.SourcePathNotFound -f $script:mockSetTargetResourceParameters.SourcePath

                { Set-TargetResource @mockSetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ('*' + $errorMessage + " (Parameter 'SourcePath')")
            }
        }
    }

    Context 'When providing both the parameters ProductKey and Edition' {
        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:mockSetTargetResourceParameters['Edition'] = 'Development'
                $script:mockSetTargetResourceParameters['ProductKey'] = $script:mockProductKey

                { Set-TargetResource @mockSetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ('*' + $script:localizedData.EditionInvalidParameter + " (Parameter 'Edition, ProductKey')")
            }
        }
    }

    Context 'When providing neither the parameters ProductKey or Edition' {
        It 'Should throw the correct error message' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { Set-TargetResource @mockSetTargetResourceParameters } |
                    Should -Throw -ExpectedMessage ('*' + $script:localizedData.EditionMissingParameter + " (Parameter 'Edition, ProductKey')")
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            Mock -CommandName Get-Item -MockWith {
                return @{
                    Extension = '.exe'
                }
            }
        }

        Context 'When Reporting Services are installed with the minimum required parameters' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    PID = InModuleScope -ScriptBlock { $script:mockProductKey }
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['ProductKey'] = $script:mockProductKey

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When Reporting Services should be uninstalled' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    Uninstall = [System.Management.Automation.SwitchParameter] $true
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Action'] = 'Uninstall'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When Reporting Services are installed with parameter Edition' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    Edition = 'Dev'
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Edition'] = 'Development'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When Reporting Services are installed with parameters ProductKey, SuppressRestart, LogPath, EditionUpgrade, and InstallFolder' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    PID = InModuleScope -ScriptBlock { $script:mockProductKey }
                    NoRestart = [System.Management.Automation.SwitchParameter] $true
                    Log = 'log.txt'
                    EditionUpgrade = [System.Management.Automation.SwitchParameter] $true
                    InstallFolder = 'C:\Temp'
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['ProductKey'] = $script:mockProductKey
                    $script:mockSetTargetResourceParameters['SuppressRestart'] = $true
                    $script:mockSetTargetResourceParameters['LogPath'] = 'log.txt'
                    $script:mockSetTargetResourceParameters['EditionUpgrade'] = $true
                    $script:mockSetTargetResourceParameters['InstallFolder'] = 'C:\Temp'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When Reporting Services are installed with parameter SuppressRestart set to $false' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    PID = InModuleScope -ScriptBlock { $script:mockProductKey }
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mock with the expected arguments' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['ProductKey'] = $script:mockProductKey
                    $script:mockSetTargetResourceParameters['SuppressRestart'] = $false

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When Reporting Services are installed with parameters EditionUpgrade set to $false' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    PID = InModuleScope -ScriptBlock { $script:mockProductKey }
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['ProductKey'] = $script:mockProductKey
                    $script:mockSetTargetResourceParameters['EditionUpgrade'] = $false

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When Reporting Services are installed using parameter SourceCredential' {
            BeforeAll {
                $mockLocalPath = Join-Path -Path $TestDrive -ChildPath 'LocalPath'

                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    PID = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                }

                Mock -CommandName Invoke-InstallationMediaCopy -MockWith {
                    return $mockLocalPath
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mocks' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                        'COMPANY\SqlAdmin',
                        ('dummyPassW0rd' | ConvertTo-SecureString -AsPlainText -Force)
                    )

                    $script:mockSetTargetResourceParameters['ProductKey'] = $script:mockProductKey
                    $script:mockSetTargetResourceParameters['SourceCredential'] = $mockShareCredential

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Invoke-InstallationMediaCopy -Exactly -Times 1 -Scope 'It'
                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    # Have to build the correct path (local path + executable).
                    $FilePath -eq (Join-Path -Path $mockLocalPath -ChildPath (Split-Path -Path (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath }) -Leaf))
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the Reporting Services installation is successful with exit code 3010' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    Edition = 'Dev'
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 3010
                }
            }

            It 'Should call the correct mocks, and set $global:DSCMachineStatus to 1' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Edition'] = 'Development'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'

                # Should set the global DSCMachineStatus variable.
                $global:DSCMachineStatus | Should -Be 1
            }

            Context 'When the Reporting Services installation is successful with exit code 3010, and called with parameter SuppressRestart' {
                BeforeAll {
                    $mockStartSqlSetupProcess_ExpectedArgumentList['NoRestart'] = [System.Management.Automation.SwitchParameter] $true
                }

                It 'Should call the correct mocks' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters['Edition'] = 'Development'
                        $script:mockSetTargetResourceParameters['SuppressRestart'] = $true

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                    }

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                    } -Exactly -Times 1 -Scope 'It'

                    # Should not set the global DSCMachineStatus variable.
                    $global:DSCMachineStatus | Should -Be 0
                }
            }
        }

        Context 'When the Reporting Services installation is successful and ForceRestart is used' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    Edition = 'Dev'
                }

                Mock -CommandName Test-PendingRestart
                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mocks, and set $global:DSCMachineStatus to 1' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Edition'] = 'Development'
                    $script:mockSetTargetResourceParameters['ForceRestart'] = $true

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                # Should set the global DSCMachineStatus variable.
                $global:DSCMachineStatus | Should -Be 1

                Should -Invoke -CommandName Test-PendingRestart -Exactly -Times 0 -Scope 'It'
                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the Reporting Services installation is successful, and there are a pending restart' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    Edition = 'Dev'
                }

                Mock -CommandName Test-PendingRestart -MockWith {
                    return $true
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 0
                }
            }

            It 'Should call the correct mocks, and set $global:DSCMachineStatus to 1' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Edition'] = 'Development'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw
                }

                # Should set the global DSCMachineStatus variable.
                $global:DSCMachineStatus | Should -Be 1

                Should -Invoke -CommandName Test-PendingRestart -Exactly -Times 1 -Scope 'It'
                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When the Reporting Services installation fails' {
            BeforeAll {
                $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                    Quiet = [System.Management.Automation.SwitchParameter] $true
                    IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                    Edition = 'Dev'
                }

                Mock -CommandName Start-SqlSetupProcess -MockWith {
                    Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                    return 1
                }
            }

            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $script:mockSetTargetResourceParameters['Edition'] = 'Development'

                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $script:localizedData.SetupFailed)
                }

                Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                    $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                } -Exactly -Times 1 -Scope 'It'

                # Should not set the global DSCMachineStatus variable.
                $global:DSCMachineStatus | Should -Be 0
            }

            Context 'When the Reporting Services installation fails, and called with parameter LogPath' {
                BeforeAll {
                    $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                        Quiet = [System.Management.Automation.SwitchParameter] $true
                        IAcceptLicenseTerms = [System.Management.Automation.SwitchParameter] $true
                        Edition = 'Dev'
                        log = 'TestDrive:\'
                    }
                }

                It 'Should throw the correct error message' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $script:mockSetTargetResourceParameters['Edition'] = 'Development'
                        $script:mockSetTargetResourceParameters['LogPath'] = 'TestDrive:\'

                        $errorMessage = $script:localizedData.SetupFailedWithLog -f $script:mockSetTargetResourceParameters.LogPath

                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw -ExpectedMessage ('*' + $errorMessage)
                    }

                    Should -Invoke -CommandName Start-SqlSetupProcess -ParameterFilter {
                        $FilePath -eq (InModuleScope -ScriptBlock { $script:mockSetTargetResourceParameters.SourcePath })
                    } -Exactly -Times 1 -Scope 'It'

                    # Should not set the global DSCMachineStatus variable.
                    $global:DSCMachineStatus | Should -Be 0
                }
            }
        }
    }
}

Describe "DSC_SqlRSSetup\Convert-EditionName" -Tag 'Helper' {
    Context 'When converting edition names' {
        BeforeDiscovery {
            $testCases = @(
                @{
                    InputName = 'Development'
                    OutputName = 'Dev'
                }
                @{
                    InputName = 'Evaluation'
                    OutputName = 'Eval'
                }
                @{
                    InputName = 'ExpressAdvanced'
                    OutputName = 'ExprAdv'
                }
                @{
                    InputName = 'Dev'
                    OutputName = 'Development'
                }
                @{
                    InputName = 'Eval'
                    OutputName = 'Evaluation'
                }
                @{
                    InputName = 'ExprAdv'
                    OutputName = 'ExpressAdvanced'
                }
            )
        }

        It 'Should return the value <OutputName> when converting from value <InputName>' -ForEach $testCases {
            InModuleScope -Parameters @{
                InputName = $InputName
                OutputName = $OutputName
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                Convert-EditionName -Name $InputName | Should -Be $OutputName
            }
        }
    }
}

Describe "DSC_SqlRSSetup\Get-FileProductVersion" -Tag 'Helper' {
    Context 'When converting edition names' {
        BeforeAll {
            Mock -CommandName Get-Item -MockWith {
                return @{
                    VersionInfo = @{
                        ProductVersion = '14.0.0.0'
                    }
                }
            }
        }

        It 'Should return the correct product version' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                Get-FileProductVersion -Path 'TestDrive:\MockExecutable.exe' | Should -Be '14.0.0.0'
            }
        }
    }
}
