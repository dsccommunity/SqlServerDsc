$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL logins

# NOTE: This resource requires WMF5 and PsDscRunAsCredential

function ConnectSQL
{
    param
    (
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )
    
    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
    
    if($SQLInstanceName -eq "MSSQLSERVER")
    {
        $ConnectSQL = $SQLServer
    }
    else
    {
        $ConnectSQL = "$SQLServer\$SQLInstanceName"
    }

    Write-Verbose "Connecting to SQL $ConnectSQL"
    $SQL = New-Object Microsoft.SqlServer.Management.Smo.Server $ConnectSQL

    if($SQL)
    {
        Write-Verbose "Connected to SQL $ConnectSQL"
        $SQL
    }
    else
    {
        Write-Verbose "Failed connecting to SQL $ConnectSQL"
    }
}


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.Management.Automation.PSCredential]
        $LoginCredential,

        [ValidateSet("SqlLogin","WindowsUser","WindowsGroup")]
        [System.String]
        $LoginType,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    if(!$SQL)
    {
        $SQL = ConnectSQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        Write-Verbose "Getting SQL logins"
        $SQLLogins = $SQL.Logins
        if($SQLLogins)
        {
            if($SQLLogins[$Name])
            {
                Write-Verbose "SQL login name $Name is present"
                $Ensure = "Present"
                $LoginType = $SQLLogins[$Name].LoginType
                Write-Verbose "SQL login name is of type $LoginType"
            }
            else
            {
                Write-Verbose "SQL login name $Name is absent"
                $Ensure = "Absent"
            }
        }
        else
        {
            Write-Verbose "Failed getting SQL logins"
            $Ensure = "Absent"
        }
    }
    else
    {
        $Ensure = "Absent"
    }

    $returnValue = @{
        Ensure = $Ensure
        Name = $Name
        LoginType = $LoginType
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.Management.Automation.PSCredential]
        $LoginCredential,

        [ValidateSet("SqlLogin","WindowsUser","WindowsGroup")]
        [System.String]
        $LoginType = "WindowsUser",

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    if(($Ensure -eq "Present") -and ($LoginType -eq "SqlLogin") -and !$PSBoundParameters.ContainsKey('LoginCredential'))
    {
        throw New-TerminatingError -ErrorType FailedLogin
    }

    if(!$SQL)
    {
        $SQL = ConnectSQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        switch($Ensure)
        {
            "Present"
            {
                try
                {
                    Write-Verbose "Creating SQL login $Name of type $LoginType"
                    $SQLLogin = New-Object Microsoft.SqlServer.Management.Smo.Login $SQL,$Name
                    $SQLLogin.LoginType = $LoginType
                    if($LoginType -eq "SqlLogin")
                    {
                        $SQLLogin.Create($LoginCredential.GetNetworkCredential().Password)
                    }
                    else
                    {
                        $SQLLogin.Create()
                    }
                }
                catch
                {
                    Write-Verbose "Failed creating SQL login $Name of type $LoginType"
                }
            }
            "Absent"
            {
                try
                {
                    Write-Verbose "Deleting SQL login $Name"
                    $SQLLogins = $SQL.Logins
                    $SQLLogins[$Name].Drop()
                }
                catch
                {
                    Write-Verbose "Failed deleting SQL login $Name"
                }
            }
        }
    }

    ### TODO update with localized helper
    if(!(Test-TargetResource @PSBoundParameters))
    {
        throw New-TerminatingError -ErrorType TestFailedAfterSet -ErrorCategory InvalidResult
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.Management.Automation.PSCredential]
        $LoginCredential,

        [ValidateSet("SqlLogin","WindowsUser","WindowsGroup")]
        [System.String]
        $LoginType = "WindowsUser",

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER"
    )

    $SQLServerLogin = Get-TargetResource @PSBoundParameters

    $result = ($SQLServerLogin.Ensure -eq $Ensure) -and ($SQLServerLogin.LoginType -eq $LoginType)
    
    $result
}


Export-ModuleMember -Function *-TargetResource