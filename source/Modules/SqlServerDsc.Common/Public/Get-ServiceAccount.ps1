<#
    .SYNOPSIS
        Builds service account parameters for service account.

    .PARAMETER ServiceAccount
        Credential for the service account.
#>
function Get-ServiceAccount
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ServiceAccount
    )

    $accountParameters = @{ }

    switch -Regex ($ServiceAccount.UserName.ToUpper())
    {
        '^(?:NT ?AUTHORITY\\)?(SYSTEM|LOCALSERVICE|LOCAL SERVICE|NETWORKSERVICE|NETWORK SERVICE)$'
        {
            $accountParameters = @{
                UserName = "NT AUTHORITY\$($Matches[1])"
            }
        }

        '^(?:NT SERVICE\\)(.*)$'
        {
            $accountParameters = @{
                UserName = "NT SERVICE\$($Matches[1])"
            }
        }

        # Testing if account is a Managed Service Account, which ends with '$'.
        '\$$'
        {
            $accountParameters = @{
                UserName = $ServiceAccount.UserName
            }
        }

        # Normal local or domain service account.
        default
        {
            $accountParameters = @{
                UserName = $ServiceAccount.UserName
                Password = $ServiceAccount.GetNetworkCredential().Password
            }
        }
    }

    return $accountParameters
}
