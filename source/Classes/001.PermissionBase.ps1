<#
    .SYNOPSIS
        This is base class to use for all permission classes.

    .NOTES
        This base class cannot have DSC properties. If it would have, then the
        DSC resource that uses the complex type that use this as a parent class
        would fail with the error:

        The 'Permission' property with type 'DatabasePermission' of DSC resource class 'SqlDatabasePermission' is not supported."

    .EXAMPLE
        [PermissionBase] @{}

        Initializes a new instance of the PermissionBase class without any
        property values.

    .EXAMPLE
        [PermissionBase] @{ State = 'Grant' }

        Initializes a new instance of the PermissionBase class with property
        values.
#>
class PermissionBase : IComparable, System.IEquatable[Object]
{
    PermissionBase ()
    {
    }

    [System.Boolean] Equals([System.Object] $object)
    {
        $isEqual = $false

        if ($object -is $this.GetType())
        {
            if ($this.Grant -eq $object.Grant)
            {
                if (-not (Compare-Object -ReferenceObject $this.Permission -DifferenceObject $object.Permission))
                {
                    $isEqual = $true
                }
            }
        }

        return $isEqual
    }

    [System.Int32] CompareTo([Object] $object)
    {
        [System.Int32] $returnValue = 0

        if ($null -eq $object)
        {
            return 1
        }

        if ($object -is $this.GetType())
        {
            <#
                Less than zero    - The current instance precedes the object specified by the CompareTo
                                    method in the sort order.
                Zero              - This current instance occurs in the same position in the sort order
                                    as the object specified by the CompareTo method.
                Greater than zero - This current instance follows the object specified by the CompareTo
                                    method in the sort order.
            #>
            $returnValue = 0

            # Order objects in the order 'Grant', 'GrantWithGrant', 'Deny'.
            switch ($this.State)
            {
                'Grant'
                {
                    if ($object.State -in @('GrantWithGrant', 'Deny'))
                    {
                        # This current instance precedes $object
                        $returnValue = -1
                    }
                }

                'GrantWithGrant'
                {
                    if ($object.State -in @('Grant'))
                    {
                        # This current instance follows $object
                        $returnValue = 1
                    }

                    if ($object.State -in @('Deny'))
                    {
                        # This current instance precedes $object
                        $returnValue = -1
                    }
                }

                'Deny'
                {
                    if ($object.State -in @('Grant', 'GrantWithGrant'))
                    {
                        # This current instance follows $object
                        $returnValue = 1
                    }
                }
            }
        }
        else
        {
            $errorMessage = $script:localizedData.InvalidTypeForCompare -f @(
                $this.GetType().FullName,
                $object.GetType().FullName
            )

            New-InvalidArgumentException -ArgumentName 'Object' -Message $errorMessage
        }

        return $returnValue
    }

    [System.String] ToString()
    {
        $concatenatedPermission = ($this.Permission | Sort-Object) -join ', '

        return ('{0}: {1}' -f $this.State, $concatenatedPermission)
    }
}
