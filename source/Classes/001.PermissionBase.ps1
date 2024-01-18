<#
    .SYNOPSIS
        This is base class to use for all permission classes.

    .PARAMETER State
        The state of the permission.

    .NOTES
        The DSC properties specifies the attribute Mandatory but State was meant
        to be attribute Key, but those attributes are not honored correctly during
        compilation in the current implementation of PowerShell DSC. If the
        attribute would have been left as Key then it would not have been possible
        to add an identical instance of ServerPermission in two separate DSC
        resource instances in a DSC configuration. The Key property only works
        on the top level DSC properties. E.g. two resources instances of
        SqlPermission in a DSC configuration trying to grant the database
        permission 'AlterAnyDatabase' in two separate databases would have failed compilation
        as a the property State would have been seen as "duplicate resource".

        Since it is not possible to use the attribute Key the State property is
        evaluate during runtime so that no two states are enforcing the same
        permission.

        The method Equals() returns $false if type is not the same on both sides
        of the comparison. There was a thought to throw an exception if the object
        being compared was of another type, but since there was issues with using
        for example [ServerPermission[]], it was left out. This can be the correct
        way since if moving for example [ServerPermission[]] to the left side and
        the for example [ServerPermission] to the right side, then the left side
        array is filtered with the matching values on the right side. This is the
        normal behavior for other types.

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
    [DscProperty(Mandatory)]
    [ValidateSet('Grant', 'GrantWithGrant', 'Deny')]
    [System.String]
    $State

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
