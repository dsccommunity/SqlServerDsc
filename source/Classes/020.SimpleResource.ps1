<#
    .SYNOPSIS
        Resource for testing.
#>

[DscResource()]
class SimpleResource
{
    [DscProperty(Key)]
    [System.String]
    $InstanceName

    [DscProperty(Key)]
    [System.String]
    $DatabaseName

    [DscProperty(Key)]
    [System.String]
    $Name

    [DscProperty()]
    [System.String]
    $ServerName = (Get-ComputerName)

    [DscProperty(Mandatory)]
    [DatabasePermission[]]
    $Permission

    [DscProperty()]
    [Ensure]
    $Ensure = [Ensure]::Present

    # [DscProperty(NotConfigurable)]
    # [Reason[]]
    # $Reasons

    [SimpleResource] Get()
    {
        $dscResourceObject = [SimpleResource] @{
            InstanceName = 'SQL2017'
            DatabaseName = 'MyDB'
            Name = 'MyPrincipal'
            ServerName = 'MyHost'
            Ensure = 'Present'
            Permission = [DatabasePermission[]] @(
                    [DatabasePermission] @{
                        State = 'Grant'
                        Permission = @('CONNECT')
                    }
                    [DatabasePermission] @{
                        State = 'Deny'
                        Permission = @('SELECT')
                    }
                )
        }

        return $dscResourceObject
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set()
    {
    }
}
