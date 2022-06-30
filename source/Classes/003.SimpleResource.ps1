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
        $dscResourceObject = [System.Activator]::CreateInstance($this.GetType())

        $dscResourceObject.InstanceName = 'SQL2017'
        $dscResourceObject.DatabaseName = 'MyDB'
        $dscResourceObject.Name = 'MyPrincipal'
        $dscResourceObject.ServerName = 'MyHost'
        $dscResourceObject.Ensure = 'Present'

        # Attempt 1
        <#
        $dscResourceObject.Permission = [DatabasePermission[]] @(
            [DatabasePermission] @{
                State = 'Grant'
                Permission = @('CONNECT')
            }
         )
        #>

        # Attempt 2
        <#
        $dscResourceObject.Permission = [CimInstance[]] @(
            (
                New-CimInstance -ClientOnly -ClassName 'DatabasePermission' -Namespace 'root/microsoft/windows/desiredstateconfiguration' -Property @{
                    State = 'Grant'
                    Permission = @('CONNECT')
                }
            )
        )
        #>

        # Attempt 3
        <#
        $dscResourceObject.Permission = [DatabasePermission[]] @(
            (
                New-CimInstance -ClientOnly -Namespace 'root/Microsoft/Windows/DesiredStateConfiguration' -ClassName 'DatabasePermission' -Property @{
                    State = 'Grant'
                    Permission = @('CONNECT')
                }
            )
        )
        #>
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
