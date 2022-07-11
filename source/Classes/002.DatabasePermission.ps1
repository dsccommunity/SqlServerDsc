<#
    .SYNOPSIS
        The possible database permission states.

    .PARAMETER State
        The state of the permission.

    .PARAMETER Permission
        The permissions to be granted or denied for the user in the database.

    .NOTES
        The DSC properties specifies attributes Key and Required, those attributes
        are not honored during compilation in the current implementation of
        PowerShell DSC. They are kept here so when they do get honored it will help
        detect missing properties during compilation. The Key property is evaluate
        during runtime so that no two states are enforcing the same permission.
#>
class DatabasePermission : System.IEquatable[Object]
{
    [DscProperty(Mandatory)]
    [ValidateSet('Grant', 'GrantWithGrant', 'Deny')]
    [System.String]
    $State

    # TODO: Can we use a validate set for the permissions?
    [DscProperty(Mandatory)]
    [System.String[]]
    $Permission

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
        else
        {
            <#
                TODO: Not sure how to handle [DatabasePermission[]], this was meant to
                      throw for example if the right side was of the comparison was a
                      [String]. But this would also throw if the the left side was
                      [DatabasePermission] and the right side was [DatabasePermission[]].
                      For now it returns $false if type is not [DatabasePermission]
                      on both sides of the comparison. This can be the correct way
                      since if moving [DatabasePermission[]] to the left side and
                      the [DatabasePermission] to the right side, then the left side
                      array is filtered with the matching values on the right side.
            #>
            #throw ('Invalid type in comparison. Expected type [{0}], but the type was [{1}].' -f $this.GetType().FullName, $object.GetType().FullName)
        }

        return $isEqual
    }
}
