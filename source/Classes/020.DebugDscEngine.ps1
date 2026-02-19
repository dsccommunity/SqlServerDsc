<#
    .SYNOPSIS
        The `DebugDscEngine` DSC resource is used for debugging and testing
        purposes to demonstrate DSC resource patterns and behaviors.

    .DESCRIPTION
        The `DebugDscEngine` DSC resource is used for debugging and testing
        purposes to demonstrate DSC resource patterns and behaviors. This
        resource does not perform any actual configuration changes but instead
        outputs verbose messages to help understand the DSC resource lifecycle
        and method execution flow.

        The built-in parameter **PSDscRunAsCredential** can be used to run the resource
        as another user.

        ## Requirements

        * No specific requirements - this is a debug resource for testing purposes.

        ## Known issues

        All issues are not listed here, see [here for all open issues](https://github.com/dsccommunity/SqlServerDsc/issues?q=is%3Aissue+is%3Aopen+in%3Atitle+DebugDscEngine).

    .PARAMETER KeyProperty
        Specifies the key property for the resource. This is a required property
        that uniquely identifies the resource instance.

    .PARAMETER MandatoryProperty
        Specifies a mandatory property that must be provided when using the resource.
        This demonstrates how mandatory properties work in DSC resources.

    .PARAMETER WriteProperty
        Specifies an optional write property that can be configured by the resource.
        This property can be enforced and will be compared during Test() operations.

    .PARAMETER ReadProperty
        Specifies a read-only property that is returned by the resource but cannot
        be configured. This property is populated during Get() operations to show
        the current state.

    .NOTES
        This resource is designed for debugging and testing purposes only.
        It demonstrates the proper patterns for creating DSC class-based resources
        following the SqlServerDsc module conventions.

    .EXAMPLE
        Configuration Example
        {
            Import-DscResource -ModuleName SqlServerDsc

            Node localhost
            {
                DebugDscEngine 'TestResource'
                {
                    KeyProperty       = 'UniqueIdentifier'
                    MandatoryProperty = 'RequiredValue'
                    WriteProperty     = 'ConfigurableValue'
                }
            }
        }

        This example shows how to use the DebugDscEngine resource for testing.
#>
[DscResource(RunAsCredential = 'Optional')]
class DebugDscEngine : ResourceBase
{
    [DscProperty(Key)]
    [System.String]
    $KeyProperty

    [DscProperty(Mandatory)]
    [System.String]
    $MandatoryProperty

    [DscProperty()]
    [System.String]
    $WriteProperty

    [DscProperty()]
    [System.Int32]
    $ModifyDelayMilliseconds

    [DscProperty()]
    [System.Boolean]
    $EnableDebugOutput

    [DscProperty(NotConfigurable)]
    [System.String]
    $ReadProperty

    DebugDscEngine () : base ($PSScriptRoot)
    {
        # These properties will not be enforced.
        $this.ExcludeDscProperties = @(
            'MandatoryProperty'
            'ModifyDelayMilliseconds'
            'EnableDebugOutput'
        )

        # Default simulated modification delay in milliseconds. Can be overridden by the user.
        $this.ModifyDelayMilliseconds = 100

        # Debug output disabled by default. Set to $true to enable verbose environment dump and warnings.
        $this.EnableDebugOutput = $false
    }

    [DebugDscEngine] Get()
    {
        # Output all environment variables to verify the environment
        if ($this.EnableDebugOutput)
        {
            Write-Verbose -Message ("`nEnvironment Variables from inside DSC resource:`n$([System.Environment]::GetEnvironmentVariables().GetEnumerator() | Sort-Object Key | ForEach-Object { "$( $_.Key ) = $( $_.Value )" } | Out-String)")
            Write-Warning -Message 'Mocked warning message for testing purposes.'
        }

        # Call the base method to return the properties.
        return ([ResourceBase] $this).Get()
    }

    [System.Boolean] Test()
    {
        # Call the base method to test all of the properties that should be enforced.
        return ([ResourceBase] $this).Test()
    }

    [void] Set()
    {
        # Call the base method to enforce the properties.
        ([ResourceBase] $this).Set()
    }

    <#
        Base method Get() call this method to get the current state as a hashtable.
        The parameter properties will contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message (
            $this.localizedData.Getting_CurrentState -f @(
                $properties.KeyProperty
            )
        )

        Write-Verbose -Message (
            $this.localizedData.Debug_GetCurrentState_Called -f @(
                $properties.KeyProperty,
                ($properties.Keys -join ', ')
            )
        )

        $currentState = @{
            KeyProperty       = $properties.KeyProperty.ToUpper()
            MandatoryProperty = 'CurrentMandatoryStateValue'
            WriteProperty     = 'CurrentStateValue'
            ReadProperty      = 'ReadOnlyValue_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
        }

        Write-Verbose -Message (
            $this.localizedData.Debug_GetCurrentState_Returning -f @(
                ($currentState.Keys -join ', ')
            )
        )

        return $currentState
    }

    <#
        Base method Set() call this method with the properties that are not in
        desired state and should be enforced. It is not called if all properties
        are in desired state. The variable $properties contains only the properties
        that are not in desired state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message (
            $this.localizedData.Debug_Modify_Called -f @(
                $this.KeyProperty,
                ($properties.Keys -join ', ')
            )
        )

        foreach ($propertyName in $properties.Keys)
        {
            $propertyValue = $properties[$propertyName]

            Write-Verbose -Message (
                $this.localizedData.Debug_Modify_Property -f @(
                    $propertyName,
                    $propertyValue
                )
            )

            # Simulate setting the property using configurable delay
            Start-Sleep -Milliseconds $this.ModifyDelayMilliseconds
        }

        Write-Verbose -Message (
            $this.localizedData.Debug_Modify_Completed -f $this.KeyProperty
        )
    }

    <#
        Base method Assert() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message (
            $this.localizedData.Debug_AssertProperties_Called -f @(
                $this.KeyProperty,
                ($properties.Keys -join ', ')
            )
        )

        # Validate that KeyProperty is not null or empty
        if ([System.String]::IsNullOrEmpty($properties.KeyProperty))
        {
            New-ArgumentException -ArgumentName 'KeyProperty' -Message $this.localizedData.KeyProperty_Invalid
        }

        # Validate that MandatoryProperty is not null or empty
        if ([System.String]::IsNullOrEmpty($properties.MandatoryProperty))
        {
            New-ArgumentException -ArgumentName 'MandatoryProperty' -Message $this.localizedData.MandatoryProperty_Invalid
        }

        Write-Verbose -Message (
            $this.localizedData.Debug_AssertProperties_Completed -f $this.KeyProperty
        )
    }

    <#
        Base method Normalize() call this method with the properties that was assigned
        a value.
    #>
    hidden [void] NormalizeProperties([System.Collections.Hashtable] $properties)
    {
        Write-Verbose -Message (
            $this.localizedData.Debug_NormalizeProperties_Called -f @(
                $this.KeyProperty,
                ($properties.Keys -join ', ')
            )
        )

        # Normalize KeyProperty to uppercase
        if ($properties.ContainsKey('KeyProperty'))
        {
            $this.KeyProperty = $properties.KeyProperty.ToUpper()

            Write-Verbose -Message (
                $this.localizedData.Debug_NormalizeProperties_Property -f @(
                    'KeyProperty',
                    $this.KeyProperty
                )
            )
        }

        # Normalize WriteProperty to trim whitespace
        if ($properties.ContainsKey('WriteProperty'))
        {
            $this.WriteProperty = $properties.WriteProperty.Trim()

            Write-Verbose -Message (
                $this.localizedData.Debug_NormalizeProperties_Property -f @(
                    'WriteProperty',
                    $this.WriteProperty
                )
            )
        }

        Write-Verbose -Message (
            $this.localizedData.Debug_NormalizeProperties_Completed -f $this.KeyProperty
        )
    }
}
