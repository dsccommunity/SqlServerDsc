$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Debug -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Full","Simple","BulkLogged")]
		[System.String]
		$RecoveryModel = "Full",

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlServerInstance,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName
	)

	Write-Verbose -Message "Checking Database $DatabaseName recovery mode for $RecoveryModel." -Verbose	

	$db = Get-SqlDatabase -ServerInstance $SqlServerInstance -Name $DatabaseName
    $value = ($db.RecoveryModel -eq $RecoveryModel)
	Write-Verbose -Message "Database $DatabaseName recovery mode comparison $value." -Verbose
	
    $returnValue = @{
	    RecoveryModel = $db.RecoveryModel
	    SqlServerInstance = $SqlServerInstance
	    DatabaseName = $DatabaseName
    }
	
    $returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Full","Simple","BulkLogged")]
		[System.String]
		$RecoveryModel = "Full",

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlServerInstance,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName
	)  

	$db = Get-SqlDatabase -ServerInstance $SqlServerInstance -Name $DatabaseName	
	Write-Verbose -Message "Database $DatabaseName recovery mode is $db.RecoveryModel." -Verbose
	
    if($db.RecoveryModel -ne $RecoveryModel)
    {
	    Write-Verbose -Message "Changing $DatabaseName recovery mode to $RecoveryModel." -Verbose
        $db.RecoveryModel = $RecoveryModel;
        $db.Alter();
		Write-Verbose -Message "DB $DatabaseName recovery mode is changed to $RecoveryModel." -Verbose
    }
	
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
		[parameter(Mandatory = $true)]
		[ValidateSet("Full","Simple","BulkLogged")]
		[System.String]
		$RecoveryModel = "Full",

		[parameter(Mandatory = $true)]
		[System.String]
		$SqlServerInstance,

		[parameter(Mandatory = $true)]
		[System.String]
		$DatabaseName
	)   

    $result = ((Get-TargetResource @PSBoundParameters).RecoveryModel -eq $RecoveryModel)
	
	$result
}


Export-ModuleMember -Function *-TargetResource

