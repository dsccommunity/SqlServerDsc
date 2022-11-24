<#
    .SYNOPSIS
        Returns wether the specified service account require password to be provided.

    .SYNOPSIS
        Returns wether the specified service account require password to be provided.
        If the account is a (global) managed service account, virtual account, or a
        built-in account then there is no need to provide a password.

    .PARAMETER Name
        Credential name for the service account.

    .OUTPUTS
        [System.Boolean]
#>
function Test-ServiceAccountRequirePassword
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    # Assume local or domain service account.
    $requirePassword = $true

    switch -Regex ($Name.ToUpper())
    {
        # Built-in account.
        '^(?:NT ?AUTHORITY\\)?(SYSTEM|LOCALSERVICE|LOCAL SERVICE|NETWORKSERVICE|NETWORK SERVICE)$' # CSpell: disable-line
        {
            $requirePassword = $false

            break
        }

        # Virtual account.
        '^(?:NT SERVICE\\)(.*)$'
        {
            $requirePassword = $false

            break
        }

        # (Global) Managed Service Account.
        '\$$'
        {
            $requirePassword = $false

            break
        }
    }

    return $requirePassword
}
