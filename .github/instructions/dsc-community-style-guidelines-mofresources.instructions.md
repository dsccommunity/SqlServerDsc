---
applyTo: "source/DSCResources/**/*.psm1"
---

# Guidelines for MOF-based Desired State Configuration (DSC) Resources

## Return a Hashtable from Get-TargetResource

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Return a Boolean from Test-TargetResource

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Avoid Returning Anything From Set-TargetResource

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Define Get-TargetResource, Set-TargetResource, and Test-TargetResource for Every DSC Resource

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Get-TargetResource should not contain unused non-mandatory parameters

The inclusion of a non-mandatory parameter that is never used could signal that
there is a design flaw in the implementation of the `Get-TargetResource` function.
The non-mandatory parameters that are used to call `Get-TargetResource` should help
to retrieve the actual values of the properties for the resource.
For example, if there is a parameter `Ensure` that is non-mandatory, that parameter
describes the state the resource should have, but it might not be used to retrieve
the actual values.
Another example would be if a parameter `FilePathName` is set to be non-mandatory,
but `FilePathName` is actually a property that `Get-TargetResource` should return
the actual value of.
In that case it does not make sense to assign a value to `FilePathName` when
calling `Get-TargetResource` because that value will never be used.

**Bad:**

```powershell
<#
    .SYNOPSIS
        Returns the current state of the feature.

    .PARAMETER Name
        The feature for which to return the state for.

    .PARAMETER ServerName
        The server name on which the feature is installed.

    .PARAMETER Ensure
        The desired state of the feature.
#>
function Get-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter()]
        [System.String]
        $Ensure
    )

    Write-Verbose -Message ('{0} for {1}' -f $Name, $ServerName)

    if( $Name )
    {
        $feature = 'Enabled'
    }

    return @{
        Name = $Name
        Servername = $ServerName
        Feeature = $feature
    }
}
```

**Good:**

```powershell
<#
    .SYNOPSIS
        Returns the current state of the feature.

    .PARAMETER Name
        The feature for which to return the state for.

    .PARAMETER ServerName
        The server name on which the feature is installed.
#>
function Get-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName
    )

    Write-Verbose -Message ('{0} for {1}' -f $Name, $ServerName)

    if( $Name )
    {
        $feature = 'Yes'
    }

    return @{
        Name = $Name
        Servername = $ServerName
        Feeature = $feature
    }
}
```

## Any unused parameters that must be included in a function definition should include 'Not used in \<function_name\>' in the help comment for that parameter in the comment-based help

The inclusion of a mandatory parameter in the 'Get-TargetResource' function that
is never used could signal that there is a design flaw in the implementation of
the function. The mandatory parameters that are used to call 'Get-TargetResource'
should help to retrieve the actual values of the properties for the resource.
For example, if there is a parameter 'Ensure' that is mandatory, that parameter
will not be used to retrieve the actual values. Another example would be if a
parameter 'FilePathName' is set to be mandatory, but 'FilePathName' is actually
a property that 'Get-TargetResource' should return the actual value of. In that
case it does not make sense to assign a value to 'FilePathName' when calling
'Get-TargetResource' because that value will never be used.

The inclusion of a mandatory or a non-mandatory parameter in the Test-TargetResource
function that is not used is more common since it is required that both the
'Set-TargetResource' and the 'Test-TargetResource' have the same parameters. Thus,
there will be times when not all of the parameters in the 'Test-TargetResource'
function will be used in the function.

If there is a need design-wise to include a mandatory parameter that will not be
used, then the comment-based help for that parameter should contain the description
'Not used in <function_name>'.

**Bad:**

```powershell
<#
    .SYNOPSIS
        Returns the current state of the feature.

    .PARAMETER Name
        The feature for which to return the state for.

    .PARAMETER ServerName
        The server name on which the feature is installed.

    .PARAMETER Ensure
        The desired state of the feature.
#>
function Get-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Ensure
    )

    Write-Verbose -Message ('{0} for {1}' -f $Name, $ServerName)

    if( $Name )
    {
        $feature = 'Yes'
    }

    return @{
        Name = $Name
        Servername = $ServerName
        Feeature = $feature
    }
}
```

**Good:**

```powershell
<#
    .SYNOPSIS
        Returns the current state of the feature.

    .PARAMETER Name
        The feature for which to return the state for.

    .PARAMETER ServerName
        The server name on which the feature is installed.

    .PARAMETER Ensure
        The desired state of the feature.
        Not used in Get-TargetResource
#>
function Get-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Ensure
    )

    Write-Verbose -Message ('{0} for {1}' -f $Name, $ServerName)

    if( $Name )
    {
        $feature = 'Yes'
    }

    return @{
        Name = $Name
        Servername = $ServerName
        Feeature = $feature
    }
}
```

## Use Identical Parameters for Set-TargetResource and Test-TargetResource

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Use Write-Verbose At Least Once in Get-TargetResource, Set-TargetResource, and Test-TargetResource

**Bad:**

```powershell

```

**Good:**

```powershell

```

## Use *-TargetResource for Exporting DSC Resource Functions

**Bad:**

```powershell

```

**Good:**

```powershell

```
