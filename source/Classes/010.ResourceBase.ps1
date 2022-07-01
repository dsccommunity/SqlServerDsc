<#
    .SYNOPSIS
        A class with methods that are equal for all class-based resources.

    .DESCRIPTION
        A class with methods that are equal for all class-based resources.

    .NOTES
        This class should not contain any DSC properties.
#>

class ResourceBase
{
    # Hidden property for holding localization strings
    hidden [System.Collections.Hashtable] $localizedData = @{}

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
        $keyProperty = $this | Get-KeyProperty

        # TODO: TA BORT -VERBOSE
        Write-Verbose -Verbose -Message ($this.localizedData.GetCurrentState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

        <#
            TODO: Should call back to the derived class for proper handling of adding
                  additional parameters to the variable $keyProperty that needs to be
                  passed to GetCurrentState().
        #>
        #$specialKeyProperty = @()

        $getCurrentStateResult = $this.GetCurrentState($keyProperty)

        Write-Verbose -Verbose -Message ($getCurrentStateResult | Out-String)

        $dscResourceObject = [System.Activator]::CreateInstance($this.GetType())

        foreach ($propertyName in $this.PSObject.Properties.Name)
        {
            if ($propertyName -in @($getCurrentStateResult.Keys))
            {
                $dscResourceObject.$propertyName = $getCurrentStateResult.$propertyName
            }
        }

        # Return properties.
        return $dscResourceObject
    }

    [void] Set()
    {
        # Get all key properties.
        $keyProperty = $this | Get-KeyProperty

        Write-Verbose -Verbose -Message ($this.localizedData.SetDesiredState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

        $this.Assert()

        # Call the Compare method to get enforced properties that are not in desired state.
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $propertiesToModify = $this.GetDesiredStateForSplatting($propertiesNotInDesiredState)

            $propertiesToModify.Keys | ForEach-Object -Process {
                Write-Verbose -Verbose -Message ($this.localizedData.SetProperty -f $_, $propertiesToModify.$_)
            }

            <#
                Call the Modify() method with the properties that should be enforced
                and was not in desired state.
            #>
            $this.Modify($propertiesToModify)
        }
        else
        {
            Write-Verbose -Verbose -Message $this.localizedData.NoPropertiesToSet
        }
    }

    [System.Boolean] Test()
    {
        # Get all key properties.
        $keyProperty = $this | Get-KeyProperty

        Write-Verbose -Verbose -Message ($this.localizedData.TestDesiredState -f $this.GetType().Name, ($keyProperty | ConvertTo-Json -Compress))

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
            Write-Verbose -Verbose -Message $this.localizedData.InDesiredState
        }
        else
        {
            Write-Verbose -Verbose -Message $this.localizedData.NotInDesiredState
        }

        return $isInDesiredState
    }

    <#
        Returns a hashtable containing all properties that should be enforced and
        are not in desired state.

        This method should normally not be overridden.
    #>
    hidden [System.Collections.Hashtable[]] Compare()
    {
        $currentState = $this.Get() | ConvertFrom-DscResourceInstance
        $desiredState = $this | Get-DesiredStateProperty

        $CompareDscParameterState = @{
            CurrentValues     = $currentState
            DesiredValues     = $desiredState
            Properties        = $desiredState.Keys
            ExcludeProperties = @('DnsServer')
            IncludeValue      = $true
        }

        <#
            Returns all enforced properties not in desires state, or $null if
            all enforced properties are in desired state.
        #>
        return (Compare-DscParameterState @CompareDscParameterState)
    }

    # Returns a hashtable containing all properties that should be enforced.
    hidden [System.Collections.Hashtable] GetDesiredStateForSplatting([System.Collections.Hashtable[]] $Properties)
    {
        $desiredState = @{}

        $Properties | ForEach-Object -Process {
            $desiredState[$_.Property] = $_.ExpectedValue
        }

        return $desiredState
    }

    # This method should normally not be overridden.
    hidden [void] Assert()
    {
        $desiredState = $this | Get-DesiredStateProperty

        $this.AssertProperties($desiredState)
    }

    <#
        This method can be overridden if resource specific property asserts are
        needed. The parameter properties will contain the properties that was
        passed a value.
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
