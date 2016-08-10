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
        $Credential,

        [System.String[]]
        $Variable
    )

    Import-Module -Name SQLPS -WarningAction SilentlyContinue -ErrorAction Stop
    
    if($null -ne $Credential)
    {
        $null = $PSBoundParameters.Add("Username", $Credential.UserName)
        $null = $PSBoundParameters.Add("Password", $Credential.GetNetworkCredential().password)

        $null = $PSBoundParameters.Remove("Credential")
    }

    $null = $PSBoundParameters.Remove("SetFilePath")
    $null = $PSBoundParameters.Remove("GetFilePath")
    $null = $PSBoundParameters.Remove("TestFilePath")

    $result = Invoke-Sqlcmd -InputFile $getFilePath @PSBoundParameters -ErrorAction Stop

    $getResult = Out-String -InputObject $result
        
    $returnValue = @{
        ServerInstance = [System.String] $ServerInstance
        SetFilePath = [System.String] $SetFilePath
        GetFilePath = [System.String] $GetFilePath
        TestFilePath = [System.String] $TestFilePath
        Username = [System.Management.Automation.PSCredential] $Credential
        Variable = [System.String[]] $Variable
        GetResult = [System.String[]] $getresult
    }

    $returnValue
}

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
        $Credential,

        [System.String[]]
        $Variable
    )

    Import-Module -Name SQLPS -WarningAction SilentlyContinue -ErrorAction Stop
    
    if($null -ne $Credential)
    {
        $null = $PSBoundParameters.Add("Username", $Credential.UserName)
        $null = $PSBoundParameters.Add("Password", $Credential.GetNetworkCredential().password)

        $null = $PSBoundParameters.Remove("Credential")
    }

    $null = $PSBoundParameters.Remove("SetFilePath")
    $null = $PSBoundParameters.Remove("GetFilePath")
    $null = $PSBoundParameters.Remove("TestFilePath")

    Invoke-Sqlcmd -InputFile $setFilePath @PSBoundParameters -ErrorAction Stop 
}


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
        $Credential,

        [System.String[]]
        $Variable
    )

    Import-Module -Name SQLPS -WarningAction SilentlyContinue -ErrorAction Stop
    
    try
    {   
        if($null -ne $Credential)
        {
            $null = $PSBoundParameters.Add("Username", $Credential.UserName)
            $null = $PSBoundParameters.Add("Password", $Credential.GetNetworkCredential().password)

            $null = $PSBoundParameters.Remove("Credential")
        }
     
        $null = $PSBoundParameters.Remove("SetFilePath")
        $null = $PSBoundParameters.Remove("GetFilePath")
        $null = $PSBoundParameters.Remove("TestFilePath")

        $result = Invoke-Sqlcmd -InputFile $testFilePath @PSBoundParameters -ErrorAction stop

        if($result -eq $null)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    catch
    {
        Write-Verbose $_
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource

