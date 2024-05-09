[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
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

Describe 'Prerequisites' -Tag @('Integration_SQL2016', 'Integration_SQL2017', 'Integration_SQL2019', 'Integration_SQL2022') {
    Context 'Create required local Windows users' {
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
    }

    Context 'Should create required local Windows service accounts' {
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
    }

    Context 'Add local Windows users to local groups' {
        It 'Should add SqlInstall to local administrator group' {
            # Add user to local administrator group
            Add-LocalGroupMember -Group 'Administrators' -Member 'SqlInstall'

            # Verify if user is part of local administrator group
            $adminGroup = Get-LocalGroup -Name 'Administrators'
            $adminGroupMembers = Get-LocalGroupMember -Group $adminGroup
            $adminGroupMembers.Name | Should -Contain ('{0}\SqlInstall' -f (Get-ComputerName))
        }
    }

    Context 'Download correct SQL Server media' {
        It 'Should download SQL Server 2016 media' -Tag @('Integration_SQL2016') {
            $url = 'https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SQLServer2016SP1-FullSlipstream-x64-ENU.iso'

            $mediaFile = Save-SqlDscSqlServerMedia -Url $url -DestinationPath $env:TEMP -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'media.iso'
        }

        It 'Should download SQL Server 2017 media' -Tag @('Integration_SQL2017') {
            $url = 'https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLServer2017-x64-ENU.iso'

            $mediaFile = Save-SqlDscSqlServerMedia -Url $url -DestinationPath $env:TEMP -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'media.iso'
        }

        It 'Should download SQL Server 2019 media' -Tag @('Integration_SQL2019') {
            $url = 'https://download.microsoft.com/download/d/a/2/da259851-b941-459d-989c-54a18a5d44dd/SQL2019-SSEI-Dev.exe'

            $mediaFile = Save-SqlDscSqlServerMedia -Url $url -DestinationPath $env:TEMP -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'media.iso'
        }

        It 'Should download SQL Server 2022 media' -Tag @('Integration_SQL2022') {
            $url = 'https://download.microsoft.com/download/c/c/9/cc9c6797-383c-4b24-8920-dc057c1de9d3/SQL2022-SSEI-Dev.exe'

            $mediaFile = Save-SqlDscSqlServerMedia -Url $url -DestinationPath $env:TEMP -Force -Quiet -ErrorAction 'Stop'

            $mediaFile.Name | Should -Be 'media.iso'
        }
    }
}
