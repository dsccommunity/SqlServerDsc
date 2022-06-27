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

        Write-Verbose -Message ($this.localizedData.GetCurrentState -f $this.DnsServer, $this.GetType().Name)

        # Get all key properties.
        $keyProperty = $this |
            Get-Member -MemberType 'Property' |
            Select-Object -ExpandProperty Name |
            Where-Object -FilterScript {
                $this.GetType().GetMember($_).CustomAttributes.Where( { $_.NamedArguments.MemberName -eq 'Key' }).NamedArguments.TypedValue.Value -eq $true
            }

        $getParameters = @{}

        # TODO: Should be a member, and for each property it should call back to the derived class for proper handling.
        $specialKeyProperty = @()

        # Set ComputerName depending on value of DnsServer.
        # if ($this.DnsServer -ne 'localhost')
        # {
        #     $getParameters['ComputerName'] = $this.DnsServer
        # }

        # Set each key property that does not need special handling (those were handle above).
        $keyProperty |
            Where-Object -FilterScript {
                $_ -notin $specialKeyProperty
            } |
            ForEach-Object -Process {
                $getParameters[$_] = $this.$_
            }

        $getCurrentStateResult = $this.GetCurrentState($getParameters)

        $dscResourceObject = [System.Activator]::CreateInstance($this.GetType())

        foreach ($propertyName in $this.PSObject.Properties.Name)
        {
            if ($propertyName -in @($getCurrentStateResult.Keys))
            {
                $dscResourceObject.$propertyName = $getCurrentStateResult.$propertyName
            }
        }

        # Always set this as it won't be in the $getCurrentStateResult
        #$dscResourceObject.DnsServer = $this.DnsServer

        # Return properties.
        return $dscResourceObject
    }

    [void] Set()
    {
        $this.Assert()

        Write-Verbose -Message ($this.localizedData.SetDesiredState -f $this.DnsServer, $this.GetType().Name)

        # Call the Compare method to get enforced properties that are not in desired state.
        $propertiesNotInDesiredState = $this.Compare()

        if ($propertiesNotInDesiredState)
        {
            $propertiesToModify = $this.GetDesiredStateForSplatting($propertiesNotInDesiredState)

            $propertiesToModify.Keys | ForEach-Object -Process {
                Write-Verbose -Message ($this.localizedData.SetProperty -f $_, $propertiesToModify.$_, $this.GetType().Name)
            }

            # if ($this.DnsServer -ne 'localhost')
            # {
            #     $propertiesToModify['ComputerName'] = $this.DnsServer
            # }

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
        Write-Verbose -Message ($this.localizedData.TestDesiredState -f $this.DnsServer, $this.GetType().Name)

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
            Write-Verbose -Message ($this.localizedData.InDesiredState -f $this.DnsServer, $this.GetType().Name)
        }
        else
        {
            Write-Verbose -Message ($this.localizedData.NotInDesiredState -f $this.DnsServer, $this.GetType().Name)
        }

        return $isInDesiredState
    }

    <#
        Returns a hashtable containing all properties that should be enforced.
        This method should normally not be overridden.
    #>
    hidden [System.Collections.Hashtable[]] Compare()
    {
        $currentState = $this.Get() | ConvertFrom-DscResourceInstance
        $desiredState = $this | ConvertFrom-DscResourceInstance

        <#
            Remove properties that have $null as the value, and remove read
            properties so that there is no chance to compare those.
        #>
        @($desiredState.Keys) | ForEach-Object -Process {
            $isReadProperty = $this.GetType().GetMember($_).CustomAttributes.Where( { $_.NamedArguments.MemberName -eq 'NotConfigurable' }).NamedArguments.TypedValue.Value -eq $true

            if ($isReadProperty -or $null -eq $desiredState[$_])
            {
                $desiredState.Remove($_)
            }
        }

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
        #Assert-Module -ModuleName 'DnsServer'

        $this.AssertProperties()
    }

    # This method can be overridden if resource specific asserts are needed.
    hidden [void] AssertProperties()
    {
    }

    # This method must be overridden by a resource.
    hidden [void] Modify([System.Collections.Hashtable] $properties)
    {
        throw $this.localizedData.ModifyMethodNotImplemented
    }

    # This method must be overridden by a resource.
    hidden [System.Collections.Hashtable] GetCurrentState([System.Collections.Hashtable] $properties)
    {
        throw $this.localizedData.GetCurrentStateMethodNotImplemented
    }
}
