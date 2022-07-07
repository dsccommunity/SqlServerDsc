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

Describe 'ResourceBase\GetCurrentState()' -Tag 'GetCurrentState' {
    Context 'When the required methods are not overridden' {
        BeforeAll {
            $mockResourceBaseInstance = InModuleScope -ScriptBlock {
                [ResourceBase]::new()
            }
        }

        Context 'When there is no override for the method GetCurrentState' {
            It 'Should throw the correct error' {
                { $mockResourceBaseInstance.GetCurrentState(@{}) } | Should -Throw $mockResourceBaseInstance.GetCurrentStateMethodNotImplemented
            }
        }
    }
}

Describe 'ResourceBase\Modify()' -Tag 'Modify' {
    Context 'When the required methods are not overridden' {
        BeforeAll {
            $mockResourceBaseInstance = InModuleScope -ScriptBlock {
                [ResourceBase]::new()
            }
        }


        Context 'When there is no override for the method Modify' {
            It 'Should throw the correct error' {
                { $mockResourceBaseInstance.Modify(@{}) } | Should -Throw $mockResourceBaseInstance.ModifyMethodNotImplemented
            }
        }
    }
}

Describe 'ResourceBase\AssertProperties()' -Tag 'AssertProperties' {
    BeforeAll {
        $mockResourceBaseInstance = InModuleScope -ScriptBlock {
            [ResourceBase]::new()
        }
    }


    It 'Should not throw' {
        $mockDesiredState = @{
            MyProperty1 = 'MyValue1'
        }

        { $mockResourceBaseInstance.AssertProperties($mockDesiredState) } | Should -Not -Throw
    }
}

Describe 'ResourceBase\Get()' -Tag 'Get' {
    Context 'When the system is in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ClassName -MockWith {
                # Only return localized strings for this class name.
                @('ResourceBase')
            }
        }

        Context 'When the configuration should be present' {
            BeforeAll {
                Mock -CommandName Get-ClassName -MockWith {
                    # Only return localized strings for this class name.
                    @('ResourceBase')
                }

                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            MyResourceKeyProperty1 = 'MyValue1'
            MyResourceProperty2 = 'MyValue2'
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should have correctly instantiated the resource class' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                    $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                }
            }

            It 'Should return the correct values for the properties' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'
                    $mockResourceBaseInstance.MyResourceProperty2 = 'MyValue2'

                    $getResult = $mockResourceBaseInstance.Get()

                    $getResult.MyResourceKeyProperty1 | Should -Be 'MyValue1'
                    $getResult.MyResourceProperty2 | Should -Be 'MyValue2'
                    $getResult.Ensure | Should -Be ([Ensure]::Present)
                    $getResult.Reasons | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When the configuration should be absent' {
            BeforeAll {
                Mock -CommandName Get-ClassName -MockWith {
                    # Only return localized strings for this class name.
                    @('ResourceBase')
                }

                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            MyResourceKeyProperty1 = 'MyValue1'
            MyResourceProperty2 = $null
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should have correctly instantiated the resource class' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                    $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                }
            }

            It 'Should return the correct values for the properties' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance.Ensure = [Ensure]::Absent
                    $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'

                    $getResult = $mockResourceBaseInstance.Get()

                    $getResult.MyResourceKeyProperty1 | Should -Be 'MyValue1'
                    $getResult.MyResourceProperty2 | Should -BeNullOrEmpty
                    $getResult.Ensure | Should -Be ([Ensure]::Absent)
                    $getResult.Reasons | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When returning Ensure property from method GetCurrentState()' {
            Context 'When the configuration should be present' {
                BeforeAll {
                    Mock -CommandName Get-ClassName -MockWith {
                        # Only return localized strings for this class name.
                        @('ResourceBase')
                    }

                    <#
                        Must use a here-string because we need to pass 'using' which must be
                        first in a scriptblock, but if it is outside the here-string then
                        PowerShell will fail to parse the test script.
                    #>
                    $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            Ensure = [Ensure]::Present
            MyResourceKeyProperty1 = 'MyValue1'
            MyResourceProperty2 = 'MyValue2'
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                    InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
                }

                It 'Should have correctly instantiated the resource class' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                        $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                    }
                }

                It 'Should return the correct values for the properties' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'
                        $mockResourceBaseInstance.MyResourceProperty2 = 'MyValue2'

                        $getResult = $mockResourceBaseInstance.Get()

                        $getResult.MyResourceKeyProperty1 | Should -Be 'MyValue1'
                        $getResult.MyResourceProperty2 | Should -Be 'MyValue2'
                        $getResult.Ensure | Should -Be ([Ensure]::Present)
                        $getResult.Reasons | Should -BeNullOrEmpty
                    }
                }
            }

            Context 'When the configuration should be absent' {
                BeforeAll {
                    Mock -CommandName Get-ClassName -MockWith {
                        # Only return localized strings for this class name.
                        @('ResourceBase')
                    }

                    <#
                        Must use a here-string because we need to pass 'using' which must be
                        first in a scriptblock, but if it is outside the here-string then
                        PowerShell will fail to parse the test script.
                    #>
                    $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            Ensure = [Ensure]::Absent
            MyResourceKeyProperty1 = 'MyValue1'
            MyResourceProperty2 = $null
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                    InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
                }

                It 'Should have correctly instantiated the resource class' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                        $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                    }
                }

                It 'Should return the correct values for the properties' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance.Ensure = [Ensure]::Absent
                        $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'

                        $getResult = $mockResourceBaseInstance.Get()

                        $getResult.MyResourceKeyProperty1 | Should -Be 'MyValue1'
                        $getResult.MyResourceProperty2 | Should -BeNullOrEmpty
                        $getResult.Ensure | Should -Be ([Ensure]::Absent)
                        $getResult.Reasons | Should -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            Mock -CommandName Get-ClassName -MockWith {
                # Only return localized strings for this class name.
                @('ResourceBase')
            }
        }

        Context 'When the configuration should be present' {
            Context 'When a non-mandatory parameter is not in desired state' {
                BeforeAll {
                    <#
                        Must use a here-string because we need to pass 'using' which must be
                        first in a scriptblock, but if it is outside the here-string then
                        PowerShell will fail to parse the test script.
                    #>
                    $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            MyResourceKeyProperty1 = 'MyValue1'
            MyResourceProperty2 = 'MyValue2'
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                    InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
                }

                It 'Should have correctly instantiated the resource class' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                        $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                    }
                }

                It 'Should return the correct values for the properties' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'
                        $mockResourceBaseInstance.MyResourceProperty2 = 'NewValue2'

                        $getResult = $mockResourceBaseInstance.Get()

                        $getResult.MyResourceKeyProperty1 | Should -Be 'MyValue1'
                        $getResult.MyResourceProperty2 | Should -Be 'MyValue2'
                        $getResult.Ensure | Should -Be ([Ensure]::Absent)

                        $getResult.Reasons | Should -HaveCount 1
                        $getResult.Reasons[0].Code | Should -Be 'MyMockResource:MyMockResource:MyResourceProperty2'
                        $getResult.Reasons[0].Phrase | Should -Be 'The property MyResourceProperty2 should be "NewValue2", but was "MyValue2"'
                    }
                }
            }

            Context 'When a mandatory parameter is not in desired state' {
                BeforeAll {
                    <#
                        Must use a here-string because we need to pass 'using' which must be
                        first in a scriptblock, but if it is outside the here-string then
                        PowerShell will fail to parse the test script.
                    #>
                    $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            MyResourceKeyProperty1 = $null
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                    InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
                }

                It 'Should have correctly instantiated the resource class' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                        $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                    }
                }

                It 'Should return the correct values for the properties' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'

                        $getResult = $mockResourceBaseInstance.Get()

                        $getResult.MyResourceKeyProperty1 | Should -BeNullOrEmpty
                        $getResult.Ensure | Should -Be ([Ensure]::Absent)

                        $getResult.Reasons | Should -HaveCount 1
                        $getResult.Reasons[0].Code | Should -Be 'MyMockResource:MyMockResource:MyResourceKeyProperty1'
                        $getResult.Reasons[0].Phrase | Should -Be 'The property MyResourceKeyProperty1 should be "MyValue1", but was null'
                    }
                }
            }
        }

        Context 'When the configuration should be absent' {
            BeforeAll {
                Mock -CommandName Get-ClassName -MockWith {
                    # Only return localized strings for this class name.
                    @('ResourceBase')
                }

                <#
                    Must use a here-string because we need to pass 'using' which must be
                    first in a scriptblock, but if it is outside the here-string then
                    PowerShell will fail to parse the test script.
                #>
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            MyResourceKeyProperty1 = 'MyValue1'
            MyResourceProperty2 = 'MyValue2'
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should have correctly instantiated the resource class' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                    $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                }
            }

            It 'Should return the correct values for the properties' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance.Ensure = [Ensure]::Absent
                    $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'
                    $mockResourceBaseInstance.MyResourceProperty2 = $null

                    $getResult = $mockResourceBaseInstance.Get()

                    $getResult.MyResourceKeyProperty1 | Should -Be 'MyValue1'
                    $getResult.MyResourceProperty2 | Should -Be 'MyValue2'
                    $getResult.Ensure | Should -Be ([Ensure]::Present)

                    $getResult.Reasons | Should -HaveCount 1
                    $getResult.Reasons[0].Code | Should -Be 'MyMockResource:MyMockResource:MyResourceProperty2'
                    $getResult.Reasons[0].Phrase | Should -Be 'The property MyResourceProperty2 should be "", but was "MyValue2"'
                }
            }
        }

        Context 'When returning Ensure property from method GetCurrentState()' {
            Context 'When the configuration should be present' {
                BeforeAll {
                    <#
                        Must use a here-string because we need to pass 'using' which must be
                        first in a scriptblock, but if it is outside the here-string then
                        PowerShell will fail to parse the test script.
                    #>
                    $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            Ensure = [Ensure]::Absent
            MyResourceKeyProperty1 = 'MyValue1'
            MyResourceProperty2 = 'MyValue2'
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                    InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
                }

                It 'Should have correctly instantiated the resource class' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                        $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                    }
                }

                It 'Should return the correct values for the properties' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'
                        $mockResourceBaseInstance.MyResourceProperty2 = 'NewValue2'

                        $getResult = $mockResourceBaseInstance.Get()

                        $getResult.MyResourceKeyProperty1 | Should -Be 'MyValue1'
                        $getResult.MyResourceProperty2 | Should -Be 'MyValue2'
                        $getResult.Ensure | Should -Be ([Ensure]::Absent)

                        $getResult.Reasons | Should -HaveCount 2

                        # The order in the array was sometimes different so could not use array index ($getResult.Reasons[0]).
                        $getResult.Reasons.Code | Should -Contain 'MyMockResource:MyMockResource:MyResourceProperty2'
                        $getResult.Reasons.Code | Should -Contain 'MyMockResource:MyMockResource:Ensure'
                        $getResult.Reasons.Phrase | Should -Contain 'The property MyResourceProperty2 should be "NewValue2", but was "MyValue2"'
                        $getResult.Reasons.Phrase | Should -Contain 'The property Ensure should be "Present", but was "Absent"'
                    }
                }
            }

            Context 'When the configuration should be absent' {
                BeforeAll {
                    Mock -CommandName Get-ClassName -MockWith {
                        # Only return localized strings for this class name.
                        @('ResourceBase')
                    }

                    <#
                        Must use a here-string because we need to pass 'using' which must be
                        first in a scriptblock, but if it is outside the here-string then
                        PowerShell will fail to parse the test script.
                    #>
                    $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [Reason[]]
    $Reasons

    [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        return @{
            Ensure = [Ensure]::Present
            MyResourceKeyProperty1 = 'MyValue1'
            MyResourceProperty2 = 'MyValue2'
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                    InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
                }

                It 'Should have correctly instantiated the resource class' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                        $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                    }
                }

                It 'Should return the correct values for the properties' {
                    InModuleScope -ScriptBlock {
                        $mockResourceBaseInstance.Ensure = [Ensure]::Absent
                        $mockResourceBaseInstance.MyResourceKeyProperty1 = 'MyValue1'

                        $getResult = $mockResourceBaseInstance.Get()

                        $getResult.MyResourceKeyProperty1 | Should -Be 'MyValue1'
                        $getResult.MyResourceProperty2 | Should -Be 'MyValue2'
                        $getResult.Ensure | Should -Be ([Ensure]::Present)

                        $getResult.Reasons | Should -HaveCount 1

                        $getResult.Reasons[0].Code | Should -Be 'MyMockResource:MyMockResource:Ensure'
                        $getResult.Reasons[0].Phrase | Should -Be 'The property Ensure should be "Absent", but was "Present"'
                    }
                }
            }
        }
    }
}

Describe 'ResourceBase\Test()' -Tag 'Test' {
    BeforeAll {
        Mock -CommandName Get-ClassName -MockWith {
            # Only return localized strings for this class name.
            @('ResourceBase')
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            <#
                This will override (mock) the method Compare() that is called by Test().
                Overriding this method is something a derived class normally should not
                do, but done here to simplify the tests.
            #>
            $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [System.Collections.Hashtable[]] Compare()
    {
        return $null
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

            InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
        }

        It 'Should have correctly instantiated the resource class' {
            InModuleScope -ScriptBlock {
                $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $mockResourceBaseInstance.Test() | Should -BeTrue
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            <#
                This will override (mock) the method Compare() that is called by Test().
                Overriding this method is something a derived class normally should not
                do, but done here to simplify the tests.
            #>
            $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [System.Collections.Hashtable[]] Compare()
    {
        # Could just return any non-null object, but mocking a real result.
        return @{
            Property      = 'MyResourceProperty2'
            ExpectedValue = '1'
            ActualValue   = '2'
        }
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

            InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
        }

        It 'Should have correctly instantiated the resource class' {
            InModuleScope -ScriptBlock {
                $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $mockResourceBaseInstance.Test() | Should -BeFalse
            }
        }
    }
}

Describe 'ResourceBase\Compare()' -Tag 'Compare' {
    BeforeAll {
        Mock -CommandName Get-ClassName -MockWith {
            # Only return localized strings for this class name.
            @('ResourceBase')
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $MyResourceKeyProperty1

    [DscProperty()]
    [System.String]
    $MyResourceProperty2

    [DscProperty(NotConfigurable)]
    [System.String]
    $MyResourceReadProperty

    [ResourceBase] Get()
    {
        # Creates a new instance of the mock instance MyMockResource.
        $currentStateInstance = [System.Activator]::CreateInstance($this.GetType())

        $currentStateInstance.MyResourceProperty2 = 'MyValue1'
        $currentStateInstance.MyResourceReadProperty = 'MyReadValue1'

        return $currentStateInstance
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

            InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
        }

        It 'Should have correctly instantiated the resource class' {
            InModuleScope -ScriptBlock {
                $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
            }
        }

        Context 'When no properties are enforced' {
            It 'Should not return any property to enforce' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance.Compare() | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When one property are enforced but in desired state' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance.MyResourceProperty2 = 'MyValue1'
                }
            }

            It 'Should not return any property to enforce' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance.Compare() | Should -BeNullOrEmpty -Because 'no result ($null) means all properties are in desired state'
                }
            }
        }
    }

    Context 'When the system is not in the desired state' {
        BeforeAll {
            $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
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

    [ResourceBase] Get()
    {
        # Creates a new instance of the mock instance MyMockResource.
        $currentStateInstance = [System.Activator]::CreateInstance($this.GetType())

        $currentStateInstance.MyResourceProperty2 = 'MyValue1'
        $currentStateInstance.MyResourceProperty3 = 'MyValue2'
        $currentStateInstance.MyResourceReadProperty = 'MyReadValue1'

        return $currentStateInstance
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

            InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
        }

        It 'Should have correctly instantiated the resource class' {
            InModuleScope -ScriptBlock {
                $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
            }
        }

        Context 'When only enforcing one property' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    # Set desired value for the property that should be enforced.
                    $mockResourceBaseInstance.MyResourceProperty2 = 'MyNewValue'
                }
            }

            It 'Should return the correct property that is not in desired state' {
                InModuleScope -ScriptBlock {
                    $compareResult = $mockResourceBaseInstance.Compare()
                    $compareResult | Should -HaveCount 1

                    $compareResult[0].Property | Should -Be 'MyResourceProperty2'
                    $compareResult[0].ExpectedValue | Should -Be 'MyNewValue'
                    $compareResult[0].ActualValue | Should -Be 'MyValue1'
                }
            }
        }

        Context 'When only enforcing two properties' {
            BeforeAll {
                InModuleScope -ScriptBlock {
                    # Set desired value for the properties that should be enforced.
                    $mockResourceBaseInstance.MyResourceProperty2 = 'MyNewValue1'
                    $mockResourceBaseInstance.MyResourceProperty3 = 'MyNewValue2'
                }
            }

            It 'Should return the correct property that is not in desired state' {
                InModuleScope -ScriptBlock {
                    <#
                        The properties that are returned are not [ordered] so they can
                        come in any order from run to run. The test handle that.
                    #>
                    $compareResult = $mockResourceBaseInstance.Compare()
                    $compareResult | Should -HaveCount 2

                    $compareResult.Property | Should -Contain 'MyResourceProperty2'
                    $compareResult.Property | Should -Contain 'MyResourceProperty3'

                    $compareProperty = $compareResult.Where( { $_.Property -eq 'MyResourceProperty2' })
                    $compareProperty.ExpectedValue | Should -Be 'MyNewValue1'
                    $compareProperty.ActualValue | Should -Be 'MyValue1'

                    $compareProperty = $compareResult.Where( { $_.Property -eq 'MyResourceProperty3' })
                    $compareProperty.ExpectedValue | Should -Be 'MyNewValue2'
                    $compareProperty.ActualValue | Should -Be 'MyValue2'
                }
            }
        }
    }
}

Describe 'ResourceBase\GetDesiredStateForSplatting()' -Tag 'GetDesiredStateForSplatting' {
    BeforeAll {
        $mockResourceBaseInstance = InModuleScope -ScriptBlock {
            [ResourceBase]::new()
        }

        $mockProperties = @(
            @{
                Property      = 'MyResourceProperty1'
                ExpectedValue = 'MyNewValue1'
                ActualValue   = 'MyValue1'
            },
            @{
                Property      = 'MyResourceProperty2'
                ExpectedValue = 'MyNewValue2'
                ActualValue   = 'MyValue2'
            }
        )
    }

    It 'Should return the correct values in a hashtable' {
        $getDesiredStateForSplattingResult = $mockResourceBaseInstance.GetDesiredStateForSplatting($mockProperties)

        $getDesiredStateForSplattingResult | Should -BeOfType [System.Collections.Hashtable]

        $getDesiredStateForSplattingResult.Keys | Should -HaveCount 2
        $getDesiredStateForSplattingResult.Keys | Should -Contain 'MyResourceProperty1'
        $getDesiredStateForSplattingResult.Keys | Should -Contain 'MyResourceProperty2'

        $getDesiredStateForSplattingResult.MyResourceProperty1 | Should -Be 'MyNewValue1'
        $getDesiredStateForSplattingResult.MyResourceProperty2 | Should -Be 'MyNewValue2'
    }
}

Describe 'ResourceBase\Set()' -Tag 'Set' {
    BeforeAll {
        Mock -CommandName Assert-Module
        Mock -CommandName Get-ClassName -MockWith {
            # Only return localized strings for this class name.
            @('ResourceBase')
        }
    }

    Context 'When the system is in the desired state' {
        BeforeAll {
            $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
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

    # Hidden property to determine whether the method Modify() was called.
    hidden [System.Collections.Hashtable] $mockModifyProperties = @{}

    [System.Collections.Hashtable[]] Compare()
    {
        return $null
    }

    [void] Modify([System.Collections.Hashtable] $properties)
    {
        $this.mockModifyProperties = $properties
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

            InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
        }

        It 'Should have correctly instantiated the resource class' {
            InModuleScope -ScriptBlock {
                $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
            }
        }

        It 'Should not set any property' {
            InModuleScope -ScriptBlock {
                $mockResourceBaseInstance.Set()

                $mockResourceBaseInstance.mockModifyProperties | Should -BeNullOrEmpty
            }
        }
    }

    Context 'When the system is not in the desired state' {
        Context 'When setting one property' {
            BeforeAll {
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
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

    # Hidden property to determine whether the method Modify() was called.
    hidden [System.Collections.Hashtable] $mockModifyProperties = @{}

    [System.Collections.Hashtable[]] Compare()
    {
        return @(
            @{
                Property      = 'MyResourceProperty2'
                ExpectedValue = 'MyNewValue1'
                ActualValue   = 'MyValue1'
            }
        )
    }

    [void] Modify([System.Collections.Hashtable] $properties)
    {
        $this.mockModifyProperties = $properties
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should have correctly instantiated the resource class' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                    $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                }
            }

            It 'Should set the correct property' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance.Set()

                    $mockResourceBaseInstance.mockModifyProperties.Keys | Should -HaveCount 1
                    $mockResourceBaseInstance.mockModifyProperties.Keys | Should -Contain 'MyResourceProperty2'

                    $mockResourceBaseInstance.mockModifyProperties.MyResourceProperty2 | Should -Contain 'MyNewValue1'
                }
            }
        }

        Context 'When setting two properties' {
            BeforeAll {
                $inModuleScopeScriptBlock = @'
using module SqlServerDsc

class MyMockResource : ResourceBase
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

    # Hidden property to determine whether the method Modify() was called.
    hidden [System.Collections.Hashtable] $mockModifyProperties = @{}

    [System.Collections.Hashtable[]] Compare()
    {
        return @(
            @{
                Property      = 'MyResourceProperty2'
                ExpectedValue = 'MyNewValue1'
                ActualValue   = 'MyValue1'
            },
            @{
                Property      = 'MyResourceProperty3'
                ExpectedValue = 'MyNewValue2'
                ActualValue   = 'MyValue2'
            }
        )
    }

    [void] Modify([System.Collections.Hashtable] $properties)
    {
        $this.mockModifyProperties = $properties
    }
}

$script:mockResourceBaseInstance = [MyMockResource]::new()
'@

                InModuleScope -ScriptBlock ([Scriptblock]::Create($inModuleScopeScriptBlock))
            }

            It 'Should have correctly instantiated the resource class' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance | Should -Not -BeNullOrEmpty
                    $mockResourceBaseInstance.GetType().BaseType.Name | Should -Be 'ResourceBase'
                }
            }

            It 'Should set the correct properties' {
                InModuleScope -ScriptBlock {
                    $mockResourceBaseInstance.Set()

                    $mockResourceBaseInstance.mockModifyProperties.Keys | Should -HaveCount 2
                    $mockResourceBaseInstance.mockModifyProperties.Keys | Should -Contain 'MyResourceProperty2'
                    $mockResourceBaseInstance.mockModifyProperties.Keys | Should -Contain 'MyResourceProperty3'

                    $mockResourceBaseInstance.mockModifyProperties.MyResourceProperty2 | Should -Contain 'MyNewValue1'
                    $mockResourceBaseInstance.mockModifyProperties.MyResourceProperty3 | Should -Contain 'MyNewValue2'
                }
            }
        }
    }
}
