# Import the CommonResourceHelper module to test
$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules\DscResource.Common'

Import-Module -Name (Join-Path -Path $script:modulesFolderPath -ChildPath 'DscResource.Common.psm1') -Force

InModuleScope 'DscResource.Common' {
    Describe 'DscResource.Common\Test-DscParameterState' -Tag 'TestDscParameterState' {
        Context -Name 'When passing values' -Fixture {
            It 'Should return true for two identical tables' {
                $mockDesiredValues = @{ Example = 'test' }

                $testParameters = @{
                    CurrentValues = $mockDesiredValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when a value is different for [System.String]' {
                $mockCurrentValues = @{ Example = [System.String] 'something' }
                $mockDesiredValues = @{ Example = [System.String] 'test' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [System.Int32]' {
                $mockCurrentValues = @{ Example = [System.Int32] 1 }
                $mockDesiredValues = @{ Example = [System.Int32] 2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [Int16]' {
                $mockCurrentValues = @{ Example = [System.Int16] 1 }
                $mockDesiredValues = @{ Example = [System.Int16] 2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [UInt16]' {
                $mockCurrentValues = @{ Example = [System.UInt16] 1 }
                $mockDesiredValues = @{ Example = [System.UInt16] 2 }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is different for [Boolean]' {
                $mockCurrentValues = @{ Example = [System.Boolean] $true }
                $mockDesiredValues = @{ Example = [System.Boolean] $false }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when a value is missing' {
                $mockCurrentValues = @{ }
                $mockDesiredValues = @{ Example = 'test' }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when only a specified value matches, but other non-listed values do not' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = 'true' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false'  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Example')
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when only specified values do not match, but other non-listed values do ' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = 'true' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false'  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('SecondExample')
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when an empty hash table is used in the current values' {
                $mockCurrentValues = @{ }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = 'false'  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when evaluating a table against a CimInstance' {
                $mockCurrentValues = @{ Handle = '0'; ProcessId = '1000'  }

                $mockWin32ProcessProperties = @{
                    Handle = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName = 'Win32_Process'
                    Property = $mockWin32ProcessProperties
                    Key = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Handle','ProcessId')
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when evaluating a table against a CimInstance and a value is wrong' {
                $mockCurrentValues = @{ Handle = '1'; ProcessId = '1000'  }

                $mockWin32ProcessProperties = @{
                    Handle = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName = 'Win32_Process'
                    Property = $mockWin32ProcessProperties
                    Key = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = @('Handle','ProcessId')
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return true when evaluating a hash table containing an array' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = @('1','2') }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1','2')  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $true
            }

            It 'Should return false when evaluating a hash table containing an array with wrong values' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = @('A','B') }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1','2')  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when evaluating a hash table containing an array, but the CurrentValues are missing an array' {
                $mockCurrentValues = @{ Example = 'test' }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1','2')  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }

            It 'Should return false when evaluating a hash table containing an array, but the property i CurrentValues is $null' {
                $mockCurrentValues = @{ Example = 'test'; SecondExample = $null }
                $mockDesiredValues = @{ Example = 'test'; SecondExample = @('1','2')  }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false
            }
        }

        Context -Name 'When passing invalid types for DesiredValues' -Fixture {
            It 'Should throw the correct error when DesiredValues is of wrong type' {
                $mockCurrentValues = @{ Example = 'something' }
                $mockDesiredValues = 'NotHashTable'

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                $mockCorrectErrorMessage = ($script:localizedData.PropertyTypeInvalidForDesiredValues -f $testParameters.DesiredValues.GetType().Name)
                { Test-DscParameterState @testParameters } | Should -Throw $mockCorrectErrorMessage
            }

            It 'Should write a warning when DesiredValues contain an unsupported type' {
                Mock -CommandName Write-Warning -Verifiable

                # This is a dummy type to test with a type that could never be a correct one.
                class MockUnknownType
                {
                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property1

                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property2

                    MockUnknownType()
                    {
                    }
                }

                $mockCurrentValues = @{ Example = New-Object -TypeName MockUnknownType }
                $mockDesiredValues = @{ Example = New-Object -TypeName MockUnknownType }

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                }

                Test-DscParameterState @testParameters | Should -Be $false

                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1
            }
        }

        Context -Name 'When passing an CimInstance as DesiredValue and ValuesToCheck is $null' -Fixture {
            It 'Should throw the correct error' {
                $mockCurrentValues = @{ Example = 'something' }

                $mockWin32ProcessProperties = @{
                    Handle = 0
                    ProcessId = 1000
                }

                $mockNewCimInstanceParameters = @{
                    ClassName = 'Win32_Process'
                    Property = $mockWin32ProcessProperties
                    Key = 'Handle'
                    ClientOnly = $true
                }

                $mockDesiredValues = New-CimInstance @mockNewCimInstanceParameters

                $testParameters = @{
                    CurrentValues = $mockCurrentValues
                    DesiredValues = $mockDesiredValues
                    ValuesToCheck = $null
                }

                $mockCorrectErrorMessage = $script:localizedData.PropertyTypeInvalidForValuesToCheck
                { Test-DscParameterState @testParameters } | Should -Throw $mockCorrectErrorMessage
            }
        }

        Assert-VerifiableMock
    }

    Describe 'DscResource.Common\Get-RegistryPropertyValue' -Tag 'GetRegistryPropertyValue' {
        BeforeAll {
            $mockWrongRegistryPath = 'HKLM:\SOFTWARE\AnyPath'
            $mockCorrectRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'
            $mockPropertyName = 'InstanceName'
            $mockPropertyValue = 'AnyValue'
        }

        Context 'When there are no property in the registry' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    return @{
                        'UnknownProperty' = $mockPropertyValue
                    }
                }
            }

            It 'Should return $null' {
                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
                $result | Should -BeNullOrEmpty

                Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
            }
        }

        Context 'When the call to Get-ItemProperty throws an error (i.e. when the path does not exist)' {
            BeforeAll {
                Mock -CommandName Get-ItemProperty -MockWith {
                    throw 'mocked error'
                }
            }

            It 'Should not throw an error, but return $null' {
                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
                $result | Should -BeNullOrEmpty

                Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there are a property in the registry' {
            BeforeAll {
                $mockGetItemProperty_InstanceName = {
                    return @{
                        $mockPropertyName = $mockPropertyValue
                    }
                }

                $mockGetItemProperty_InstanceName_ParameterFilter = {
                    $Path -eq $mockCorrectRegistryPath `
                    -and $Name -eq $mockPropertyName
                }

                Mock -CommandName Get-ItemProperty `
                    -MockWith $mockGetItemProperty_InstanceName `
                    -ParameterFilter $mockGetItemProperty_InstanceName_ParameterFilter
            }

            It 'Should return the correct value' {
                $result = Get-RegistryPropertyValue -Path $mockCorrectRegistryPath -Name $mockPropertyName
                $result | Should -Be $mockPropertyValue

                Assert-MockCalled Get-ItemProperty -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe 'DscResource.Common\Format-Path' -Tag 'FormatPath' {
        BeforeAll {
            $mockCorrectPath = 'C:\Correct\Path'
            $mockPathWithTrailingBackslash = 'C:\Correct\Path\'
            $mockPathWithOnlyQualifier = 'M:'
            $mockCorrectQualifierPath = 'M:\'
        }

        Context 'When there is a path that is wrongly formatted, but now formatting was requested' {
            It 'Should return the same wrongly formatted path' {
                $result = Format-Path -Path $mockPathWithTrailingBackslash
                $result | Should -BeExactly $mockPathWithTrailingBackslash
            }
        }

        Context 'When there is a path that is formatted correctly, and using TrailingSlash' {
            It 'Should return the same path' {
                $result = Format-Path -Path $mockCorrectPath -TrailingSlash
                $result | Should -BeExactly $mockCorrectPath
            }
        }

        Context 'When there is a path that has a trailing backslash, and using TrailingSlash' {
            It 'Should return the path without trailing backslash' {
                $result = Format-Path -Path $mockPathWithTrailingBackslash -TrailingSlash
                $result | Should -BeExactly $mockCorrectPath
            }
        }

        Context 'When there is a path that has only a qualifier, and using TrailingSlash' {
            It 'Should return the path with trailing backslash after the qualifier' {
                $result = Format-Path -Path $mockPathWithOnlyQualifier -TrailingSlash
                $result | Should -BeExactly $mockCorrectQualifierPath
            }
        }
    }

    # Tests only the parts of the code that does not already get tested thru the other tests.
    Describe 'DscResource.Common\Copy-ItemWithRobocopy' -Tag 'CopyItemWithRobocopy' {
        BeforeAll {
            $mockRobocopyExecutableName = 'Robocopy.exe'
            $mockRobocopyExecutableVersionWithoutUnbufferedIO = '6.2.9200.00000'
            $mockRobocopyExecutableVersionWithUnbufferedIO = '6.3.9600.16384'
            $mockRobocopyExecutableVersion = ''     # Set dynamically during runtime
            $mockRobocopyArgumentSilent = '/njh /njs /ndl /nc /ns /nfl'
            $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty = '/e'
            $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource = '/purge'
            $mockRobocopyArgumentUseUnbufferedIO = '/J'
            $mockRobocopyArgumentSourcePath = 'C:\Source\SQL2016'
            $mockRobocopyArgumentDestinationPath = 'D:\Temp'
            $mockRobocopyArgumentSourcePathWithSpaces = 'C:\Source\SQL2016 STD SP1'
            $mockRobocopyArgumentDestinationPathWithSpaces = 'D:\Temp\DSC SQL2016'

            $mockGetCommand = {
                return @(
                    (
                        New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Name' -Value $mockRobocopyExecutableName -PassThru |
                            Add-Member -MemberType ScriptProperty -Name FileVersionInfo -Value {
                                return @( ( New-Object -TypeName Object |
                                        Add-Member -MemberType NoteProperty -Name 'ProductVersion' -Value $mockRobocopyExecutableVersion -PassThru -Force
                                    ) )
                            } -PassThru -Force
                    )
                )
            }

            $mockStartSqlSetupProcessExpectedArgument = ''  # Set dynamically during runtime
            $mockStartSqlSetupProcessExitCode = 0  # Set dynamically during runtime

            $mockStartSqlSetupProcess_Robocopy = {
                if ( $ArgumentList -cne $mockStartSqlSetupProcessExpectedArgument )
                {
                    throw "Expected arguments was not the same as the arguments in the function call.`nExpected: '$mockStartSqlSetupProcessExpectedArgument' `n But was: '$ArgumentList'"
                }

                return New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value 0 -PassThru -Force
            }

            $mockStartSqlSetupProcess_Robocopy_WithExitCode = {
                return New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'ExitCode' -Value $mockStartSqlSetupProcessExitCode -PassThru -Force
            }
        }

        Context 'When Copy-ItemWithRobocopy is called it should return the correct arguments' {
            BeforeEach {
                Mock -CommandName Get-Command -MockWith $mockGetCommand -Verifiable
                Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy -Verifiable
                $mockRobocopyArgumentSourcePathQuoted = '"{0}"' -f $mockRobocopyArgumentSourcePath
                $mockRobocopyArgumentDestinationPathQuoted = '"{0}"' -f $mockRobocopyArgumentDestinationPath
            }


            It 'Should use Unbuffered IO when copying' {
                $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

                $mockStartSqlSetupProcessExpectedArgument =
                    $mockRobocopyArgumentSourcePathQuoted,
                    $mockRobocopyArgumentDestinationPathQuoted,
                    $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty,
                    $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                    $mockRobocopyArgumentUseUnbufferedIO,
                    $mockRobocopyArgumentSilent -join ' '

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePath
                    DestinationPath = $mockRobocopyArgumentDestinationPath
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process  -Exactly -Times 1 -Scope It
            }

            It 'Should not use Unbuffered IO when copying' {
                $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithoutUnbufferedIO

                $mockStartSqlSetupProcessExpectedArgument =
                    $mockRobocopyArgumentSourcePathQuoted,
                    $mockRobocopyArgumentDestinationPathQuoted,
                    $mockRobocopyArgumentCopySubDirectoriesIncludingEmpty,
                    $mockRobocopyArgumentDeletesDestinationFilesAndDirectoriesNotExistAtSource,
                    '',
                    $mockRobocopyArgumentSilent -join ' '

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePath
                    DestinationPath = $mockRobocopyArgumentDestinationPath
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Copy-ItemWithRobocopy throws an exception it should return the correct error messages' {
            BeforeEach {
                $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

                Mock -CommandName Get-Command -MockWith $mockGetCommand -Verifiable
                Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy_WithExitCode -Verifiable
            }

            It 'Should throw the correct error message when error code is 8' {
                $mockStartSqlSetupProcessExitCode = 8

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePath
                    DestinationPath = $mockRobocopyArgumentDestinationPath
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw "Robocopy reported errors when copying files. Error code: $mockStartSqlSetupProcessExitCode."

                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
            }

            It 'Should throw the correct error message when error code is 16' {
                $mockStartSqlSetupProcessExitCode = 16

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePath
                    DestinationPath = $mockRobocopyArgumentDestinationPath
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw "Robocopy reported errors when copying files. Error code: $mockStartSqlSetupProcessExitCode."

                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
            }

            It 'Should throw the correct error message when error code is greater than 7 (but not 8 or 16)' {
                $mockStartSqlSetupProcessExitCode = 9

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePath
                    DestinationPath = $mockRobocopyArgumentDestinationPath
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Throw "Robocopy reported that failures occurred when copying files. Error code: $mockStartSqlSetupProcessExitCode."

                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Copy-ItemWithRobocopy is called and finishes successfully it should return the correct exit code' {
            BeforeEach {
                $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

                Mock -CommandName Get-Command -MockWith $mockGetCommand -Verifiable
                Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy_WithExitCode -Verifiable
            }

            AfterEach {
                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
            }

            It 'Should finish successfully with exit code 1' {
                $mockStartSqlSetupProcessExitCode = 1

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePath
                    DestinationPath = $mockRobocopyArgumentDestinationPath
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
            }

            It 'Should finish successfully with exit code 2' {
                $mockStartSqlSetupProcessExitCode = 2

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePath
                    DestinationPath = $mockRobocopyArgumentDestinationPath
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
            }

            It 'Should finish successfully with exit code 3' {
                $mockStartSqlSetupProcessExitCode = 3

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePath
                    DestinationPath = $mockRobocopyArgumentDestinationPath
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw
            }
        }

        Context 'When Copy-ItemWithRobocopy is called with spaces in paths and finishes successfully it should return the correct exit code' {
            BeforeEach {
                $mockRobocopyExecutableVersion = $mockRobocopyExecutableVersionWithUnbufferedIO

                Mock -CommandName Get-Command -MockWith $mockGetCommand -Verifiable
                Mock -CommandName Start-Process -MockWith $mockStartSqlSetupProcess_Robocopy_WithExitCode -Verifiable
            }

            AfterEach {
                Assert-MockCalled -CommandName Get-Command -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Start-Process -Exactly -Times 1 -Scope It
            }

            It 'Should finish successfully with exit code 1' {
                $mockStartSqlSetupProcessExitCode = 1

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePathWithSpaces
                    DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

            }

            It 'Should finish successfully with exit code 2' {
                $mockStartSqlSetupProcessExitCode = 2

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePathWithSpaces
                    DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw

            }

            It 'Should finish successfully with exit code 3' {
                $mockStartSqlSetupProcessExitCode = 3

                $copyItemWithRobocopyParameter = @{
                    Path = $mockRobocopyArgumentSourcePathWithSpaces
                    DestinationPath = $mockRobocopyArgumentDestinationPathWithSpaces
                }

                { Copy-ItemWithRobocopy @copyItemWithRobocopyParameter } | Should -Not -Throw
            }
        }
    }

    Describe 'DscResource.Common\Get-TemporaryFolder' -Tag 'GetTemporaryFolder' {
        BeforeAll {
            $mockExpectedTempPath = [IO.Path]::GetTempPath()
        }

        Context 'When using Get-TemporaryFolder' {
            It 'Should return the correct temporary path' {
                Get-TemporaryFolder | Should -BeExactly $mockExpectedTempPath
            }
        }
    }

    Describe 'DscResource.Common\Invoke-InstallationMediaCopy' -Tag 'InvokeInstallationMediaCopy' {
        BeforeAll {
            $mockSourcePathUNC = '\\server\share'
            $mockSourcePathUNCWithLeaf = '\\server\share\leaf'
            $mockSourcePathGuid = 'cc719562-0f46-4a16-8605-9f8a47c70402'
            $mockDestinationPath = 'TestDrive:\'

            $mockShareCredentialUserName = 'COMPANY\SqlAdmin'
            $mockShareCredentialPassword = 'dummyPassW0rd'
            $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                $mockShareCredentialUserName,
                ($mockShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
            )

            $mockGetTemporaryFolder = {
                return $mockDestinationPath
            }

            $mockNewGuid = {
                return New-Object -TypeName Object |
                            Add-Member -MemberType NoteProperty -Name 'Guid' -Value $mockSourcePathGuid -PassThru -Force
            }

            Mock -CommandName Connect-UncPath
            Mock -CommandName Disconnect-UncPath
            Mock -CommandName Copy-ItemWithRobocopy
            Mock -CommandName Get-TemporaryFolder -MockWith $mockGetTemporaryFolder
            Mock -CommandName New-Guid -MockWith $mockNewGuid
        }

        Context 'When invoking installation media copy, using SourcePath containing leaf' {
            It 'Should call the correct mocks' {
                {
                    $invokeInstallationMediaCopyParameters = @{
                        SourcePath = $mockSourcePathUNCWithLeaf
                        SourceCredential = $mockShareCredential
                    }

                    Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
                } | Should -Not -Throw

                Assert-MockCalled -CommandName Connect-UncPath -Exactly -Times 1 -Scope 'It'
                Assert-MockCalled -CommandName New-Guid -Exactly -Times 0 -Scope 'It'
                Assert-MockCalled -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope 'It'
                Assert-MockCalled -CommandName Copy-ItemWithRobocopy -Exactly -Times 1 -Scope 'It'
                Assert-MockCalled -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope 'It'
            }

            It 'Should return the correct destination path' {
                $invokeInstallationMediaCopyParameters = @{
                    SourcePath = $mockSourcePathUNCWithLeaf
                    SourceCredential = $mockShareCredential
                    PassThru = $true
                }

                $invokeInstallationMediaCopyResult = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters

                $invokeInstallationMediaCopyResult | Should -Be ('{0}leaf' -f $mockDestinationPath)
            }
        }

        Context 'When invoking installation media copy, using SourcePath without a leaf' {
            It 'Should call the correct mocks' {
                {
                    $invokeInstallationMediaCopyParameters = @{
                        SourcePath = $mockSourcePathUNC
                        SourceCredential = $mockShareCredential
                    }

                    Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
                } | Should -Not -Throw

                Assert-MockCalled -CommandName Connect-UncPath -Exactly -Times 1 -Scope 'It'
                Assert-MockCalled -CommandName New-Guid -Exactly -Times 1 -Scope 'It'
                Assert-MockCalled -CommandName Get-TemporaryFolder -Exactly -Times 1 -Scope 'It'
                Assert-MockCalled -CommandName Copy-ItemWithRobocopy -Exactly -Times 1 -Scope 'It'
                Assert-MockCalled -CommandName Disconnect-UncPath -Exactly -Times 1 -Scope 'It'
            }

            It 'Should return the correct destination path' {
                $invokeInstallationMediaCopyParameters = @{
                    SourcePath = $mockSourcePathUNC
                    SourceCredential = $mockShareCredential
                    PassThru = $true
                }

                $invokeInstallationMediaCopyResult = Invoke-InstallationMediaCopy @invokeInstallationMediaCopyParameters
                $invokeInstallationMediaCopyResult | Should -Be ('{0}{1}' -f $mockDestinationPath, $mockSourcePathGuid)
            }
        }
    }

    Describe 'DscResource.Common\Connect-UncPath' -Tag 'ConnectUncPath' {
        BeforeAll {
            $mockSourcePathUNC = '\\server\share'

            $mockShareCredentialUserName = 'COMPANY\SqlAdmin'
            $mockShareCredentialPassword = 'dummyPassW0rd'
            $mockShareCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(
                $mockShareCredentialUserName,
                ($mockShareCredentialPassword | ConvertTo-SecureString -AsPlainText -Force)
            )

            Mock -CommandName New-SmbMapping -MockWith {
                return @{
                    RemotePath = $mockSourcePathUNC
                }
            }
        }

        Context 'When connecting to a UNC path without credentials (using current credentials)' {
            It 'Should call the correct mocks' {
                {
                    $connectUncPathParameters = @{
                        RemotePath = $mockSourcePathUNC
                    }

                    Connect-UncPath @connectUncPathParameters
                } | Should -Not -Throw

                Assert-MockCalled -CommandName New-SmbMapping -ParameterFilter {
                    $RemotePath -eq $mockSourcePathUNC `
                    -and $PSBoundParameters.ContainsKey('UserName') -eq $false
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When connecting to a UNC path with specific credentials' {
            It 'Should call the correct mocks' {
                {
                    $connectUncPathParameters = @{
                        RemotePath = $mockSourcePathUNC
                        SourceCredential = $mockShareCredential
                    }

                    Connect-UncPath @connectUncPathParameters
                } | Should -Not -Throw

                Assert-MockCalled -CommandName New-SmbMapping -ParameterFilter {
                    $RemotePath -eq $mockSourcePathUNC `
                    -and $UserName -eq $mockShareCredentialUserName
                } -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When connecting to a UNC path and using parameter PassThru' {
            It 'Should return the correct MSFT_SmbMapping object' {
                $connectUncPathParameters = @{
                    RemotePath = $mockSourcePathUNC
                    SourceCredential = $mockShareCredential
                    PassThru = $true
                }

                $connectUncPathResult = Connect-UncPath @connectUncPathParameters
                $connectUncPathResult.RemotePath | Should -Be $mockSourcePathUNC
            }
        }
    }

    Describe 'DscResource.Common\Disconnect-UncPath' -Tag 'DisconnectUncPath' {
        BeforeAll {
            $mockSourcePathUNC = '\\server\share'

            Mock -CommandName Remove-SmbMapping
        }

        Context 'When disconnecting from an UNC path' {
            It 'Should call the correct mocks' {
                {
                    $disconnectUncPathParameters = @{
                        RemotePath = $mockSourcePathUNC
                    }

                    Disconnect-UncPath @disconnectUncPathParameters
                } | Should -Not -Throw

                Assert-MockCalled -CommandName Remove-SmbMapping -Exactly -Times 1 -Scope 'It'
            }
        }
    }

    Describe 'DscResource.Common\Test-PendingReboot' -Tag 'TestPendingReboot' {
        Context 'When there is a pending reboot' {
            BeforeAll {
                Mock -CommandName Get-RegistryPropertyValue -MockWith {
                    return 'AnyValue'
                }
            }

            It 'Should return $true' {
                $testPendingRebootResult = Test-PendingReboot
                $testPendingRebootResult | Should -BeTrue

                Assert-MockCalled -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
            }
        }

        Context 'When there are no pending reboot' {
            BeforeAll {
                Mock -CommandName Get-RegistryPropertyValue
            }

            It 'Should return $true' {
                $testPendingRebootResult = Test-PendingReboot
                $testPendingRebootResult | Should -BeFalse

                Assert-MockCalled -CommandName Get-RegistryPropertyValue -Exactly -Times 1 -Scope 'It'
            }
        }
    }

    Describe 'Start-SqlSetupProcess' -Tag 'StartSqlSetupProcess' {
        Context 'When starting a process successfully' {
            It 'Should return exit code 0' {
                $startSqlSetupProcessParameters = @{
                    FilePath = 'powershell.exe'
                    ArgumentList = '-Command &{Start-Sleep -Seconds 2}'
                    Timeout = 30
                }

                $processExitCode = Start-SqlSetupProcess @startSqlSetupProcessParameters
                $processExitCode | Should -BeExactly 0
            }
        }

        Context 'When starting a process and the process does not finish before the timeout period' {
            It 'Should throw an error message' {
                $startSqlSetupProcessParameters = @{
                    FilePath = 'powershell.exe'
                    ArgumentList = '-Command &{Start-Sleep -Seconds 4}'
                    Timeout = 2
                }

                { Start-SqlSetupProcess @startSqlSetupProcessParameters } | Should -Throw -ErrorId 'ProcessNotTerminated,Microsoft.PowerShell.Commands.WaitProcessCommand'
            }
        }
    }
}

