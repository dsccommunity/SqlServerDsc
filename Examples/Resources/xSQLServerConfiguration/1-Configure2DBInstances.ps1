<#
.EXAMPLE
	This example shows how to configure 2 DB Instances on the same server to have CLR enabled.
	The DSC configuration & data is compiled and run from a C:\Temp directory.

#>

$configData = @{

	AllNodes = @(
	
		NodeName = "localhost"
		SQLInstances = @("CONTENT", "DIST")
		OptionName = "clr enabled"
	)
}

Configuration Example 
{
    Import-DscResource -ModuleName xSqlServer

    node localhost {
	
        foreach ($SQLInstance in $node.SQLInstances) {
		
			xSQLServerConfiguration ("SQLConfigCLR_{0}" -f $SQLInstance) {
			
				SQLServer = $node.NodeName
				SQLInstanceName = $SQLInstance
				OptionName = $node.OptionName
				OptionValue = 1
			}
		}
    }
}

Example -ConfigurationData $configData

Start-DscConfiguration -Path "C:\temp\Example" -Force -Wait -Verbose