<#
    .SYNOPSIS
        The reason a property of a DSC resource is not in desired state.

    .DESCRIPTION
        A DSC resource can have a read-only property `Reasons` that the compliance
        part (audit via Azure Policy) of Azure AutoManage Machine Configuration
        uses. The property Reasons holds an array of SqlReason. Each SqlReason
        explains why a property of a DSC resource is not in desired state.
#>

class SqlReason
{
    [DscProperty()]
    [System.String]
    $Code

    [DscProperty()]
    [System.String]
    $Phrase
}
