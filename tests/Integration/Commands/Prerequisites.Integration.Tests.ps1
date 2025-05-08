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
}

# CSpell: ignore Remoting
Describe 'Prerequisites' {
    Context 'Create required local Windows users' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        BeforeAll {
            $password = ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force
        }

        It 'Should create SqlInstall user' {
            $user = New-LocalUser -Name 'SqlInstall' -Password $password -FullName 'SQL Install User' -Description 'User for SQL installation.'

            $user.Name | Should -Be 'SqlInstall'
            (Get-LocalUser -Name 'SqlInstall').Name | Should -Be 'SqlInstall'
        }

        It 'Should create SqlAdmin user' {
            $user = New-LocalUser -Name 'SqlAdmin' -Password $password -FullName 'SQL Admin User' -Description 'User for SQL administration.'

            $user.Name | Should -Be 'SqlAdmin'
            (Get-LocalUser -Name 'SqlAdmin').Name | Should -Be 'SqlAdmin'
        }

        It 'Should create SqlIntegrationTest user' {
            $user = New-LocalUser -Name 'SqlIntegrationTest' -Password $password -FullName 'SQL Integration Test User' -Description 'User for SQL integration testing.'

            $user.Name | Should -Be 'SqlIntegrationTest'
            (Get-LocalUser -Name 'SqlIntegrationTest').Name | Should -Be 'SqlIntegrationTest'
        }
    }

    Context 'Should create required local Windows service accounts' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        BeforeAll {
            $password = ConvertTo-SecureString -String 'yig-C^Equ3' -AsPlainText -Force
        }

        It 'Should create svc-SqlPrimary user' {
            $user = New-LocalUser -Name 'svc-SqlPrimary' -Password $password -FullName 'svc-SqlPrimary' -Description 'Runs the SQL Server service.'

            $user.Name | Should -Be 'svc-SqlPrimary'
            (Get-LocalUser -Name 'svc-SqlPrimary').Name | Should -Be 'svc-SqlPrimary'
        }

        It 'Should create svc-SqlAgentPri user' {
            $user = New-LocalUser -Name 'svc-SqlAgentPri' -Password $password -FullName 'svc-SqlAgentPri' -Description 'Runs the SQL Server Agent service.'

            $user.Name | Should -Be 'svc-SqlAgentPri'
            (Get-LocalUser -Name 'svc-SqlAgentPri').Name | Should -Be 'svc-SqlAgentPri'
        }

        It 'Should create svc-SqlSecondary user' {
            $user = New-LocalUser -Name 'svc-SqlSecondary' -Password $password -FullName 'svc-SqlSecondary' -Description 'Runs the SQL Server service.'

            $user.Name | Should -Be 'svc-SqlSecondary'
            (Get-LocalUser -Name 'svc-SqlSecondary').Name | Should -Be 'svc-SqlSecondary'
        }

        It 'Should create svc-SqlAgentSec user' {
            $user = New-LocalUser -Name 'svc-SqlAgentSec' -Password $password -FullName 'svc-SqlAgentSec' -Description 'Runs the SQL Server Agent service.'

            $user.Name | Should -Be 'svc-SqlAgentSec'
            (Get-LocalUser -Name 'svc-SqlAgentSec').Name | Should -Be 'svc-SqlAgentSec'
        }

        It 'Should create svc-RS user' -Tag @('Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
            $user = New-LocalUser -Name 'svc-RS' -Password $password -FullName 'svc-RS' -Description 'Runs the Reporting Services service.'

            $user.Name | Should -Be 'svc-RS'
            (Get-LocalUser -Name 'svc-RS').Name | Should -Be 'svc-RS'
        }
    }

    Context 'Create required local Windows groups' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should create SqlIntegrationTestGroup group' {
            $group = New-LocalGroup -Name 'SqlIntegrationTestGroup' -Description 'Local Windows group for SQL integration testing.'

            $group.Name | Should -Be 'SqlIntegrationTestGroup'
            (Get-LocalGroup -Name 'SqlIntegrationTestGroup').Name | Should -Be 'SqlIntegrationTestGroup'
        }
    }

    Context 'Add local Windows users to local groups' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI') {
        It 'Should add SqlInstall to local administrator group' {
            # Add user to local administrator group
            Add-LocalGroupMember -Group 'Administrators' -Member 'SqlInstall'

            # Verify if user is part of local administrator group
            $adminGroup = Get-LocalGroup -Name 'Administrators'
            $adminGroupMembers = Get-LocalGroupMember -Group $adminGroup
            $adminGroupMembers.Name | Should -Contain ('{0}\SqlInstall' -f (Get-ComputerName))
        }

        It 'Should add SqlIntegrationTest to SqlIntegrationTestGroup group' {
            # Add user to the local group
            Add-LocalGroupMember -Group 'SqlIntegrationTestGroup' -Member 'SqlIntegrationTest'

            # Verify if user is part of the local group
            $testGroup = Get-LocalGroup -Name 'SqlIntegrationTestGroup'
            $testGroupMembers = Get-LocalGroupMember -Group $testGroup
            $testGroupMembers.Name | Should -Contain ('{0}\SqlIntegrationTest' -f (Get-ComputerName))
        }
    }

    Context 'Download correct SQL Server media' {
        It 'Should download SQL Server 2016 media' -Tag @('Integration_SQL2016') {
            $url = 'https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SQLServer2016SP1-FullSlipstream-x64-ENU.iso'

            $script:mediaFile = Save-SqlDscSqlServerMediaFile -Url $url -DestinationPath $env:TEMP -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'media.iso'
        }

        It 'Should download SQL Server 2017 media' -Tag @('Integration_SQL2017', 'Integration_SQL2017_RS') {
            $url = 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU.iso'

            $script:mediaFile = Save-SqlDscSqlServerMediaFile -Url $url -DestinationPath $env:TEMP -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'media.iso'
        }

        It 'Should download SQL Server 2019 media' -Tag @('Integration_SQL2019', 'Integration_SQL2019_RS') {
            $url = 'https://download.microsoft.com/download/d/a/2/da259851-b941-459d-989c-54a18a5d44dd/SQL2019-SSEI-Dev.exe'

            $script:mediaFile = Save-SqlDscSqlServerMediaFile -Url $url -DestinationPath $env:TEMP -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'media.iso'
        }

        It 'Should download SQL Server 2022 media' -Tag @('Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2022_RS') {
            $url = 'https://download.microsoft.com/download/c/c/9/cc9c6797-383c-4b24-8920-dc057c1de9d3/SQL2022-SSEI-Dev.exe'

            $script:mediaFile = Save-SqlDscSqlServerMediaFile -Url $url -DestinationPath $env:TEMP -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'media.iso'
        }
    }

    Context 'Mount SQL Server media' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should mount the media to a drive letter' {
            $mountedImage = Mount-DiskImage -ImagePath $script:mediaFile
            $mountedImage | Should -BeOfType 'Microsoft.Management.Infrastructure.CimInstance'

            $mountedVolume = Get-Volume -DiskImage $mountedImage
            $mountedVolume.DriveLetter | Should -Not -BeNullOrEmpty

            $env:IsoDriveLetter = $mountedVolume.DriveLetter
            $env:IsoDriveLetter | Should -Not -BeNullOrEmpty

            $env:IsoDrivePath = (Get-PSDrive -Name $env:IsoDriveLetter).Root
            $env:IsoDrivePath | Should -Be ('{0}:\' -f $env:IsoDriveLetter)
        }

        It 'Should have set environment variable for drive letter' {
            $env:IsoDriveLetter | Should -Not -BeNullOrEmpty
        }

        It 'Should have set environment variable for drive path' {
            $env:IsoDrivePath | Should -Be ('{0}:\' -f $env:IsoDriveLetter)
        }
    }

    Context 'Install correct version of module SqlServer' {
        It 'Should have the minimum required version of Microsoft.PowerShell.PSResourceGet' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
            $module = Get-Module -Name 'Microsoft.PowerShell.PSResourceGet' -ListAvailable

            $module.Count | Should -BeGreaterOrEqual 1
            #$module.Version -ge '1.0.4.1' | Should -BeTrue
        }

        It 'Should have a resource repository PSGallery with correct URI' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
            $resourceRepository = Get-PSResourceRepository -Name 'PSGallery'

            $resourceRepository | Should -HaveCount 1
            $resourceRepository.Uri | Should -Be 'https://www.powershellgallery.com/api/v2'
        }

        It 'Should install SqlServer module version 21.1.18256' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019') {
            #Install-Module -Name 'SqlServer' -RequiredVersion '21.1.18256' -Force -ErrorAction 'Stop'
            $module = Install-PSResource -Name 'SqlServer' -Version '21.1.18256' -Scope 'AllUsers' -TrustRepository -ErrorAction 'Stop' -Confirm:$false -PassThru

            $module | Should -HaveCount 1
            $module.Version -eq '21.1.18256' | Should -BeTrue
        }

        It 'Should have SqlServer module version 21.1.18256 available' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019') {
            $module = Get-Module -Name 'SqlServer' -ListAvailable

            $module | Should -HaveCount 1
            $module.Version -eq '21.1.18256' | Should -BeTrue
        }

        It 'Should install SqlServer module version 22.2.0' -Tag @('Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
            #Install-Module -Name 'SqlServer' -RequiredVersion '22.2.0' -Force -ErrorAction 'Stop'
            $module = Install-PSResource -Name 'SqlServer' -Version '22.2.0' -Scope 'AllUsers' -TrustRepository -ErrorAction 'Stop' -Confirm:$false -PassThru

            $module | Should -HaveCount 1
            $module.Version -eq '22.2.0' | Should -BeTrue
        }

        It 'Should have SqlServer module version 22.2.0 available' -Tag @('Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
            $module = Get-Module -Name 'SqlServer' -ListAvailable

            $module | Should -HaveCount 1
            $module.Version -eq '22.2.0' | Should -BeTrue
        }
    }

    Context 'Test PS Remoting to localhost' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022', 'Integration_PowerBI', 'Integration_SQL2017_RS', 'Integration_SQL2019_RS', 'Integration_SQL2022_RS') {
        It 'Should successfully run a command on localhost using PS Remoting' {
            # This is a simple test to verify that PS Remoting is working.
            # TODO: This fails on Appveyor, but works locally when debugging on AppVeyor. Investigate why.
            $result = Invoke-Command -ComputerName 'localhost' -ScriptBlock { 1 } -ErrorAction 'Stop'

            $result | Should -Be 1
        }
    }

    Context 'Download correct SQL Server 2017 Reporting Services installation executable' {
        It 'Should download SQL Server 2017 Reporting Services installation executable' -Tag @('Integration_SQL2017_RS') {
            # Microsoft SQL Server 2017 Reporting Services (14.0.601.20 - 2023-02-14) - https://www.microsoft.com/en-us/download/details.aspx?id=55252
            $url = 'https://download.microsoft.com/download/e/6/4/e6477a2a-9b58-40f7-8ad6-62bb8491ea78/SQLServerReportingServices.exe'

            # Put the executable in a temporary folder that can be accessed by other tests
            $script:mediaFile = Save-SqlDscSqlServerMediaFile -SkipExecution -Url $url -FileName 'SQLServerReportingServices.exe' -DestinationPath (Get-TemporaryFolder) -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'SQLServerReportingServices.exe'
        }
    }

    Context 'Download correct SQL Server 2019 Reporting Services installation executable' {
        It 'Should download SQL Server 2019 Reporting Services installation executable' -Tag @('Integration_SQL2019_RS') {
            # Microsoft SQL Server 2017 Reporting Services (15.0.1103.41 - 2025-01-06) - https://www.microsoft.com/en-us/download/details.aspx?id=100122
            $url = 'https://download.microsoft.com/download/1/a/a/1aaa9177-3578-4931-b8f3-373b24f63342/SQLServerReportingServices.exe'

            # Put the executable in a temporary folder that can be accessed by other tests
            $script:mediaFile = Save-SqlDscSqlServerMediaFile -SkipExecution -Url $url -FileName 'SQLServerReportingServices.exe' -DestinationPath (Get-TemporaryFolder) -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'SQLServerReportingServices.exe'
        }
    }

    Context 'Download correct SQL Server 2022 Reporting Services installation executable' {
        It 'Should download SQL Server 2022 Reporting Services installation executable' -Tag @('Integration_SQL2022_RS') {
            # Microsoft SQL Server 2017 Reporting Services (16.0.1116.38 - 2025-01-06) - https://www.microsoft.com/en-us/download/details.aspx?id=104502
            $url = 'https://download.microsoft.com/download/8/3/2/832616ff-af64-42b5-a0b1-5eb07f71dec9/SQLServerReportingServices.exe'

            # Put the executable in a temporary folder that can be accessed by other tests
            $script:mediaFile = Save-SqlDscSqlServerMediaFile -SkipExecution -Url $url -FileName 'SQLServerReportingServices.exe' -DestinationPath (Get-TemporaryFolder) -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'SQLServerReportingServices.exe'
        }
    }

    Context 'Download correct Power BI Report Server installation executable' {
        # This should always use the latest version of Power BI Report Server, and use the latest tag used in pipeline.
        It 'Should download Power BI Report Server installation executable' -Tag @('Integration_PowerBI') {
            # https://sqlserverbuilds.blogspot.com/2021/04/power-bi-report-server-versions.html
            # 15.0.1117.98 - 2025-01-22
            $url = 'https://download.microsoft.com/download/2/7/3/2739a88a-4769-4700-8748-1a01ddf60974/PowerBIReportServer.exe'

            # Put the executable in a temporary folder that can be accessed by other tests
            $script:mediaFile = Save-SqlDscSqlServerMediaFile -SkipExecution -Url $url -FileName 'PowerBIReportServer.exe' -DestinationPath (Get-TemporaryFolder) -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'PowerBIReportServer.exe'
        }
    }
}
