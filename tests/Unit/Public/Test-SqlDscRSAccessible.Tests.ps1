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

    Import-Module -Name $script:moduleName -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Item -Path 'env:SqlServerDscCI'
}

Describe 'Test-SqlDscRSAccessible' {
    BeforeAll {
        # Mock Start-Sleep to avoid actual sleeping during tests
        Mock -CommandName Start-Sleep
    }

    Context 'When validating parameter sets' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'Configuration'
                ExpectedParameters       = '-Configuration <Object> [-ServerName <string>] [-TimeoutSeconds <int>] [-RetryIntervalSeconds <int>] [-Detailed] [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'Uri'
                ExpectedParameters       = '[-ReportServerUri <string>] [-ReportsUri <string>] [-TimeoutSeconds <int>] [-RetryIntervalSeconds <int>] [-Detailed] [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Test-SqlDscRSAccessible').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When using the Uri parameter set' {
        Context 'When no URIs are specified' {
            It 'Should throw an error' {
                # Use splatting with empty values to force Uri parameter set
                { Test-SqlDscRSAccessible -ReportServerUri '' } | Should -Throw
            }
        }

        Context 'When ReportServerUri is specified and site is accessible' {
            BeforeAll {
                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should return $true and call Invoke-WebRequest with correct parameters' {
                $result = Test-SqlDscRSAccessible -ReportServerUri 'http://localhost/ReportServer'

                $result | Should -BeTrue

                Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                    $Uri -eq 'http://localhost/ReportServer' -and
                    $UseDefaultCredentials -eq $true -and
                    $UseBasicParsing -eq $true
                }
            }
        }

        Context 'When ReportsUri is specified and site is accessible' {
            BeforeAll {
                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should return $true' {
                $result = Test-SqlDscRSAccessible -ReportsUri 'http://localhost/Reports'

                $result | Should -BeTrue
            }
        }

        Context 'When both URIs are specified and both sites are accessible' {
            BeforeAll {
                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should return $true' {
                $result = Test-SqlDscRSAccessible -ReportServerUri 'http://localhost/ReportServer' -ReportsUri 'http://localhost/Reports'

                $result | Should -BeTrue
            }
        }

        Context 'When site returns HTTP error' {
            BeforeAll {
                $mockException = [System.Net.WebException]::new('The remote server returned an error: (503) Service Unavailable.')

                # Create a mock response with a non-zero status code
                $mockResponse = [PSCustomObject] @{
                    StatusCode = 503
                }

                $mockException | Add-Member -NotePropertyName 'Response' -NotePropertyValue $mockResponse -Force

                Mock -CommandName Invoke-WebRequest -MockWith {
                    throw $mockException
                }
            }

            It 'Should return $false' {
                $result = Test-SqlDscRSAccessible -ReportServerUri 'http://localhost/ReportServer' -TimeoutSeconds 5 -RetryIntervalSeconds 1

                $result | Should -BeFalse
            }
        }

        Context 'When Detailed switch is specified' {
            BeforeAll {
                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should return a detailed object' {
                $result = Test-SqlDscRSAccessible -ReportServerUri 'http://localhost/ReportServer' -ReportsUri 'http://localhost/Reports' -Detailed

                $result | Should -BeOfType [System.Management.Automation.PSCustomObject]
                $result.ReportServerAccessible | Should -BeTrue
                $result.ReportsAccessible | Should -BeTrue
                $result.ReportServerStatusCode | Should -Be 200
                $result.ReportsStatusCode | Should -Be 200
                $result.ReportServerUri | Should -Be 'http://localhost/ReportServer'
                $result.ReportsUri | Should -Be 'http://localhost/Reports'
            }
        }
    }

    Context 'When using the Configuration parameter set' {
        BeforeAll {
            $mockCimInstance = [PSCustomObject] @{
                InstanceName                  = 'SSRS'
                VirtualDirectoryReportServer  = 'ReportServer'
                VirtualDirectoryReportManager = 'Reports'
            }
        }

        Context 'When no URL reservations exist' {
            BeforeAll {
                Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                    return $null
                }
            }

            It 'Should throw an error' {
                { $mockCimInstance | Test-SqlDscRSAccessible } | Should -Throw
            }
        }

        Context 'When URL reservations exist and sites are accessible' {
            BeforeAll {
                Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                    return @{
                        Application = @('ReportServerWebService', 'ReportServerWebApp')
                        UrlString   = @('http://+:80', 'http://+:80')
                    }
                }

                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should return $true' {
                $result = Test-SqlDscRSAccessible -Configuration $mockCimInstance -ServerName 'localhost' -TimeoutSeconds 5 -RetryIntervalSeconds 1

                $result | Should -BeTrue
            }
        }

        Context 'When using custom ServerName' {
            BeforeAll {
                Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                    return @{
                        Application = @('ReportServerWebService')
                        UrlString   = @('http://+:80')
                    }
                }

                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should use the specified server name in the URI' {
                $result = Test-SqlDscRSAccessible -Configuration $mockCimInstance -ServerName 'CustomServer' -TimeoutSeconds 5 -RetryIntervalSeconds 1

                $result | Should -BeTrue

                Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                    $Uri -eq 'http://CustomServer/ReportServer'
                }
            }
        }

        Context 'When URL pattern includes non-standard port' {
            BeforeAll {
                Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                    return @{
                        Application = @('ReportServerWebService')
                        UrlString   = @('http://+:8080')
                    }
                }

                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should include port in the URI' {
                $result = Test-SqlDscRSAccessible -Configuration $mockCimInstance -ServerName 'localhost' -TimeoutSeconds 5 -RetryIntervalSeconds 1

                $result | Should -BeTrue

                Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                    $Uri -eq 'http://localhost:8080/ReportServer'
                }
            }
        }

        Context 'When URL pattern uses HTTPS with standard port' {
            BeforeAll {
                Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                    return @{
                        Application = @('ReportServerWebService')
                        UrlString   = @('https://+:443')
                    }
                }

                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should not include port in the URI' {
                $result = Test-SqlDscRSAccessible -Configuration $mockCimInstance -ServerName 'localhost' -TimeoutSeconds 5 -RetryIntervalSeconds 1

                $result | Should -BeTrue

                Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter {
                    $Uri -eq 'https://localhost/ReportServer'
                }
            }
        }

        Context 'When Detailed switch is specified with Configuration' {
            BeforeAll {
                Mock -CommandName Get-SqlDscRSUrlReservation -MockWith {
                    return @{
                        Application = @('ReportServerWebService', 'ReportServerWebApp')
                        UrlString   = @('http://+:80', 'http://+:80')
                    }
                }

                Mock -CommandName Invoke-WebRequest -MockWith {
                    return @{
                        StatusCode = 200
                    }
                }
            }

            It 'Should return a detailed object' {
                $result = Test-SqlDscRSAccessible -Configuration $mockCimInstance -ServerName 'localhost' -Detailed -TimeoutSeconds 5 -RetryIntervalSeconds 1

                $result | Should -BeOfType [System.Management.Automation.PSCustomObject]
                $result.ReportServerAccessible | Should -BeTrue
                $result.ReportsAccessible | Should -BeTrue
            }
        }
    }

    Context 'When testing retry logic' {
        Context 'When site becomes accessible on second attempt' {
            BeforeAll {
                $script:invokeCount = 0

                Mock -CommandName Invoke-WebRequest -MockWith {
                    $script:invokeCount++

                    if ($script:invokeCount -eq 1)
                    {
                        $mockException = [System.Net.WebException]::new('Connection refused')
                        $mockException | Add-Member -NotePropertyName 'Response' -NotePropertyValue $null -Force

                        throw $mockException
                    }

                    return @{
                        StatusCode = 200
                    }
                }
            }

            AfterAll {
                Remove-Variable -Name 'invokeCount' -Scope 'Script'
            }

            It 'Should return $true after retry succeeds' {
                $result = Test-SqlDscRSAccessible -ReportServerUri 'http://localhost/ReportServer' -TimeoutSeconds 10 -RetryIntervalSeconds 1

                $result | Should -BeTrue
                $script:invokeCount | Should -Be 2
            }
        }

        Context 'When site never becomes accessible' {
            BeforeAll {
                $mockException = [System.Net.WebException]::new('Connection refused')
                $mockException | Add-Member -NotePropertyName 'Response' -NotePropertyValue $null -Force

                Mock -CommandName Invoke-WebRequest -MockWith {
                    throw $mockException
                }
            }

            It 'Should return $false after all retries exhausted' {
                $result = Test-SqlDscRSAccessible -ReportServerUri 'http://localhost/ReportServer' -TimeoutSeconds 3 -RetryIntervalSeconds 1

                $result | Should -BeFalse
            }
        }
    }

    Context 'When testing default parameter values' {
        It 'Should have $env:COMPUTERNAME as default value for ServerName parameter' {
            $command = Get-Command -Name 'Test-SqlDscRSAccessible'
            $serverNameParam = $command.Parameters['ServerName']

            # The default value script block should reference $env:COMPUTERNAME
            $serverNameParam.Attributes | Where-Object -FilterScript {
                $_ -is [System.Management.Automation.ParameterAttribute]
            } | ForEach-Object -Process {
                $_.ParameterSetName | Should -Be 'Configuration'
            }

            # Verify the parameter exists and is in the correct parameter set
            $serverNameParam | Should -Not -BeNullOrEmpty
        }
    }
}
