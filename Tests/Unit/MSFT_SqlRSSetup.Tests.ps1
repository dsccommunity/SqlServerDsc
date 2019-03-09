<#
    .SYNOPSIS
        Automated unit test for MSFT_SqlRSSetup DSC resource.

    .NOTES
        To run this script locally, please make sure to first run the bootstrap
        script. Read more at
        https://github.com/PowerShell/SqlServerDsc/blob/dev/CONTRIBUTING.md#bootstrap-script-assert-testenvironment
#>

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelpers\CommonTestHelper.psm1')

if (Test-SkipContinuousIntegrationTask -Type 'Unit')
{
    return
}

$script:dscModuleName = 'SqlServerDsc'
$script:dscResourceName = 'MSFT_SqlRSSetup'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:dscModuleName `
    -DSCResourceName $script:dscResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup
{
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:dscResourceName {
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
            ($Argument -split ' ?/') | ForEach-Object {
                if ($_ -imatch '(\w+)="?([^\/]+)"?')
                {
                    $key = $Matches[1]
                    $value = ($Matches[2] -replace '" "',' ') -replace '"',''

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
                -Because ('the expected argument was: {0}' -f ($ExpectedArgument.Keys -join ','))

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

        $mockInstanceName = 'SSRS'

        # Default parameters that are used for the It-blocks.
        $mockDefaultParameters = @{
            InstanceName       = $mockInstanceName
            IAcceptLicensTerms = 'Yes'
            SourcePath         = '\\server\share\SQLServerReportingServices.exe'
        }

        Describe "MSFT_SqlRSSetup\Get-TargetResource" -Tag 'Get' {
            BeforeEach {
                $mockGetTargetResourceParameters = $mockDefaultParameters.Clone()
            }

            Context 'When the system is in the desired state' {
                Context 'When there are no installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-RegistryPropertyValue
                    }

                    It 'Should return $null as the InstanceName' {
                        $result = Get-TargetResource @mockGetTargetResourceParameters
                        $result.InstanceName | Should -BeNullOrEmpty

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @mockGetTargetResourceParameters
                        $result.IAcceptLicensTerms | Should -Be $mockGetTargetResourceParameters.IAcceptLicensTerms
                        $result.SourcePath | Should -Be $mockGetTargetResourceParameters.SourcePath

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
                    }

                    It 'Should return $null or $false for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters
                        $getTargetResourceResult.Action | Should -BeNullOrEmpty
                        $getTargetResourceResult.SourceCredential | Should -BeNullOrEmpty
                        $getTargetResourceResult.ProductKey | Should -BeNullOrEmpty
                        $getTargetResourceResult.ForceReboot | Should -BeFalse
                        $getTargetResourceResult.EditionUpgrade | Should -BeFalse
                        $getTargetResourceResult.Edition | Should -BeNullOrEmpty
                        $getTargetResourceResult.LogPath | Should -BeNullOrEmpty
                        $getTargetResourceResult.InstallFolder | Should -BeNullOrEmpty
                        $getTargetResourceResult.ErrorDumpDirectory | Should -BeNullOrEmpty
                        $getTargetResourceResult.CurrentVersion | Should -BeNullOrEmpty
                        $getTargetResourceResult.ServiceName | Should -BeNullOrEmpty

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When there is an installed Reporting Services' {
                    BeforeAll {
                        $mockGetItemProperty_InstanceName = {
                            <#
                                Currently only the one instance name of 'SSRS' is supported,
                                and the same name is currently used for instance id.
                            #>
                            return $mockInstanceName
                        }

                        $mockGetItemProperty_InstanceName_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' `
                                -and $Name -eq $mockInstanceName
                        }

                        $mockGetItemPropertyValue_InstallRootDirectory = 'C:\Program Files\Microsoft SQL Server Reporting Services'
                        $mockGetItemProperty_InstallRootDirectory = {
                            return $mockGetItemPropertyValue_InstallRootDirectory
                        }

                        $mockGetItemProperty_InstallRootDirectory_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' `
                                -and $Name -eq 'InstallRootDirectory'
                        }

                        $mockGetItemPropertyValue_ServiceName = 'SQLServerReportingServices'
                        $mockGetItemProperty_ServiceName = {
                            return $mockGetItemPropertyValue_ServiceName
                        }

                        $mockGetItemProperty_ServiceName_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\Setup' `
                                -and $Name -eq 'ServiceName'
                        }

                        $mockGetItemPropertyValue_ErrorDumpDir = 'C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles'
                        $mockGetItemProperty_ErrorDumpDir = {
                            return $mockGetItemPropertyValue_ErrorDumpDir
                        }

                        $mockGetItemProperty_ErrorDumpDir_ParameterFilter = {
                            $Path -eq 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\SSRS\CPE' `
                                -and $Name -eq 'ErrorDumpDir'
                        }

                        $mockGetItemPropertyValue_CurrentVersion = '14.0.600.1109'
                        $mockGetItemProperty_CurrentVersion = {
                            return $mockGetItemPropertyValue_CurrentVersion
                        }

                        $mockGetItemProperty_CurrentVersion_ParameterFilter = {
                            $Path -eq ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\{0}\MSSQLServer\CurrentVersion' -f $mockInstanceName) `
                                -and $Name -eq 'CurrentVersion'
                        }

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetItemProperty_InstanceName `
                            -ParameterFilter $mockGetItemProperty_InstanceName_ParameterFilter

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetItemProperty_InstallRootDirectory `
                            -ParameterFilter $mockGetItemProperty_InstallRootDirectory_ParameterFilter

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetItemProperty_ServiceName `
                            -ParameterFilter $mockGetItemProperty_ServiceName_ParameterFilter

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetItemProperty_ErrorDumpDir `
                            -ParameterFilter $mockGetItemProperty_ErrorDumpDir_ParameterFilter

                        Mock -CommandName Get-RegistryPropertyValue `
                            -MockWith $mockGetItemProperty_CurrentVersion `
                            -ParameterFilter $mockGetItemProperty_CurrentVersion_ParameterFilter
                    }

                    It 'Should return the correct InstanceName' {
                        $result = Get-TargetResource @mockGetTargetResourceParameters
                        $result.InstanceName | Should -Be $mockGetTargetResourceParameters.InstanceName

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetItemProperty_InstanceName_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'
                    }

                    It 'Should return the same values as passed as parameters' {
                        $result = Get-TargetResource @mockGetTargetResourceParameters
                        $result.IAcceptLicensTerms | Should -Be $mockGetTargetResourceParameters.IAcceptLicensTerms
                        $result.SourcePath | Should -Be $mockGetTargetResourceParameters.SourcePath
                    }

                    It 'Should return the correct values for the rest of the properties' {
                        $getTargetResourceResult = Get-TargetResource @mockGetTargetResourceParameters
                        $getTargetResourceResult.Action | Should -BeNullOrEmpty
                        $getTargetResourceResult.SourceCredential | Should -BeNullOrEmpty
                        $getTargetResourceResult.ProductKey | Should -BeNullOrEmpty
                        $getTargetResourceResult.ForceReboot | Should -BeFalse
                        $getTargetResourceResult.EditionUpgrade | Should -BeFalse
                        $getTargetResourceResult.Edition | Should -BeNullOrEmpty
                        $getTargetResourceResult.LogPath | Should -BeNullOrEmpty
                        $getTargetResourceResult.InstallFolder | Should -Be $mockGetItemPropertyValue_InstallRootDirectory
                        $getTargetResourceResult.ErrorDumpDirectory | Should -Be $mockGetItemPropertyValue_ErrorDumpDir
                        $getTargetResourceResult.CurrentVersion | Should -Be $mockGetItemPropertyValue_CurrentVersion
                        $getTargetResourceResult.ServiceName | Should -Be $mockGetItemPropertyValue_ServiceName

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetItemProperty_InstallRootDirectory_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetItemProperty_ServiceName_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetItemProperty_ErrorDumpDir_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'

                        Assert-MockCalled -CommandName Get-RegistryPropertyValue `
                            -ParameterFilter $mockGetItemProperty_CurrentVersion_ParameterFilter `
                            -Exactly -Times 1 -Scope 'It'
                    }
                }
            }
        }

        Describe "MSFT_SqlRSSetup\Test-TargetResource" -Tag 'Test' {
            BeforeEach {
                $mockTestTargetResourceParameters = $mockDefaultParameters.Clone()
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
                        $mockTestTargetResourceParameters['Action'] = 'Uninstall'

                        $result = Test-TargetResource @mockTestTargetResourceParameters
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When there is an installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = 'SSRS'
                            }
                        }
                    }

                    It 'Should return $true' {
                        $result = Test-TargetResource @mockTestTargetResourceParameters
                        $result | Should -BeTrue

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When there is an installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = 'SSRS'
                            }
                        }
                    }

                    It 'Should return $false' {
                        $mockTestTargetResourceParameters['Action'] = 'Uninstall'

                        $result = Test-TargetResource @mockTestTargetResourceParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When there are no installed Reporting Services' {
                    BeforeAll {
                        Mock -CommandName Get-TargetResource -MockWith {
                            return @{
                                InstanceName = $null
                            }
                        }
                    }

                    It 'Should return $false' {
                        $result = Test-TargetResource @mockTestTargetResourceParameters
                        $result | Should -BeFalse

                        Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1 -Scope 'It'
                    }
                }
            }
        }

        Describe "MSFT_SqlRSSetup\Set-TargetResource" -Tag 'Set' {
            BeforeAll {
                $mockProductKey = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
            }

            BeforeEach {
                $mockSetTargetResourceParameters = $mockDefaultParameters.Clone()
            }

            Context 'When providing both the parameters ProductKey and Edition' {
                BeforeEach {
                    $mockSetTargetResourceParameters['Edition'] = 'Development'
                    $mockSetTargetResourceParameters['ProductKey'] = $mockProductKey
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $script:localizedData.EditionInvalidParameter
                }
            }

            Context 'When providing neither the parameters ProductKey or Edition' {
                It 'Should throw the correct error' {
                    { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $script:localizedData.EditionMissingParameter
                }
            }

            Context 'When the system is not in the desired state' {
                Context 'When Reporting Services are installed with the minimum required parameters' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['ProductKey'] = $mockProductKey

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            PID = $mockProductKey
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When Reporting Services should be uninstalled' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Action'] = 'Uninstall'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            Uninstall = [System.Management.Automation.SwitchParameter] $true
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When Reporting Services are installed with parameter Edition' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When Reporting Services are installed with parameters ProductKey, SuppressReboot, LogPath, EditionUpgrade, and InstallFolder' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['ProductKey'] = $mockProductKey
                        $mockSetTargetResourceParameters['SuppressReboot'] = $true
                        $mockSetTargetResourceParameters['LogPath'] = 'log.txt'
                        $mockSetTargetResourceParameters['EditionUpgrade'] = $true
                        $mockSetTargetResourceParameters['InstallFolder'] = 'C:\Temp'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            PID = $mockProductKey
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
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When Reporting Services are installed using parameter SourceCredential' {
                    BeforeAll {
                        $mockLocalPath = 'C:\LocalPath'

                        $mockShareCredentialUserName = 'COMPANY\SqlAdmin'
                        $mockShareCredentialPassword = 'dummyPassW0rd'
                        $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                            $mockShareCredentialUserName,
                            ($mockShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
                        )

                        Mock -CommandName Invoke-InstallationMediaCopy -MockWith {
                            return $mockLocalPath
                        }
                    }

                    BeforeEach {
                        $mockSetTargetResourceParameters['ProductKey'] = $mockProductKey

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            PID = '1FAKE-2FAKE-3FAKE-4FAKE-5FAKE'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }
                    }

                    It 'Should call the correct mocks' {
                        $mockSetTargetResourceParameters['SourceCredential'] = $mockShareCredential
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        Assert-MockCalled -CommandName Invoke-InstallationMediaCopy -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            # Have to build the correct path (local path + executable).
                            $FilePath -eq (Join-Path -Path $mockLocalPath -ChildPath (Split-Path -Path $mockSetTargetResourceParameters.SourcePath -Leaf))
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the Reporting Services installation is successful with exit code 3010' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 3010
                        }

                        $global:DSCMachineStatus = 0
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        # Should set the global DSCMachineStatus variable.
                        $global:DSCMachineStatus | Should -Be 1

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }

                    Context 'When the Reporting Services installation is successful with exit code 3010, and called with parameter SuppressReboot' {
                        BeforeEach {
                            $mockSetTargetResourceParameters['Edition'] = 'Development'
                            $mockSetTargetResourceParameters['SuppressReboot'] = $true

                            $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                                Quiet = [System.Management.Automation.SwitchParameter] $true
                                IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                                Edition = 'Dev'
                                NoRestart = [System.Management.Automation.SwitchParameter] $true
                            }
                        }

                        It 'Should call the correct mocks' {
                            { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                            Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                                $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                            } -Exactly -Times 1 -Scope 'It'

                            # Should not set the global DSCMachineStatus variable.
                            $global:DSCMachineStatus | Should -Be 0
                        }
                    }
                }

                Context 'When the Reporting Services installation is successful and ForceReboot is used' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'
                        $mockSetTargetResourceParameters['ForceReboot'] = $true

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Test-PendingReboot
                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }

                        $global:DSCMachineStatus = 0
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        # Should set the global DSCMachineStatus variable.
                        $global:DSCMachineStatus | Should -Be 1

                        Assert-MockCalled -CommandName Test-PendingReboot -Exactly -Times 0 -Scope 'It'
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the Reporting Services installation is successful, and there are a pending reboot' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Test-PendingReboot -MockWith {
                            return $true
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 0
                        }

                        $global:DSCMachineStatus = 0
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Not -Throw

                        # Should set the global DSCMachineStatus variable.
                        $global:DSCMachineStatus | Should -Be 1

                        Assert-MockCalled -CommandName Test-PendingReboot -Exactly -Times 1 -Scope 'It'
                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }

                Context 'When the Reporting Services installation fails' {
                    BeforeEach {
                        $mockSetTargetResourceParameters['Edition'] = 'Development'

                        $mockStartSqlSetupProcess_ExpectedArgumentList = @{
                            Quiet = [System.Management.Automation.SwitchParameter] $true
                            IAcceptLicensTerms = [System.Management.Automation.SwitchParameter] $true
                            Edition = 'Dev'
                        }

                        Mock -CommandName Start-SqlSetupProcess -MockWith {
                            Test-SetupArgument -Argument $ArgumentList -ExpectedArgument $mockStartSqlSetupProcess_ExpectedArgumentList

                            return 1
                        }

                        $global:DSCMachineStatus = 0
                    }

                    It 'Should call the correct mocks' {
                        { Set-TargetResource @mockSetTargetResourceParameters } | Should -Throw $script:localizedData.SetupFailed

                        Assert-MockCalled -CommandName Start-SqlSetupProcess -ParameterFilter {
                            $FilePath -eq $mockSetTargetResourceParameters.SourcePath
                        } -Exactly -Times 1 -Scope 'It'
                    }
                }
            }
        }

        Describe "MSFT_SqlRSSetup\Convert-EditionName" -Tag 'Helper' {
            Context 'When converting edition names' {
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

                It 'Should return the the value <OutputName> when converting from value <InputName>' -TestCases $testCases {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $InputName,

                        [Parameter()]
                        [System.String]
                        $OutputName
                    )

                    Convert-EditionName -Name $InputName | Should -Be $OutputName
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}

