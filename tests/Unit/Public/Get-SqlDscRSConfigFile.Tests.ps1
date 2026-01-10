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

# cSpell:ignore MSRS NTLM
Describe 'Get-SqlDscRSConfigFile' {
    Context 'When parameter validation' {
        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach @(
            @{
                ExpectedParameterSetName = 'ByInstanceName'
                ExpectedParameters = '-InstanceName <string> [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ByConfiguration'
                ExpectedParameters = '-SetupConfiguration <Object> [<CommonParameters>]'
            }
            @{
                ExpectedParameterSetName = 'ByPath'
                ExpectedParameters = '-Path <string> [<CommonParameters>]'
            }
        ) {
            $result = (Get-Command -Name 'Get-SqlDscRSConfigFile').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )

            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }

        It 'Should have ByInstanceName as the default parameter set' {
            $command = Get-Command -Name 'Get-SqlDscRSConfigFile'

            $command.DefaultParameterSet | Should -Be 'ByInstanceName'
        }

        It 'Should have InstanceName as a mandatory parameter in the ByInstanceName parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSConfigFile').Parameters['InstanceName']

            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'ByInstanceName'}).Mandatory | Should -BeTrue
        }

        It 'Should have SetupConfiguration as a mandatory parameter in the ByConfiguration parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSConfigFile').Parameters['SetupConfiguration']

            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'ByConfiguration'}).Mandatory | Should -BeTrue
        }

        It 'Should accept SetupConfiguration parameter from pipeline' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSConfigFile').Parameters['SetupConfiguration']

            $parameterInfo.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have Path as a mandatory parameter in the ByPath parameter set' {
            $parameterInfo = (Get-Command -Name 'Get-SqlDscRSConfigFile').Parameters['Path']

            $parameterInfo.Attributes.Where({$_.ParameterSetName -eq 'ByPath'}).Mandatory | Should -BeTrue
        }
    }

    Context 'When using InstanceName parameter and the instance is found' {
        BeforeAll {
            $mockConfigFilePath = 'C:\Program Files\SSRS\SSRS\ReportServer\RSReportServer.config'
            $mockConfigXmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
    <Dsn>TestDsn</Dsn>
    <ConnectionType>Default</ConnectionType>
    <InstanceId>MSRS13.SSRS</InstanceId>
    <Service>
        <IsSchedulingService>True</IsSchedulingService>
        <IsNotificationService>True</IsNotificationService>
    </Service>
    <Authentication>
        <AuthenticationTypes>
            <RSWindowsNTLM/>
        </AuthenticationTypes>
    </Authentication>
</Configuration>
'@

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName   = 'SSRS'
                    InstallFolder  = 'C:\Program Files\SSRS'
                    ConfigFilePath = $mockConfigFilePath
                    ServiceName    = 'SQLServerReportingServices'
                }
            }

            Mock -CommandName Get-Content -MockWith {
                return $mockConfigXmlContent
            }
        }

        It 'Should return the configuration file as an XML object' {
            $result = Get-SqlDscRSConfigFile -InstanceName 'SSRS'

            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration | Should -Not -BeNullOrEmpty
            $result.Configuration.Dsn | Should -Be 'TestDsn'
            $result.Configuration.InstanceId | Should -Be 'MSRS13.SSRS'

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Content -Exactly -Times 1 -Scope It
        }

        It 'Should allow accessing nested XML elements' {
            $result = Get-SqlDscRSConfigFile -InstanceName 'SSRS'

            $result.Configuration.Service.IsSchedulingService | Should -Be 'True'
            # Self-closing XML elements exist as empty string, so check with SelectSingleNode
            $result.SelectSingleNode('//Authentication/AuthenticationTypes/RSWindowsNTLM') | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When using InstanceName parameter and the instance is not found' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return $null
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfigFile -InstanceName 'NonExistent' } | Should -Throw -ErrorId 'GSRSCF0001*'

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using InstanceName parameter and the ConfigFilePath is empty' {
        BeforeAll {
            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName   = 'SSRS'
                    InstallFolder  = 'C:\Program Files\SSRS'
                    ConfigFilePath = $null
                    ServiceName    = 'SQLServerReportingServices'
                }
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfigFile -InstanceName 'SSRS' } | Should -Throw -ErrorId 'GSRSCF0002*'

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using InstanceName parameter and reading the file fails' {
        BeforeAll {
            $mockConfigFilePath = 'C:\Program Files\SSRS\SSRS\ReportServer\RSReportServer.config'

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName   = 'SSRS'
                    InstallFolder  = 'C:\Program Files\SSRS'
                    ConfigFilePath = $mockConfigFilePath
                    ServiceName    = 'SQLServerReportingServices'
                }
            }

            Mock -CommandName Get-Content -MockWith {
                throw 'Access denied'
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfigFile -InstanceName 'SSRS' } | Should -Throw -ErrorId 'GSRSCF0003*'

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using SetupConfiguration parameter via pipeline' {
        BeforeAll {
            $mockConfigFilePath = 'C:\Program Files\SSRS\SSRS\ReportServer\RSReportServer.config'
            $mockConfigXmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
    <Dsn>TestDsn</Dsn>
    <InstanceId>MSRS13.SSRS</InstanceId>
</Configuration>
'@

            $mockSetupConfiguration = [PSCustomObject]@{
                InstanceName   = 'SSRS'
                InstallFolder  = 'C:\Program Files\SSRS'
                ConfigFilePath = $mockConfigFilePath
                ServiceName    = 'SQLServerReportingServices'
            }

            Mock -CommandName Get-Content -MockWith {
                return $mockConfigXmlContent
            }
        }

        It 'Should return the configuration file for piped SetupConfiguration' {
            $result = $mockSetupConfiguration | Get-SqlDscRSConfigFile

            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration.Dsn | Should -Be 'TestDsn'

            Should -Invoke -CommandName Get-Content -Exactly -Times 1 -Scope It
        }

        It 'Should work with SetupConfiguration parameter passed directly' {
            $result = Get-SqlDscRSConfigFile -SetupConfiguration $mockSetupConfiguration

            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration.InstanceId | Should -Be 'MSRS13.SSRS'

            Should -Invoke -CommandName Get-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using SetupConfiguration parameter and ConfigFilePath is empty' {
        BeforeAll {
            $mockSetupConfiguration = [PSCustomObject]@{
                InstanceName   = 'SSRS'
                InstallFolder  = 'C:\Program Files\SSRS'
                ConfigFilePath = $null
                ServiceName    = 'SQLServerReportingServices'
            }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfigFile -SetupConfiguration $mockSetupConfiguration } | Should -Throw -ErrorId 'GSRSCF0002*'
        }
    }

    Context 'When using Path parameter and the file exists' {
        BeforeAll {
            $mockConfigFilePath = 'C:\Backup\RSReportServer.config'
            $mockConfigXmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
    <Dsn>BackupDsn</Dsn>
    <InstanceId>MSRS13.BACKUP</InstanceId>
</Configuration>
'@

            Mock -CommandName Test-Path -MockWith {
                return $true
            } -ParameterFilter { $Path -eq $mockConfigFilePath }

            Mock -CommandName Get-Content -MockWith {
                return $mockConfigXmlContent
            }
        }

        It 'Should return the configuration file from the specified path' {
            $result = Get-SqlDscRSConfigFile -Path $mockConfigFilePath

            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration.Dsn | Should -Be 'BackupDsn'
            $result.Configuration.InstanceId | Should -Be 'MSRS13.BACKUP'

            Should -Invoke -CommandName Test-Path -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using Path parameter and the file does not exist' {
        BeforeAll {
            $mockConfigFilePath = 'C:\NonExistent\RSReportServer.config'

            Mock -CommandName Test-Path -MockWith {
                return $false
            } -ParameterFilter { $Path -eq $mockConfigFilePath }
        }

        It 'Should throw a terminating error' {
            { Get-SqlDscRSConfigFile -Path $mockConfigFilePath } | Should -Throw -ErrorId 'GSRSCF0004*'

            Should -Invoke -CommandName Test-Path -Exactly -Times 1 -Scope It
        }
    }

    # cSpell: ignore PBIRS
    Context 'When getting configuration file for Power BI Report Server' {
        BeforeAll {
            $mockConfigFilePath = 'C:\Program Files\PBIRS\PBIRS\ReportServer\RSReportServer.config'
            $mockConfigXmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
    <Dsn>PBIRSDsn</Dsn>
    <InstanceId>PBIRS</InstanceId>
    <Service>
        <IsDataModelRefreshService>True</IsDataModelRefreshService>
    </Service>
</Configuration>
'@

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName   = 'PBIRS'
                    InstallFolder  = 'C:\Program Files\PBIRS'
                    ConfigFilePath = $mockConfigFilePath
                    ServiceName    = 'PowerBIReportServer'
                }
            }

            Mock -CommandName Get-Content -MockWith {
                return $mockConfigXmlContent
            }
        }

        It 'Should return the configuration file for PBIRS' {
            $result = Get-SqlDscRSConfigFile -InstanceName 'PBIRS'

            $result | Should -BeOfType 'System.Xml.XmlDocument'
            $result.Configuration.Dsn | Should -Be 'PBIRSDsn'
            $result.Configuration.InstanceId | Should -Be 'PBIRS'
            $result.Configuration.Service.IsDataModelRefreshService | Should -Be 'True'

            Should -Invoke -CommandName Get-SqlDscRSSetupConfiguration -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Get-Content -Exactly -Times 1 -Scope It
        }
    }

    Context 'When using XPath queries on the returned XML' {
        BeforeAll {
            $mockConfigFilePath = 'C:\Program Files\SSRS\SSRS\ReportServer\RSReportServer.config'
            $mockConfigXmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<Configuration>
    <Extensions>
        <Delivery>
            <Extension Name="Report Server FileShare" Type="Microsoft.ReportingServices.FileShareDeliveryProvider.FileShareProvider"/>
            <Extension Name="Report Server Email" Type="Microsoft.ReportingServices.EmailDeliveryProvider.EmailProvider"/>
        </Delivery>
        <Render>
            <Extension Name="PDF" Type="Microsoft.ReportingServices.Rendering.ImageRenderer.PDFRenderer"/>
            <Extension Name="EXCEL" Type="Microsoft.ReportingServices.Rendering.ExcelRenderer.ExcelRenderer"/>
        </Render>
    </Extensions>
</Configuration>
'@

            Mock -CommandName Get-SqlDscRSSetupConfiguration -MockWith {
                return [PSCustomObject]@{
                    InstanceName   = 'SSRS'
                    InstallFolder  = 'C:\Program Files\SSRS'
                    ConfigFilePath = $mockConfigFilePath
                    ServiceName    = 'SQLServerReportingServices'
                }
            }

            Mock -CommandName Get-Content -MockWith {
                return $mockConfigXmlContent
            }
        }

        It 'Should support SelectSingleNode XPath queries' {
            $result = Get-SqlDscRSConfigFile -InstanceName 'SSRS'

            $pdfExtension = $result.SelectSingleNode('//Extension[@Name="PDF"]')

            $pdfExtension | Should -Not -BeNullOrEmpty
            $pdfExtension.Name | Should -Be 'PDF'
        }

        It 'Should support SelectNodes XPath queries' {
            $result = Get-SqlDscRSConfigFile -InstanceName 'SSRS'

            $extensions = $result.SelectNodes('//Extension[@Name]')

            $extensions.Count | Should -Be 4
            ($extensions | ForEach-Object { $_.Name }) | Should -Contain 'PDF'
            ($extensions | ForEach-Object { $_.Name }) | Should -Contain 'Report Server Email'
        }
    }
}
