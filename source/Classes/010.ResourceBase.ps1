<#
    .SYNOPSIS
        A class with methods that are equal for all class-based resources.

    .DESCRIPTION
        A class with methods that are equal for all class-based resources.

    .NOTES
        This class should be able to be inherited by all DSC resources. This class
        shall not contain any DSC properties, neither shall it contain anything
        specific to only a single resource.
#>

class ResourceBase
{
    # Property for holding localization strings
    hidden [System.Collections.Hashtable] $localizedData = @{}

    # Property for derived class to set properties that should not be enforced.
    hidden [System.String[]] $notEnforcedProperties = @()

    # Default constructor
    ResourceBase()
    {
        # TODO: When this fails the LCM returns 'Failed to create an object of PowerShell class SqlDatabasePermission' instead of the actual error that occurred.
        $this.localizedData = Get-LocalizedDataRecursive -ClassName ($this | Get-ClassName -Recurse)
    }

    [ResourceBase] Get()
    {
        $this.Assert()

        # Get all key properties.
        $keyProperty = $this | Get-DscProperty -Type 'Key'

        Write-Verbose -Message ($this.localizedData.GetCurrentState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

        $getCurrentStateResult = $this.GetCurrentState($keyProperty)

        $dscResourceObject = [System.Activator]::CreateInstance($this.GetType())

        # Set values returned from the derived class' GetCurrentState().
        foreach ($propertyName in $this.PSObject.Properties.Name)
        {
            if ($propertyName -in @($getCurrentStateResult.Keys))
            {
                $dscResourceObject.$propertyName = $getCurrentStateResult.$propertyName
            }
        }

        # Set key property values unless it was returned from the derived class' GetCurrentState().
        foreach ($propertyName in $keyProperty.Keys)
        {
            if ($propertyName -notin @($getCurrentStateResult.Keys))
            {
                # Add the key value to the instance to be returned.
                $dscResourceObject.$propertyName = $this.$propertyName
            }
        }

        $ignoreProperty = @()

        <#
            If the derived DSC resource has a Ensure property and it was not returned
            by GetCurrentState(), then the property Ensure is removed from the
            comparison (when calling Compare()). The property Ensure is ignored
            since the method GetCurrentState() did not return it, and the current
            state for property Ensure cannot be determined until the method Compare()
            has run to determined if other properties are not in desired state.
        #>
        if (($this | Test-ResourceHasProperty -Name 'Ensure') -and -not $getCurrentStateResult.ContainsKey('Ensure'))
        {
            $ignoreProperty += 'Ensure'
        }

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        $propertiesNotInDesiredState = $this.Compare($getCurrentStateResult, $ignoreProperty)

        <#
            Return the correct values for Ensure property if the derived DSC resource
            has such property and it hasn't been already set by GetCurrentState().
        #>
        if (($this | Test-ResourceHasProperty -Name 'Ensure') -and -not $getCurrentStateResult.ContainsKey('Ensure'))
        {
            if ($propertiesNotInDesiredState)
            {
                <#
                    Get all the key properties that might not be in desired state.
                    This will return $null if all key properties are in desired state.
                #>
                $keyPropertiesNotInDesiredState = $this | Get-DscProperty -Name $propertiesNotInDesiredState.Property -Type 'Key'

                if ($keyPropertiesNotInDesiredState)
                {
                    <#
                        The compare come back with at least one key property that was
                        not in desired state. That only happens if the object does not
                        exist on the node, so the Ensure value is set to Absent since
                        the object does not exist.
                    #>
                    $dscResourceObject.Ensure = [Ensure]::Absent
                }
                else
                {
                    <#
                        The compare come back with all key properties in desired state.
                        That only happens if the object exist on the node, so the Ensure
                        value is set to Present since the object exist.
                    #>
                    $dscResourceObject.Ensure = [Ensure]::Present
                }
            }
            else
            {
                <#
                    The compare come back with $null, meaning that all key properties
                    match. That only happens if the object exist on the node, so the
                    Ensure value is set to Present since the object exist.
                #>
                $dscResourceObject.Ensure = [Ensure]::Present
            }
        }

        <#
            Return the correct values for Reasons property if the derived DSC resource
            has such property and it hasn't been already set by GetCurrentState().
        #>
        if (($this | Test-ResourceHasProperty -Name 'Reasons') -and -not $getCurrentStateResult.ContainsKey('Reasons'))
        {
            # TODO: Below should be a private function ConvertTo-Reason.

            # Always return an empty array if all properties are in desired state.
            $dscResourceObject.Reasons = [Reason[]] @()

            if ($propertiesNotInDesiredState)
            {
                foreach ($property in $propertiesNotInDesiredState)
                {
                    if ($property.ExpectedValue -is [System.Enum])
                    {
                        # TODO: Maybe we just convert the advanced types to JSON and do not convert other types?
                        #       Test that on SqlDatabasePermission

                        # Return the string representation of the value (instead of the numeric value).
                        $propertyExpectedValue = $property.ExpectedValue.ToString()
                    }
                    else
                    {
                        $propertyExpectedValue = $property.ExpectedValue
                    }

                    if ($property.ActualValue -is [System.Enum])
                    {
                        # TODO: Maybe we just convert the advanced types to JSON and do not convert other types?
                        #       Test that on SqlDatabasePermission

                        # Return the string representation of the value so that conversion to json is correct.
                        $propertyActualValue = $property.ActualValue.ToString()
                    }
                    else
                    {
                        $propertyActualValue = $property.ActualValue
                    }

                    $dscResourceObject.Reasons += [Reason] @{
                        Code = '{0}:{0}:{1}' -f $this.GetType(), $property.Property
                        Phrase = 'The property {0} should be {1}, but was {2}' -f $property.Property, ($propertyExpectedValue | ConvertTo-Json -Compress), ($propertyActualValue | ConvertTo-Json -Compress)
                    }
                }
            }
        }

        # Return properties.
        return $dscResourceObject
    }

    [void] Set()
    {
        # Get all key properties.
        $keyProperty = $this | Get-DscProperty -Type 'Key'

        Write-Verbose -Message ($this.localizedData.SetDesiredState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

        $this.Assert()

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $propertiesToModify = $propertiesNotInDesiredState | ConvertFrom-CompareResult

            $propertiesToModify.Keys |
                ForEach-Object -Process {
                    Write-Verbose -Message ($this.localizedData.SetProperty -f $_, $propertiesToModify.$_)
                }

            <#
                Call the Modify() method with the properties that should be enforced
                and was not in desired state.
            #>
            $this.Modify($propertiesToModify)
        }
        else
        {
            Write-Verbose -Message $this.localizedData.NoPropertiesToSet
        }
    }

    [System.Boolean] Test()
    {
        # Get all key properties.
        $keyProperty = $this | Get-DscProperty -Type 'Key'

        Write-Verbose -Message ($this.localizedData.TestDesiredState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

        $this.Assert()

        $isInDesiredState = $true

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $isInDesiredState = $false
        }

        if ($isInDesiredState)
        {
            Write-Verbose $this.localizedData.InDesiredState
        }
        else
        {
            Write-Verbose $this.localizedData.NotInDesiredState
        }

        return $isInDesiredState
    }

    <#
        Returns a hashtable containing all properties that should be enforced and
        are not in desired state, or $null if all enforced properties are in
        desired state.

        This method should normally not be overridden.
    #>
    hidden [System.Collections.Hashtable[]] Compare()
    {
        # Get the current state, all properties except Read properties .
        $currentState = $this.Get() | Get-DscProperty -Type @('Key', 'Mandatory', 'Optional')

        return $this.Compare($currentState, @())
    }

    <#
        Returns a hashtable containing all properties that should be enforced and
        are not in desired state, or $null if all enforced properties are in
        desired state.

        This method should normally not be overridden.
    #>
    hidden [System.Collections.Hashtable[]] Compare([System.Collections.Hashtable] $currentState, [System.String[]] $excludeProperties)
    {
        # Get the desired state, all assigned properties that has an non-null value.
        $desiredState = $this | Get-DscProperty -Type @('Key', 'Mandatory', 'Optional') -HasValue

        $CompareDscParameterState = @{
            CurrentValues     = $currentState
            DesiredValues     = $desiredState
            Properties        = $desiredState.Keys
            ExcludeProperties = ($excludeProperties + $this.notEnforcedProperties) | Select-Object -Unique
            IncludeValue      = $true
            # This is needed to sort complex types.
            SortArrayValues   = $true
        }

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        return (Compare-DscParameterState @CompareDscParameterState)
    }

    # This method should normally not be overridden.
    hidden [void] Assert()
    {
        # Get the properties that has a non-null value and is not of type Read.
        $desiredState = $this | Get-DscProperty -Type @('Key', 'Mandatory', 'Optional') -HasValue

        $this.AssertProperties($desiredState)
    }

    <#
        This method can be overridden if resource specific property asserts are
        needed. The parameter properties will contain the properties that was
        assigned a value.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('AvoidEmptyNamedBlocks', '')]
    hidden [void] AssertProperties([System.Collections.Hashtable] $properties)
    {
    }

    <#
        This method must be overridden by a resource. The parameter properties will
        contain the properties that should be enforced and that are not in desired
        state.
    #>
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        throw $this.localizedData.ModifyMethodNotImplemented
    }

    <#
        This method must be overridden by a resource. The parameter properties will
        contain the key properties.
    #>
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        throw $this.localizedData.GetCurrentStateMethodNotImplemented
    }
}
