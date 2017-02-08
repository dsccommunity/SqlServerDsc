<#
.EXAMPLE
    This example shows how to configure 2 DB Instances on the same server to have CLR enabled.
#>

$configurationData = @{
    AllNodes = @(
        @{
            NodeName = "localhost"
            SQLInstances = @("CONTENT", "DIST")
            OptionName = "clr enabled"
        }
    )
}

Configuration Example 
{
    Import-DscResource -ModuleName xSqlServer

    node localhost {
    
        foreach ($SQLInstance in $node.SQLInstances) {
        
            xSQLServerConfiguration ('SQLConfigCLR_{0}' -f $SQLInstance) {
            
                SQLServer = $node.NodeName
                SQLInstanceName = $SQLInstance
                OptionName = $node.OptionName
                OptionValue = 1
            }
        }
    }
}
