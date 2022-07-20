[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
}

Describe 'Get-DesiredStateProperty' -Tag 'Private' {
    BeforeAll {
        <#
            Must use a here-string because we need to pass 'using' which must be
            first in a scriptblock, but if it is outside the here-string then
            PowerShell will fail to parse the test script.
        #>
        $inModuleScopeScriptBlock = @'
class MyMockResource
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty()]
    [System.String]
    $MyResourceProperty3

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
$script:mockResourceBaseInstance.MyResourceKeyProperty1 = 'MockValue1'
$script:mockResourceBaseInstance.MyResourceProperty3 = 'MockValue3'
$script:mockResourceBaseInstance.MyResourceReadProperty = 'MockReadValue1'
'@

        InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
    }

    It 'Should return the correct value' {
        InModuleScope -ScriptBlock {
            $result = Get-DesiredStateProperty -InputObject $script:mockResourceBaseInstance

            $result | Should -BeOfType [System.Collections.Hashtable]

            $result.Keys | Should -Not -Contain 'MyResourceProperty2' -Because 'properties with $null values should not be part of the collection'
            $result.Keys | Should -Not -Contain 'MyResourceReadProperty' -Because 'read properties should not be part of the collection even if they have values'

            $result.Keys | Should -Contain 'MyResourceKeyProperty1' -Because 'the property was set to a value in the mocked class'
            $result.Keys | Should -Contain 'MyResourceProperty3' -Because 'the property was set to a value in the mocked class'

            $result.MyResourceKeyProperty1 | Should -Be 'MockValue1'
            $result.MyResourceProperty3 | Should -Be 'MockValue3'
        }
    }
}
