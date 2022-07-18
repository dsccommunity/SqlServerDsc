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

Describe 'Get-DscProperty' -Tag 'Private' {
    Context 'When getting all DSC properties' {
        BeforeAll {
            <#
                Must use a here-string because we need to pass 'using' which must be
                first in a scriptblock, but if it is outside the here-string then
                PowerShell will fail to parse the test script.
            #>
            $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty2

    [DscProperty(Mandatory)]
    [System.String]
    $MyResourceMandatoryProperty

    [DscProperty()]
    [System.String]
    $MyResourceProperty

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
$script:mockResourceBaseInstance.MyResourceKeyProperty1 = 'MockValue1'
$script:mockResourceBaseInstance.MyResourceKeyProperty2 = 'MockValue2'
$script:mockResourceBaseInstance.MyResourceMandatoryProperty = 'MockValue3'
$script:mockResourceBaseInstance.MyResourceProperty = 'MockValue4'
'@

            InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
        }

        It 'Should return the correct value' {
            InModuleScope -ScriptBlock {
                $result = Get-DscProperty -InputObject $script:mockResourceBaseInstance

                $result | Should -BeOfType [System.Collections.Hashtable]

                $result.Keys | Should -HaveCount 5
                $result.Keys | Should -Contain 'MyResourceKeyProperty1'
                $result.Keys | Should -Contain 'MyResourceKeyProperty2'
                $result.Keys | Should -Contain 'MyResourceMandatoryProperty'
                $result.Keys | Should -Contain 'MyResourceProperty'
                $result.Keys | Should -Contain 'MyResourceReadProperty'

                $result.MyResourceKeyProperty1 | Should -Be 'MockValue1'
                $result.MyResourceKeyProperty2 | Should -Be 'MockValue2'
                $result.MyResourceMandatoryProperty | Should -Be 'MockValue3'
                $result.MyResourceProperty | Should -Be 'MockValue4'
                $result.MyResourceReadProperty | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When using parameter Type' {
        Context 'When getting all key properties' {
            BeforeAll {
                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty2

    [DscProperty(Mandatory)]
    [System.String]
    $MyResourceMandatoryProperty

    [DscProperty()]
    [System.String]
    $MyResourceProperty

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
$script:mockResourceBaseInstance.MyResourceKeyProperty1 = 'MockValue1'
$script:mockResourceBaseInstance.MyResourceKeyProperty2 = 'MockValue2'
$script:mockResourceBaseInstance.MyResourceMandatoryProperty = 'MockValue3'
$script:mockResourceBaseInstance.MyResourceProperty = 'MockValue4'
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Get-DscProperty -Type 'Key' -InputObject $script:mockResourceBaseInstance

                    $result | Should -BeOfType [System.Collections.Hashtable]

                    $result.Keys | Should -Not -Contain 'MyResourceProperty' -Because 'optional properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceMandatoryProperty' -Because 'mandatory properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceReadProperty' -Because 'read properties should not be part of the collection'

                    $result.Keys | Should -Contain 'MyResourceKeyProperty1' -Because 'the property is a key property'
                    $result.Keys | Should -Contain 'MyResourceKeyProperty2' -Because 'the property is a key property'

                    $result.MyResourceKeyProperty1 | Should -Be 'MockValue1'
                    $result.MyResourceKeyProperty2 | Should -Be 'MockValue2'
                }
            }
        }

        Context 'When getting all mandatory properties' {
            BeforeAll {
                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty2

    [DscProperty(Mandatory)]
    [System.String]
    $MyResourceMandatoryProperty

    [DscProperty()]
    [System.String]
    $MyResourceProperty

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
$script:mockResourceBaseInstance.MyResourceKeyProperty1 = 'MockValue1'
$script:mockResourceBaseInstance.MyResourceKeyProperty2 = 'MockValue2'
$script:mockResourceBaseInstance.MyResourceMandatoryProperty = 'MockValue3'
$script:mockResourceBaseInstance.MyResourceProperty = 'MockValue4'
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Get-DscProperty -Type 'Mandatory' -InputObject $script:mockResourceBaseInstance

                    $result | Should -BeOfType [System.Collections.Hashtable]

                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty1' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty2' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceProperty' -Because 'optional properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceReadProperty' -Because 'read properties should not be part of the collection'

                    $result.Keys | Should -Contain 'MyResourceMandatoryProperty' -Because 'the property is a mandatory property'

                    $result.MyResourceMandatoryProperty | Should -Be 'MockValue3'
                }
            }
        }

        Context 'When getting all optional properties' {
            BeforeAll {
                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty2

    [DscProperty(Mandatory)]
    [System.String]
    $MyResourceMandatoryProperty

    [DscProperty()]
    [System.String]
    $MyResourceProperty

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
$script:mockResourceBaseInstance.MyResourceKeyProperty1 = 'MockValue1'
$script:mockResourceBaseInstance.MyResourceKeyProperty2 = 'MockValue2'
$script:mockResourceBaseInstance.MyResourceMandatoryProperty = 'MockValue3'
$script:mockResourceBaseInstance.MyResourceProperty = 'MockValue4'
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Get-DscProperty -Type 'Optional' -InputObject $script:mockResourceBaseInstance

                    $result | Should -BeOfType [System.Collections.Hashtable]

                    $result.Keys | Should -Not -Contain 'MyResourceMandatoryProperty' -Because 'mandatory properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty1' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty2' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceReadProperty' -Because 'read properties should not be part of the collection'

                    $result.Keys | Should -Contain 'MyResourceProperty' -Because 'the property is a optional property'

                    $result.MyResourceProperty | Should -Be 'MockValue4'
                }
            }
        }

        Context 'When getting all read properties' {
            BeforeAll {
                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty2

    [DscProperty(Mandatory)]
    [System.String]
    $MyResourceMandatoryProperty

    [DscProperty()]
    [System.String]
    $MyResourceProperty

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
$script:mockResourceBaseInstance.MyResourceKeyProperty1 = 'MockValue1'
$script:mockResourceBaseInstance.MyResourceKeyProperty2 = 'MockValue2'
$script:mockResourceBaseInstance.MyResourceMandatoryProperty = 'MockValue3'
$script:mockResourceBaseInstance.MyResourceProperty = 'MockValue4'
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Get-DscProperty -Type 'NotConfigurable' -InputObject $script:mockResourceBaseInstance

                    $result | Should -BeOfType [System.Collections.Hashtable]

                    $result.Keys | Should -Not -Contain 'MyResourceProperty' -Because 'optional properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceMandatoryProperty' -Because 'mandatory properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty1' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty2' -Because 'key properties should not be part of the collection'

                    $result.Keys | Should -Contain 'MyResourceReadProperty' -Because 'the property is a read property'

                    $result.MyResourceReadProperty | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When getting all optional and mandatory properties' {
            BeforeAll {
                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty2

    [DscProperty(Mandatory)]
    [System.String]
    $MyResourceMandatoryProperty

    [DscProperty()]
    [System.String]
    $MyResourceProperty

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
$script:mockResourceBaseInstance.MyResourceKeyProperty1 = 'MockValue1'
$script:mockResourceBaseInstance.MyResourceKeyProperty2 = 'MockValue2'
$script:mockResourceBaseInstance.MyResourceMandatoryProperty = 'MockValue3'
$script:mockResourceBaseInstance.MyResourceProperty = 'MockValue4'
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Get-DscProperty -Type @('Mandatory', 'Optional') -InputObject $script:mockResourceBaseInstance

                    $result | Should -BeOfType [System.Collections.Hashtable]

                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty1' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty2' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceReadProperty' -Because 'read properties should not be part of the collection'

                    $result.Keys | Should -Contain 'MyResourceMandatoryProperty' -Because 'the property is a mandatory property'
                    $result.Keys | Should -Contain 'MyResourceProperty' -Because 'the property is a optional property'

                    $result.MyResourceMandatoryProperty | Should -Be 'MockValue3'
                    $result.MyResourceProperty | Should -Be 'MockValue4'
                }
            }
        }

    }

    Context 'When using parameter HasValue' {
        Context 'When getting all optional properties' {
            BeforeAll {
                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty2

    [DscProperty(Mandatory)]
    [System.String]
    $MyResourceMandatoryProperty

    [DscProperty()]
    [System.String]
    $MyResourceProperty1

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
$script:mockResourceBaseInstance.MyResourceKeyProperty1 = 'MockValue1'
$script:mockResourceBaseInstance.MyResourceKeyProperty2 = 'MockValue2'
$script:mockResourceBaseInstance.MyResourceMandatoryProperty = 'MockValue3'
$script:mockResourceBaseInstance.MyResourceProperty2 = 'MockValue5'
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should return the correct value' {
                InModuleScope -ScriptBlock {
                    $result = Get-DscProperty -Type 'Optional' -HasValue -InputObject $script:mockResourceBaseInstance

                    $result | Should -BeOfType [System.Collections.Hashtable]

                    $result.Keys | Should -Not -Contain 'MyResourceMandatoryProperty' -Because 'mandatory properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty1' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceKeyProperty2' -Because 'key properties should not be part of the collection'
                    $result.Keys | Should -Not -Contain 'MyResourceReadProperty' -Because 'optional properties should not be part of the collection'

                    $result.Keys | Should -Not -Contain 'MyResourceProperty1' -Because 'the property has a $null value'

                    $result.Keys | Should -Contain 'MyResourceProperty2' -Because 'the property has a non-null value'

                    $result.MyResourceProperty2 | Should -Be 'MockValue5'
                }
            }
        }
    }
}
