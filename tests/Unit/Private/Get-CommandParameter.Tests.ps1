BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
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

    # Do not use -Force. Doing so, or unloading the module in AfterAll, causes
    # PowerShell class types to get new identities, breaking type comparisons.
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

Describe 'Get-CommandParameter' -Tag 'Private' {
    Context 'When getting command parameters' {
        It 'Should return all parameters excluding common parameters when no exclude list is provided' {
            InModuleScope -ScriptBlock {
                function Test-Function
                {
                    [CmdletBinding()]
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $RequiredParam,

                        [Parameter()]
                        [System.String]
                        $OptionalParam1,

                        [Parameter()]
                        [System.String]
                        $OptionalParam2,

                        [Parameter()]
                        [System.Management.Automation.SwitchParameter]
                        $PassThru,

                        [Parameter()]
                        [System.Management.Automation.SwitchParameter]
                        $Force
                    )
                }

                $commandInfo = Get-Command Test-Function
                $result = Get-CommandParameter -Command $commandInfo

                $result | Should -Contain 'RequiredParam'
                $result | Should -Contain 'OptionalParam1'
                $result | Should -Contain 'OptionalParam2'
                $result | Should -Contain 'PassThru'
                $result | Should -Contain 'Force'
                $result | Should -Not -Contain 'Verbose'
                $result | Should -Not -Contain 'Debug'
                $result | Should -Not -Contain 'ErrorAction'
            }
        }

        It 'Should exclude specified parameters and common parameters' {
            InModuleScope -ScriptBlock {
                function Test-Function
                {
                    [CmdletBinding()]
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $RequiredParam,

                        [Parameter()]
                        [System.String]
                        $OptionalParam1,

                        [Parameter()]
                        [System.String]
                        $OptionalParam2,

                        [Parameter()]
                        [System.Management.Automation.SwitchParameter]
                        $PassThru,

                        [Parameter()]
                        [System.Management.Automation.SwitchParameter]
                        $Force
                    )
                }

                $commandInfo = Get-Command Test-Function
                $result = Get-CommandParameter -Command $commandInfo -Exclude @('RequiredParam', 'PassThru', 'Force')

                $result | Should -Not -Contain 'RequiredParam'
                $result | Should -Contain 'OptionalParam1'
                $result | Should -Contain 'OptionalParam2'
                $result | Should -Not -Contain 'PassThru'
                $result | Should -Not -Contain 'Force'
                $result | Should -Not -Contain 'Verbose'
                $result | Should -Not -Contain 'Debug'
            }
        }

        It 'Should return empty array when all parameters are excluded' {
            InModuleScope -ScriptBlock {
                function Test-Function
                {
                    [CmdletBinding()]
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $RequiredParam,

                        [Parameter()]
                        [System.String]
                        $OptionalParam1,

                        [Parameter()]
                        [System.String]
                        $OptionalParam2,

                        [Parameter()]
                        [System.Management.Automation.SwitchParameter]
                        $PassThru,

                        [Parameter()]
                        [System.Management.Automation.SwitchParameter]
                        $Force
                    )
                }

                $commandInfo = Get-Command Test-Function
                $result = Get-CommandParameter -Command $commandInfo -Exclude @('RequiredParam', 'OptionalParam1', 'OptionalParam2', 'PassThru', 'Force')

                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should handle empty parameter hashtable' {
            InModuleScope -ScriptBlock {
                # Create a mock function with no parameters
                function Test-EmptyFunction { }
                $commandInfo = Get-Command Test-EmptyFunction
                $result = Get-CommandParameter -Command $commandInfo

                $result | Should -BeNullOrEmpty
            }
        }
    }
}
