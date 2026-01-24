<#
    .SYNOPSIS
    Recursively searches Exception stack for specific error number.

    .PARAMETER ExceptionToSearch
    The Exception object to test

    .PARAMETER ErrorNumber
    The specific error number to look for

    .NOTES
    This function allows us to more easily write mocks.
#>
function Find-ExceptionByNumber
{
    # Define parameters
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Exception]
        $ExceptionToSearch,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ErrorNumber
    )

    # Define working variables
    $errorFound = $false

    # Check to see if the exception has an inner exception
    if ($ExceptionToSearch.InnerException)
    {
        # Assign found to the returned recursive call
        $errorFound = Find-ExceptionByNumber -ExceptionToSearch $ExceptionToSearch.InnerException -ErrorNumber $ErrorNumber
    }

    # Check to see if it was found
    if (!$errorFound)
    {
        # Check this exceptions message
        $errorFound = $ExceptionToSearch.Number -eq $ErrorNumber
    }

    # Return
    return $errorFound
}
