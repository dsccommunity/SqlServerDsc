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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    $env:SqlServerDscCI = $true

    InModuleScope -ScriptBlock {
        <#
            Stub for Invoke-CimMethod since it doesn't exist on macOS and
            we need to be able to mock it.
        #>
        function script:Invoke-CimMethod
        {
            param
            (
                [Parameter(ValueFromPipeline = $true)]
                [System.Object]
                $InputObject,

                [System.String]
                $MethodName,

                [System.Collections.Hashtable]
                $Arguments,

                [System.UInt32]
                $OperationTimeoutSec,

                [System.String]
                $ErrorAction
            )

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    'StubNotImplemented',
                    'StubCalledError',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $MyInvocation.MyCommand
                )
            )
        }
    }
}

AfterAll {
    Remove-Item -Path 'env:SqlServerDscCI' -ErrorAction 'SilentlyContinue'

    InModuleScope -ScriptBlock {
        Remove-Item -Path 'function:script:Invoke-CimMethod' -Force -ErrorAction SilentlyContinue
    }

    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}

Describe 'Invoke-RsCimMethod' -Tag 'Private' {
    Context 'When invoking a CIM method successfully on first attempt' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should invoke the method without errors' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod'

                $result | Should -Not -BeNullOrEmpty
                $result.HRESULT | Should -Be 0
            }

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'TestMethod'
            } -Exactly -Times 1

            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0
        }

        It 'Should pass arguments to the CIM method' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'SetSecureConnectionLevel' -Arguments @{ Level = 1 }

                $result | Should -Not -BeNullOrEmpty
            }

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'SetSecureConnectionLevel' -and
                $Arguments.Level -eq 1
            } -Exactly -Times 1
        }

        It 'Should pass timeout to Invoke-CimMethod as OperationTimeoutSec' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' -Timeout 120

                $result | Should -Not -BeNullOrEmpty
            }

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'TestMethod' -and
                $OperationTimeoutSec -eq 120
            } -Exactly -Times 1
        }

        It 'Should pass both arguments and timeout to Invoke-CimMethod' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'GenerateScript' -Arguments @{ DatabaseName = 'ReportServer' } -Timeout 240

                $result | Should -Not -BeNullOrEmpty
            }

            Should -Invoke -CommandName Invoke-CimMethod -ParameterFilter {
                $MethodName -eq 'GenerateScript' -and
                $Arguments.DatabaseName -eq 'ReportServer' -and
                $OperationTimeoutSec -eq 240
            } -Exactly -Times 1
        }
    }

    Context 'When CIM method returns a result with properties' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT     = 0
                    Application = @('ReportServerWebService', 'ReportServerWebApp')
                    UrlString   = @('http://+:80/ReportServer', 'http://+:80/Reports')
                }
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should return the full result object' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'ListReservedUrls'

                $result | Should -Not -BeNullOrEmpty
                $result.Application | Should -HaveCount 2
                $result.Application[0] | Should -Be 'ReportServerWebService'
                $result.UrlString[0] | Should -Be 'http://+:80/ReportServer'
            }
        }
    }

    Context 'When CIM method succeeds after retry' {
        BeforeAll {
            $script:invokeCimMethodCallCount = 0

            Mock -CommandName Invoke-CimMethod -MockWith {
                $script:invokeCimMethodCallCount++

                if ($script:invokeCimMethodCallCount -lt 3)
                {
                    return [PSCustomObject] @{
                        HRESULT = 1
                        Error   = 'Temporary failure'
                    }
                }

                return [PSCustomObject] @{
                    HRESULT = 0
                }
            }

            Mock -CommandName Start-Sleep
        }

        BeforeEach {
            $script:invokeCimMethodCallCount = 0
        }

        It 'Should succeed after retrying' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $result = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod'

                $result | Should -Not -BeNullOrEmpty
                $result.HRESULT | Should -Be 0
            }

            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 3
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 2
        }

        It 'Should use default delay of 30 seconds between retries' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $null = Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod'
            }

            Should -Invoke -CommandName Start-Sleep -ParameterFilter {
                $Seconds -eq 30
            } -Exactly -Times 2
        }
    }

    Context 'When CIM method fails with ExtendedErrors and all retries exhausted' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                $result = [PSCustomObject] @{
                    HRESULT = 1
                }
                $result | Add-Member -MemberType NoteProperty -Name 'ExtendedErrors' -Value @('Extended error message')
                return $result
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should throw with extended error message after all retries' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*TestMethod*HRESULT: 1*Extended error message*'
            }

            # 1 initial + 2 retries = 3 attempts
            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 3
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 2
        }
    }

    Context 'When CIM method fails with Error property and all retries exhausted' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 2
                    Error   = 'Error property message'
                }
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should throw with error property message after all retries' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*TestMethod*HRESULT: 2*Error property message*'
            }
        }
    }

    Context 'When CIM method fails with empty ExtendedErrors but has Error property' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                $result = [PSCustomObject] @{
                    HRESULT = 3
                    Error   = 'Fallback error message'
                }
                $result | Add-Member -MemberType NoteProperty -Name 'ExtendedErrors' -Value @()
                return $result
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should fall back to Error property message' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*TestMethod*HRESULT: 3*Fallback error message*'
            }
        }
    }

    Context 'When CIM method fails with no error details available' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                $result = [PSCustomObject] @{
                    HRESULT = 4
                    Error   = ''
                }
                $result | Add-Member -MemberType NoteProperty -Name 'ExtendedErrors' -Value @()
                return $result
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should use fallback message when neither ExtendedErrors nor Error have content' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*TestMethod*HRESULT: 4*No error details were returned*'
            }
        }
    }

    Context 'When Invoke-CimMethod throws an exception' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                throw [System.InvalidOperationException]::new('Connection failure')
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should throw immediately without retrying' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' } |
                    Should -Throw -ExpectedMessage '*Connection failure*'
            }

            # Only 1 attempt - exceptions are not retried
            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0
        }
    }

    Context 'When SkipRetry is specified' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 1
                    Error   = 'Single attempt failure'
                }
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should only attempt once and not retry' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' -SkipRetry } |
                    Should -Throw -ExpectedMessage '*TestMethod*Single attempt failure*'
            }

            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0
        }
    }

    Context 'When custom RetryCount and RetryDelaySeconds are specified' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 1
                    Error   = 'Failure'
                }
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should use custom retry count' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' -RetryCount 5 } |
                    Should -Throw
            }

            # 1 initial + 5 retries = 6 attempts
            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 6
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 5
        }

        It 'Should use custom delay between retries' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' -RetryDelaySeconds 60 -RetryCount 2 } |
                    Should -Throw
            }

            # 1 initial + 2 retries = 3 attempts with 2 sleeps
            Should -Invoke -CommandName Start-Sleep -ParameterFilter {
                $Seconds -eq 60
            } -Exactly -Times 2
        }
    }

    Context 'When RetryCount is 0' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 1
                    Error   = 'No retry failure'
                }
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should only attempt once like SkipRetry' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                { Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' -RetryCount 0 } |
                    Should -Throw -ExpectedMessage '*TestMethod*No retry failure*'
            }

            Should -Invoke -CommandName Invoke-CimMethod -Exactly -Times 1
            Should -Invoke -CommandName Start-Sleep -Exactly -Times 0
        }
    }

    Context 'When different errors occur across retries' {
        BeforeAll {
            $script:invokeCimMethodCallCount = 0

            Mock -CommandName Invoke-CimMethod -MockWith {
                $script:invokeCimMethodCallCount++

                switch ($script:invokeCimMethodCallCount)
                {
                    1
                    {
                        return [PSCustomObject] @{
                            HRESULT = 1
                            Error   = 'First error'
                        }
                    }
                    2
                    {
                        return [PSCustomObject] @{
                            HRESULT = 2
                            Error   = 'Second error'
                        }
                    }
                    3
                    {
                        return [PSCustomObject] @{
                            HRESULT = 3
                            Error   = 'Third error'
                        }
                    }
                    default
                    {
                        return [PSCustomObject] @{
                            HRESULT = 4
                            Error   = 'Fourth error'
                        }
                    }
                }
            }

            Mock -CommandName Start-Sleep
        }

        BeforeEach {
            $script:invokeCimMethodCallCount = 0
        }

        It 'Should collect all unique errors in the final error message' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $errorThrown = $null

                try
                {
                    # Use RetryCount 3 to get 4 total attempts (1 initial + 3 retries)
                    Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod' -RetryCount 3
                }
                catch
                {
                    $errorThrown = $_.Exception.Message
                }

                $errorThrown | Should -Not -BeNullOrEmpty
                $errorThrown | Should -BeLike '*Attempt 1:*First error*'
                $errorThrown | Should -BeLike '*Attempt 2:*Second error*'
                $errorThrown | Should -BeLike '*Attempt 3:*Third error*'
                $errorThrown | Should -BeLike '*Attempt 4:*Fourth error*'
            }
        }
    }

    Context 'When same error repeats across retries' {
        BeforeAll {
            Mock -CommandName Invoke-CimMethod -MockWith {
                return [PSCustomObject] @{
                    HRESULT = 1
                    Error   = 'Same error'
                }
            }

            Mock -CommandName Start-Sleep
        }

        It 'Should only include unique error once in the final error message' {
            InModuleScope -ScriptBlock {
                $mockCimInstance = [PSCustomObject] @{
                    InstanceName = 'SSRS'
                }

                $errorThrown = $null

                try
                {
                    Invoke-RsCimMethod -CimInstance $mockCimInstance -MethodName 'TestMethod'
                }
                catch
                {
                    $errorThrown = $_.Exception.Message
                }

                $errorThrown | Should -Not -BeNullOrEmpty

                # With default RetryCount=2, we have 3 attempts but same error should only appear once
                $errorThrown | Should -BeLike '*Attempt 1:*Same error*'
                $errorThrown | Should -Not -BeLike '*Attempt 2:*'
                $errorThrown | Should -Not -BeLike '*Attempt 3:*'
            }
        }
    }
}
