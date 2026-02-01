<#
    .SYNOPSIS
        Escapes a string for use in a T-SQL string literal.

    .DESCRIPTION
        This function escapes a string for safe use in T-SQL string literals by
        doubling single quotes. This is the standard SQL Server escaping mechanism
        for preventing SQL injection when embedding values in dynamic T-SQL queries.

        Use this function when you need to escape a value that will also be used
        elsewhere (e.g., for redaction), ensuring the escaped value matches what
        appears in the final query.

    .PARAMETER Text
        Specifies the text string to escape for T-SQL.

    .EXAMPLE
        ConvertTo-SqlString -Text "O'Brien"

        Returns: O''Brien

    .EXAMPLE
        ConvertTo-SqlString -Text "Pass'word;123"

        Returns: Pass''word;123

    .EXAMPLE
        $escapedPassword = ConvertTo-SqlString -Text $password
        $query = "EXECUTE sys.sp_adddistributor @password = N'$escapedPassword';"
        Invoke-SqlDscQuery -Query $query -RedactText $escapedPassword

        Escapes the password and uses the same escaped value for both the query
        and the RedactText parameter to ensure proper redaction.

    .INPUTS
        None.

    .OUTPUTS
        System.String

        Returns the escaped string with single quotes doubled.

    .NOTES
        This function only escapes single quotes by doubling them. This is
        sufficient for SQL Server string literals enclosed in single quotes.
#>
function ConvertTo-SqlString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Text
    )

    $escapedText = $Text -replace "'", "''"

    return $escapedText
}
