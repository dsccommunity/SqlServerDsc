<#
    .SYNOPSIS
        Formats a query string with escaped values to prevent SQL injection.

    .DESCRIPTION
        This function formats a query string with placeholders using provided
        arguments. Each argument is escaped by doubling single quotes to prevent
        SQL injection vulnerabilities. This is the standard escaping mechanism
        for SQL Server string literals.

        The function takes a format string with standard PowerShell format
        placeholders (e.g., {0}, {1}) and an array of arguments to substitute
        into those placeholders. Each argument is escaped before substitution.

    .PARAMETER Query
        Specifies the query string containing format placeholders (e.g., {0}, {1}).
        The placeholders will be replaced with the escaped values from the
        Argument parameter.

    .PARAMETER Argument
        Specifies an array of strings that will be used to format the query string.
        Each string will have single quotes escaped by doubling them before being
        substituted into the query.

    .EXAMPLE
        ConvertTo-EscapedQueryString -Query "SELECT * FROM Users WHERE Name = N'{0}'" -Argument "O'Brien"

        Returns: SELECT * FROM Users WHERE Name = N'O''Brien'

    .EXAMPLE
        ConvertTo-EscapedQueryString -Query "EXECUTE sys.sp_adddistributor @distributor = N'{0}', @password = N'{1}';" -Argument 'Server1', "Pass'word;123"

        Returns: EXECUTE sys.sp_adddistributor @distributor = N'Server1', @password = N'Pass''word;123';

    .INPUTS
        None.

    .OUTPUTS
        `System.String`

        Returns the formatted query string with escaped values.

    .NOTES
        This function escapes single quotes by doubling them, which is the
        standard SQL Server escaping mechanism for string literals. This helps
        prevent SQL injection when embedding values in dynamic T-SQL queries.
#>
function ConvertTo-EscapedQueryString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Query,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String[]]
        $Argument
    )

    $escapedArguments = @()

    foreach ($currentArgument in $Argument)
    {
        $escapedArguments += ConvertTo-SqlString -Text $currentArgument
    }

    $result = $Query -f $escapedArguments

    return $result
}
