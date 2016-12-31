$script:currentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Import-Module -Name (Join-Path -Path (Split-Path -Path (Split-Path -Path $script:currentPath -Parent) -Parent) -ChildPath 'xSQLServerHelper.psm1')

<#
    .SYNOPSIS
        Returns the current state of the SQL Server features.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine. For default instances, only specify the computer name. For named instances, use the format ComputerName\InstanceName.
    
    .PARAMETER SetFilePath
        Path to SQL file that will perform Set action.

    .PARAMETER GetFilePath
        Path to SQL file that will perform Get action. SQL Queries returned by this function are returned by the Get-DscConfiguration cmdlet with the GetResult parameter.

    .PARAMETER TestFilePath
        ath to SQL file that will perform Test action. Any Script that does not throw an error and returns null is evaluated to true. Invoke-SqlCmd treats SQL Print statements as verbose text, this will not cause a Test to return false.

    .PARAMETER Credential
        The credentials to use to authenticate using SQL Authentication. To authenticate using Windows Authentication, assing the credentials to the built-in parameter 'PsDscRunAsCredential'. If both parameters 'Credential' and 'PsDscRunAsCredential' are not assigned, then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER Variable
        Creates a sqlcmd scripting variable for use in the sqlcmd script, and sets a value for the variable.

    .OUTPUTS
        Hash table containing key 'GetResult' which holds the value of the result from the SQL script that was ran from the parameter 'GetFilePath'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [System.String[]]
        $Variable
    )   

    $result = Invoke-SqlScript -ServerInstance $ServerInstance -SqlScriptPath $GetFilePath `
                -Credential $Credential -Variable $Variable -ErrorAction Stop

    $getResult = Out-String -InputObject $result
        
    $returnValue = @{
        ServerInstance = [System.String] $ServerInstance
        SetFilePath = [System.String] $SetFilePath
        GetFilePath = [System.String] $GetFilePath
        TestFilePath = [System.String] $TestFilePath
        Username = [System.Object] $Credential
        Variable = [System.String[]] $Variable
        GetResult = [System.String[]] $getresult
    }

    $returnValue
}

<#
    .SYNOPSIS
        Returns the current state of the SQL Server features.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine. For default instances, only specify the computer name. For named instances, use the format ComputerName\InstanceName.
    
    .PARAMETER SetFilePath
        Path to SQL file that will perform Set action.

    .PARAMETER GetFilePath
        Path to SQL file that will perform Get action. SQL Queries returned by this function are returned by the Get-DscConfiguration cmdlet with the GetResult parameter.

    .PARAMETER TestFilePath
        ath to SQL file that will perform Test action. Any Script that does not throw an error and returns null is evaluated to true. Invoke-SqlCmd treats SQL Print statements as verbose text, this will not cause a Test to return false.

    .PARAMETER Credential
        The credentials to use to authenticate using SQL Authentication. To authenticate using Windows Authentication, assing the credentials to the built-in parameter 'PsDscRunAsCredential'. If both parameters 'Credential' and 'PsDscRunAsCredential' are not assigned, then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER Variable
        Creates a sqlcmd scripting variable for use in the sqlcmd script, and sets a value for the variable.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [System.String[]]
        $Variable
    )

    Invoke-SqlScript -ServerInstance $ServerInstance -SqlScriptPath $SetFilePath `
                -Credential $Credential -Variable $Variable -ErrorAction Stop
}

<#
    .SYNOPSIS
        Returns the current state of the SQL Server features.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine. For default instances, only specify the computer name. For named instances, use the format ComputerName\InstanceName.
    
    .PARAMETER SetFilePath
        Path to SQL file that will perform Set action.

    .PARAMETER GetFilePath
        Path to SQL file that will perform Get action. SQL Queries returned by this function are returned by the Get-DscConfiguration cmdlet with the GetResult parameter.

    .PARAMETER TestFilePath
        ath to SQL file that will perform Test action. Any Script that does not throw an error and returns null is evaluated to true. Invoke-SqlCmd treats SQL Print statements as verbose text, this will not cause a Test to return false.

    .PARAMETER Credential
        The credentials to use to authenticate using SQL Authentication. To authenticate using Windows Authentication, assing the credentials to the built-in parameter 'PsDscRunAsCredential'. If both parameters 'Credential' and 'PsDscRunAsCredential' are not assigned, then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER Variable
        Creates a sqlcmd scripting variable for use in the sqlcmd script, and sets a value for the variable.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [System.String[]]
        $Variable
    )

    try
    {   
        $result = Invoke-SqlScript -ServerInstance $ServerInstance -SqlScriptPath $TestFilePath `
                -Credential $Credential -Variable $Variable -ErrorAction Stop

        if($null -eq $result)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    catch [Microsoft.SqlServer.Management.PowerShell.SqlPowerShellSqlExecutionException]
    {
        Write-Verbose $_
        return $false
    }
}

<#
    .SYNOPSIS
        Execute an SQL script located in a file on disk.

    .PARAMETER ServerInstance
        The name of an instance of the Database Engine. For default instances, only specify the computer name. For named instances, use the format ComputerName\InstanceName.
    
    .PARAMETER SqlScriptPath
        Path to SQL script file that will be executed.

    .PARAMETER Credential
        The credentials to use to authenticate using SQL Authentication. To authenticate using Windows Authentication, assing the credentials to the built-in parameter 'PsDscRunAsCredential'. If both parameters 'Credential' and 'PsDscRunAsCredential' are not assigned, then SYSTEM account will be used to authenticate using Windows Authentication.

    .PARAMETER Variable
        Creates a sqlcmd scripting variable for use in the sqlcmd script, and sets a value for the variable.
#>
function Invoke-SqlScript
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlScriptPath,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [System.String[]]
        $Variable
    )

    Import-SQLPSModule

    if($null -ne $Credential)
    {
        $null = $PSBoundParameters.Add("Username", $Credential.UserName)
        $null = $PSBoundParameters.Add("Password", $Credential.GetNetworkCredential().password)   
    }

    $null = $PSBoundParameters.Remove("Credential")
    $null = $PSBoundParameters.Remove("SqlScriptPath")

    Invoke-Sqlcmd -InputFile $SqlScriptPath @PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
