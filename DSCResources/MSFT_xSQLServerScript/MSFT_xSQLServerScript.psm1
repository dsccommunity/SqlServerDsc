function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [System.String]
        $Username,

        [System.String]
        $Password,

        [System.String[]]
        $Variable
    )

    Import-Module -Name SQLPS -WarningAction SilentlyContinue -ErrorAction Stop
    
    $null = $PSBoundParameters.Remove("SetFilePath")
    $null = $PSBoundParameters.Remove("GetFilePath")
    $null = $PSBoundParameters.Remove("TestFilePath")

    $result = Invoke-Sqlcmd -InputFile $getFilePath @PSBoundParameters -ErrorAction Stop

    $getResult = Out-String -InputObject $result
        
    $returnValue = @{
        ServerInstance = [System.String]$ServerInstance
        SetFilePath = [System.String]$SetFilePath
        GetFilePath = [System.String]$GetFilePath
        TestFilePath = [System.String]$TestFilePath
        Username = [System.String]$Username
        Password = [System.String]$Password
        Variable = [System.String[]]$Variable
        GetResult = [System.String[]]$getresult
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [System.String]
        $Username,

        [System.String]
        $Password,

        [System.String[]]
        $Variable
    )

    Import-Module -Name SQLPS -WarningAction SilentlyContinue -ErrorAction Stop
    
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
        [parameter(Mandatory = $true)]
        [System.String]
        $ServerInstance,

        [parameter(Mandatory = $true)]
        [System.String]
        $SetFilePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $GetFilePath,

        [parameter(Mandatory = $true)]
        [System.String]
        $TestFilePath,

        [System.String]
        $Username,

        [System.String]
        $Password,

        [System.String[]]
        $Variable
    )

    Import-Module -Name SQLPS -WarningAction SilentlyContinue -ErrorAction Stop
    
    try
    {    
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

